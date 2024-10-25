declare -a seed=(1 2 3 4)
declare -a threshold=(10.0)
declare -a simulationTime=(10.0)

for s in "${seed[@]}"
do
    ./ns3 run scratch/script-power-grid.cc --  --seed=$seed --threshold=$threshold --simulationTime=$simulationTime 
done