# -*- coding: utf-8 -*-

from allocating import Hosts

def deploy_non_io(deployment):
	deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_tidb()
	deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_pd()
	deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_monitoring()
	deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_grafana()

	used_vcores = deployment.used_vcores()
	if used_vcores < deployment.vcores:
		deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_pd()
		deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_pd()

	while True:
		used_vcores = deployment.used_vcores()
		if used_vcores + deployment.cost_model['tidb'] > deployment.vcores:
			break
		deployment.least_cpu_use_host().least_use_dev(nvme_only=False).deploy_tidb()

def deploy_tikv(deployment):
	run_on_all_disk = len(deployment.nvmes) == 0 or float(len(deployment.nvmes)) / float(len(deployment.devs)) < 1 / 2
	if run_on_all_disk:
		# deploy tikv on both nvme and non-nvme
		for host_name in deployment.hosts:
			for dev in deployment.hwrs[host_name].devs:
				dev.deploy_tikv()
	else:
		# deploy tikv on nvme only
		for host_name in deployment.hosts:
			for dev in deployment.hwrs[host_name].nvmes:
				dev.deploy_tikv()

	# deploy tikv * 2 on one disk:
	# - if we got lots of cpu
	# - if only deployed 2 * tikv totally, 2 is not a good amount
	used_vcores = deployment.used_vcores()
	have_extra_cpu = used_vcores < deployment.vcores / 2 - deployment.cost_model['tidb'] * 2
	if deployment.io_instance_cnt() == 2 or (have_extra_cpu and not run_on_all_disk):
		for host_name in deployment.hosts:
			for dev in deployment.hwrs[host_name].nvmes:
				dev.deploy_tikv()

def main():
	deployment = Hosts(Hosts.std_cost_model(), 'deployed-by-tom')

	for host_name in deployment.hwrs.keys():
		hwr = deployment.hwrs[host_name]
		hwr.dump()

	deploy_tikv(deployment)
		if deployment.io_instance_cnt() == 0:
			panic('[:(] try to auto select storage instance but failed')
			import sys
			sys.exit(1)

	deploy_non_io(deployment)
	deployment.flush()

	print('[:)] deploy info had written to env')

main()
