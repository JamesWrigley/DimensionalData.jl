abstract type AbstractDimensionalArray{T,N,D<:Tuple} <: AbstractArray{T,N} end

const AbDimArray = AbstractDimensionalArray

const StandardIndices = Union{AbstractArray,Colon,Integer}

# Interface methods ############################################################

dims(A::AbDimArray) = A.dims
@inline rebuild(x, data, dims=dims(x)) = rebuild(x, data, dims, refdims(x))


# Array interface methods ######################################################

Base.size(A::AbDimArray) = size(data(A))
Base.iterate(A::AbDimArray, args...) = iterate(data(A), args...)

Base.@propagate_inbounds Base.getindex(A::AbDimArray{<:Any, N}, I::Vararg{<:Integer, N}) where N =
    getindex(data(A), I...)
Base.@propagate_inbounds Base.getindex(A::AbDimArray, I::Vararg{<:StandardIndices}) =
    rebuildsliced(A, getindex(data(A), I...), I)

# Linear indexing
Base.@propagate_inbounds Base.getindex(A::AbDimArray{<:Any, N} where N, I::StandardIndices) =
    getindex(data(A), I)
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.getindex(A::AbDimArray{<:Any, 1}, I::Union{Colon, AbstractArray}) =
    rebuildsliced(A, getindex(data(A), I), (I,))

Base.@propagate_inbounds Base.view(A::AbDimArray, I::Vararg{<:StandardIndices}) =
    rebuildsliced(A, view(data(A), I...), I)
Base.@propagate_inbounds Base.view(A::AbDimArray{<:Any, 1}, I::StandardIndices) =
    rebuildsliced(A, view(data(A), I), (I,))
Base.@propagate_inbounds Base.view(A::AbDimArray{<:Any, N} where N, I::StandardIndices) =
    view(data(A), I)

Base.@propagate_inbounds Base.setindex!(A::AbDimArray, x, I::Vararg{StandardIndices}) =
    setindex!(data(A), x, I...)

Base.copy(A::AbDimArray) = rebuild(A, copy(data(A)))
Base.copy!(dst::AbDimArray, src::AbDimArray) = copy!(data(dst), data(src))
Base.copy!(dst::AbDimArray, src::AbstractArray) = copy!(data(dst), src)
Base.copy!(dst::AbstractArray, src::AbDimArray) = copy!(dst, data(src))

Base.BroadcastStyle(::Type{<:AbDimArray}) = Broadcast.ArrayStyle{AbDimArray}()

Base.similar(A::AbDimArray) = rebuild(A, similar(data(A)); name = "")
Base.similar(A::AbDimArray, ::Type{T}) where T = rebuild(A, similar(data(A), T); name = "")
Base.similar(A::AbDimArray, ::Type{T}, I::Tuple{Int64,Vararg{Int64}}) where T =
    rebuild(A, similar(data(A), T, I); name = "")
Base.similar(A::AbDimArray, ::Type{T}, I::Tuple{Union{Integer,AbstractRange},Vararg{Union{Integer,AbstractRange},N}}) where {T,N} =
    rebuildsliced(A, similar(data(A), T, I...), I; name = "")
Base.similar(A::AbDimArray, ::Type{T}, I::Vararg{<:Integer}) where T =
    rebuildsliced(A, similar(data(A), T, I...), I; name = "")
Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbDimArray}}, ::Type{ElType}) where ElType = begin
    A = find_dimensional(bc)
    # TODO How do we know what the new dims are?
    rebuildsliced(A, similar(Array{ElType}, axes(bc)), axes(bc); name = "")
end

# Need to cover a few type signatures to avoid ambiguity with base
# Don't remove these even though they look redundant

@inline find_dimensional(bc::Base.Broadcast.Broadcasted) = find_dimensional(bc.args)
@inline find_dimensional(ext::Base.Broadcast.Extruded) = find_dimensional(ext.x)
@inline find_dimensional(args::Tuple{}) = error("dimensional array not found")
@inline find_dimensional(args::Tuple) = find_dimensional(find_dimensional(args[1]), tail(args))
@inline find_dimensional(x) = x
@inline find_dimensional(A::AbDimArray, rest) = A
@inline find_dimensional(::Any, rest) = find_dimensional(rest)


# Concrete implementation ######################################################

"""
    DimensionalArray(data, dims, refdims, name)

The main subtype of `AbstractDimensionalArray`.
Maintains and updates its dimensions through transformations and moves dimensions to
`refdims` after reducing operations (like e.g. `mean`).
"""
struct DimensionalArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N}} <: AbstractDimensionalArray{T,N,D}
    data::A
    dims::D
    refdims::R
    name::String
end
"""
    DimensionalArray(data, dims::Tuple; refdims=(), name = "")
Constructor with optional `refdims` and `name` keyword.
The `name` is propagated across most sensible operations, even reducing ones.

Example:
```julia
using Dates, DimensionalData
using DimensionalData: Time, X
timespan = DateTime(2001):Month(1):DateTime(2001,12)
A = DimensionalArray(rand(12,10), (Time(timespan), X(10:10:100)))
A[X<|Near([12, 35]), Time<|At(DateTime(2001,5))]
A[Near(DateTime(2001, 5, 4)), Between(20, 50)]
```
"""
DimensionalArray(A::AbstractArray, dims; refdims=(), name = "") =
    DimensionalArray(A, formatdims(A, dims), refdims, name)

# Getters
refdims(A::DimensionalArray) = A.refdims
data(A::DimensionalArray) = A.data
label(A::DimensionalArray) = A.name

# DimensionalArray interface
@inline rebuild(A::DimensionalArray, data, dims, refdims; name = A.name) =
    DimensionalArray(data, dims; refdims = refdims, name = name)
@inline rebuild(A::DimensionalArray, data, dims; refdims = refdims(A), name = A.name) =
    DimensionalArray(data, dims, refdims, name)

# Array interface (AbstractDimensionalArray takes care of everything else)
Base.@propagate_inbounds Base.setindex!(A::DimensionalArray, x, I::Vararg{StandardIndices}) =
    setindex!(data(A), x, I...)