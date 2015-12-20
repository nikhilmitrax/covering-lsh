module LSH
export LSHTable, ClassicLSHTable
abstract LSHTable
abstract LSHHash
type SetLSHHash <: Associative{BitArray{1}, Set{BitArray{1}}}
  g::Dict{BitArray{1}, Set{BitArray{1}}}
  a::BitArray{1}
end

function SetLSHHash(d, num_h)
  newa = BitArray{1}(d)
  newa[1:num_h] = true
  SetLSHHash(Dict{BitArray{1}, Set{BitArray{1}}}(), shuffle!(newa))
end

type ClassicLSHTable <: LSHTable
  gTable::Array{SetLSHHash, 1}
  n::Int
  d::Int
  c::Int
  r::Int
  δ::Float64
end

import Base.print
print(io::IO, t::SetLSHHash) = print(io, length(t.g))
print(io::IO, t::ClassicLSHTable) = print(io, t.gTable)

import Base.show
show(io::IO, t::SetLSHHash) = show(io, length(t.g))
show(io::IO, t::ClassicLSHTable) = show(io, t.gTable)


import Base.push!
function push!(t::SetLSHHash, p::BitArray{1})
  if haskey(t.g, t.a & p)
    push!(t.g[t.a & p], p)
  else
    setindex!(t.g, push!(Set{BitArray{1}}(), p), t.a & p)
  end
end

function push!(t::ClassicLSHTable, p::BitArray{1})
  for g in t.gTable
    push!(g, p)
  end
end

import Base.get
function get(t::SetLSHHash, p::BitArray{1})
  get(t.g, t.a & p, Set([]))
end

function get(t::ClassicLSHTable, p::BitArray{1})
  all = [get(g, p) for g in t.gTable]
  set = all[1]
  for i=2:length(all)
    union!(set, all[i])
  end
  return set
end

function ClassicLSHTable(n::Int, d::Int, c::Int, r::Int, δ::Float64)
  # this uses enough hash tables for constant sucesss probability
  # should probably be adjusted
  # also the parameter in SetLSHHash(d, num_h) is chosen arbitrarily
  ClassicLSHTable([SetLSHHash(d, 20) for x in 1:(ceil(n^(1/c)))], n, d, c, r, δ)
end

end

using LSH


parse_bits(l) = convert(BitArray{1}, map((x) -> parse(Bool, x), collect(l)))

function runtest(f, queries, truth_file)
  n = parse(Int, (readline(f)))
  d = parse(Int, (readline(f)))
  println(n)
  println(d)
  gg = ClassicLSHTable(n, d, 5, 1, 0.01) # dummy values!
  val2ind = Dict{BitArray{1}, Int}()
  ind2val = Dict{Int, BitArray{1}}()
  ind = 0
  for l in eachline(f)
    val = parse_bits(chomp(l))
    val2ind[val] = ind
    ind2val[ind] = val
    push!(gg, val)
    ind = ind + 1
  end
  println("The following line shows how many unique hashes in each table g_i:")
  println(gg)

  # read the query file and map indices to BitArrays
  ind2query = Dict{Int, BitArray{1}}()
  num_queries = parse(Int, readline(queries))
  readline(queries)
  for (i, q) in enumerate(eachline(queries))
    ind2query[i] = parse_bits(chomp(q))
  end

  # go through the ground truth file, get the neighbors of each
  # query, and test recall against ground truth
  precision = Array{Float64}(num_queries)
  recall = Array{Float64}(num_queries)
  maxdist = gg.c * gg.r
  for (i, vecs) in enumerate(eachline(truth_file))
    groundtruth = Set([ind2val[parse(v)] for v in split(vecs, ",")])
    found = get(gg, ind2query[i])
    intersection = length(found ∩ groundtruth)
    precision[i] = intersection / length(found)
    recall[i] = intersection / length(groundtruth)
  end
  @printf("Average precision: %6f\n", sum(precision) / length(precision))
  @printf("Average recall: %6f\n", sum(recall) / length(recall))
  println(string("Note that currently we are using thresholded SIFT values",
  " so the ground truth given in the dataset will not exactly match the nearest",
  " neighbors in hamming space."))
end

infile = open(ARGS[1])
q = open(ARGS[2])
tf = open(ARGS[3])
runtest(infile, q, tf)
close(infile)
close(q)
close(tf)
