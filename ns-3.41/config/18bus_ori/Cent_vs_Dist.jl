#clearconsole()
#Run MAIN0.jl, Cent.jl, Dist.jl

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


##Plotting
p1 = scatter( Vcent_a, marker = (:hexagon, 5, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-A")
scatter!( Vdist_a, marker = (:plus, 5, 0.6, :black, stroke(1,0.1,:black,:dot)), label="distributed", title="Phs-A")

p2 = scatter( Vcent_b, marker = (:hexagon, 5, 0.6, :green, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-B")
scatter!( Vdist_b, marker = (:plus, 5, 0.6, :black, stroke(1,0.1,:black,:dot)), label="distributed", title="Phs-B")

p3 = scatter( Vcent_c, marker = (:hexagon, 5, 0.6, :blue, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-C")
scatter!( Vdist_c, marker = (:plus, 5, 0.6, :black, stroke(1,0.1,:black,:dot)), label="distributed", title="Phs-C")

plot(p1,p2,p3,
        layout=(3,1),
        size=(600,500),
        xlabel="bus",
        ylabel="voltage(p.u.)",
        xlims=(0,19),
        xticks=0:1:19)
#png("voltageprof.png")

##
#=
        p1 = scatter( abs.(Vcent_a-Vdist_a), marker = (:hexagon, 5, 0.6, :red, stroke(1,0.1,:red,:line)), label=false, title="Phs-A")

        p2 = scatter( abs.(Vcent_b-Vdist_b), marker = (:hexagon, 5, 0.6, :green, stroke(1,0.1,:green,:line)), label=false, title="Phs-B")

        p3 = scatter( abs.(Vcent_c-Vdist_c), marker = (:hexagon, 5, 0.6, :blue, stroke(1,0.1,:blue,:line)), label=false, title="Phs-C")

        plot(p1, p2, p3,
                layout=(3,1),
                size=(600,500),
                xlabel="bus",
                ylabel="error(p.u.)",
                        xlims=(0,19),
                        xticks=0:1:19)
png("voltage_error.png")
=#
