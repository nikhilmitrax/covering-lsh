module LSH
export LSHTable, ClassicLSHTable, SetLSHHash, PaghLSHHash, generate_bitset, PaghLSHTable, hamming
using DataStructures: MultiDict
abstract LSHTable
abstract LSHHash
type SetLSHHash <: Associative{UInt128, Array{UInt32,1}}
  g::Dict{UInt128, Array{UInt32,1}}
  #g::MultiDict{UInt128, UInt32}
  a::UInt128
  data::Array{UInt128, 1}
end
function setbit(input, bit, ind, dim)
  mask = UInt128(1)
  mask = mask << (dim - ind)
  if bit == 0
    mask = ~mask
    return (mask & input)
  else
    return (mask | input)
  end
end


function bitdot(a, b)
  dist = 0
  x = a & b
  while (x != 0)
    x = x & (x - 0x1)
    dist = dist + 1
  end
  return (dist % 2)
end

function hamming(a, b)
  dist = 0
  x = a $ b
  while (x != 0)
    x = x & (x - 0x1)
    dist = dist + 1
  end
  return dist
end

function generate_bitset(r, d=128)
  bitset = Set{UInt128}()
  for v_index=1:(2^(r+1)-1)
    av = UInt128(0)
    v = UInt128(v_index)
    for i=1:d
      mi = UInt128(i % (2^(r + 1) - 1))
      # m should be a function from {1...d} onto {0,1}^(r+1)
      #mi = UInt128(i)
      av = setbit(av, bitdot(mi, v), i, d)
    end
    push!(bitset, av)
  end
  setdiff!(bitset, UInt128(0))
  return bitset
end

function randbits(k)
  x = UInt128(0)
  for j=(128-k):(127)
    r = convert(UInt128, rand(1:j+1))
    b = UInt128(1) << r
    if (x & b) != 0
      x = x | (UInt128(1) << convert(UInt128, j))
    else
      x = x | b
    end
  end
  return x
end

function SetLSHHash(d, num_h, data)
  SetLSHHash(Dict{UInt128, Array{UInt32,1}}(), randbits(num_h), data)
  #SetLSHHash(MultiDict{UInt128, UInt32}(), rand(UInt128), data)
end

function PaghLSHHash(d, my_vec, data)
  SetLSHHash(Dict{UInt128, Array{UInt32, 1}}(), my_vec, data)
end

type ClassicLSHTable <: LSHTable
  gTable::Array{SetLSHHash, 1}
  data::Array{UInt128, 1}
  n::Int
  d::Int
  c::Int
  r::Int
  δ::Float64
end

type PaghLSHTable <: LSHTable
  gTable::Array{SetLSHHash, 1}
  data::Array{UInt128, 1}
  n::Int
  d::Int
  c::Float64
  r::Int
end
import Base.print
print(io::IO, t::SetLSHHash) = print(io, length(t.g))
print(io::IO, t::ClassicLSHTable) = print(io, t.gTable)

import Base.show
show(io::IO, t::SetLSHHash) = show(io, length(t.g))
show(io::IO, t::ClassicLSHTable) = show(io, t.gTable)


import Base.push!
#function push!(t::SetLSHHash, ptr::UInt32)
  #insert!(t.g, t.a & t.data[ptr], ptr)
#end
function push!(t::SetLSHHash, ptr::UInt32)
  p = t.data[ptr]
  k = t.a & p
  if !haskey(t.g, k)
    t.g[k] = []
  end
  push!(t.g[k], ptr)
end

function push!(t::LSHTable, p::UInt32)
  for g in t.gTable
    push!(g, p)
  end
end

import Base.get
function get(t::SetLSHHash, p::UInt128)
  get(t.g, t.a & p, Array{UInt32, 1}())
end

function get(t::LSHTable, p::UInt128)
   arr = Array{UInt32,1}()
   for g in t.gTable
     append!(arr, get(g,p))
   end
   return arr
end

function ClassicLSHTable(data::Array{UInt128, 1}, n::Int, d::Int, c::Int, r::Int, δ::Float64)
  # this uses enough hash tables for constant sucesss probability
  # should probably be adjusted
  # also the parameter in SetLSHHash(d, num_h) is chosen arbitrarily
  k = convert(Int, ceil(log(1/(1 - (c*r/d)), 2n)))
  println(k)
  println(n^(1/c))
  ClassicLSHTable([SetLSHHash(d, k, data) for x in 1:(ceil(n^(1/c)))], data, n, d, c, r, δ)
end

function PaghLSHTable(data::Array{UInt128, 1}, n::Int, d::Int, c, r::Int)
  family = generate_bitset(r, d)
  PaghLSHTable([PaghLSHHash(d, g, data) for g in family], data, n, d, c, r)
end
end
