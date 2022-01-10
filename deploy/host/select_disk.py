# -*- coding: utf-8 -*-

import sys

size_1g = 1024 * 1024 * 1024

class Dev:
	def __init__(self, name, type, fs, size, parent, removable, mounted):
		self.name = name
		self.type = type
		self.fs = fs
		self.size = int(size)
		self.parent = parent
		self.removable = removable == '1'
		self.mounted = mounted
		self.avail = self.size

	def set_avail(self, avail):
		self.avail = int(avail)

	def disk(self):
		if len(self.parent) != 0:
			return self.parent
		else:
			return self.name

	def dump(self):
		mounted = self.mounted
		if len(mounted) == 0:
			mounted = '(no)'
		return "dev:"+self.name+", disk:"+self.disk()+", type:"+self.type+", fs:"+self.fs+", size:"+str(self.size)+", avail:"+str(self.avail)+", mounted:"+self.mounted

def parse_lsblk(lines):
	lines = lines.split('\n')[1:]
	blks = []
	parents = set()
	rtree = {}
	for line in lines:
		fields = line.split(' ')
		blk = Dev(fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], ' '.join(fields[6:]))
		blks.append(blk)
		parents.add(blk.parent)
		rtree[blk.name] = blk.parent

	for blk in blks:
		while blk.parent in rtree and len(rtree[blk.parent]) != 0:
			blk.parent = rtree[blk.parent]

	filtered = {}
	for blk in blks:
		if blk.mounted in ['/', '/home', '[SWAP]']:
			continue
		if blk.mounted.find('docker') >= 0:
			continue
		if blk.name.startswith('sda'):
			continue
		if blk.type not in ['disk', 'part'] and len(blk.mounted) == 0:
			continue
		if blk.name in parents:
			continue
		if blk.removable:
			continue
		if blk.avail < size_1g * 32:
			continue
		filtered['/dev/' + blk.name] = blk

	return filtered

def parse_df(lines):
	lines = lines.split('\n')[1:]
	devs = []
	for line in lines:
		fields = line.split()
		devs.append((fields[0], fields[1]))
	return devs

def parse(lsblk_lines, df_lines):
	devs = parse_lsblk(lsblk_lines)
	avails = parse_df(df_lines)
	for name, avail in avails:
		if name in devs:
			dev = devs[name]
			dev.set_avail(avail)
	return devs

def main():
	lsblk_lines = sys.argv[1]
	df_lines = sys.argv[2]

	devs = parse(lsblk_lines, df_lines)

	disks = {}
	for name in devs.keys():
		dev = devs[name]
		if dev.name not in disks:
			disks[name] = [dev]
		else:
			devs = disks[name]
			devs.append(dev)

	for name in disks.keys():
		devs = disks[name]
		devs.sort(key=lambda dev:dev.avail, reverse=True)

	# discard avail-size too small partitions
	for name in disks.keys():
		devs = disks[name]
		sum_size = 0
		candidate_size_min = 0
		for i in range(0, len(devs)):
			dev = devs[i]
			if dev.size < candidate_size_min:
				devs = devs[:i]
				break
			sum_size += dev.size
			candidate_size_min = int(sum_size / (i + 1) / 3)
		disks[name] = devs

	sys.stderr.write('disks:\n')
	for name in disks.keys():
		devs = disks[name]
		sys.stderr.write('    ' + devs[0].dump() + '\n')
		for dev in devs[1:]:
			sys.stderr.write('      ' + dev.dump() + '\n')

	for name in disks.keys():
		devs = disks[name]
		greatest = devs[0]
		print('dev.' + greatest.name + '.mounted=' + greatest.mounted)
		print('dev.' + greatest.name + '.avail=' + str(greatest.avail))
		print('dev.' + greatest.name + '.fs=' + str(greatest.fs))
		for dev in devs[1:]:
			print('dev.' + greatest.name + '.alter.' + dev.name + '.mounted=' + dev.mounted)
			print('dev.' + greatest.name + '.alter.' + dev.name + '.avail=' + str(dev.avail))
			print('dev.' + greatest.name + '.alter.' + dev.name + '.fs=' + str(dev.fs))

main()
