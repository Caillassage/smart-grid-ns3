include("Area1.jl")
include("Area2.jl") 
#Solve: min x^2 + y^2
#Subject to: -x -y = -4
lambda = 1 
#Initializing x value
x0 = 0;
#Initializing y value
y0 = 0;
rho = 1 
iter = 1
f = -x0 -y0 +4

while abs(f) > 0.001

    #updating value of x with a constant y value given by previous iteration
        global (x) = solve_practice_area1(lambda, rho, y0) 
    #updating value of y with a constant x value given by previous iteration
        global (y) = solve_practice_area2(lambda, rho, x0)

    # printing something
        println(solve_practice_area1(1.66667, 1, 1.66667))
        println(solve_practice_area2(lambda, 1, x0))
        println(lambda + rho*(-x -y +4))
    #Setting value of x for next iteration to be the value found in current iteration
        global x0 = x
    #Setting value of y for next iteration to be the value found in current iteration
        global y0 = y
        global lambda = lambda + rho*(-x -y +4)
        println("x: ", x)
        println("y: ", y)
        println("lambda: ", lambda)
        global iter = iter+1
        global f = -x0 -y0 +4
        println("====================================")
end
