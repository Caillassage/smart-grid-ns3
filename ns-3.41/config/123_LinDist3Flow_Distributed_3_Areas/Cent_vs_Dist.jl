#clearconsole()
#Run MAIN.jl, Cent.jl, Dist.jl
## Evaluating objective function

# println("Centralized Obj Value = ", cent_obj )
# println("Distributed Obj Value = ", dist_obj )

plot(sum(hcat(obj1_hist,obj2_hist), dims=2),label="Distributed",color=:blue1,linewidth=2)
plot!(obj_dist*ones(iter), label="Centralized",linestyle=:dash,linewidth=2,color=:red1)

xlabel!("iteration")
ylabel!("Objective Value")
annotate!(300,500,"Centralized Obj = $(obj_cent)")
annotate!(300,400,"Distributed Obj = $(obj_dist)")
## Getting dist voltages

Vdist_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Vdist_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Vdist_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

for bus in BUS_SET["area_1"]
        Vdist_a[bus] = :a in BUS_PHS_SET["area_1"][bus] ? sqrt(v1[(bus,:a)]) : NaN
        Vdist_b[bus] = :b in BUS_PHS_SET["area_1"][bus] ? sqrt(v1[(bus,:b)])  : NaN
        Vdist_c[bus] = :c in BUS_PHS_SET["area_1"][bus] ? sqrt(v1[(bus,:c)])  : NaN
end

for bus in BUS_SET["area_2"]
        Vdist_a[bus] = :a in BUS_PHS_SET["area_2"][bus] ? sqrt(v2[(bus,:a)]) : NaN
        Vdist_b[bus] = :b in BUS_PHS_SET["area_2"][bus] ? sqrt(v2[(bus,:b)])  : NaN
        Vdist_c[bus] = :c in BUS_PHS_SET["area_2"][bus] ? sqrt(v2[(bus,:c)])  : NaN
end


vcent=zeros(130,3)
vcent[:,1]=Vcent_a
vcent[:,2]=Vcent_b
vcent[:,3]=Vcent_c

vdist=zeros(130,3)
vdist[:,1]=Vdist_a
vdist[:,2]=Vdist_b
vdist[:,3]=Vdist_c

df = DataFrame(vcenta = vcent[1:130], vcentb = vcent[131:260], vcentc = vcent[261:390] )
CSV.write("Plotting\\vprof_cent.csv",df)

df = DataFrame(vdista = vdist[1:130], vdistb = vdist[131:260], vdistc = vdist[261:390] )
CSV.write("Plotting\\vprof_rho_$(rho).csv",df)

##Plotting
p1 = scatter( Vcent_a, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-A")
scatter!( Vdist_a, marker = (:plus, 2, 0.6, :black, stroke(1,0.1,:black,:dot)), label="distributed", title="Phs-A")

p2 = scatter( Vcent_b, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-B")
scatter!( Vdist_b, marker = (:plus, 2, 0.6, :black, stroke(1,0.1,:black,:dot)), label="distributed", title="Phs-B")

p3 = scatter( Vcent_c, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-C")
scatter!( Vdist_c, marker = (:plus, 2, 0.6, :black, stroke(1,0.1,:black,:dot)), label="distributed", title="Phs-C")

plot(p1,p2,p3,
        layout=(3,1),
        size=(600,500),
        xlabel="bus",
        ylabel="voltage(p.u.)",
        xlims=(0,131),
        xticks=0:1:131)
#png("voltagecomp.png")

## Error evaluation

p1 = plot(abs.(Vcent_a-Vdist_a),color=:blue1,label="error")
p2 = plot(abs.(Vcent_b-Vdist_b),color=:red1,label="error")
p3 = plot(abs.(Vcent_c-Vdist_c),color=:green1,label="error")
plot(p1,p2,p3,layout=(3,1),xlabel="bus",ylabel="error")

##
#=
        p1 = scatter( abs.(Vcent_a-Vdist_a), marker = (:hexagon, 5, 0.6, :red, stroke(1,0.1,:red,:dot)), label=false, title="Phs-A")

        p2 = scatter( abs.(Vcent_b-Vdist_b), marker = (:hexagon, 5, 0.6, :green, stroke(1,0.1,:green,:dot)), label=false, title="Phs-B")

        p3 = scatter( abs.(Vcent_c-Vdist_c), marker = (:hexagon, 5, 0.6, :blue, stroke(1,0.1,:blue,:dot)), label=false, title="Phs-C")


        plot(p1, p2, p3,
                layout=(3,1),
                size=(600,500),
                xlabel="bus",
                ylabel="error(p.u.)",
                        xlims=(0,131))
                        #xticks=0:1:19)
=#
