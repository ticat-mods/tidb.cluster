# -*- coding: utf-8 -*-

import os
import sys
sys.path.append('../../../helper/python.helper')

from copy import deepcopy
from ticat import Env
from ssh import ssh_exe

class Dev:
	def __init__(self, cost_model, host, name, avail, mounted, os_default = False):
		self.cost_model = cost_model
		self.host = host
		self.name = name
		self.avail = int(avail)
		self.mounted = mounted
		self.deployed = {}
		self.os_default = os_default

	def is_os_default(self):
		return self.os_default

	def is_nvme(self):
		return self.name.startswith('nvme')

	def _deploy_service(self, name):
		new_cnt = 1
		new_services = [name]
		new_io_cnt = 0
		if name in ['tikv', 'tiflash']:
			new_io_cnt = 1
		if name in self.deployed:
			old_cnt, old_services, old_io_cnt = self.deployed[name]
			new_cnt += old_cnt
			new_services = old_services + new_services
			new_io_cnt += old_io_cnt
		self.deployed[name] = (new_cnt, new_services, new_io_cnt)

	def deploy_tikv(self):
		self._deploy_service('tikv')

	def deploy_pd(self):
		self._deploy_service('pd')

	def deploy_tidb(self):
		self._deploy_service('tidb')

	def deploy_tiflash(self):
		self._deploy_service('tiflash')

	def deploy_monitoring(self):
		self._deploy_service('monitoring')

	def deploy_grafana(self):
		self._deploy_service('grafana')

	def used_vcores(self):
		used_vcores_sum = 0
		for name in self.deployed:
			_, services, _ = self.deployed[name]
			for name in services:
				used_vcores_sum += self.cost_model.need_vcores(name)
		return used_vcores_sum

	# return: map{service: (instance_cnt, used_vcores, io_instance_cnt), ...}
	def deployed_instances(self):
		return deepcopy(self.deployed)

	def io_instance_cnt(self):
		io_cnt_sum = 0
		for name in self.deployed:
			_, _, io_cnt = self.deployed[name]
			io_cnt_sum += io_cnt
		return io_cnt_sum

class Host:
	def __init__(self, cost_model, env, name):
		self.cost_model = cost_model
		self.name = name
		hwr_env = env.detach_prefix('deploy.host.resource.' + name + '.')

		self.vcores = int(hwr_env.must_get('vcores'))

		self.numa_nodes = []
		numa_nodes = hwr_env.must_get('numa')
		if len(numa_nodes) > 0:
			self.numa_nodes = numa_nodes.split(',')

		self.mem_gb = hwr_env.must_get('mem-gb')

		dev_names = hwr_env.must_get('devs')
		if len(dev_names) > 0:
			dev_names = dev_names.split(',')
		self.devs = []
		self.nvmes = []
		for dev_name in dev_names:
			dev_env = hwr_env.with_prefix('dev.' + dev_name + '.')
			avail = int(dev_env.must_get('avail'))
			mounted = dev_env.must_get('mounted')
			dev = Dev(cost_model, self, dev_name, avail, mounted)
			self.devs.append(dev)
			if dev.is_nvme():
				self.nvmes.append(dev)
		if len(dev_names) == 0:
			dev = Dev(cost_model, self, '', -1, '', True)
			self.devs.append(dev)

	def least_use_dev(self, nvme_only):
		devs = self.devs
		if nvme_only:
			devs = self.nvmes
		cand = None
		cand_used_vcores = -1
		cand_io_cnt = -1
		for dev in devs:
			io_cnt = dev.io_instance_cnt()
			used_vcores = dev.used_vcores()
			if io_cnt == 0:
				return dev
			if cand == None or cand_io_cnt > io_cnt or cand_io_cnt == io_cnt and cand_used_vcores > used_vcores:
				cand = dev
				cand_io_cnt = io_cnt
				cand_used_vcores = used_vcores
		return cand

	def used_vcores(self):
		used_vcores_sum = 0
		for dev in self.devs:
			used_vcores_sum += dev.used_vcores()
		return used_vcores_sum

	def io_instance_cnt(self):
		sum = 0
		for dev in self.devs:
			sum += dev.io_instance_cnt()
		return sum

	# return: map{service: (instance_cnt, used_vcores, io_instance_cnt), ...}
	def deployed_instances(self):
		services_sum = {}
		for dev in self.devs:
			dev_vcores, services = dev.deployed_instances()
			for name in services.keys():
				cnt, vcores, io_cnt = services[name]
				if name not in services_sum:
					services_sum[name] = (cnt, vcores, io_cnt)
				else:
					old_cnt, old_vcores, old_io_cnt = services_sum[name]
					services_sum[name] = (cnt + old_cnt, vcores + old_vcores, io_cnt + old_io_cnt)
		return services_sum

	def dump(self):
		print('host:'+self.name+', vcores:'+str(self.vcores)+', mem:'+self.mem_gb+'G'+', numa:'+str(self.numa_nodes))
		for dev in self.devs:
			print('    dev:'+dev.name+', avail:'+str(dev.avail)+', mounted:'+dev.mounted+', os-disk:'+str(dev.os_default))

