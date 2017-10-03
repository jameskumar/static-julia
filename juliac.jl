## Assumptions:
## 1. g++ / x86_64-w64-mingw32-gcc is available and is in path

function compile(julia_program_file)
    filename = split(julia_program_file, ".")[1]
    O_FILE = "$(filename).o"
    SO_FILE = "lib$(filename).$(Libdl.dlext)"

    julia_pkglibdir = joinpath(dirname(Pkg.dir()), "lib", basename(Pkg.dir()))

    if is_windows()
        julia_program_file = replace(julia_program_file, "\\", "\\\\")
        julia_pkglibdir = replace(julia_pkglibdir, "\\", "\\\\")
    end

    command = `"$(Base.julia_cmd())" "--startup-file=no" "--output-o" "$O_FILE" "-e"
               "include(\"$julia_program_file\"); push!(Base.LOAD_CACHE_PATH, \"$julia_pkglibdir\"); empty!(Base.LOAD_CACHE_PATH)"`
    println("Running command:\n$command")
    run(command)

    command = `$(Base.julia_cmd()) $(joinpath(dirname(JULIA_HOME), "share", "julia", "julia-config.jl"))`
    cflags = Base.shell_split(readstring(`$command --cflags`))
    ldflags = Base.shell_split(readstring(`$command --ldflags`))
    ldlibs = Base.shell_split(readstring(`$command --ldlibs`))

    command = `gcc -m64 -shared -o $SO_FILE $O_FILE $cflags $ldflags $ldlibs -Wl,-rpath,\$ORIGIN`
    if is_windows()
        command = `$command -Wl,--export-all-symbols`
    end
    println("Running command:\n$command")
    run(command)

    command = `gcc -m64 $C_FILE -o $E_FILE $SO_FILE $cflags $ldflags $ldlibs -Wl,-rpath,\$ORIGIN`
    println("Running command:\n$command")
    run(command)
end


if length(ARGS) != 1
    println("Usage: $(@__FILE__) <Julia Program file>")
    exit(1)
end

JULIA_PROGRAM_FILE = ARGS[1]

println("Program file:\n$(abspath(JULIA_PROGRAM_FILE))")

compile(JULIA_PROGRAM_FILE)

