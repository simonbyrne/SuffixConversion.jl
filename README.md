# SuffixConversion.jl

[![Build Status](https://github.com/simonbyrne/SuffixConversion.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/simonbyrne/SuffixConversion.jl/actions/workflows/CI.yml?query=branch%3Amain)

SuffixConversion.jl makes it easier to write type-generic code supporting different floating point types.

The principle interface is the `@suffix <typename>` macro which defines a special variable of the same name prefixed with an underscore (`_`). When pre-multiplied by a number, it will convert the number to the specified type:

```julia
julia> using SuffixConversion

julia> @suffix Float64
SuffixConversion.SuffixConverter{Float64}()

julia> @suffix Float32
SuffixConversion.SuffixConverter{Float32}()

julia> 0.2_Float32
0.2f0
```
This takes advantage of Julia's [implicit multiplication of numerical literal coefficients](https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/#man-numeric-literal-coefficients).

# Why?

One of the benefits of Julia is that you can write generic code: a single method definition will work efficiently for multiple datatypes, by generating specialized code for each type signature. One difficulty is working with numeric literals: by default, a literal with a decimal point (e.g. `7.3`) is treated as a `Float64`, which may cause unexpected promotion:
```julia
julia> addhalf_naive(x) = x + 0.5
addhalf_naive (generic function with 1 method)

julia> addhalf_naive(Float32(1)) # returns a Float64
1.5
```

The intended way to use this package is to use `@suffix` inside your function definition to define the corresponding suffix variable. Typically the type will be either determined by a parameter in the type signature:
```julia
function addhalf(x::FT) where {FT}
    @suffix FT
    return x + 0.5_FT
end    
```
or it can also be computed as part of the expression:
```julia
function addhalf(x)
    @suffix FT = typeof(x)
    return x + 0.5_FT
end    
```

Another common cause of unexpected type promotion are integer values: while arithmetic operations which combine floating point and integer values will be converted to the floating point type:
```julia
julia> 2 * 1.2f0 # returns a Float32
2.4f0
```
some intermediate integer-only operations such as division (`/`) or square root (`sqrt`) can be converted to a `Float64`, which may result in an unexpectd conversion:
```julia
julia> 1/2 * 1.2f0 # returns a Float64
0.6000000238418579
```
This can be addressed by appending the suffix to the integer literals
```julia
function mulhalf(x::FT) where {FT}
    @suffix FT
    return 1_FT/2_FT * x
end
```

# What are the performance impacts?

For most floating point types (other than `BigFloat`, see below) this should generally work with no runtime overhead, as the Julia compiler is able to determine that the conversion is pure (i.e. has no side effects), and so [constant fold](https://en.wikipedia.org/wiki/Constant_folding) the conversion at compile time. 

For example, the `addhalf` function defined above is able to convert this to a single `Float32` multiply:
```julia
julia> @code_llvm addhalf(1f0)
;  @ REPL[2]:1 within `addhalf`
define float @julia_addhalf_115(float %0) #0 {
top:
;  @ REPL[2]:3 within `addhalf`
; ┌ @ float.jl:408 within `+`
   %1 = fadd float %0, 5.000000e-01
; └
  ret float %1
}
```

# What about `BigFloat`s?

`BigFloat`s are handled specially by first converting to a decimal string representation, then converting back. This allows things like
```julia
julia> @suffix BigFloat
SuffixConversion.SuffixConverter{BigFloat}()

julia> 0.2_BigFloat
0.2000000000000000000000000000000000000000000000000000000000000000000000000000004
```
whereas regular conversion will give the `Float64` value in `BigFloat` precision
```
julia> BigFloat(0.2)
0.200000000000000011102230246251565404236316680908203125
```

Note that the literal still goes through the Julia parser, which first converts literals to `Float64`, so this may not work as intended if there are more than 15 significant figures:
```julia
julia> 0.1000000000000000000007_BigFloat
0.1000000000000000000000000000000000000000000000000000000000000000000000000000002

julia> big"0.1000000000000000000007"
0.1000000000000000000007000000000000000000000000000000000000000000000000000000003
```


# Alternatives

## Manual conversion

The typical alternative is to manually convert everything to literals
```julia
addhalf(x::FT) where {FT} = x + FT(0.5)
```
This is mostly equivalent to our approach (other than the `BigFloat` handling), however it does require more parentheses, which can get confusing with larger expressions.

## ChangePrecision.jl

Another package which tries to address this problem is [ChangePrecision.jl](https://github.com/JuliaMath/ChangePrecision.jl): it defines a macro `@changeprecision` which performs conversion syntactically. It includes the disclaimer ["This package is for quick experiments, not production code"](https://github.com/JuliaMath/ChangePrecision.jl#this-package-is-for-quick-experiments-not-production-code), and appears to be intended for use at the top-level, rather than inside function definitions.