class Hosts:
	def __init__(self, cost_model, deploy_dir_name):
		self.cost_model = cost_model
		self.deploy_dir_name = deploy_dir_name

		self.env = Env()

		self.deploy_to_user = self.env.must_get('deploy.to-user')
		self.deploy_user = self.env.must_get('deploy.user')

		self.hosts = []
		hosts = self.env.must_get('deploy.hosts')
		if len(hosts) > 0:
			hosts = hosts.split(',')
			for host in hosts:
				if host not in self.hosts:
					self.hosts.append(host)

		self.hwrs = {}
		self.vcores = 0
		self.nvmes = []
		self.devs = []
		for host in self.hosts:
			hwr = Host(self.cost_model, self.env, host)
			self.nvmes += hwr.nvmes
			self.devs += hwr.devs
			self.hwrs[host] = hwr

	def least_cpu_use_host(self, for_service):
		while True:
			cand = None
			max_avail_vcores = -1
			not_enough_vcores = False
			for host in self.hosts:
				hwr = self.hwrs[host]
				used_vcores = hwr.used_vcores()
				if used_vcores > hwr.vcores:
					not_enough_vcores = True
					break
				avail_vcores = hwr.vcores - used_vcores
				if cand == None or max_avail_vcores < avail_vcores:
					cand = hwr
					max_avail_vcores = avail_vcores

			if not not_enough_vcores and self.cost_model.need_vcores(for_service) <= max_avail_vcores:
				return cand
			self.cost_model.down_grade(50)

	def used_vcores(self):
		used_vcores_sum = 0
		for host in self.hosts:
			used_vcores_sum += self.hwrs[host].used_vcores()
		return used_vcores_sum

	# return: map{service: (instance_cnt, used_vcores, io_instance_cnt), ...}
	def deployed_instances(self):
		services_sum = {}
		for host in self.hosts:
			hwr = self.hwrs[host]
			services = hwr.deployed_instances()
			for name in services.keys():
				cnt, vcores, io_cnt = services[name]
				if name not in services_sum:
					services_sum[name] = (cnt, vcores, io_cnt)
				else:
					old_cnt, old_vcores, old_io_cnt = services_sum[name]
					services_sum[name] = (cnt + old_cnt, vcores + old_vcores, io_cnt + old_io_cnt)
		return services_sum

	def io_instance_cnt(self):
		sum = 0
		for host in self.hosts:
			hwr = self.hwrs[host]
			sum += hwr.io_instance_cnt()
		return sum

	def clone(self):
		return deepcopy(self)

	# TODO: auto setup numa
	def flush(self):
		services = {}
		for host in self.hosts:
			hwr = self.hwrs[host]
			id_gen = {}
			for dev in hwr.devs:
				for service in dev.deployed.keys():
					cnt, _, _ = dev.deployed[service]
					for _ in range(0, cnt):
						if service not in id_gen:
							id = host
							nid = '@+0'
							id_gen[service] = 0
						else:
							nid = '@+' + str(id_gen[service] * 2)
							id = host + nid
						location = (host, dev, id, nid)
						if service not in services:
							services[service] = [location]
						else:
							services[service].append(location)
						id_gen[service] += 1

		dirs = set()
		for service in services.keys():
			locations = services[service]
			key = 'deploy.host.' + service
			vals = []
			for i in range(0, len(locations)):
				host, dev, id, nid = locations[i]
				vals.append(id)
				if dev.is_os_default():
					continue
				on_dev_path = dev.mounted
				if on_dev_path == '/home':
					on_dev_path = os.path.join(dev.mounted, self.deploy_to_user)
				path = os.path.join(on_dev_path, self.deploy_dir_name, service + nid)
				self.env.set('deploy.prop.' + service + '.' + id + '.deploy_dir', path)
				dirs.add((host, os.path.join(on_dev_path, self.deploy_dir_name)))
			self.env.set(key, ','.join(vals))

		if self.deploy_to_user != 'tidb':
			self.env.set('deploy.prop.global.user', self.deploy_to_user)

		if not self.env.has('deploy.conf.tikv.storage.block-cache.capacity') and ('tikv' in services):
			tikvs = services['tikv']
			for i in range(0, len(tikvs)):
				host_name, dev, id, nid = tikvs[i]
				bc_id_key = 'deploy.conf.tikv.' + id + '.storage.block-cache.capacity'
				if self.env.has(bc_id_key):
					continue
				bc_host_key = 'deploy.conf.tikv.' + host_name + '.storage.block-cache.capacity'
				if self.env.has(bc_host_key):
					bc_gb = self.env.get(bc_host_key)
				else:
					host = self.hwrs[host_name]
					n = host.io_instance_cnt()
					if n <= 1:
						continue
					bc_gb = float(host.mem_gb) * 0.45 / n
					bc_gb = str(int(bc_gb)) + 'GB'
				self.env.set(bc_id_key, bc_gb)

		for host, dir in dirs:
			ssh_exe(host, 'sudo mkdir -p "' + dir + '"', self.deploy_user)
			ssh_exe(host, 'sudo chown -R ' + self.deploy_to_user + ' "' + dir + '"', self.deploy_user)

		self.env.flush()

	@staticmethod
	def std_cost_model():
		class Costs:
			def __init__(self):
				self.cost_map = {
					'tikv': 16,
					'pd': 8,
					'tidb': 16,
					'tiflash': 16,
					'monitoring': 2,
					'grafana': 4,
				}
			def down_grade(self, down_to_percent = 50):
				for service in self.cost_map.keys():
					vcores = self.cost_map[service]
					self.cost_map[service] = float(vcores) * float(down_to_percent) / 100
			def need_vcores(self, service):
				if service not in self.cost_map:
					return 0
				return self.cost_map[service]

		return Costs()
