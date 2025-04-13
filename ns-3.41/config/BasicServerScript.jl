function add_one(x)
    return x + 1
end

# MAIN
arg = parse(Float64, ARGS[1])
arg = add_one(arg)

if arg < 10
    println(arg)
    println(arg)
    println(arg)
    println(arg)
else
    println("Optimal solution found")
end