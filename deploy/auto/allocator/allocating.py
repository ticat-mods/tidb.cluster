# -*- coding: utf-8 -*-

class Dev:
	def __init__(self, name, avail, mounted):
		self.name = name
		self.avail = int(avail)
		self.mounted = mounted

	def is_nvme(self):
		return self.name.startswith('nvme')

class Host:
	def __init__(self, env, host):
		self.host = host
		hwr_env = env.detach_prefix('deploy.host.resource.' + host + '.')

		self.vcores = hwr_env.must_get('vcores')

		numa_nodes = hwr_env.must_get('numa')
		if len(numa_nodes) > 0:
			self.numa_nodes = numa_nodes.split(',')

		self.mem_gb = hwr_env.must_get('mem-gb')

		self.dev_names = []
		dev_names = hwr_env.must_get('devs')
		if len(dev_names) > 0:
			self.dev_names = dev_names.split(',')

		self.devs = []
		self.nvmes = []
		for dev_name in self.dev_names:
			dev_env = hwr_env.with_prefix('dev.' + dev_name + '.')
			avail = int(dev_env.must_get('avail'))
			mounted = dev_env.must_get('mounted')
			dev = Dev(dev_name, avail, mounted)
			self.devs.append(dev)
			if dev.is_nvme():
				self.nvmes.append(dev)

	def dump(self):
		print('host:'+self.host+', vcores:'+self.vcores+', mem:'+self.mem_gb+'G'+', numa:'+str(self.numa_nodes))
		for dev in self.devs:
			print('    dev:'+dev.name+', avail:'+str(dev.avail)+', mounted:'+dev.mounted)

class Hosts:
	def __init__(self, env):
		self.env = env

		self.hosts = []
		hosts = self.env.must_get('deploy.hosts')
		if len(hosts) > 0:
			self.hosts = hosts.split(',')

		self.hwrs = {}
		self.vcores = 0
		self.nvmes = 0
		self.devs = 0
		for host in self.hosts:
			hwr = Host(self.env, host)
			self.nvmes += len(hwr.nvmes)
			self.devs += len(hwr.devs)
			self.hwrs[host] = hwr

class Deployment:
	def __init__(self, env):
		self.env = env
		self.tikvs = set()
		self.tidbs = set()

	def add_tikv(self, tikv):
		self.tikvs.add(tikv)

	def add_tidb(self, tidb):
		self.tidbs.add(tidb)

	def flush(self):
		pass
