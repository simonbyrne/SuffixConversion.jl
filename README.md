# SuffixConversion.jl

[![Build Status](https://github.com/simonbyrne/SuffixConversion.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/simonbyrne/SuffixConversion.jl/actions/workflows/CI.yml?query=branch%3Amain)

Defines suffix variables for making it easier to write generic code. The key interface is the `@suffix FT` macro which will define a variable prefixed with an underscore. When pre-multiplied by a number, this will perform conversion to the appropriate type. Specifically, it is designed to take advantage of Julia's [implicit multiplication of numerical literal coefficients](https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/#man-numeric-literal-coefficients).

```
using SuffixConversion

function addhalf(x::FT) where {FT}
    @suffix FT
    return x + 0.5_FT
end
```

