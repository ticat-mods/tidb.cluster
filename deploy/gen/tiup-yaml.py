# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')
sys.path.append('../../helper/tiup.helper')

from ticat import Env
from strs import to_true
from topology import TiUPYaml

def main():
	env = Env()
	depose_kvs = to_true(env.must_get('deploy.env.kvs.depose-after-deployed'))

	yaml = TiUPYaml(env, depose_kvs = depose_kvs)
	text, path = yaml.save()

	env.set('tidb.tiup.yaml', path)
	env.flush()

	print(text + '\n')
	print('tidb.tiup.yaml=' + path)

main()
