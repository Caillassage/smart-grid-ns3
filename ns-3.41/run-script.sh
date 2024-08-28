#!/bin/bash

# Define the range and step size
start=10
end=140
step=10

seed_list=(1 2 3 4 5 6 7 8 9)

for (( distanceStepSize=start; distanceStepSize<=end; distanceStepSize+=step ))
do
    echo "distanceStepSize=$distanceStepSize"
    for seed in "${seed_list[@]}"
    do
        echo "seed=$seed"
        # Run the script with the current distanceStepSize as an argument
        ./ns3 run scratch/script-autonomous-bus.cc -- --seed=$seed --distanceStepSize=$distanceStepSize > out.txt 2>&1
        # Look for the word "throughput" in the output and print the next value
        nextValue=$(grep -A 1 "Throughput:" "out.txt" | tail -n 1)
        echo "$nextValue"
        latency=$(grep "Latency:" "out.txt" | head -n 1)
        echo "$latency"
        sinr=$(grep "SINR:" "out.txt" | head -n 1)
        echo "$sinr"
        mcs=$(grep "MCS:" "out.txt" | head -n 1)
        echo "$mcs"
        tbler=$(grep "TBLER:" "out.txt" | head -n 1)
        echo "$tbler"
        echo "----------------------------------------"
    done
    echo "===================================================================================================="
done