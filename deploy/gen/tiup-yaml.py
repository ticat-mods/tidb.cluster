# -*- coding: utf-8 -*-

##
# <delta> is:
#     -<uint> | +<uint>
#
# <port> is:
#     <uint> | <delta>
#
# <host_delta> is:
#     <host_name>@<delta>
#     eg: 127.0.0.1@3000, 127.0.0.1@+3
#
# <service> is:
#     tikv | pd | tidb | tiflash | monitored | grafana | monitoring
#
# <instance> is:
#     <service> | <service>@<host_delta>
#     # If <instance> is <service>, all instances of this type are affected
#
# ###
#
# Input env pairs:
#
#     # This will write prop key-value to global section in tiup yaml:
#       '''
#       global:
#         <conf_name>: <value>
#       '''
#     * Write by command: deploy.set.global.prop <prop_name> <value_str>
#  => deploy.prop.global.<prop_name> = <value_str>
#
#     # This will write to global sub section of 'resource_control' in tiup yaml:
#       '''
#       global:
#         resource_control:
#           <conf_name>: <value>
#       '''
#     * Write by command: deploy.set.global.resouce-control <conf_name> <value_str>
#  => deploy.resource_control.global.<conf_name> = <value_str>
#
#     # This will write prop key-value to instance config section in tiup yaml:
#       '''
#       <service>[_servers]:
#         - host: <instance_host>
#           <conf_name>: <value>
#       '''
#       - If without <instance_id>, all instance of this service will be affected
#       - If <instance_id> is 'monitored', the output will be:
#       '''
#       monitored:
#         <conf_name>: <value>
#       '''
#     * Write by command: deploy.set.<service>.prop <conf_name> <value_str> [<instance_id>]
#  => deploy.prop.<service>.<conf_name> = <value_str>
#  => deploy.prop.<service>.<instance_id>.<conf_name> = <value_str>
#
#     # This will write to service config section in tiup yaml:
#       '''
#       server_configs:
#         <service>:
#           <conf_name>: <value>
#       '''
#     * Write by command: deploy.set.<service>.config <conf_name> <value_str>
#  => deploy.conf.<service>.<conf_name> = <value_str>
#
#     # This will write to instance config section in tiup yaml: (<instance_id> is defined at L81 in this doc)
#       '''
#       <service>[_servers]:
#         - host: <instance_host>
#           config:
#             <conf_name>: <value>
#       '''
#     * Write by command: deploy.set.<service>.config <conf_name> <value_str> <instance_id>
#  => deploy.conf.<service>.<instance_id>.<conf_name> = <value_str>
#
#     # Similiar with 'deploy.global.<resource_control>.*'
#     * Write by command: deploy.set.<service>.resource-control <conf_name> <value_str> [<instance_id>]
#  => deploy.resource_control.<service>.<conf_name> = <value_str>
#  => deploy.resource_control.<service>.<instance_id>.<conf_name> = <value_str>
#
#     ###
#     # Port value calculating:
#     #   - If a  <uint> is specified, port is: <uint> + global <delta>
#     #   - If no <uint> is specified, port is: <default> + instance <delta> + global <delta>
#     ###
#
#     # Declair the global port delta, take effect in the whole time (deploy, scale in|out, ect)
#     * Write by command: deploy.set.port.delta <delta>
#  => deploy.port.delta = <delta>
#
#     # Tree purpose:
#       - Declair what instances in this cluster
#       - Declair their host and ports(by delta)
#       - <host_delta> also use as <instance_id>, for scale in|out, etc
#     * Write by command: deploy.set.<service> <host_delta>,<host_delta>,...
#  => deploy.host.<service> = <host_delta>,<host_delta>,...
#
#     # Declair additional ports of one instance or one type of services
#     * Write by command: deploy.set.<service>.port <port_name> <uint> [<instance_id>]
#  => deploy.port.<service>.<port_name> = <uint>
#  => deploy.port.<service>.<instance_id>.<port_name> = <uint>
##

