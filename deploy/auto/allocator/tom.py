# -*- coding: utf-8 -*-

from allocating import Hosts

def deploy_non_io(deployment):
	deployment.least_cpu_use_host().least_use_dev(False).deploy_tidb()
	deployment.least_cpu_use_host().least_use_dev(False).deploy_pd()
	deployment.least_cpu_use_host().least_use_dev(False).deploy_monitoring()
	deployment.least_cpu_use_host().least_use_dev(False).deploy_grafana()

	used_vcores = deployment.used_vcores()
	if used_vcores < deployment.vcores:
		deployment.least_cpu_use_host().least_use_dev(False).deploy_pd()
		deployment.least_cpu_use_host().least_use_dev(False).deploy_pd()

	while True:
		used_vcores = deployment.used_vcores()
		if used_vcores + deployment.cost_model['tidb'] > deployment.vcores:
			break
		deployment.least_cpu_use_host().least_use_dev(False).deploy_tidb()

def deploy_tikv(deployment):
	if float(len(deployment.nvmes)) / float(len(deployment.devs)) < 1 / 2:
		# deploy tikv on both nvme and non-nvme
		for host_name in deployment.hosts:
			for dev in deployment.hwrs[host_name].devs:
				dev.deploy_tikv()
	else:
		# deploy tikv on nvme only
		for host_name in deployment.hosts:
			for dev in deployment.hwrs[host_name].nvmes:
				dev.deploy_tikv()
		used_vcores = deployment.used_vcores()
		# deploy tikv * 2 on one nvme if we got lots of cpu
		if used_vcores < deployment.vcores / 2 - deployment.cost_model['tidb'] * 2:
			for host_name in deployment.hosts:
				for dev in deployment.hwrs[host_name].nvmes:
					dev.deploy_tikv()

def main():
	deployment = Hosts(Hosts.std_cost_model(), 'deployed-by-tom')

	for host_name in deployment.hwrs.keys():
		hwr = deployment.hwrs[host_name]
		hwr.dump()

	deploy_tikv(deployment)
	deploy_non_io(deployment)
	deployment.flush()

	print('[:)] deploy info had written to env')

main()
