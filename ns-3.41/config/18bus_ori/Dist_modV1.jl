using Sockets, JuMP, Printf, Plots, Dates, DataFrames, CSV, Logging
time1= time()

# Set the global logging level to Error to suppress Warnings
global_logger(ConsoleLogger(stderr, Logging.Error))

include("Cent-revised.jl")

num_RPi = 2

# Initialize variables
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

MAX_ITER = 1000
iter = 1
global Thr = 0.13 #10 sec

#100, 0.75, 0.5, 1, 0.16, 0.15, 0.14, 

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
TX_Data = []
RX_Data = []
Delay_k = []
Delay_proc = []
Delay_cc = []
D_K = []
T_K = []
Z_12 = []
Primal_Resi = []
LocalUpdate = []
global update1 = 0 
global update2 = 0
global global_update = 0
GlobalUpdate = []

residual_12_hist =[]
# Set to keep track of RPi IDs from which data has been received
global received_ids = Set()


# Function to create a single concatenated string of formatted numbers
function format_concatenated()
        return [join(["1.00000000" for _ in 1:24], "")]  # Creates one long string and wraps it in an array
end

# Initialize previous_data with a single string per RPi
previous_data = [format_concatenated() for _ in 1:num_RPi]

# Pad zeros to ensure specific width
function zero_pad(number, width)
        return lpad(string(number), width, '0')
end
    
# Pad zeros to ensure specific width and format to 4 decimal places
function format_and_zero_pad(number, width)
        formatted_number = @sprintf("%.5f", number)  # Format to 4 decimal places
        return lpad(formatted_number, width, '0')
end

#pad zeros to each element of a vector to ensrue specific length
function format_and_zero_pad_vector(vector, width)
        # Format each element of the vector to four decimal places and pad to the specified width
        formatted_vector = join([@sprintf("%0*.5f", width, num) for num in vector], "")
        return formatted_vector
end 

#retrieved back to vector shape
function parse_formatted_vector(message, num_elements, element_width)
        retrieved_vector = Float64[]  # Initialize an empty array to store the parsed numbers
        for i in 0:(num_elements - 1)
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

