if length(ARGS) > 0
    # The first argument is assumed to be the variable we want to use
    x = parse(Float64, ARGS[1])
    y = parse(Float64, ARGS[2])
    lambda = parse(Float64, ARGS[3])
    rho = parse(Float64, ARGS[4])

    f = -x - y + 4

    if abs(f) > 0.001
        lambda = lambda + rho * (-x - y + 4)
        println(x)
        println(y)
        println(lambda)
        println(rho)
    else
        println("Optimal solution found")
    end
end