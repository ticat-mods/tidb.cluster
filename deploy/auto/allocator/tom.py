# -*- coding: utf-8 -*-

import sys
sys.path.append('../../../helper/python.helper')

from ticat import Env
from allocating import Hosts
from allocating import Deployment

def main():
	env = Env()

	hosts = Hosts(env)
	for host in hosts.hwrs.keys():
		hwr = hosts.hwrs[host]
		hwr.dump()

	depl = Deployment(env)
	env.flush()

main()
