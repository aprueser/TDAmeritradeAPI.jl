module Movers

    using LazyJSON, StructTypes, StructArrays, DataFrames, DataFramesMeta;

    export toDataFrame

    struct Mover
        change::Float64
        description::String
        direction::String
        last::Float64
        symbol::String
        totalVolume::Int64
    end

    StructTypes.StructType(::Type{Mover}) = StructTypes.Struct()

    function toDataFrame(ljson::LazyJSON.Array{Nothing, String})

        vec = Vector{Mover}()

        for m in ljson
            mv::Mover = convert(Mover, m)
            push!(vec, mv)
        end

        df = DataFrame(vec, copycols = false)

        return(df)
    end

end ## Movers module