import hashlib
import os
import sys
sys.path.append('../../helper/python.helper')

from ticat import Env

class Ports:
	_service_ports = {
		'tikv':
			{
				'port': 20160,
				'status_port': 20180,
			},
		'pd':
			{
				'client_port': 2379,
				'peer_port': 2380,
			},
		'tidb':
			{
				'port': 4000,
				'status_port': 10080,
			},
		'tiflash':
			{
				'tcp_port': 9000,
				'http_port': 8123,
				'flash_service_port': 3930,
				'flash_proxy_port': 20170,
				'flash_proxy_status_port': 20292,
				'metrics_port': 8234,
			},
		'monitoring':
			{
				'port': 9090,
			},
		'grafana':
			{
				'port': 3000,
			},
		'monitored':
			{
				'node_exporter_port': 9100,
				'blackbox_exporter_port': 9115,
			},
		'alertmanager':
			{
				'web_port': 9093,
				'cluster_port': 9094,
			},
	}

	@staticmethod
	def main_name(service_name):
		return {
			'tikv': 'port',
			'pd': 'client_port',
			'tidb': 'port',
			'tiflash': 'tcp_port',
			'monitoring': 'port',
			'grafana': 'port',
			'monitored': 'node_exporter_port',
			'alertmanager': 'web_port',
		}[service_name]

	@staticmethod
	def default(service_name, port_name):
		return Ports._service_ports[service_name][port_name]

	@staticmethod
	def names(service_name):
		names = []
		for name in Ports._service_ports[service_name].keys():
			names.append(name)
		return names

	@staticmethod
	def calculate_port(default, instance_delta, global_delta, values):
		values.reverse()
		for v in values:
			if is_number(v):
				port = to_int(v) + global_delta
				return port, port == default

		port = default
		for v in values:
			port += to_int(v)
		port += instance_delta + global_delta
		return port, port == default

def parse_host_port(id):
	i = id.find('@')
	if i <= 0:
		return id, ''
	return id[:i], id[i+1:]

def is_number(s):
	if len(s) > 0 and (s[0] == '+' or s[0] == '-'):
		return False
	try:
		int(s)
	except ValueError:
		return False
	else:
		return True

def is_bool(s):
	s = s.lower()
	return s == 'true' or s == 'false'

def is_delta(s):
	return len(s) > 0 and (s[0] == '+' or s[0] == '-') and is_number(s[1:])

def to_int(s):
	if len(s) == 0:
		return 0
	return int(s)

def assert_is_number(n):
	if not is_number(n):
		raise Exception(n + ' should be number')

def assert_is_delta(n):
	if not is_delta(n):
		raise Exception(n + ' should be delta value, eg: +89, -88')

def may_quote(s):
	if is_number(s) or is_bool(s):
		return s
	return '"' + s + '"'

def dump_kvs(indent, kvs):
	keys = []
	for k in kvs.keys():
		keys.append(k)
	keys.sort()
	lines = []
	for k in keys:
		# TODO: support list type value
		v = kvs[k]
		lines.append(indent + k + ': ' + may_quote(v))
	return lines

def dump_kvs_list(indent, *kvs_list):
	kvs = {}
	for it in kvs_list:
		for k in it.keys():
			v = it[k]
			kvs[k] = v
	return dump_kvs(indent, kvs)

class Attr:
	def __init__(self):
		self.props = {}
		self.ports = {}
		self.confs = {}
		self.resource = {}

class Instance:
	def __init__(self, id):
		self.host, self.port_delta = parse_host_port(id)
		if self.port_delta == '+0':
			self.id = self.host
		else:
			self.id = id
		self.attr = Attr()

