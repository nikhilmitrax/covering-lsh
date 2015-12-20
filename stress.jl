"""
Creates a hash table with (approximately) n keys, each key storing a set of approximately q values.
"""
function stress(n::Int,q::Int)
  x = Dict{BitArray{1}, Set{BitArray{1}}}()
  for i=1:n
    x[rand!(BitArray(128))] = Set([rand!(BitArray(128)) for i=1:q])
  end
  return x
end
