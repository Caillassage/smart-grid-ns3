# Current version: we are currently using this version for data collection

using Sockets, JuMP, Printf, Plots, Dates, DataFrames, CSV, Logging
using Gurobi

time1 = time()

# Set the global logging level to Error to suppress Warnings
global_logger(ConsoleLogger(stderr, Logging.Error))

include("Cent-revised.jl")

global num_RPi = 3

# Initialize variables
lambda_121 = ones(24)
lambda_122 = ones(24)

lambda_131 = ones(24)
lambda_133 = ones(24)

lambda_121_init = ones(24)
lambda_122_init = ones(24)
lambda_131_init = ones(24)
lambda_133_init = ones(24)

#lambda_343 = ones(24)
#lambda_344 = ones(24)

z12 = ones(24)
z13 = ones(24)
z12_init = ones(24)
z13_init = ones(24)

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

# x_131_hist = []
x_133_hist = []

t1_hist = []
t2_hist = []

t3_hist = []

obj1_hist = []
obj2_hist = []
obj3_hist = []

primal_residual_hist12 = []
primal_residual_hist13 = []
dual_residual_hist12 = []
dual_residual_hist13 = []
residual_hist=[]

rho = 50.0
MAX_ITER = 1000

iter = 1
iter_init = 1

# Define a structure for storing the data
struct TimeLog
    iteration::Int
    rpi_id::Int
    rx_time::Float64
end

# Initialize an array to store the logs
global time_logs = TimeLog[]

# Data lists
Iteration = []
TX_Time = []
RX_Time = []
RX_Time_D = []
TX_Data = []
RX_Data = []
Delay_k = []
Delay_proc = []
Delay_BFD = []
Delay_AFD = []

Delay_cc = []
D_K = []
T_K = []
Z_12 = []
Z_13 = []
Primal_Resi12 = []
Primal_Resi13 = []
LocalUpdate = []
global update1 = 0
global update2 = 0
global update3 = 0
global global_update = 0
GlobalUpdate = []

# Set to keep track of RPi IDs from which data has been received
global received_ids = Set()

# Pad zeros to ensure specific width
function zero_pad(number, width)
    return lpad(string(number), width, '0')
end

function format_and_zero_pad_vector(vector, width)
    # Apply formatting, padding, and truncation to each number in the vector
    # and join them into a single string
    formatted_vector = join([adjust_number(num, width) for num in vector], "")
    return formatted_vector
end

function adjust_number(num, width)
    # Calculate maximum number of decimal places based on the integer part length
    int_part_length = num < 0 ? length(string(trunc(Int, abs(num)))) + 1 : length(string(trunc(Int, num)))
    max_decimal_places = max(0, width - int_part_length - 1)  # Account for the decimal point

    # Directly round the number to fit the width, adjusting decimal places dynamically
    if max_decimal_places > 0
        num_r = round(num, digits=max_decimal_places)
    else
        num_r = round(num)  # Round to the nearest integer if no decimal places fit
    end

    # Format the rounded number to a string with precise control over decimal places
    formatted_num = @sprintf("%.*f", max_decimal_places, num_r)

    # Check the formatted string length and adjust with padding if necessary
    if length(formatted_num) < width
        return lpad(formatted_num, width, '0')
    elseif length(formatted_num) > width
        # Reduce decimal places if it's still too long, and format again
        # edge case like, num=999.95 and width=3
        formatted_num = @sprintf("%.10f", num)
        formatted_num = formatted_num[1:width]
    end

    return formatted_num
end

#retrieved back to vector shape
function parse_formatted_vector(message, num_elements, element_width)
    retrieved_vector = Float64[]  # Initialize an empty array to store the parsed numbers
    for i in 0:(num_elements-1)
        start_index = i * element_width + 1  # Calculate the starting index of each element
        end_index = start_index + element_width - 1  # Calculate the ending index
        substring = message[start_index:end_index]  # Extract the substring for the element
        number = parse(Float64, substring)  # Convert the substring to a Float64
        push!(retrieved_vector, number)  # Append the number to the array
    end
    return retrieved_vector
end

# Socket for Server
function create_socket()
    host = "0.0.0.0"  # Listen on all interfaces
    port = 21001
    udpsock = UDPSocket()
    bind(udpsock, IPv4(host), port; reuseaddr=true)
    println("UDP Server is listening on port ", port)
    return udpsock
end

function handshake(udpsock, num_RPi)
    address_list = Vector{Union{Nothing,Sockets.InetAddr{IPv4}}}(undef, num_RPi)  # Initialize with `Nothing` and compatible types
    while count(!isnothing, address_list) < num_RPi
        addr, data = recvfrom(udpsock)

        inital_data = String(data)

        rpi_id = parse(Int, inital_data[1:2])  # RPI ID received from the client

        if isnothing(address_list[rpi_id])
            if rpi_id in 1:num_RPi
                address_list[rpi_id] = addr  # Store the address based on RPI ID
                println("Received handshake from RPI ID $rpi_id at $addr")
            else
                println("Invalid RPI ID received from $addr")
            end
        end
        println("address_list: ", address_list)
    end
    return address_list
