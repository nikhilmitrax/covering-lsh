import cv2
import json
import os
import sys

def change_extension(filename, new_ext):
	return os.path.splitext(filename)[0]+new_ext


def convert_to_half(s):
	counter = 0
	new_s = ""
	for i in range(0,len(s),2):
		elem = s[i:i+2]
		counter +=1
		if elem == "00" or elem == "01":
			new_s += "0"
		else:
			new_s +="1"

	return new_s
def get_attr(obj):
	return dict([attr, getattr(obj, attr)] for attr in dir(obj) if not attr.startswith('_'))

def getDescriptor(filename):
	img = cv2.imread(filename)

	orb = cv2.ORB_create()

	kp = orb.detect(img,None)

	kp, des = orb.compute(img, kp)

	bitvector_list = []
	for i in range(des.shape[0]):
		s = ""
		for j in range(des.shape[1]):
			s+= '{0:08b}'.format(des[i][j])
		# print i, s
		s = convert_to_half(s)
		bitvector_list.append(s)
	return img, kp, bitvector_list

def run(filename):
	print filename
	img1, kp1, des1 = getDescriptor(filename)
	img_list = []
	for point, descriptor in zip(kp1, des1):
		img_dict = {'kp':get_attr(point), 'des': descriptor}
		img_list.append(img_dict)
	new_name = change_extension(filename, '.json')
	print "Writing", new_name

	with open(new_name, 'w') as outfile:
	    json.dump(img_list, outfile)
if __name__ == '__main__':
	for filename in sys.argv[1:]:
		if os.path.isdir(filename):
			for i in os.listdir(filename):
				if i.endswith('.jpg'):
					try:
						run(filename+i)
					except Exception as e:
						print "failed", i, e
		else:
			run(filename)