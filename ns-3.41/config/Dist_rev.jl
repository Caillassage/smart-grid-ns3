
#Run MAIN.jl
include("solve_area1.jl")
include("solve_area2.jl")
include("solve_area3.jl")

lambda_121 = ones(24)
lambda_122 = ones(24)

lambda_131 = ones(24)
lambda_133 = ones(24)

#lambda_343 = ones(24)
#lambda_344 = ones(24)

z12 = ones(24)
z13 = ones(24)
#z34 = ones(24)

#=
z12 = [0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0]
z13 = [0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0]
z34 = [0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0]
=#
lambda_121_hist = []
lambda_122_hist = []

lambda_131_hist = []
lambda_133_hist = []



z12_hist = [ones(24)]
z13_hist = [ones(24)]


x_121_hist = []
x_122_hist = []

x_131_hist = []
x_133_hist = []

t1_hist = []
t2_hist = []

t3_hist = []

obj1_hist = []
obj2_hist = []
obj3_hist = []

primal_residual_hist = []
dual_residual_hist = []
residual_hist=[]

rho = 50.0
MAX_ITER = 200

iter = 1
while iter <= MAX_ITER # changer en if, le MAX_ITER est défini dans le script server ns3

        # return x1, t1, obj1
        global x1,v1,t1, opf1, Pg1,Pg2,Pg3,Qg1,Qg2,Qg3, obj1, nl1, Pdg1, Qdg1, Pb38_2 = solve_area1(vcat(lambda_121, lambda_131), vcat(z12,z13), rho)
        println(x1)
        global x2,v2,t2, opf2,obj2, nl2, Pdg2, Qdg2= solve_area2(lambda_122, z12, rho)
        println(x2)
        global x3, v3, t3, opf3, obj3, nl3, Pdg3, Qdg3 = solve_area3(lambda_133, z13,rho)
        println(x3)

        global z12 = 1/2 * ( x1[1:24]+(1/rho)*lambda_121 + x2+(1/rho)*lambda_122 )
        global z13 = 1/2 * ( x1[25:48]+(1/rho)*lambda_131 + x3+(1/rho)*lambda_133 )

        global lambda_121 = lambda_121 + rho*(x1[1:24] - z12)
        global lambda_122 = lambda_122 + rho*(x2 - z12)
        global lambda_131 = lambda_131 + rho*(x1[25:48] - z13)
        global lambda_133 = lambda_133 + rho*(x3 - z13)
        println(lambda_121)
        println(lambda_122)
        println(lambda_131)
        println(lambda_133)
        #border solutions
        push!(x_121_hist,x1)
        push!(x_122_hist,x2)
        push!(x_133_hist,x3)

        #dual variables
        push!(lambda_121_hist,lambda_121)
        push!(lambda_122_hist,lambda_122)
        push!(lambda_131_hist,lambda_131)
        push!(lambda_133_hist,lambda_133)

        #consensus variables
        push!(z12_hist,z12)
        push!(z13_hist,z13)

        # obj values
        push!(obj1_hist,obj1)
        push!(obj2_hist,obj2)
        push!(obj3_hist,obj3)

        # solvetime
        push!(t1_hist,t1)
        push!(t2_hist,t2)
        push!(t3_hist,t3)

       # dual_residual_12 = [abs.(z12_hist[end] - z12_hist[end-1])]

        #maximum(maximum(dual_residual_hist))

       # primal_residual_12 = [abs.(x1-z12), abs.(x2-z12)]
       # dual_residual_12 = [abs.(z12_hist[end] - z12_hist[end-1])]
#=
        residual_12 = [abs.(x1-z12), abs.(x2-z12), abs.(z12_hist[end] - z12_hist[end-1])]
        if all([all(residual_12[i] .< 0.0001) for i in 1:length(residual_12)])
                break
        end
=#
 #       push!(primal_residual_hist, primal_residual_12)
  #      push!(dual_residual_hist, dual_residual_12)


        global residual = [ abs.(x1[1:24]- z12), abs.(x2 - z12), abs.(z12_hist[end]-z12_hist[end-1]),
                            abs.(x1[25:48] - z13), abs.(x3 - z13), abs.(z13_hist[end]-z13_hist[end-1])]

        if all([maximum(residual[i]) for i in 1:length(residual)] .< 0.0001) # all([all(residual[i] .< 0.0001) for i in 1:length(residual)])
        break
        end

       # push!(residual_hist, residual)

      

        global iter = iter+1

end


#=
Psub_dist = (Pg1+Pg2+Pg3)*(1e3*sbase) #kW
Qsub_dist = (Qg1+Qg2+Qg3)*(1e3*sbase) #kW
obj_dist = sum( [obj1_hist[end],obj2_hist[end] ])
=#
nc = 24
nr = (iter<MAX_ITER) ? iter : MAX_ITER