end

# Function to initialize previous data for a variable number of RPis
function initialize_previous_data(rpi_data_list)
    # Apply format_and_zero_pad_vector to each RPI's data
    return [[format_and_zero_pad_vector(data, 10)] for data in rpi_data_list]
end

# Example data arrays for different RPis
data_rpi1 = [0.08, 0.03666061, 0.93044957, 0.92184141, 0.5204187, -0.06683, -0.0, 0.0, -0.0, 0.0, 0.93536611, 0.9025, 0.42391827, 0.06988037, 0.076, 0.03466061, -0.0, 0.0, 0.90613814, 0.9025, 0.49695586, -0.1185468, -0.0, 0.0, -0.0, 0.0, 0.91033298, 0.91390587, 0.53052319, -0.1623328, 0.072, 0.03266061, -0.0, 0.0, 0.92232261, 0.9025, 0.4054239, 0.02258297, -0.0, 0.0, -0.004, -0.002, 0.91536363, 0.9025, 0.41399617, -0.1436305, -0.0, 0.0]
data_rpi2 = [0.08, 0.03666061, 1.01309886, 1.00776464, 0.02, 0.04666061, -0.0, 0.0, -0.0, 0.0, 1.00157976, 1.00084856, 0.01227941, 0.00577608, 0.01372059, 0.00822392, -0.0, 0.0, 1.00484059, 1.00221617, 0.039, 0.019, -0.0, 0.0]
data_rpi3 = [-0.0, 0.0, 0.9989009, 0.99991203, 0.01910978, 0.00438613, 0.02089022, 0.00227447, -0.0, 0.0, 0.99974641, 0.9992691, 0.016, -0.0053394, -0.0, 0.0, -0.004, -0.002, 1.00458208, 1.00045438, 0.052, 0.01266061, -0.0, 0.0]
# List of all RPI data
rpi_data_list = [data_rpi1, data_rpi2, data_rpi3]

# Initialize previous_data with formatted strings for each RPI
previous_data = initialize_previous_data(rpi_data_list)
println("previous_data: ", previous_data)


