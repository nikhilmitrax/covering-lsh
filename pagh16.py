#test
import BitVector
import hadamard_code
#defining dot product to be and operator

def dot(a,b, moduli = 0):
	total = 0
	s_z = min(len(a), len(b))
	for i in range(s_z):
		total += a[i]*b[i]
	if moduli != 0:
		return total%moduli
	else:
		return total

def generate_bitset(d,r):
	# mi2 = mi1 = BitVector.BitVector(intVal = 0, size = r+1)
	vector_set = set()
	for v_index in range(1,2**(r+1)):
		av = BitVector.BitVector(size = d)
		v = BitVector.BitVector(intVal = v_index, size = r+1)
		for i in range(1,d+1):
			mi = BitVector.BitVector(intVal = i, size = r+1)
			avi = dot(mi,v,2)
			av[i-1] = avi
		vector_set.add(av.int_val())
	vector_set.remove(0)
	return vector_set
def print_vector_matrix(vm, d):
	print "Size :",len(vm)
	for vec in vm:
		print BitVector.BitVector(intVal = vec, size = d)
def test_dot():
	a = BitVector.BitVector(bitstring="1011")
	b = BitVector.BitVector(bitstring="1111")
	print dot(a,b)
if __name__ == '__main__':
	all_vecs = generate_bitset(128,10)
	print_vector_matrix(all_vecs, 7)
	# test_dot()
