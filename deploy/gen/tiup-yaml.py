# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')
sys.path.append('../../helper/tiup.helper')

from ticat import Env
from topology import TiUPYaml

def main():
	env = Env()
	yaml = TiUPYaml(env)
	text, path = yaml.save()

	env.set('tidb.tiup.yaml', path)
	env.flush()

	print(text + '\n')
	print('tidb.tiup.yaml=' + path)


main()
