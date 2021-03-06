@static if VERSION >= v"0.7.0-DEV.3382"
    using Libdl
end

using Compat # for occursin

depsfile = joinpath(dirname(@__FILE__),"deps.jl")
if isfile(depsfile)
    rm(depsfile)
end

function write_depsfile(path)
    open(depsfile,"w") do f
        print(f,"const libcplex = ")
        show(f, path) # print with backslashes excaped on windows
        println(f)
    end
end

@static if (VERSION >= v"0.7.0-DEV.3382" && Sys.isapple()) || (VERSION < v"0.7.0-DEV.3382" && is_apple())
    Libdl.dlopen("libstdc++",Libdl.RTLD_GLOBAL)
end

base_env = "CPLEX_STUDIO_BINARIES"

const cpxvers = ["1260","1261","1262","1263","1270", "1271","128","1280"]

libnames = String["cplex"]
for v in reverse(cpxvers)
    if (VERSION >= v"0.7.0-DEV.3382" && Sys.isapple()) || (VERSION < v"0.7.0-DEV.3382" && is_apple())
        push!(libnames, "libcplex$v.dylib")
    elseif (VERSION >= v"0.7.0-DEV.3382" && Sys.isunix()) || (VERSION < v"0.7.0-DEV.3382" && is_unix())
        push!(libnames, "libcplex$v.so")
        if haskey(ENV, base_env)
            push!(libnames, joinpath(ENV[base_env], "libcplex$v.so"))
        end
    end
end

const wincpxvers = ["126","1261","1262","1263","127","1270","1271","128","1280"]
@static if (VERSION >= v"0.7.0-DEV.3382" && Sys.iswindows()) || (VERSION < v"0.7.0-DEV.3382" && is_windows())
    for v in reverse(wincpxvers)
        env = base_env * v
        if haskey(ENV,env)
            for d in split(ENV[env],';')
                occursin("cplex", d) || continue
                if length(v) == 3 # annoying inconsistency
                    push!(libnames,joinpath(d,"cplex$(v)0"))
                else
                    push!(libnames,joinpath(d,"cplex$(v)"))
                end
            end
        end
    end
end

found = false

for l in libnames
    d = Libdl.dlopen_e(l)
    if d != C_NULL
        global found = true
        write_depsfile(Libdl.dlpath(d))
        break
    end
end

if !found
    error("Unable to locate CPLEX installation. Note this must be downloaded separately. See the CPLEX.jl README for further instructions.")
end
