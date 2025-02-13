#clearconsole()
#Run MAIN0.jl
#this will initialize all the necessary variables
include("Cent-revised")

include("solve_area1.jl")
include("solve_area2.jl")

lambda_121 = ones(24)
lambda_122 = ones(24)
z12 = ones(24)

lambda_121_hist = []
lambda_122_hist = []
z12_hist = [ones(24)]
x_121_hist = []
x_122_hist = []

primal_residual_hist = []
dual_residual_hist = []

rho = 100

MAX_ITER = 200

iter = 1


while iter <= MAX_ITER

        global x1,v1, opf1 = solve_area1(lambda_121, z12, rho)
        global x2,v2, opf2 = solve_area2(lambda_122, z12, rho)

        global z12 = 1/2*( x1+(1/rho)*lambda_121 + x2+(1/rho)*lambda_122)

        global lambda_121 = lambda_121 + rho*(x1 - z12)
        global lambda_122 = lambda_122 + rho*(x2 - z12)

        #border solutions
        push!(x_121_hist, x1)
        push!(x_122_hist, x2)

        #dual variables
        push!(lambda_121_hist, lambda_121)
        push!(lambda_122_hist, lambda_122)

        #consensus variables
        push!(z12_hist, z12)


        primal_residual_12 = [abs.(x1-z12), abs.(x2-z12)]
        dual_residual_12 = [abs.(z12_hist[end] - z12_hist[end-1])]

        residual_12 = [abs.(x1-z12), abs.(x2-z12), abs.(z12_hist[end] - z12_hist[end-1])]

        push!(primal_residual_hist, primal_residual_12)
        push!(dual_residual_hist, dual_residual_12)

        if all([all(residual_12[i] .< 0.0001) for i in 1:length(residual_12)])
                break
        end

        global iter = iter+1

end


nc = 24
nr = (iter<MAX_ITER) ? iter : MAX_ITER

z12_mat = collect(transpose(reshape([z12_hist[i][j] for i in 1:nr for j in 1:nc], nc, nr)))

x_121_mat = collect(transpose(reshape([x_121_hist[i][j] for i in 1:nr for j in 1:nc], nc, nr)))
x_122_mat = collect(transpose(reshape([x_122_hist[i][j] for i in 1:nr for j in 1:nc], nc, nr)))

lambda_121_mat = collect(transpose(reshape([lambda_121_hist[i][j] for i in 1:nr for j in 1:nc], nc, nr)))
lambda_122_mat = collect(transpose(reshape([lambda_122_hist[i][j] for i in 1:nr for j in 1:nc], nc, nr)))


##Recovering boundary bus voltages

#BUS 3
bus=3
#Phs-A
p1 = plot(sqrt.(x_121_mat[:,3]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,3]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,3]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[3,:a]*ones(iter,1), color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-B
p2 = plot(sqrt.(x_121_mat[:,11]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,11]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,11]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[3,:b]*ones(iter,1), color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-C
p3 = plot(sqrt.(x_121_mat[:,19]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,19]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,19]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[3,:c]*ones(iter,1), color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

plot(p1,p2,p3, layout = (3,1), xlabel="iteration num", ylabel="voltage (p.u)", title=["Phs-A" "Phs-B" "Phs-C"], legend=(0.37,0.5), size=(600,700))
png("voltagecomp_bus3.png")

#BUS 4
bus=4
#Phs-A
p1 = plot(sqrt.(x_121_mat[:,4]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,4]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,4]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[4,:a]*ones(iter,1), color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-B
p2 = plot(sqrt.(x_121_mat[:,12]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,12]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,12]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[4,:b]*ones(iter,1), color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-C
p3 = plot(sqrt.(x_121_mat[:,20]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,20]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,20]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[4,:c]*ones(iter,1), color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

plot(p1,p2,p3, layout = (3,1), xlabel="iteration num", ylabel="voltage (p.u)", title=["Phs-A" "Phs-B" "Phs-C"], legend=(0.37,0.5), size=(600,700))
png("voltagecomp_bus4.png")

## Boundary branch flows

#BRANCH (3,4)
branch=(3,4)

#Phs-A
p1 = plot((x_121_mat[:,5])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,5])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,5])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Pbranch[(3,4),:a]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Branch-$(branch)")

#Phs-B
p2 = plot((x_121_mat[:,13])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,13])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,13])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Pbranch[(3,4),:b]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Branch-$(branch)")

#Phs-C
p3 = plot((x_121_mat[:,21])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,21])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,21])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Pbranch[(3,4),:c]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Branch-$(branch)")

plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="active power flow (MW)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,900))
        #ylims=(0,10.5))
png("Pflowcomp_br34.png")

#Phs-A
p1 = plot((x_121_mat[:,6])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,6])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,6])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Qbranch[(3,4),:a]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Branch-$(branch)")

#Phs-B
p2 = plot((x_121_mat[:,14])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,14])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,14])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Qbranch[(3,4),:b]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Branch-$(branch)")

#Phs-C
p3 = plot((x_121_mat[:,22])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,22])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,22])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Qbranch[(3,4),:c]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Branch-$(branch)")

plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="reactive power flow (MVAr)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,700),
        ylims=(0,5))
png("Qflowcomp_br34.png")



#Control variable
#BUS 3

bus=3
#Phs-A
p1 = plot((x_121_mat[:,2])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,2])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,2])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(Qdg[3,:a]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-B
p2 = plot((x_121_mat[:,10])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,10])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,10])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(Qdg[3,:b]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-C
p3 = plot((x_121_mat[:,18])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,18])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,18])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(Qdg[3,:c]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="Reactive power of DG (MVar)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,700),
        ylims=(0,0.5))
png("Qdgcomp_bus3.png")

#BUS 4
bus=4
#Phs-A
p1 = plot((x_121_mat[:,8])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,8])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,8])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(Qdg[3,:a]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-B
p2 = plot((x_121_mat[:,16])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,16])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,16])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(Qdg[3,:b]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")

#Phs-C
p3 = plot((x_121_mat[:,24])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,24])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,24])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(Qdg[3,:c]*ones(iter,1)*sbase, color=:black, linestyle=:dash, linewidth=2, label="centralized @Bus-$(bus)")


plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="Reactive power of DG (MVar)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,700),
        ylims=(-0.2,0.8))
#png("Qdgcomp_bus4.png")

println("z12: ", z12)
