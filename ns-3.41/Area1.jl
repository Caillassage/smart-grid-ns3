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