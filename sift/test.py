"""
test.py

Use this code to compare 2 images based on ORB descriptors. the meat of the editable code
is in the main checkfunc.
"""

import cv2
import numpy as np
from matplotlib import pyplot as plt

print "version", cv2.__version__

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
		bitvector_list.append(s)
	# print brief.getInt('bytes')
	# print len(kp), des.shape
	# bitvector_list = np.array(bitvector_list)
	# print type(bitvector_list)
	# print type(des)
	# print des[0][0]
	# print bitvector_list[0][0]
	# print des.dtype, bitvector_list.shape
	return img, kp, des

def matcher(des1, des2):
	# FLANN_INDEX_KDTREE = 0
	# index_params = dict(algorithm = FLANN_INDEX_KDTREE, trees = 5)
	# search_params = dict(checks=50)   # or pass empty dictionary

	# flann = cv2.FlannBasedMatcher(index_params,search_params)

	# matches = flann.knnMatch(des1,des2)
	# return matches
	# BFMatcher with default params
	bf = cv2.BFMatcher()
	matches = bf.knnMatch(des1,des2, k=2)
	# print type(matches[0][0])
	# print len(matches[0])

	for mat in matches:
		print get_attr(mat[0])
		print get_attr(mat[1])
		print
	# print matches[0][0].distance
	# print matches[0][1].distance
	# Apply ratio test
	good = []
	# for m,n in matches:
	#     if m.distance < 0.80*n.distance:
	#         good.append([m])
	return matches

def renderMatch(img1, kp1, img2, kp2, matches):
	matchesMask = [[0,0] for i in xrange(len(matches))]
	for i,x in enumerate(matches):
		# print i, type(x), len(x)
		# print 
	    if x[0].distance < 0.75*x[1].distance:
	        matchesMask[i]=[1,0]

	draw_params = dict(matchColor = (0,255,0),
	                   singlePointColor = (255,0,0),
	                   matchesMask = matchesMask,
	                   flags = 0)

	img3 = cv2.drawMatchesKnn(img1,kp1,img2,kp2,matches,None,**draw_params)
	cv2.imwrite('test.JPG',img3)
	plt.imshow(img3,),plt.show()

if __name__ == '__main__':
	img1, kp1, des1 = getDescriptor('t1.JPG')
	img2, kp2, des2 = getDescriptor('t2.JPG')
	matches = matcher(des1, des2)
	renderMatch(img1, kp1, img2, kp2, matches)