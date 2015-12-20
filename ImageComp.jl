module ImageComp
using LSH
export PaghDescriptorSet

type PaghDescriptorSet
  table::PaghLSHTable
  keypoints::Array{Dict{AbstractString, Any}, 1}
  data::Array{UInt128, 1}
end
import Base.get
function get(ds::PaghDescriptorSet, q::UInt128)
  get(ds.table, q)
end
function PaghDescriptorSet(keypoints::Array{Dict{AbstractString, Any}, 1}, data::Array{UInt128, 1}, r)
  t = PaghLSHTable(data, length(data), 128, log(2,length(data))/r, r)
  for i::UInt32 = 1:length(data)
    push!(t, i)
  end
  return PaghDescriptorSet(t, keypoints, data)
end

end
using ImageComp
import LSH
import JSON
f = open(ARGS[1])
q = open(ARGS[2])
function descriptors_from_file(f, r)
  pairs = JSON.parse(f)
  keypoints = Array{Dict{AbstractString, Any}, 1}(length(pairs))
  data = Array{UInt128, 1}(length(pairs))
  for (i, pair) in enumerate(pairs)
    keypoints[i] = pair["kp"]
    data[i] = parse(UInt128, pair["des"], 2)
  end

  ds = PaghDescriptorSet(keypoints, data, r)
  return ds
end

fds = descriptors_from_file(f, 5)
q = JSON.parse(q)
final = Array{Dict{AbstractString, Any}, 1}()

for (i, pair) in enumerate(q)
  query = parse(UInt128, pair["des"], 2)
  results_indices = get(fds, query)
  dict = Dict{AbstractString, Any}()
  if length(results_indices) > 0
    smallest_dist, smallest_result_ind = findmin([LSH.hamming(query, fds.data[x]) for x in results_indices])
    smallest_data_ind = results_indices[smallest_result_ind]
    dict["query_kp"] = Dict{AbstractString, Any}("kp" => pair["kp"], "des" => pair["des"])
    dict["result_kp"] = Dict{AbstractString, Any}("kp" => fds.keypoints[smallest_data_ind], "des" => bits(fds.data[smallest_data_ind]))
    dict["hamming"] = smallest_dist
  else
    dict["query_kp"] = Dict{AbstractString, Any}("kp" => pair["kp"], "des" => pair["des"])
    dict["result_kp"] = Dict{AbstractString, Any}("kp" => Dict{AbstractString, Any}(), "des" => "")
    dict["hamming"] = 128
  end
  push!(final, dict)
end

JSON.print(final)
