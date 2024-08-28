using JuMP, Ipopt

function solve_practice_area2(lambda, rho, x)

model2 = Model(Ipopt.Optimizer)
@variable(model2, y >= 0) 
#updating y variable using constant x value given by central controller
@expression(model2, Total_gen2, y^2) 
@objective(model2, Min, Total_gen2
+ lambda'*(-x -y +4)
+ rho/2*(-x -y +4)'*(-x -y +4))
optimize!(model2) 
return((value(y)))
end