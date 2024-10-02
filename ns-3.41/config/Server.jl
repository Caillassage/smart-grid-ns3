if length(ARGS) > 0
    # The first argument is assumed to be the variable we want to use
    x = parse(Float64, ARGS[1])
    y = parse(Float64, ARGS[2])
    rho = parse(Float64, ARGS[3])
    lambda = parse(Float64, ARGS[4])
    #println("Received: ", x)
end

println(x+y)