z12_mat = collect(transpose(reshape([z12_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )
z13_mat = collect(transpose(reshape([z13_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )

x_121_mat = collect(transpose(reshape([x_121_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )
x_122_mat = collect(transpose(reshape([x_122_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )

#x_131_mat = collect(transpose(reshape([x_131_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )
x_133_mat = collect(transpose(reshape([x_133_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )


lambda_121_mat = collect(transpose(reshape([lambda_121_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )
lambda_122_mat = collect(transpose(reshape([lambda_122_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )

lambda_131_mat = collect(transpose(reshape([lambda_131_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )
lambda_133_mat = collect(transpose(reshape([lambda_133_hist[i][j] for i in 1:nr for j in 1:nc],nc,nr) ) )


## Solve time calculation

solvetime_all = [t1_hist t2_hist t3_hist]

worst=zeros(size(solvetime_all,1),1)
for i=1:size(solvetime_all,1)
   global worst[i]=maximum(solvetime_all[i,:])
end
solvetime_dist=sum(worst)
#=
##
res = zeros(nr,24)
max_res = zeros(nr)
for i = 1:nr
        res[i,:] = maximum(residual_hist[i])
        max_res[i] = maximum(res[i,:])
end
df = DataFrame(max_res = max_res)
CSV.write("Plotting\\max_res_rho_$(rho).csv",df)

=#


##


#=
df = DataFrame(rho = rho, Iteration = nr, Psub =Psub_dist,  Qsub =Qsub_dist, objective = obj_dist,
             Pdg_21 = (z12_mat[end,1]+Pload[21,:a])*(1e3*sbase), Qdg_21 = (z12_mat[end,2]+Qload[21,:a])*(1e3*sbase))
              #PbranchA = z12_mat[:,5]*(1e3*sbase) , PbranchB = z12_mat[:,13]*(1e3*sbase) , PbranchC = z12_mat[:,21]*(1e3*sbase)  )
CSV.write("Plotting\\results_rho_$(rho).csv",df)
=#

##
Pdgdist_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Pdgdist_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Pdgdist_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

for bus in BUS_SET["area_1"]
        Pdgdist_a[bus] = :a in BUS_PHS_SET["area_1"][bus] ? Pdg1[(bus,:a)] : 0
        Pdgdist_b[bus] = :b in BUS_PHS_SET["area_1"][bus] ? Pdg1[(bus,:b)]  : 0
        Pdgdist_c[bus] = :c in BUS_PHS_SET["area_1"][bus] ? Pdg1[(bus,:c)]  : 0
end

for bus in BUS_SET["area_2"]
        Pdgdist_a[bus] = :a in BUS_PHS_SET["area_2"][bus] ? Pdg2[(bus,:a)] : 0
        Pdgdist_b[bus] = :b in BUS_PHS_SET["area_2"][bus] ? Pdg2[(bus,:b)]  : 0
        Pdgdist_c[bus] = :c in BUS_PHS_SET["area_2"][bus] ? Pdg2[(bus,:c)]  : 0
end

for bus in BUS_SET["area_3"]
        Pdgdist_a[bus] = :a in BUS_PHS_SET["area_3"][bus] ? Pdg3[(bus,:a)] : 0
        Pdgdist_b[bus] = :b in BUS_PHS_SET["area_3"][bus] ? Pdg3[(bus,:b)]  : 0
        Pdgdist_c[bus] = :c in BUS_PHS_SET["area_3"][bus] ? Pdg3[(bus,:c)]  : 0
end
Pdg_dist_total = sum(Pdgdist_a + Pdgdist_b + Pdgdist_c)*(1e3*sbase)


Qdgdist_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Qdgdist_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Qdgdist_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

for bus in BUS_SET["area_1"]
        Qdgdist_a[bus] = :a in BUS_PHS_SET["area_1"][bus] ? Qdg1[(bus,:a)] : 0
        Qdgdist_b[bus] = :b in BUS_PHS_SET["area_1"][bus] ? Qdg1[(bus,:b)]  : 0
        Qdgdist_c[bus] = :c in BUS_PHS_SET["area_1"][bus] ? Qdg1[(bus,:c)]  : 0
end

for bus in BUS_SET["area_2"]
        Qdgdist_a[bus] = :a in BUS_PHS_SET["area_2"][bus] ? Qdg2[(bus,:a)] : 0
        Qdgdist_b[bus] = :b in BUS_PHS_SET["area_2"][bus] ? Qdg2[(bus,:b)]  : 0
        Qdgdist_c[bus] = :c in BUS_PHS_SET["area_2"][bus] ? Qdg2[(bus,:c)]  : 0
end

for bus in BUS_SET["area_3"]
        Qdgdist_a[bus] = :a in BUS_PHS_SET["area_3"][bus] ? Qdg3[(bus,:a)] : 0
        Qdgdist_b[bus] = :b in BUS_PHS_SET["area_3"][bus] ? Qdg3[(bus,:b)]  : 0
        Qdgdist_c[bus] = :c in BUS_PHS_SET["area_3"][bus] ? Qdg3[(bus,:c)]  : 0
end

Qdg_dist_total = sum(Qdgdist_a + Qdgdist_b + Qdgdist_c)*(1e3*sbase)

##Recovering boundary bus voltages

#BUS 135(org), 21(new)
bus=21
#Phs-A
p1 = plot(sqrt.(x_121_mat[:,3]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,3]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,3]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[bus,:a]*ones(iter,1),label="centralized  @Bus-$(bus)",linewidth=2,linestyle=:dash,color=:black)

#Phs-B
p2 = plot(sqrt.(x_121_mat[:,11]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,11]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,11]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[bus,:b]*ones(iter,1),label="centralized  @Bus-$(bus)",linewidth=2,linestyle=:dash,color=:black)

#Phs-C
p3 = plot(sqrt.(x_121_mat[:,19]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,19]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,19]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")
plot!(V[bus,:c]*ones(iter,1),label="centralized  @Bus-$(bus)",linewidth=2,linestyle=:dash,color=:black)

plot(p1,p2,p3, layout = (3,1), xlabel="iteration num", ylabel="voltage (p.u)", title=["Phs-A" "Phs-B" "Phs-C"], legend=(0.37,0.5), size=(600,700))



#BRANCH (3,4)
branch=(135,35)

#Phs-A
p1 = plot((x_121_mat[:,5])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,5])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,5])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Pbranch[(21,56),:a]*ones(iter,1)*sbase,label="centralized  @Branch-$(branch)",linewidth=2,linestyle=:dash,color=:black)

#Phs-B
p2 = plot((x_121_mat[:,13])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,13])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,13])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Pbranch[(21,56),:b]*ones(iter,1)*sbase,label="centralized  @Branch-$(branch)",linewidth=2,linestyle=:dash,color=:black)

#Phs-C
p3 = plot((x_121_mat[:,21])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,21])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,21])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")
plot!(Pbranch[(21,56),:c]*ones(iter,1)*sbase,label="centralized  @Branch-$(branch)",linewidth=2,linestyle=:dash,color=:black)

plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="active power flow (MW)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,900))
        #ylims=(0,6))

plot(t1_hist, color=:red, linewidth=2, label="Area 1 - Optimization Time")
plot!(t2_hist, color=:blue, linewidth=2, label="Area 2 - Optimization Time")
plot!(t3_hist, color=:green, linewidth=2, label="Area 3 - Optimization Time")
#solvetime_all = [t1_hist t2_hist t3_hist]
#=
#Phs-A
p1 = plot((x_121_mat[:,6])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,6])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,6])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")

#Phs-B
p2 = plot((x_121_mat[:,12])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(branch)")
plot!((x_122_mat[:,12])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(branch)")
plot!((z12_mat[:,12])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(branch)")

#Phs-C
p3 = plot((x_121_mat[:,18])*sbase, color=:red, linewidth=2, label="area1 @Branch-$(bus)")
plot!((x_122_mat[:,18])*sbase, color=:blue, linewidth=2, label="area2 @Branch-$(bus)")
plot!((z12_mat[:,18])*sbase, color=:green, linewidth=2, label="consensus @Branch-$(bus)")

plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="reactive power flow (MVAr)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,700),
        ylims=(0,13))
=#


##
#Control variable
#BUS 3
#=
bus=3
#Phs-A
p1 = plot((x_121_mat[:,2])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,2])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,2])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")

#Phs-B
p2 = plot((x_121_mat[:,10])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,10])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,10])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")

#Phs-C
p3 = plot((x_121_mat[:,18])*sbase, color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,18])*sbase, color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,18])*sbase, color=:green, linewidth=2, label="consensus @Bus-$(bus)")

plot(p1,p2,p3,
        layout = (3,1),
        xlabel="iteration num",
        ylabel="voltage (p.u)",
        title=["Phs-A" "Phs-B" "Phs-C"],
        legend=(0.37,0.5), size=(600,700),
        ylims=(-0.2,11))


#BUS 4
bus=4
#Phs-A
p1 = plot((x_121_mat[:,8]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,8]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,8]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")

#Phs-B
p2 = plot((x_121_mat[:,16]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,16]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,16]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")

#Phs-C
p3 = plot((x_121_mat[:,24]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!((x_122_mat[:,24]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!((z12_mat[:,24]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")

plot(p1,p2,p3, layout = (3,1), xlabel="iteration num", ylabel="voltage (p.u)", title=["Phs-A" "Phs-B" "Phs-C"], legend=(0.37,0.5), size=(600,700))
=#