function handle_clients(udpsock)
        global received_ids
        address_list = Vector{Union{Nothing, Sockets.InetAddr{IPv4}}}(undef, num_RPi)  # Initialize with `Nothing` and compatible types
        
        try
                # Handshake with all RPis
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
                 
                global packet_number = 0
                # Loop until condition satisfied
                while iter <= MAX_ITER
                        println("\n")
                        println("Iteration: ", iter)
                        
                        #list to save no of interations
                        push!(Iteration, iter)
                        # Increment the packet number at the start of each iteration
                        packet_number += 1
                        println("Packet Number: ", packet_number)

                        global tx_times = []
                        global rx_times = []

                        task_tx_time = [Vector{String}() for _ in 1:num_RPi]  # Initialize as list of lists
                        task_rx_time = [Vector{String}() for _ in 1:num_RPi]  # Initialize as list of lists
                        task_delay = [Vector{Float64}() for _ in 1:num_RPi]  # Initialize as list of lists
                        process_delay = [Vector{Float64}() for _ in 1:num_RPi]  # Initialize as list of lists
                        update_fr = [Vector{Int}() for _ in 1:num_RPi]  # Initialize as list of lists

                        #The width for the formatted string is set to 8 to accommodate the formatted number plus the decimal point.
                        message = zero_pad(packet_number, 4) * format_and_zero_pad_vector(z12, 10) * format_and_zero_pad(rho, 10)
                        
                        # send data to all Clients/Areas
                        for i in 1:num_RPi
                                # Data for Area 1 (client 1) 
                                if i==1 #since address_list first item is for area1
                                        final_message = message * format_and_zero_pad_vector(lambda_121, 10)

                                # Data for Area 2 (client 2)
                                elseif i==2 #since address_list second item is for area2
                                        final_message = message * format_and_zero_pad_vector(lambda_122, 10)
                                end
                                
                                final_message_bytes = Vector{UInt8}(final_message)

                                # Extract IP address and port from InetAddr object for each RPI
                                ip = address_list[i].host  # Extract the IP address using `host`
                                port = address_list[i].port  # Extract the port number

                                # tx_time = Dates.now()
                                global tx_time = time()
                                # println("tx_time: ", tx_time)

                                send(udpsock, ip, port, final_message_bytes)
                                println("Sent data to RPI ID $i")
                                
                                push!(tx_times, string(tx_time))
                                push!(task_tx_time[i], string(tx_time))
                        end
                        # Set tx_time after sending data to all RPis
                        global window_time = time()

                        # println("length(received_ids)1", length(received_ids))
                        while time()<= (window_time +Thr) && length(received_ids) < num_RPi
                                
                                _, data = recvfrom(udpsock)
                                current_time = time()
                                result_data = String(data)     
                                received_pak_num = parse(Int, result_data[1:4])  # Minimize parsing if possible

                                # Check time first to avoid processing late packets
                                if current_time > (window_time + Thr) || received_pak_num != packet_number
                                        if current_time > (window_time + Thr)
                                                rx1_time = time()
                                                # Create a new TimeLog entry
                                                push!(time_logs, TimeLog(iter, num_RPi, rx1_time))
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
                                data_type = result_data[5:5]             # 'x' or 'y'
                                
                                rpi_id = parse(Int, result_data[6:7])  
                                # Add the RPi ID to the set
                                push!(received_ids, rpi_id)
                                push!(task_rx_time[rpi_id], string(rx_time))
                                # println("task_rx_time:", task_rx_time)

                                # Calculate delay
                                D_ak = (rx_time - parse(Float64, tx_times[rpi_id]))
                                push!(task_delay[rpi_id], D_ak)
                                # println("RPi: $rpi_id, RX Message: $result_data, Delay(s): $D_ak")
                                println("Rx from RPi: $rpi_id, Delay(s): $D_ak")
                                
                                x_message_segment = result_data[8:247]  # The numeric value as a Float64
                                proc_delay = parse(Float64, result_data[248:257])  # The numeric value as a Float64
                                push!(process_delay[rpi_id], proc_delay)

                                # saved last received data
                                previous_data[rpi_id] = [x_message_segment]

                                # Assign the value based on RPI ID and data_type (need to address here at client side)
                                if rpi_id == 1
                                        global x1 = parse_formatted_vector(x_message_segment, 24, 10)  # Received x1 from Area 1 (RPI ID 1)
                                        # println("x1 from RPI ID 1: ", x1)

                                        #Update frequency
                                        global update1 = update1 + 1
                                        push!(update_fr[rpi_id], update1)

                                elseif rpi_id == 2
                                        global x2 = parse_formatted_vector(x_message_segment, 24, 10)  # Received x2 from Area 2 (RPI ID 2)
                                        # println("x2 from RPI ID 2: ", x2)

                                        #Update frequency
                                        global update2 = update2 + 1
                                        push!(update_fr[rpi_id], update2)
                                else
                                        println("Unexpected data format or RPI_ID")
                                end
                        end

                        #check if global variable updates or not
                        if length(received_ids) > 0
                                global global_update = global_update + 1
                                push!(GlobalUpdate, global_update)
                        else
                                push!(GlobalUpdate, "NA")  
                        end

                        # Final check if loop exited due to all data received
                        if length(received_ids) == num_RPi
                                println("Data received from all RPis within time frame.") 
                        else
                                println("Waiting for more data or time limit reached.")
                                for id in 1:num_RPi
                                        if id ∉ received_ids
                                                # Extract previous data for the RPI ID and store it in old_data
                                                old_data = previous_data[id][1]

                                                # Print a message indicating the action taken and showing the old data
                                                println("Data not received from RPI ID $id. Using previous data.")
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
                                                        global x1 = parse_formatted_vector(old_data, 24, 10)  # Received x1 from Area 1 (RPI ID 1)
                                                        println("Old x1: ", x1)
                                                elseif id == 2
                                                        global x2 = parse_formatted_vector(old_data, 24, 10)  # Received x2 from Area 2 (RPI ID 2)
                                                        println("Old x2: ", x2)
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
                        push!(Delay_k, task_delay)
                        push!(Delay_proc, process_delay)
                        push!(LocalUpdate, update_fr)

                        # Update z12, lambda_121, lambda_122
                        global z12 = 1/2*( x1+(1/rho)*lambda_121 + x2+(1/rho)*lambda_122)
                        push!(Z_12, z12)

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
                        push!(Primal_Resi, primal_residual_12)

                        dual_residual_12 = [abs.(z12_hist[end] - z12_hist[end-1])]

                        residual_12 = [abs.(x1-z12), abs.(x2-z12), abs.(z12_hist[end] - z12_hist[end-1])]
                        # println("primal_residual_12:", primal_residual_12)
                        push!(residual_12_hist, residual_12)

                        push!(primal_residual_hist, primal_residual_12)
                        push!(dual_residual_hist, dual_residual_12)

                        #if consdition satisfied the loop breaks early
                        if all([all(residual_12[i] .< 0.0001) for i in 1:length(residual_12)])
                                cc2_time = time()
                                cc_delay = cc2_time-cc1_time
                                push!(Delay_cc, cc_delay)
                                t_k = d_k + cc_delay
                                push!(T_K, t_k)
                                break
                        end

                        #concensus delay
                        cc2_time = time()
                        cc_delay = cc2_time-cc1_time
                        t_k = d_k + cc_delay
                        push!(T_K, t_k)
                        # println("t_k: ", T_K)
                        push!(Delay_cc, cc_delay)
                        # println("Delay_cc: ", Delay_cc)   

                        # iteration increment
                        global iter = iter+1
                end
        finally
                println("z12: ", z12)
                println("Task Done")
                # println("iterations: ", Iteration)
                # println("TX_Time: ", TX_Time)
                # println("tx_times: ", tx_times)

                ####plotting things...
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
                png("Qdgcomp_bus4.png")
                #plotting things finsihed here.
                println("z12_hist", z12)

               # Open the log file in read mode
                open("Data/RPilogfile.txt", "r") do file
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
                    Iteration = Iteration,
                    TX_Time = TX_Time,
                    RX_Time = RX_Time,
                    Delay_process = Delay_proc,
                    Delay = Delay_k,
                    D_K = D_K,
                    Delay_cc = Delay_cc,
                    T_K = T_K,
                    Z12 = Z_12,
                    Primal_Residual = Primal_Resi,
                    LocalUpdate =  LocalUpdate,
                    GlobalUpdate = GlobalUpdate
                )
                sys_timestamp = Dates.format(Dates.now(), "u-dd-YYYY_H_M")
                path = "$(new_experiment_id)_RPi_Dist_($(num_RPi))_$(Thr)_$(iter)_$sys_timestamp.csv"

                filename = "Data/$path"
                CSV.write(filename, dataset)

                # Open the log file in append mode
                open("Data/RPilogfile.txt", "a") do file
                        time_logs_string = join(["[$(log.iteration),$(log.rpi_id),$(log.rx_time)]" for log in time_logs], ", ")

                        # Write the new experiment ID, date, and number of PMUs to the file in a new line
                        write(file, "ExpID = $(new_experiment_id), Date = $(sys_timestamp), NumRPI = $(num_RPi), timeLogs= [$time_logs_string]\n")
                end

                println("Data saved to ", filename)

                close(udpsock)
        end
end

udpsock = create_socket()
time2= time()
Initialization_time = time2-time1
println("Model Initialization Time (S): ", Initialization_time)
if !isnothing(udpsock)
    handle_clients(udpsock)
end