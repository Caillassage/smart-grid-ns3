using JuMP, Ipopt

function solve_practice_area2(lambda, rho, x)

model2 = Model(Ipopt.Optimizer)
@variable(model2, y >= 0) 
#updating y variable using constant x value given by central controller
@expression(model2, Total_gen2, y^2) 
@objective(model2, Min, Total_gen2
+ lambda'*(-x - y +4)
+ rho/2*(-x - y +4)'*(-x -y +4))
optimize!(model2) 
return((value(y)))
end

if length(ARGS) > 0
    # The first argument is assumed to be the variable we want to use
    x1 = parse(Float64, ARGS[1])
    # x2 = parse(Float64, ARGS[2])
    # x3 = parse(Float64, ARGS[3])
    # x4 = parse(Float64, ARGS[4])
    # x5 = parse(Float64, ARGS[5])
    # lambda = parse(Float64, ARGS[6])
    # rho = parse(Float64, ARGS[7])
    lambda = parse(Float64, ARGS[2])
    rho = parse(Float64, ARGS[3])

    start_time = time()
    println(solve_practice_area2(lambda, rho, x1))
    end_time = time()
    
    time_taken = end_time - start_time
    println(time_taken)
end