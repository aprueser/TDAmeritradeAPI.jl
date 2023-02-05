#######################################################
## Define Date Conversion Function
#######################################################
function fromUnix2Date(d::Int64)::Dates.DateTime
    return(Dates.unix2datetime(d/1000))
end

function fromUnix2Date(d::Vector{T})::Vector{Dates.DateTime} where {T <: Real}
    return(Dates.unix2datetime.(d/1000))
end

function singleStructToDataFrame(s::Any)::ErrorTypes.Option{DataFrame}
    some(DataFrame([(key=>getfield(s, key) for key in fieldnames(typeof(s)))...]))
end