class Service:
	def __init__(self, name):
		self.name = name
		self.attr = Attr()
		self.instances = []

	@staticmethod
	def is_storage(name):
		return name == 'tikv' or name == 'tiflash'

	@staticmethod
	def names():
		return ['tikv', 'pd', 'tidb', 'tiflash', 'monitoring', 'grafana', 'monitored', 'alertmanager']

	@staticmethod
	def global_configurable_names():
		# TODO: how to support tiflash-learner?
		return ['tikv', 'pd', 'tidb', 'tiflash', 'tiflash-learner']

	@staticmethod
	def output_names():
		return {
			'tikv': 'tikv_servers',
			'pd': 'pd_servers',
			'tidb': 'tidb_servers',
			'tiflash': 'tiflash_servers',
			'monitoring': 'monitoring_servers',
			'grafana': 'grafana_servers',
			'monitored': 'monitored',
			'alertmanager': 'alertmanager_servers',
		}

class HostInstanceCounter:
	def __init__(self):
		self.counter = {}

	def add_instance(self, host, service, id):
		if host not in self.counter:
			service_instances = {}
		else:
			service_instances = self.counter[host]
		if service not in service_instances:
			instances = set()
		else:
			instances = service_instances[service]
		instances.add(id)
		service_instances[service] = instances
		self.counter[host] = service_instances

	def hosts(self):
		return self.counter.keys()

	def need_location_host_label(self):
		def multi_storage(host_info):
			if 'tikv' in host_info:
				if len(host_info['tikv']) > 1:
					return True
			if 'tiflash' in host_info:
				if len(host_info['tiflash']) > 1:
					return True
			return False

		for host in self.counter.keys():
			service_instances = self.counter[host]
			if multi_storage(service_instances):
				return True
		return False

class Global:
	def __init__(self):
		self.confs = {}
		self.resource = {}

	def empty(self):
		return len(self.confs) + len(self.resource) == 0

