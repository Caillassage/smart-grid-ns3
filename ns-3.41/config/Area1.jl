using JuMP, Ipopt

function solve_practice_area1(lambda, rho, y)

model1 = Model(Ipopt.Optimizer)
@variable(model1, x >= 0) 
#updating x variable using constant y value given by central controller
@expression(model1, Total_gen1, x^2) 
@objective(model1, Min, Total_gen1
+ lambda'*(-x - y +4)
+ rho/2*(-x - y +4)'*(-x - y +4))
optimize!(model1) 
return((value(x)))
end

if length(ARGS) > 0
    # The first argument is assumed to be the variable we want to use
    y1 = parse(Float64, ARGS[1])
    # y2 = parse(Float64, ARGS[2])
    # y3 = parse(Float64, ARGS[3])
    # y4 = parse(Float64, ARGS[4])
    # y5 = parse(Float64, ARGS[5])
    # lambda = parse(Float64, ARGS[6])
    # rho = parse(Float64, ARGS[7])
    lambda = parse(Float64, ARGS[2])
    rho = parse(Float64, ARGS[3])

    start_time = time()
    println(solve_practice_area1(lambda, rho, y1))
    end_time = time()

    time_taken = end_time - start_time
    println(time_taken)
end