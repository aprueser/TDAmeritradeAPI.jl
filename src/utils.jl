#######################################################
## Define Date Conversion Function
#######################################################
function fromUnix2Date(d::Int64)::Dates.DateTime
    return(Dates.unix2datetime(d/1000))
end

function fromUnix2Date(d)::Vector{Dates.DateTime}
    return(Dates.unix2datetime.(d/1000))
end