function handle_clients(udpsock)
    # thresholds = [100]  # List of threshold values
    #typical value: 0.21~0.30, 0.16~25, 0.11~0.20 
    # thresholds = [100, 1, 0.75, 0.5, 0.4, 0.35, 0.30, 0.25, 0.22, 0.21, 0.205, 0.20, 0.15, 0.10, 0.08, 0.05]
    thresholds = [0.08, 0.05]
    num_experiments = 5

    for thr in thresholds
        global Thr = thr  # Set the current threshold value
        println("Running experiments for threshold $Thr")

        for exp_num in 1:num_experiments
            println("Starting Experiment $exp_num")

            #reset all variables
            # Initialize variables
            global lambda_121 = ones(24)
            global lambda_122 = ones(24)
            global lambda_131 = ones(24)
            global lambda_133 = ones(24)

            global z12 = ones(24)
            global z13 = ones(24)
            
            global z12_init = ones(24)
            global z13_init = ones(24)

            global lambda_121_init = ones(24)
            global lambda_122_init = ones(24)
            global lambda_131_init = ones(24)
            global lambda_133_init = ones(24)

            global lambda_121_hist = []
            global lambda_122_hist = []
            global lambda_131_hist = []
            global lambda_133_hist = []

            global z12_hist = [ones(24)]
            global z13_hist = [ones(24)]

            global x_121_hist = []
            global x_122_hist = []
            # global x_131_hist = []
            global x_133_hist = []

            global primal_residual_hist12 = []
            global primal_residual_hist13 = []
            global dual_residual_hist12 = []
            global dual_residual_hist13 = []

            global rho = 50.0
            global MAX_ITER = 1000
            global iter = 1
            global iter_init = 1
            # global Thr = 0.13 #10 sec
            #100, 0.75, 0.5, 1, 0.16, 0.15, 0.14, 0.13, 0.12, 0.10

            # Data lists
            global Iteration = []
            global TX_Time = []
            global RX_Time = []
            global RX_Time_D = []
            global TX_Data = []
            global RX_Data = []
            global Delay_k = []
            global Delay_proc = []
            global Delay_BFD = []
            global Delay_AFD = []
            global Delay_cc = []
            global D_K = []
            global T_K = []
            global Z_12 = []
            global Z_13 = []
            global Primal_Resi12 = []
            global Primal_Resi13 = []
            global LocalUpdate = []
            global update1 = 0
            global update2 = 0
            global update3 = 0
            global global_update = 0
            global GlobalUpdate = []

            global residual_hist = []
            # Set to keep track of RPi IDs from which data has been received
            global received_ids = Set()

            # Function to initialize previous data for a variable number of RPis
            function initialize_previous_data(rpi_data_list)
                # Apply format_and_zero_pad_vector to each RPI's data
                return [[format_and_zero_pad_vector(data, 10)] for data in rpi_data_list]
            end

            # Example data arrays for different RPis
            data_rpi1 = [0.08, 0.03666061, 0.93044957, 0.92184141, 0.5204187, -0.06683, -0.0, 0.0, -0.0, 0.0, 0.93536611, 0.9025, 0.42391827, 0.06988037, 0.076, 0.03466061, -0.0, 0.0, 0.90613814, 0.9025, 0.49695586, -0.1185468, -0.0, 0.0, -0.0, 0.0, 0.91033298, 0.91390587, 0.53052319, -0.1623328, 0.072, 0.03266061, -0.0, 0.0, 0.92232261, 0.9025, 0.4054239, 0.02258297, -0.0, 0.0, -0.004, -0.002, 0.91536363, 0.9025, 0.41399617, -0.1436305, -0.0, 0.0]
            data_rpi2 = [0.08, 0.03666061, 1.01309886, 1.00776464, 0.02, 0.04666061, -0.0, 0.0, -0.0, 0.0, 1.00157976, 1.00084856, 0.01227941, 0.00577608, 0.01372059, 0.00822392, -0.0, 0.0, 1.00484059, 1.00221617, 0.039, 0.019, -0.0, 0.0]
            data_rpi3 = [-0.0, 0.0, 0.9989009, 0.99991203, 0.01910978, 0.00438613, 0.02089022, 0.00227447, -0.0, 0.0, 0.99974641, 0.9992691, 0.016, -0.0053394, -0.0, 0.0, -0.004, -0.002, 1.00458208, 1.00045438, 0.052, 0.01266061, -0.0, 0.0]
            
            # List of all RPI data
            rpi_data_list = [data_rpi1, data_rpi2, data_rpi3]
            # Initialize previous_data with formatted strings for each RPI
            previous_data = initialize_previous_data(rpi_data_list)
            #println("previous_data1", previous_data)

            #######
            global received_ids
            try
                #initial packet sending loop
                global packet_number_init = 0
                # Loop until condition satisfied
                while iter_init <= 15
                    println("\n")
                    println("Dummy Iteration: ", iter_init)

                    # Increment the packet number at the start of each iteration
                    packet_number_init += 1

                    global tx_times_init = []
                    global rx_times_init = []

                    #The width for the formatted string is set to 8 to accommodate the formatted number plus the decimal point.
                    # message_init = "D" * zero_pad(packet_number_init, 4) * format_and_zero_pad_vector(z12_init, 10) * adjust_number(rho, 10)
                    message_init = "D" * zero_pad(packet_number_init, 4) * adjust_number(rho, 10)

                    # send data to all Clients/Areas
                    for i in 1:num_RPi
                        # Data for Area 1 (client 1) 
                        if i == 1 #since address_list first item is for area1
                            final_message_init = message_init * format_and_zero_pad_vector(vcat(z12_init, z13_init), 10) * format_and_zero_pad_vector(vcat(lambda_121_init, lambda_131_init), 10)
                            # print("vcat(z12_init, z13_init: ", vcat(z12_init, z13_init))
                            
                            # print("vcat(lambda_121_init, lambda_131_init: ", vcat(lambda_121_init, lambda_131_init))

                            # Data for Area 2 (client 2)
                        elseif i == 2 #since address_list second item is for area2
                            final_message_init = message_init * format_and_zero_pad_vector(z12_init, 10) * format_and_zero_pad_vector(lambda_122_init, 10)
                            #final_message = message * format_and_zero_pad_vector(lambda_121, 10)
                        
                        # Data for Area 3 (client 3)
                        elseif i == 3 #since address_list second item is for area2
                            final_message_init = message_init * format_and_zero_pad_vector(z13_init, 10) * format_and_zero_pad_vector(lambda_133_init, 10)
                            #final_message = message * format_and_zero_pad_vector(lambda_121, 10)
                        end
                        # print("final_message_init: ", final_message_init)

                        final_message_bytes_init = Vector{UInt8}(final_message_init)
                        
                        # Extract IP address and port from InetAddr object for each RPI
                        ip_init = address_list[i].host  # Extract the IP address using `host`
                        port_init = address_list[i].port  # Extract the port number
                        
                        # tx_time = Dates.now()
                        global tx_time_init = time()
                        # println("tx_time: ", tx_time)

                        send(udpsock, ip_init, port_init, final_message_bytes_init)
                        # println("Sent Dummy data to RPI ID $i")

                        push!(tx_times_init, string(tx_time_init))

                    end
                        
                    # println("length(received_ids)1", length(received_ids))
                    while length(received_ids) < num_RPi
                        _, data = recvfrom(udpsock)
                        current_time_init = time()
                        # println("Dummy data: ", data)
                        result_data_init = String(data)
                        # println("Dummy data Strg: ", result_data_init) 
                        received_pak_num_init = parse(Int, result_data_init[1:4])  # Minimize parsing if possible

                        # Process data only if within the time window
                        rx_time_init = current_time_init
                        # println("rx_time: ", rx_time)

                        global cc1_time_init = rx_time_init #consensus check time
                        push!(rx_times_init, string(rx_time_init))

                        rpi_id_init = parse(Int, result_data_init[6:7])
                        # Add the RPi ID to the set
                        push!(received_ids, rpi_id_init)

                        # Calculate delay
                        D_ak_init = (rx_time_init - parse(Float64, tx_times_init[rpi_id_init]))
                        println("Dummy Rx from RPi: $rpi_id_init, Delay(s): $D_ak_init")
                        if rpi_id_init == 1
                            proc_delay_init = parse(Float64, result_data_init[488:497])
                            x_message_segment_init = result_data_init[8:487]
                            x1_init = parse_formatted_vector(x_message_segment_init, 48, 10)
                        else
                            proc_delay_init = parse(Float64, result_data_init[248:257])  # The numeric value as a Float64
                        end
                        # println("Dummy proc_delay_init: ", proc_delay_init)
                    end
                    # Reset received_ids for the next iteration
                    global received_ids = Set()
                    # iteration increment
                    iter_init = iter_init + 1
                    # sleep(0.20) #sleep for 0.20 sec to avoid hangover
                end
                # sleep(1)

                #main data loop
                global packet_number = 0
                global violation = 0
                # Loop until condition satisfied
                while iter <= MAX_ITER
                    println("\n")
                    # println("Iteration: ", iter)

                    #list to save no of interations
                    push!(Iteration, iter)
                    # Increment the packet number at the start of each iteration
                    packet_number += 1
                    println("Packet Number: ", packet_number)

                    global tx_times = []
                    global rx_times = []

                    task_tx_time = [Vector{String}() for _ in 1:num_RPi]  # Initialize as list of lists
                    task_rx_time = [Vector{String}() for _ in 1:num_RPi]  # Initialize as list of lists
                    task_rx_time_D = [Vector{String}() for _ in 1:num_RPi]  # Initialize as list of lists
                    task_delay = [Vector{Float64}() for _ in 1:num_RPi]  # Initialize as list of lists
                    process_delay = [Vector{Float64}() for _ in 1:num_RPi]  # Initialize as list of lists
                    beforeData_delay = [Vector{Float64}() for _ in 1:num_RPi]  # Initialize as list of lists
                    afterData_delay = [Vector{Float64}() for _ in 1:num_RPi]  # Initialize as list of lists
                    update_fr = [Vector{Int}() for _ in 1:num_RPi]  # Initialize as list of lists

                    #The width for the formatted string is set to 8 to accommodate the formatted number plus the decimal point.
                    # message = zero_pad(packet_number, 4) * format_and_zero_pad_vector(z12, 10) * adjust_number(rho, 10) #2 Areas
                    message = zero_pad(packet_number, 4) * adjust_number(rho, 10) #3 Areas

                    # send data to all Clients/Areas
                    #for i in num_RPi:-1:1        
                    for i in 1:num_RPi
                        # Data for Area 1 (client 1) 
                        if i == 1 #since address_list first item is for area1
                            final_message = message * format_and_zero_pad_vector(vcat(z12, z13), 10) * format_and_zero_pad_vector(vcat(lambda_121, lambda_131), 10)

                            # Data for Area 2 (client 2)
                        elseif i == 2 #since address_list second item is for area2
                            final_message = message * format_and_zero_pad_vector(z12, 10) * format_and_zero_pad_vector(lambda_122, 10)
                            #final_message = message * format_and_zero_pad_vector(lambda_121, 10)
                        
                        # Data for Area 3 (client 3)
                        elseif i == 3 #since address_list second item is for area2
                            final_message = message * format_and_zero_pad_vector(z13, 10) * format_and_zero_pad_vector(lambda_133, 10)
                            #final_message = message * format_and_zero_pad_vector(lambda_121, 10)
                        end
                        # print("z12: ", z12)
                        # print("z13: ", z13)
                        # print("lambda_121: ", lambda_121)
                        # print("lambda_131: ", lambda_131)
                        # print("vcat(lambda_121, lambda_131): ", vcat(lambda_121, lambda_131))
                        # print("vcat(z12, z13: ", vcat(z12, z13))
                        # print("final_message: ", final_message)
                        # println("final_message: $i", final_message)
                        final_message_bytes = Vector{UInt8}(final_message)

                        # Extract IP address and port from InetAddr object for each RPI
                        ip = address_list[i].host  # Extract the IP address using `host`
                        port = address_list[i].port  # Extract the port number

                        send(udpsock, ip, port, final_message_bytes)
                        # tx_time = Dates.now()
                        global tx_time = time()
                        # println("tx_time: ", tx_time)
                        println("Sent data to RPI ID $i.")

                        push!(tx_times, string(tx_time))
                        push!(task_tx_time[i], string(tx_time))
                    end
                    # Set tx_time after sending data to all RPis
                    global window_time = time()

                    # println("length(received_ids)1", length(received_ids))
                    while time() <= (window_time + Thr) && length(received_ids) < num_RPi

                        test_time= time()
                        _, data = recvfrom(udpsock)
                        current_time = time()
                        # println("time to recevie data: ", current_time-test_time)
                        # println("data: ", data)
                        result_data = String(data)
                        received_pak_num = parse(Int, result_data[1:4])  # Minimize parsing if possible

                        # Check time first to avoid processing late packets
                        if current_time > (window_time + Thr) || received_pak_num != packet_number
                            if current_time > (window_time + Thr)
                                rx1_time = time()
                                rpi_id1 = parse(Int, result_data[6:7])
                                # Create a new TimeLog entry
                                #push!(time_logs, TimeLog(iter, rpi_id1, rx1_time)) 
                                push!(task_rx_time_D[rpi_id1], string(rx1_time))
                                violation = violation + 1
                            end
                            continue
                        end

                        # Process data only if within the time window
                        rx_time = current_time
                        # println("rx_time: ", rx_time)

                        global cc1_time = rx_time #consensus check time
                        push!(rx_times, string(rx_time))

                        # Extract packet number and compare
                        received_pak_num = parse(Int, result_data[1:4])

                        # Extract data type ('x' or 'y'), RPI ID, and the value
                        data_type = result_data[5:5]             # 'X' or 'Y' or 'Z'

                        rpi_id = parse(Int, result_data[6:7])
                        # Add the RPi ID to the set
                        push!(received_ids, rpi_id)
                        push!(task_rx_time[rpi_id], string(rx_time))

                        #duplicate of task_rx_time
                        push!(task_rx_time_D[rpi_id], string(rx_time))

                        # Calculate delay
                        D_ak = (rx_time - parse(Float64, tx_times[rpi_id]))
                        push!(task_delay[rpi_id], D_ak)
                        # println("RPi: $rpi_id, RX Message: $result_data, Delay(s): $D_ak")
                        println("Rx from RPi: $rpi_id, Delay(s): $D_ak")

                        if rpi_id == 1
                            x_message_segment = result_data[8:487]  # The numeric value as a Float64
                            proc_delay = parse(Float64, result_data[488:497])  # The numeric value as a Float64
                            BFD_time = parse(Float64, result_data[498:511])  # The numeric value as a Float64
                            AFD_time = parse(Float64, result_data[512:525])  # The numeric value as a Float64
                            global x1 = parse_formatted_vector(x_message_segment, 48, 10)  # Received x1 from Area 1 (RPI ID 1)
                            # println("x1 from RPI ID 1: ", x1)

                            #Update frequency
                            global update1 = update1 + 1
                            push!(update_fr[rpi_id], update1)

                        elseif rpi_id == 2
                            x_message_segment = result_data[8:247]  # The numeric value as a Float64
                            proc_delay = parse(Float64, result_data[248:257])  # The numeric value as a Float64
                            BFD_time = parse(Float64, result_data[258:271])  # The numeric value as a Float64
                            AFD_time = parse(Float64, result_data[272:285])  # The numeric value as a Float64
                            global x2 = parse_formatted_vector(x_message_segment, 24, 10)  # Received x2 from Area 2 (RPI ID 2)
                            # println("x2 from RPI ID 2: ", x2)

                            #Update frequency
                            global update2 = update2 + 1
                            push!(update_fr[rpi_id], update2)
                            
                        elseif  rpi_id == 3
                            x_message_segment = result_data[8:247]  # The numeric value as a Float64
                            proc_delay = parse(Float64, result_data[248:257])  # The numeric value as a Float64
                            BFD_time = parse(Float64, result_data[258:271])  # The numeric value as a Float64
                            AFD_time = parse(Float64, result_data[272:285])  # The numeric value as a Float64
                            global x3 = parse_formatted_vector(x_message_segment, 24, 10)  # Received x2 from Area 2 (RPI ID 2)
                            # println("x3 from RPI ID 3: ", x3)

                            #Update frequency
                            global update3 = update3 + 1
                            push!(update_fr[rpi_id], update3)

                        else
                            println("Unexpected data format or RPI_ID")
                        end

                        # x_message_segment = result_data[8:247]  # The numeric value as a Float64
                        # proc_delay = parse(Float64, result_data[248:257])  # The numeric value as a Float64
                        push!(process_delay[rpi_id], proc_delay)

                        #new: delay before data recevied 
                        # BFD_time = parse(Float64, result_data[258:271])  # The numeric value as a Float64
                        # println("BFD_time: ", BFD_time)
                        BFD_delay = (BFD_time - parse(Float64, tx_times[rpi_id]))
                        push!(beforeData_delay[rpi_id], BFD_delay)
                        
                        # AFD_time = parse(Float64, result_data[272:285])  # The numeric value as a Float64
                        AFD_delay = (rx_time - AFD_time)
                        push!(afterData_delay[rpi_id], AFD_delay)

                        # saved last received data
                        previous_data[rpi_id] = [x_message_segment]
                        # println("x_message_segment: ", x_message_segment)
                        # println("previous_data1", previous_data)
                    end

                    #check if global variable updates or not
                    if length(received_ids) > 0
                        global global_update = global_update + 1
                        push!(GlobalUpdate, global_update)
                    else
                        # push!(GlobalUpdate, "NA")  
                        push!(GlobalUpdate, global_update)
                    end

                    # Final check if loop exited due to all data received
                    if length(received_ids) == num_RPi
                        println("Data received from all RPis.")
                    else
                        println("Waiting for data/time limit reached.")
                        for id in 1:num_RPi
                            if id ∉ received_ids
                                # Extract previous data for the RPI ID and store it in old_data
                                old_data = previous_data[id][1]
                                # println("previous_data1", previous_data)
                                # Print a message indicating the action taken and showing the old data
                                println("Data not received from RPI ID $id.")
                                rx_time = time()
                                # println("rx_time:", rx_time)
                                push!(task_rx_time[id], string(rx_time))
                                # println("task_rx_time:", task_rx_time)

                                # Calculate delay
                                D_ak = Thr #if data is not recevied within Thr, delay is equal to Thr
                                push!(task_delay[id], D_ak)
                                # println("D_ak:: ", D_ak)

                                global cc1_time = rx_time #consensus check time

                                # Assign the value based on RPI ID and data_type (need to address here at client side)
                                if id == 1
                                    global x1 = parse_formatted_vector(old_data, 48, 10)  # Received x1 from Area 1 (RPI ID 1)
                                    println("Using Old x1 data.")
                                    #update the local update using last data 
                                    push!(update_fr[id], update1)

                                elseif id == 2
                                    global x2 = parse_formatted_vector(old_data, 24, 10)  # Received x2 from Area 2 (RPI ID 2)
                                    println("Using Old x2 data.")
                                    #update the local update using last data 
                                    push!(update_fr[id], update2)
                                
                                elseif id == 3
                                    global x3 = parse_formatted_vector(old_data, 24, 10)  # Received x2 from Area 2 (RPI ID 2)
                                    println("Using Old x2 data.")
                                    #update the local update using last data 
                                    push!(update_fr[id], update3)
                                else
                                    println("Unexpected data format or RPI_ID")
                                end
                            end
                        end
                    end
                    # Reset received_ids for the next iteration
                    global received_ids = Set()

                    max_delay = maximum(maximum(sublist) for sublist in task_delay if !isempty(sublist))
                    d_k = min(Thr, max_delay)
                    push!(D_K, d_k)
                    # println("D_k:", d_k)
                    # println("RX_Time", RX_Time)
                    # println("Delay_k", Delay_k)
                    #save the data
                    push!(TX_Time, task_tx_time)
                    # println("task_rx_time Final", task_rx_time)
                    push!(RX_Time, task_rx_time)
                    push!(RX_Time_D, task_rx_time_D) #duplicate of RX_Time
                    push!(Delay_k, task_delay)
                    push!(Delay_proc, process_delay)
                    #new:
                    push!(Delay_BFD, beforeData_delay)
                    push!(Delay_AFD, afterData_delay)

                    push!(LocalUpdate, update_fr)

                    # Update z12, lambda_121, lambda_122
                    global z12 = 1/2 * ( x1[1:24]+(1/rho)*lambda_121 + x2+(1/rho)*lambda_122 )
                    global z13 = 1/2 * ( x1[25:48]+(1/rho)*lambda_131 + x3+(1/rho)*lambda_133 )
                    push!(Z_12, z12)
                    push!(Z_13, z13)

                    global lambda_121 = lambda_121 + rho*(x1[1:24] - z12)
                    global lambda_122 = lambda_122 + rho*(x2 - z12)
                    global lambda_131 = lambda_131 + rho*(x1[25:48] - z13)
                    global lambda_133 = lambda_133 + rho*(x3 - z13)

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
                    # push!(obj1_hist,obj1)
                    # push!(obj2_hist,obj2)
                    # push!(obj3_hist,obj3)

                    # solvetime
                    # push!(t1_hist,t1)
                    # push!(t2_hist,t2)

                    # additionally saved primal residual
                    primal_residual_12 = [abs.(x1[1:24]- z12), abs.(x2 - z12)]
                    primal_residual_13 = [abs.(x1[25:48] - z13), abs.(x3 - z13)]

                    push!(Primal_Resi12, primal_residual_12)
                    push!(Primal_Resi13, primal_residual_13)

                    dual_residual_12 = [abs.(z12_hist[end]-z12_hist[end-1])]
                    dual_residual_13 = [abs.(z13_hist[end]-z13_hist[end-1])]

                    global residual = [ abs.(x1[1:24]- z12), abs.(x2 - z12), abs.(z12_hist[end]-z12_hist[end-1]),
                                        abs.(x1[25:48] - z13), abs.(x3 - z13), abs.(z13_hist[end]-z13_hist[end-1])]

                    #residual_12 = [abs.(x1 - z12), abs.(x2 - z12), abs.(z12_hist[end] - z12_hist[end-1])]
                    # println("primal_residual_12:", primal_residual_12)
                    push!(residual_hist, residual)

                    push!(primal_residual_hist12, primal_residual_12)
                    push!(primal_residual_hist13, primal_residual_13)

                    push!(dual_residual_hist12, dual_residual_12)
                    push!(dual_residual_hist13, dual_residual_13)

                    #if consdition satisfied the loop breaks early                        
                    if all([maximum(residual[i]) for i in 1:length(residual)] .< 0.0001) # all([all(residual[i] .< 0.0001) for i in 1:length(residual)])
                        cc2_time = time()
                        cc_delay = cc2_time - cc1_time
                        push!(Delay_cc, cc_delay)
                        t_k = d_k + cc_delay
                        push!(T_K, t_k)
                        break
                    end

                    #concensus delay
                    cc2_time = time()
                    cc_delay = cc2_time - cc1_time
                    t_k = d_k + cc_delay
                    push!(T_K, t_k)
                    # println("t_k: ", T_K)
                    push!(Delay_cc, cc_delay)
                    # println("Delay_cc: ", Delay_cc)   

                    # iteration increment
                    iter = iter + 1
                    #sleep(0.2)
                end
            finally
                println("z12: ", z12)
                println("z13: ", z13)
                println("Task Done")

                ####plotting things...
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
                #=
                solvetime_all = [t1_hist t2_hist ]

                worst=zeros(size(solvetime_all,1),1)
                for i=1:size(solvetime_all,1)
                global worst[i]=maximum(solvetime_all[i,:])
                end
                solvetime_dist=sum(worst)

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

                # ##
                # Pdgdist_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
                # Pdgdist_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
                # Pdgdist_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

                # for bus in BUS_SET["area_1"]
                #         Pdgdist_a[bus] = :a in BUS_PHS_SET["area_1"][bus] ? Pdg1[(bus,:a)] : 0
                #         Pdgdist_b[bus] = :b in BUS_PHS_SET["area_1"][bus] ? Pdg1[(bus,:b)]  : 0
                #         Pdgdist_c[bus] = :c in BUS_PHS_SET["area_1"][bus] ? Pdg1[(bus,:c)]  : 0
                # end

                # for bus in BUS_SET["area_2"]
                #         Pdgdist_a[bus] = :a in BUS_PHS_SET["area_2"][bus] ? Pdg2[(bus,:a)] : 0
                #         Pdgdist_b[bus] = :b in BUS_PHS_SET["area_2"][bus] ? Pdg2[(bus,:b)]  : 0
                #         Pdgdist_c[bus] = :c in BUS_PHS_SET["area_2"][bus] ? Pdg2[(bus,:c)]  : 0
                # end

                # for bus in BUS_SET["area_3"]
                #         Pdgdist_a[bus] = :a in BUS_PHS_SET["area_3"][bus] ? Pdg3[(bus,:a)] : 0
                #         Pdgdist_b[bus] = :b in BUS_PHS_SET["area_3"][bus] ? Pdg3[(bus,:b)]  : 0
                #         Pdgdist_c[bus] = :c in BUS_PHS_SET["area_3"][bus] ? Pdg3[(bus,:c)]  : 0
                # end
                # Pdg_dist_total = sum(Pdgdist_a + Pdgdist_b + Pdgdist_c)*(1e3*sbase)


                # Qdgdist_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
                # Qdgdist_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
                # Qdgdist_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

                # for bus in BUS_SET["area_1"]
                #         Qdgdist_a[bus] = :a in BUS_PHS_SET["area_1"][bus] ? Qdg1[(bus,:a)] : 0
                #         Qdgdist_b[bus] = :b in BUS_PHS_SET["area_1"][bus] ? Qdg1[(bus,:b)]  : 0
                #         Qdgdist_c[bus] = :c in BUS_PHS_SET["area_1"][bus] ? Qdg1[(bus,:c)]  : 0
                # end

                # for bus in BUS_SET["area_2"]
                #         Qdgdist_a[bus] = :a in BUS_PHS_SET["area_2"][bus] ? Qdg2[(bus,:a)] : 0
                #         Qdgdist_b[bus] = :b in BUS_PHS_SET["area_2"][bus] ? Qdg2[(bus,:b)]  : 0
                #         Qdgdist_c[bus] = :c in BUS_PHS_SET["area_2"][bus] ? Qdg2[(bus,:c)]  : 0
                # end

                # for bus in BUS_SET["area_3"]
                #         Qdgdist_a[bus] = :a in BUS_PHS_SET["area_3"][bus] ? Qdg3[(bus,:a)] : 0
                #         Qdgdist_b[bus] = :b in BUS_PHS_SET["area_3"][bus] ? Qdg3[(bus,:b)]  : 0
                #         Qdgdist_c[bus] = :c in BUS_PHS_SET["area_3"][bus] ? Qdg3[(bus,:c)]  : 0
                # end

                # Qdg_dist_total = sum(Qdgdist_a + Qdgdist_b + Qdgdist_c)*(1e3*sbase)

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

                
                #plotting things finsihed here.
                println("z12_hist", z12)

                # Open the log file in read mode
                open("Data/RPilogfile_123_3.txt", "r") do file
                    # Read all lines from the file
                    lines = readlines(file)
                    # Get the last line of the file
                    last_line = lines[end]
                    # Split the last line by commas
                    last_line_separated = split(last_line, ',')
                    # Extract the previous experiment ID from the first element
                    global previous_experiment_id = parse(Int, split(last_line_separated[1], '=')[2])
                end
                # Increment the experiment ID by 1
                new_experiment_id = previous_experiment_id + 1

                # Save data to CSV
                dataset = DataFrame(
                    Iteration=Iteration,
                    TX_Time=TX_Time,
                    RX_Time=RX_Time,
                    RX_Time_Dup=RX_Time_D,
                    T_lo=Delay_proc,
                    D_SA=Delay_BFD,
                    D_AS=Delay_AFD,
                    D_AK=Delay_k,
                    D_K=D_K,
                    T_cc=Delay_cc,
                    T_K=T_K,
                    Z12=Z_12,
                    Z13=Z_13,
                    X1=x_121_hist,
                    X2=x_122_hist,
                    X3=x_133_hist,
                    L1=lambda_121_hist,
                    L2=lambda_122_hist,
                    L3=lambda_131_hist,
                    L4=lambda_133_hist,
                    Primal_Residual12=Primal_Resi12,
                    Primal_Residual13=Primal_Resi13,
                    LocalUpdate=LocalUpdate,
                    GlobalUpdate=GlobalUpdate
                )
                sys_timestamp = Dates.format(Dates.now(), "u-dd-YYYY_H_M")
                path = "$(new_experiment_id)_123_3Ar_RPi_Dist_($(num_RPi))_$(Thr)_$(packet_number)_$sys_timestamp.csv"

                filename = "Data/$path"
                CSV.write(filename, dataset)
                
                # Open the log file in append mode
                open("Data/RPilogfile_123_3.txt", "a") do file
                    # time_logs_string = join(["[$(log.iteration),$(log.rpi_id),$(log.rx_time)]" for log in time_logs], ", ")
                    # write(file, "ExpID = $(new_experiment_id), Date = $(sys_timestamp), NumRPI = $(num_RPi), timeLogs= [$time_logs_string]\n")

                    # Write the new experiment ID, date, and number of PMUs to the file in a new line
                    write(file, "ExpID = $(new_experiment_id), Date = $(sys_timestamp), NumRPI = $(num_RPi), Violation_no= $violation\n")
                end
                println("Data saved to ", filename)
            end
            #sleep(5)
        end
        #sleep(5)
    end
    close(udpsock)
end

#main code sequence
udpsock = create_socket()
time2 = time()
Initialization_time = time2 - time1
println("Model Initialization Time (S): ", Initialization_time)

address_list = handshake(udpsock, num_RPi)
if !isnothing(udpsock)
    handle_clients(udpsock)
end