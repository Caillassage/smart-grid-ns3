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
    x = parse(Float64, ARGS[1])
    rho = parse(Float64, ARGS[2])
    lambda = parse(Float64, ARGS[3])
    #println("Received: ", x)
end

println(solve_practice_area1(lambda, rho, x))