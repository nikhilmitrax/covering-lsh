import cv2
import numpy as np
import matplotlib.pyplot as plt
import sys, os

def transform(imfile):
	img = cv2.imread(imfile)
	rows,cols,ch = img.shape

	pts1 = np.float32([[50,50],[200,50],[50,200]])
	pts2 = np.float32([[10,100],[200,50],[100,250]])

	M = cv2.getAffineTransform(pts1,pts2)

	dst = cv2.warpAffine(img,M,(cols,rows))

	head, tail = os.path.split(imfile)
	head = 'd_'+head
	filename = os.path.join(head, tail)
	if not os.path.exists(head):
	    os.makedirs(head)
	print "writing", filename
	cv2.imwrite(filename,dst)

if __name__ == '__main__':
	for filename in sys.argv[1:]:
		if os.path.isdir(filename):
			for i in os.listdir(filename):
				if i.endswith('.jpg'):
					try:
						transform(filename+i)
					except Exception as e:
						print "failed", i, e
		else:
			transform(filename)