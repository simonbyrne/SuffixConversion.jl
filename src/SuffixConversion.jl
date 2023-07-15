module SuffixConversion

export @suffix

"""
    SuffixConverter{T}()

When used with suffix multiplication, it will convert the result to type `T`.

When used with `BigFloat`s, it will convert the convert via string conversion,
then parsing.
"""
struct SuffixConverter{T}
end

Base.:*(x::Number, ::SuffixConverter{FT}) where {FT} = convert(FT, x)
Base.:*(x::Number, ::SuffixConverter{BigFloat}) = BigFloat(string(x))

Base.Broadcast.broadcasted(::typeof(*), x::Number, s::SuffixConverter) = x * s


"""
    @suffix T [= ....]

Defines a [`SuffixConverter`](@ref) for type `T` with the same name, prefixed by
an underscore. For convenience, it can also accept an expression which defines
`T` itself.`

# Examples

Using an already-defined type
```julia
function addhalf(x::FT) where {FT}
    @suffix FT
    return x + 0.5_FT
end
```

Defining the type inline
```julia
function addhalf(x)
    @suffix FT = typeof(FT)
    return x + 0.5_FT
end
```
"""
macro suffix(T::Symbol)
    :($(esc(Symbol(:_, T))) = SuffixConverter{$(esc(T))}())
end

macro suffix(ex::Expr)
    @assert ex.head == :(=) && ex.args[1] isa Symbol
    quote
        $(esc(ex))
        $(esc(Symbol(:_, ex.args[1]))) = SuffixConverter{$(esc(ex.args[1]))}()
    end
end

end