class TiUPYaml:
	def __init__(self):
		self.delta = ''
		self.instances = {}
		self.hosts_info = HostInstanceCounter()
		self.glb = Global()

		self.session = Env()
		self.env = self.session.detach_prefix('deploy.')
		self.user_set_location_label = self.env.has('conf.pd.replication.location-labels')
		self._parse()

	def _parse(self):
		self.delta = to_int(self.env.get_ex('port.delta', ''))

		self._parse_kvs('prop.global.', self.glb.confs)
		self._parse_kvs('resource_control.global.', self.glb.resource)

		for name in Service.names():
			self._parse_service(name)

	def _parse_service(self, name):
		service = Service(name)

		if self.env.has('host.' + name):
			ids = self.env.get('host.' + name)
			if len(ids) != 0:
				ids = ids.split(',')
				for id in ids:
					instance = Instance(id)
					self._parse_kvs('prop.' + name + '.' + id + '.', instance.attr.props)
					self._parse_kvs('port.' + name + '.' + id + '.', instance.attr.ports)
					self._parse_kvs('conf.' + name + '.' + id + '.', instance.attr.confs)
					self._parse_kvs('resource_control.' + name + '.' + id + '.', instance.attr.resource)
					service.instances.append(instance)
					self.hosts_info.add_instance(instance.host, name, id)

		self._parse_kvs('prop.' + name + '.', service.attr.props)
		self._parse_kvs('port.' + name + '.', service.attr.ports)
		self._parse_kvs('conf.' + name + '.', service.attr.confs)
		self._parse_kvs('resource_control.' + name + '.', service.attr.resource)
		self.instances[name] = service

	def _parse_kvs(self, prefix, to):
		kvs = self.env.detach_prefix(prefix)
		for k in kvs.keys():
			v = kvs.get(k)
			to[k] = v

	def dump(self):
		lines = []
		if not self.glb.empty():
			lines.append('global:')
			lines += dump_kvs('  ', self.glb.confs)
			res_lines = dump_kvs('    ', self.glb.resource)
			if len(res_lines) > 0:
				lines.append('  resource_control:')
				lines += res_lines

		need_location_host_label = not self.user_set_location_label and self.hosts_info.need_location_host_label()
		services = Service.output_names()

		glb_conf_lines = []
		for name in Service.global_configurable_names():
			glb_conf_lines += self._dump_service_conf(name, need_location_host_label)
		if len(glb_conf_lines) > 0:
			lines.append('server_configs:')
			lines += glb_conf_lines

		for name in Service.names():
			if name == 'monitored':
				service_lines = self._dump_monitored()
			else:
				service_lines = self._dump_instances(name, services[name], need_location_host_label)
			lines += service_lines

		return '\n'.join(lines)

	def _dump_service_conf(self, name, need_location_host_label):
		lines = []
		if name not in self.instances:
			return lines
		service = self.instances[name]
		lines += dump_kvs('    ', service.attr.confs)
		if need_location_host_label and name == 'pd' and not self.env.has('conf.pd.replication.location-labels'):
			lines.append('    replication.location-labels: [ "host" ]')
		if len(lines) > 0:
			lines.insert(0, '  ' + name + ':')
		return lines

	def _dump_monitored(self):
		lines = []
		name = 'monitored'
		if self.delta == 0 and 'monitored' not in self.instances:
			return lines
		service = None
		if name in self.instances:
			service  = self.instances[name]

		port_names = Ports.names(name)
		port_names.sort()
		for port_name in port_names:
			service_ports = []
			if service != None:
				defined_ports = service.attr.ports
				if port_name in defined_ports:
					service_ports = [defined_ports[port_name]]
			port, is_def = Ports.calculate_port(Ports.default(name, port_name), 0, self.delta, service_ports)
			if not is_def:
				lines.append('  ' + port_name + ': ' + str(port))
		if service != None:
			lines += dump_kvs_list('  ' , service.attr.props)
		if len(lines) > 0:
			lines.insert(0, name + ':')
		return lines

	def _dump_instances(self, name, output_name, need_location_host_label):
		lines = []
		if name not in self.instances:
			return lines
		service = self.instances[name]
		if len(service.instances) == 0:
			return lines
		lines.append(output_name + ':')

		for instance in service.instances:
			lines.append('  - host: ' + instance.host)
			#lines.append('    #(deployer instance id: ' + instance.id + ')')
			lines += self._dump_ports_list(name, to_int(instance.port_delta), '    ', service.attr.ports, instance.attr.ports)

			lines += dump_kvs_list('    ' , service.attr.props, instance.attr.props)

			config_lines = dump_kvs('      ', instance.attr.confs)
			if len(config_lines) > 0 or need_location_host_label and (Service.is_storage(name)):
				lines.append('    config:')
				lines += config_lines
				if need_location_host_label:
					lines.append('      server.labels: { host: "' + instance.host + '" }')

			res_lines = dump_kvs_list('      ' , service.attr.resource, instance.attr.resource)
			if len(res_lines) > 0:
				lines.append('    resource_control:')
				lines += res_lines

		return lines

	def _dump_ports_list(self, service_name, instance_delta, indent, *ports_list):
		kvs = {}
		keys = []
		for ports in ports_list:
			for k in ports:
				if k not in kvs:
					kvs[k] = []
					keys.append(k)
				list = kvs[k]
				list.append(ports[k])
				kvs[k] = list

		if instance_delta + self.delta != 0:
			keys = Ports.names(service_name)
		keys.sort()

		lines = []
		def dump_port(name):
			list = []
			if name in kvs:
				list = kvs[name]
			port, is_def = Ports.calculate_port(Ports.default(service_name, name), instance_delta, self.delta, list)
			if not is_def:
				lines.append('    ' + name + ': ' + str(port))

		# Put the main port at the first line
		main_name = Ports.main_name(service_name)
		dump_port(main_name)
		for k in keys:
			if k == main_name:
				continue
			dump_port(k)
		return lines

	def save(self):
		text = self.dump()
		md5hash = hashlib.md5(text.encode('utf-8'))
		md5part = md5hash.hexdigest()[:7]
		path = os.path.join(sys.argv[1], md5part + '.yaml')

		file = open(path, 'w')
		file.write(text)
		file.close()

		self.session.set('tidb.tiup.yaml', path)
		self.session.flush()

		print(text + '\n')
		print('tidb.tiup.yaml=' + path)

def main():
	yaml = TiUPYaml()
	yaml.save()

main()
