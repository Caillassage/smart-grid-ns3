function add_one(x)
    return x + 1
end

# MAIN
arg = parse(Float64, ARGS[1])

start_time = time()
println(add_one(arg))
end_time = time()

time_taken = end_time - start_time
println(time_taken)