# -*- coding: utf-8 -*-

from allocating import Hosts

def deploy_non_io(deployment):
	if deployment.hints.pd_with_tikv:
		hosts = deployment.tikv_hosts()
		pd_number = len(hosts) >= 3 and 3 or 1
		for i in range(0, pd_number):
			hosts[i].least_use_dev(nvme_only=False).deploy_pd()

	deployment.least_cpu_use_host(for_service='tidb').least_use_dev(nvme_only=False).deploy_tidb()

	if not deployment.hints.pd_with_tikv:
		deployment.least_cpu_use_host(for_service='pd').least_use_dev(nvme_only=False).deploy_pd()

	deployment.least_cpu_use_host(for_service='monitoring').least_use_dev(nvme_only=False).deploy_monitoring()
	deployment.least_cpu_use_host(for_service='grafana').least_use_dev(nvme_only=False).deploy_grafana()

	if not deployment.hints.pd_with_tikv:
		used_vcores = deployment.used_vcores()
		if used_vcores < deployment.vcores:
			deployment.least_cpu_use_host(for_service='pd').least_use_dev(nvme_only=False).deploy_pd()
			deployment.least_cpu_use_host(for_service='pd').least_use_dev(nvme_only=False).deploy_pd()

	while True:
		used_vcores = deployment.used_vcores()
		host = deployment.least_cpu_use_host(for_service='tidb', allow_down_grade=False)
		if host == None:
			break
		host.least_use_dev(nvme_only=False).deploy_tidb()

def deploy_tikv(deployment):
	run_on_all_disk = len(deployment.nvmes) == 0 or float(len(deployment.nvmes)) / float(len(deployment.devs)) < 1 / 2
	for host_name in deployment.hosts:
		host = deployment.hwrs[host_name]
		if run_on_all_disk:
			# deploy tikv on both nvme and non-nvme
			devs = host.devs
		else:
			# deploy tikv on nvme only
			devs = host.nvmes
		for dev in devs:
			if deployment.hints.reached_tikv_total_cnt():
				return
			if deployment.hints.reached_tikv_per_host_cnt(host):
				continue
			dev.deploy_tikv()

	# deploy tikv * 2 on one disk:
	# - if we got lots of cpu
	# - if only deployed 2 * tikv totally, 2 is not a good amount

	def deploy_more(on_nvme):
		for host_name in deployment.hosts:
			host = deployment.hwrs[host_name]
			devs = on_nvme and host.nvmes or host.devs
			for dev in devs:
				if deployment.hints.reached_tikv_total_cnt():
					return
				dev.deploy_tikv()

	used_vcores = deployment.used_vcores()
	have_extra_cpu = used_vcores < deployment.vcores / 2 - deployment.cost_model.need_vcores('tidb') * 2
	if deployment.io_instance_cnt() == 2 or (have_extra_cpu and not run_on_all_disk):
		deploy_more(len(deployment.nvmes) != 0)

def main():
	deployment = Hosts(Hosts.std_cost_model(), 'deployed-by-tom')

	for host_name in deployment.hwrs.keys():
		host = deployment.hwrs[host_name]
		host.dump()

	deploy_tikv(deployment)
	if deployment.io_instance_cnt() == 0:
		print('[:(] try to auto select storage instance but failed')
		import sys
		sys.exit(1)

	deploy_non_io(deployment)
	deployment.flush()

	print('[:)] deploy info had written to env')

main()
