
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

for bus in BUS_SET["area_3"]
    Vdist_a[bus] = :a in BUS_PHS_SET["area_3"][bus] ? sqrt(v3[(bus,:a)]) : NaN
    Vdist_b[bus] = :b in BUS_PHS_SET["area_3"][bus] ? sqrt(v3[(bus,:b)])  : NaN
    Vdist_c[bus] = :c in BUS_PHS_SET["area_3"][bus] ? sqrt(v3[(bus,:c)])  : NaN
end


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


