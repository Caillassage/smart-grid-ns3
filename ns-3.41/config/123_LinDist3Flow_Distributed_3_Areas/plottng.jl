## BRANCH (628,632)
bus=628
#Phs-A
p1 = plot(sqrt.(x_121_mat[:,3]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,3]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,3]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")

#Phs-B
p2 = plot(sqrt.(x_121_mat[:,11]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,11]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,11]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")

#Phs-C
p3 = plot(sqrt.(x_121_mat[:,19]), color=:red, linewidth=2, label="area1 @Bus-$(bus)")
plot!(sqrt.(x_122_mat[:,19]), color=:blue, linewidth=2, label="area2 @Bus-$(bus)")
plot!(sqrt.(z12_mat[:,19]), color=:green, linewidth=2, label="consensus @Bus-$(bus)")

plot(p1,p2,p3, layout = (3,1), xlabel="iteration num", ylabel="voltage (p.u)", title=["Phs-A" "Phs-B" "Phs-C"], legend=(0.37,0.5), size=(600,700))


#=
p2 = plot(sqrt.(x_121_mat[:,4]),label="area1  @Node-632",linewidth=2,color=:red1)
plot!(sqrt.(x_122_mat[:,4]),label="area2  @Node-632",linewidth=2,color=:blue1)
plot!(sqrt.(z12_mat[:,4]),label="consensus  @Node-632",linewidth=2,color=:green1)
#plot!(V[632]*ones(iter,1),label="centralized  @Node-632",linewidth=2,linestyle=:dash,color=:black)


plot(p1,p2,layout=(1,2),xlabel="iteration",ylabel="voltage (p.u.)",title=["Voltage" "Voltage"],legend=:bottomright,size=(600,300))
=#
