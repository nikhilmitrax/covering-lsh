# note that module LSH must be on the julia load path
# the simplest way to make this happen is just `export JULIA_LOAD_PATH=./` in the shell
# see note above function runme() at the bottom of the file
using LSH



function table_from_file(f)
  n = parse(Int, (readline(f)))
  d = parse(Int, (readline(f)))
  println(n)
  println(d)

  data = Array{UInt128, 1}(n)
  for (i,l) in enumerate(eachline(f))
     data[i] = parse(UInt128, chomp(l), 2)
  end
  gg = ClassicLSHTable(data, n, d, 4, 5, 0.01) # dummy values!
  for i::UInt32=1:length(data)
    push!(gg, i)
  end
  return gg
end

function offline(f, queries, truth_file, c, r, δ, k)
  #tic()
  n = parse(Int, (readline(f)))
  d = parse(Int, (readline(f)))
  println(STDERR, n)
  println(STDERR, d)
  data = Array{UInt128, 1}(n)
  for (i,l) in enumerate(eachline(f))
     data[i] = parse(UInt128, chomp(l), 2)
  end
  num_queries = parse(Int, readline(queries))
  readline(queries)
  query = Array{UInt128, 1}(num_queries)
  for (i, q) in enumerate(eachline(queries))
    query[i] = parse(UInt128, chomp(q), 2)
  end
  covering_family = collect(generate_bitset(r))
  println(STDERR, covering_family)
  L = length(covering_family)
  println(STDERR, L)
  #k = 60

  pagh_results = Array{Array{UInt32, 1}}(num_queries)
  for j=1:length(pagh_results)
    pagh_results[j] = []
  end
  #k, L = getlshparams(n,d,c,r,δ)
  #k = 80
  #L = ceil(n^(1/c))
  #L = 63
  pagh_success = zeros(Bool, num_queries)
  pagh_lengths = zeros(Int, num_queries)
  for x in 1:L
    println(STDERR, x)
    #g1 = SetLSHHash(d, k, data)
    if covering_family[x] == UInt128(1)
      println(STDERR, "busted")
    end
    g = PaghLSHHash(d, covering_family[x], data)
    for ptr::UInt32 in 1:length(data)
      push!(g, ptr)
    end
    for (i, q) in enumerate(query)
      #append!(pagh_results[i], [data[ptr] for ptr in get(g, q)])
      #append!(pagh_results[i], get(g, q))
      for val in get(g, q)
        if hamming(data[val], q) <= r
          pagh_success[i] = true
        end
        pagh_lengths[i] += 1
      end
    end
  end
  #for (i, arr) in enumerate(pagh_results)
    #pagh_lengths[i] = length(arr)
    #for neighbor in arr
      ##if hamming(neighbor, query[i]) <= r
      #if hamming(data[neighbor], query[i]) <= r
        #pagh_success[i] = true
        #break
      #end
    #end
  #end
  pagh_results = []
  #toc()
    #tic()
  classic_results = Array{Array{UInt32, 1}}(num_queries)
  for j=1:length(classic_results)
    classic_results[j] = []
  end
  classic_success = zeros(Bool, num_queries)
  classic_lengths = zeros(Int, num_queries)
  for x in 1:L
    println(STDERR, x)
    g = SetLSHHash(d, k, data)
    for ptr::UInt32 in 1:length(data)
      push!(g, ptr)
    end
    for (i, q) in enumerate(query)
      #append!(classic_results[i], [data[ptr] for ptr in get(g, q)])
      #append!(classic_results[i], get(g, q))
      for val in get(g, q)
        classic_lengths[i] += 1
        if hamming(data[val], q) <= r
          classic_success[i] = true
        end
      end
    end
  end
  #for (i, arr) in enumerate(classic_results)
    #classic_lengths[i] = length(arr)
    #for neighbor in arr
      ##if hamming(neighbor, query[i]) <= r
      #if hamming(data[neighbor], query[i]) <= r
        #classic_success[i] = true
        #break
      #end
    #end
  #end
  #toc()
  num_impossible = 0
  for (i, smallest) in enumerate(eachline(truth_file))
    if parse(Int, chomp(smallest)) > r
      #pagh_success[i] = true
      #classic_success[i] = true
      num_impossible += 1
    end
  end

  return (pagh_success, classic_success, pagh_lengths, classic_lengths, num_impossible)
end

function runtest(f, queries, truth_file)
  tic()
  gg = table_from_file(f)
  println("The following line shows how many unique hashes in each table g_i:")
  println(gg)
  # read the query file and map indices to BitArrays
  num_queries = parse(Int, readline(queries))
  readline(queries)
  ind2query = Array{UInt128, 1}(num_queries)
  for (i, q) in enumerate(eachline(queries))
    ind2query[i] = parse(UInt128, chomp(q), 2)
  end

  # go through the ground truth file, get the neighbors of each
  # query, and test recall against ground truth
  success = Array{Bool}(num_queries)
  for i=1:length(success)
    success[i] = false
  end
  println("Preprocessing time:")
  toc()
  tic()
  for (i, vecs) in enumerate(eachline(truth_file))
    found = get(gg, ind2query[i])
    success[i] = false
    for bits in found
      if hamming(ind2query[i], gg.data[bits]) < gg.r
#        println("****")
        success[i] = true
        break
      end
    end
    #println("------")
  end
  println(sum(success))
  println("Query time: ")
  toc()
  return gg
end

function arraysizewalk(a)
  size = 0
  for i=1:length(a)
    if isdefined(a, i)
      size = size + sizeof(a[i])
    end
  end
  return size
end
function run_trial(c, r, δ, k, infile, q, tf)
  pagh, succ, plen, len, num_impossible = offline(infile, q, tf, c, r, δ, k)
  #println(string("No ", r, "-near neighbors: ", num_impossible))
  #println(string("Pagh successes: ", sum(pagh)))
  #println(string("Classic successes: ", sum(succ)))
  #println(string("Average hits per query, Pagh: ",mean(plen)))
  #println(string("Average hits per query, classic: ", mean(len)))
  #println(string("Total hits, Pagh: ", sum(plen)))
  #println(string("Total hits, classic: ", sum(len)))
  #println(string("Comparisons if negative results fall back on brute force: ", 1000000*(length(succ) - sum(succ) + num_impossible)))
  println(join([string(128),
                string(c),
                string(r),
                string(δ),
                string(num_impossible),
                string(k),
                string(sum(pagh)),
                string(sum(succ)),
                string(sum(plen)),
                string(sum(len))], ","))
end
# to run: either give arguments like below on the command line, or just uncomment ARGS line
function runme()
#ARGS = ["matlab/sift_base.fvecs.csv", "matlab/sift_query.fvecs.csv", "sift_mindist.log", "3", "4", ".01"]
c = parse(Int, ARGS[4])
r = parse(Int, ARGS[5])
δ = parse(Float64, ARGS[6])
println("d,c,r,delta,impossible,k,pagh,classic,pagh.hits,classic.hits")
for k=60:10:80
  for r in [3,4,5,6]
    c = log(2, 1000000)/r
    infile = open(ARGS[1])
    q = open(ARGS[2])
    tf = open(ARGS[3])
    run_trial(c, r, δ, k, infile, q, tf)
    close(infile)
    close(q)
    close(tf)
    gc()
  end
end
end
runme()
