# makes calling C functions a bit easier
macro cpx_ccall(func, args...)
    f = "CPX$(func)"
    quote
        ccall(($f,libcplex), $(args...))
    end
end

typealias GChars Union(Cchar, Char)
typealias IVec Vector{Cint}
typealias FVec Vector{Float64}
typealias CVec Vector{Cchar}
typealias CoeffMat Union(Matrix{Float64}, SparseMatrixCSC{Float64})

typealias GCharOrVec Union(Cchar, Char, Vector{Cchar}, Vector{Char})

ivec(v::IVec) = v
fvec(v::FVec) = v
cvec(v::CVec) = v

ivec{I<:Integer}(v::Vector{I}) = convert(IVec, v)
fvec{T<:Real}(v::Vector{T}) = convert(FVec, v)
cvec(v::Vector{Char}) = convert(CVec, v)

_chklen(v, n::Integer) = (length(v) == n || error("Inconsistent argument dimensions."))

cvecx(c::GChars, n::Integer) = fill(Cchar[c...], n)
cvecx(c::Vector{Cchar}, n::Integer) = (_chklen(c, n); c)
cvecx(c::Vector{Char}, n::Integer) = (_chklen(c, n); convert(Vector{Cchar}, c))

# -----
# Types
# -----
type CPXenv
    ptr::Ptr{Void}

    function CPXenv(ptr::Ptr{Void})
        env = new(ptr)
        # finalizer(env, close_CPLEX)
        env
    end
end

type CPXproblem
    env::CPXenv # Cplex environment
    lp::Ptr{Void} # Cplex problem (lp)
    nint::Int # number of integer variables

    function CPXproblem(env::CPXenv, lp::Ptr{Void})
        prob = new(env, lp, 0)
        finalizer(prob, free_problem)
        prob
    end
end