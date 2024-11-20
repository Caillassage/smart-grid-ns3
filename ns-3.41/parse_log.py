import re
import csv

# Define the path to your log file and output CSV file
log_file_path = 'log.txt'  # Replace with the actual path to your log file
output_csv_path = 'output.csv'

# Initialize list to store data per iteration
data = []

# Regex patterns to capture log details
iteration_pattern = re.compile(r'Current iteration: (\d+)')
send_pattern = re.compile(r'(\d+\.\d+)s.*HandleRead\(\):.* server sent (\d+) bytes')
receive_pattern = re.compile(r'(\d+\.\d+)s.*HandleRead\(\):.* client received (\d+) bytes')
optimization_pattern = re.compile(r'Optimization Time: ([\d.]+)')

# Initialize variables for storing times within an iteration
current_iteration = None
tx_times = []
rx_times = []
optimization_time = 0

# Function to process and reset iteration data
def process_iteration():
    if current_iteration is not None and tx_times and rx_times:
        delays = [rx - tx for tx, rx in zip(tx_times, rx_times) if rx > tx]
        if delays:
            D_K = max(delays)
            round_trip_delay = sum(delays)
            T_K = D_K + optimization_time
        else:
            D_K = round_trip_delay = T_K = 0

        # Append data for this iteration
        # Append data for this iteration
        data.append([
            current_iteration,
            tx_times,       # TX_Time dictionary
            rx_times,       # RX_Time dictionary
            round_trip_delay,
            D_K,
            T_K,
        ])

# Read and process the log file
with open(log_file_path, 'r') as f:
    for line in f:
        # Check for iteration number
        iter_match = iteration_pattern.search(line)
        if iter_match:
            # Process the previous iteration before starting a new one
            process_iteration()

            # Start a new iteration
            current_iteration = int(iter_match.group(1))
            tx_times = []
            rx_times = []
            optimization_time = 0

        # Capture transmission times
        send_match = send_pattern.search(line)
        if send_match:
            tx_times.append(float(send_match.group(1)))
            print(tx_times)

        # Capture reception times
        receive_match = receive_pattern.search(line)
        if receive_match:
            rx_times.append(float(receive_match.group(1)))
            print(rx_times)

        # Capture optimization time
        optimization_match = optimization_pattern.search(line)
        if optimization_match:
            optimization_time = float(optimization_match.group(1))

# Process the final iteration
process_iteration()

# Write the results to a CSV file
with open(output_csv_path, 'w', newline='') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(['Iteration', 'TX_Times', 'RX_Times', 'Round_Trip_Delay', 'D_K', 'T_K'])
    csvwriter.writerows(data)

print(f"Data successfully written to {output_csv_path}")
