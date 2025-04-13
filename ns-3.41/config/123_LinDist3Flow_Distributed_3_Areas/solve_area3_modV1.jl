## We are using this version to collect data
using Sockets, JuMP, Ipopt, Gurobi, Printf, Dates, Logging

#create Gurobi environment
env = Gurobi.Env()

# Set the global logging level to Eorror to Suppress Warnings
global_logger(ConsoleLogger(stderr, Logging.Error))

#include the network configuraiton file
include("Cent-revised.jl")

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
     for i in 0:(num_elements - 1)
         start_index = i * element_width + 1  # Calculate the starting index of each element
         end_index = start_index + element_width - 1  # Calculate the ending index
         substring = message[start_index:end_index]  # Extract the substring for the element
         number = parse(Float64, substring)  # Convert the substring to a Float64
         push!(retrieved_vector, number)  # Append the number to the array
     end
     return retrieved_vector
end
 
RPI_ID = 3 # Hardcoded identifier for client3/Area3, never changed

#function for the optimization work
function solve_area3(lambda=zeros(24), z=zeros(24), rho=0)
area = "area_3"

#opf3 = Model(Gurobi.Optimizer)
#set_optimizer_attribute(opf3, "print_level", 0)
#set_optimizer_attribute(opf3, "OutputFlag", 0)

# Initialize the model with specific environment
opf3 = Model(() -> Gurobi.Optimizer(env))
set_optimizer_attribute(opf3, "OutputFlag", 0) #supress Gurobi output

#Branch variables def
@variable(opf3, Pbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf3, Qbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf3, v[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
#@variable(opf3, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
#@variable(opf3, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf3, Qdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
@variable(opf3, Pdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])

## slackbus constraint
#@constraint(opf3, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
#                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )
#@constraint(opf3, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
#                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )


#Power balance
@constraint(opf3, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Pload[j,phs] - Pdg[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

@constraint(opf3, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))



#Voltage drop
@constraint(opf3, [(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

#PV modelling as a linear constraint
 k = 16
 phi=180/k
 @constraint(opf3, [l=1:k, i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]], -SDGmax[i,phs] <=   cosd(l*phi)*Pdg[i,phs] + sind(l*phi)*Qdg[i,phs]  <= SDGmax[i,phs] )

 #DG constraint
@constraint(opf3, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], 0 <= Pdg[i,phs] <= PDGmax[i,phs]  )

@constraint(opf3, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])


#Voltage limits
@constraint(opf3, [i in setdiff(BUS_SET_ex[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)

x = [ Pdg[31,:a]-Pload[31,:a], Qdg[31,:a]-Qload[31,:a], v[31,:a], v[94,:a], Pbranch[(31,94),:a], Qbranch[(31,94),:a], Pdg[94,:a]-Pload[94,:a], Qdg[94,:a]-Qload[94,:a],
     Pdg[31,:b]-Pload[31,:b], Qdg[31,:b]-Qload[31,:b], v[31,:b], v[94,:b], Pbranch[(31,94),:b], Qbranch[(31,94),:b], Pdg[94,:b]-Pload[94,:b], Qdg[94,:b]-Qload[94,:b],
     Pdg[31,:c]-Pload[31,:c], Qdg[31,:c]-Qload[31,:c], v[31,:c], v[94,:c], Pbranch[(31,94),:c], Qbranch[(31,94),:c], Pdg[94,:c]-Pload[94,:c], Qdg[94,:c]-Qload[94,:c] ]

@expression(opf3, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf3, aux[i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf3, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf3, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf3, Total_vdev, sum(aux[i, phs] for i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i]) )

@expression(opf3, Pdgtot, sum(Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )
@expression(opf3, Qdgtot, sum(Qdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )

@expression(opf3, PVHC, sum(PDGmax[i,phs]-Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]))

@objective(opf3, Min, Total_vdev
                        + lambda'*(x-z)
                        + rho/2*(x-z)'*(x-z))

solvetime = @elapsed optimize!(opf3)

return[value(Pdg[31,:a])-Pload[31,:a], value(Qdg[31,:a])-Qload[31,:a], value(v[31,:a]), value(v[94,:a]), value(Pbranch[(31,94),:a]), value(Qbranch[(31,94),:a]),value(Pdg[94,:a])-Pload[94,:a], value(Qdg[94,:a])-Qload[94,:a],
        value(Pdg[31,:b])-Pload[31,:b], value(Qdg[31,:b])-Qload[31,:b], value(v[31,:b]), value(v[94,:b]), value(Pbranch[(31,94),:b]), value(Qbranch[(31,94),:b]),value(Pdg[94,:b])-Pload[94,:b], value(Qdg[94,:b])-Qload[94,:b],
        value(Pdg[31,:c])-Pload[31,:c], value(Qdg[31,:c])-Qload[31,:c], value(v[31,:c]), value(v[94,:c]), value(Pbranch[(31,94),:c]), value(Qbranch[(31,94),:c]), value(Pdg[94,:c])-Pload[94,:c], value(Qdg[94,:c])-Qload[94,:c] ],
        value.(v),solvetime, opf3, JuMP.objective_value(opf3),  value(Pload[31,:a] - Pdg[31,:a]), value.(Pdg), value.(Qdg)

end


#UDP Client function
function udp_client()
    Server_URL = "wn4ss-iot.eng.buffalo.edu"
    Server_PORT = 21001
    server_ip = getaddrinfo(Server_URL, IPv4)
    udpsock = UDPSocket()

    try
        # Send initial "Hello" message to server
        message = "Hello"
        initial_message = zero_pad(RPI_ID, 2) * message
        message_bytes = Vector{UInt8}(initial_message)
        send(udpsock, server_ip, Server_PORT, message_bytes)
        println("Initial message, $message sent to $Server_URL")

        while true
            # Wait for data message from the server
            t1= time()
            # println("time before data: ", t1)
            sender, data = recvfrom(udpsock)
            # data arrival time
            time1 = time()
            formatted_t1= @sprintf("%.3f", time1)

            # println("time1: ", time1)
            # println("time before data: ", formatted_t1)

            initial_msg = String(data)
            #println("String data: $initial_msg")
            
            # Parse the message into packet_num, lambda, rho, and y
            packet_type = initial_msg[1:1]
            # println("packet_type", packet_type)

            if packet_type == "D"
              packet_num = initial_msg[2:5]
              println("Dummy Packet No: ", packet_num)
              rho_message_segment = initial_msg[6:15]    # Next 10 characters for rho
              z13_message_segment = initial_msg[16:255]
              lambda_message_segment = initial_msg[256:495]     # Last 8 characters for y
            else
              # Parse the message into packet_num, lambda, rho, and y
              packet_num = initial_msg[1:4]
              println("Packet No: ", packet_num)
              rho_message_segment = initial_msg[5:14]    # Next 10 characters for rho
              z13_message_segment = initial_msg[15:254]
              lambda_message_segment = initial_msg[255:494]     # Last 8 characters for y
            end

            # Convert the parsed strings to Float64   
            z13 = parse_formatted_vector(z13_message_segment, 24, 10)
            # println("z13 vector: ", z13)
            rho = parse(Float64, rho_message_segment)
            # println("rho: ", rho) 
            lambda133 = parse_formatted_vector(lambda_message_segment, 24, 10)
            # println("lambda: ", lambda133)
            t2= time()
            # println("time before opt: ", t2)
            #add sleep time
            #sleep(0.08)

            # Solve for x2 using the received lambda, rho, z
            x3, _, _ = solve_area3(lambda133, z13, rho)
            t3= time()
            # println("time after opt: ", t3)

            #println("Calculated x3: $x3")
            formatted_x3 = format_and_zero_pad_vector(x3, 10)
            #println("formatted_x3: ", formatted_x3)

            time2 = time()
            # println("time2: ", time2)
            delay_proc = time2-time1
            delay_BFD = time1-t1
            formatted_time2= @sprintf("%.3f", time2)

            #println("delay before data:", delay_BFD)
            #println("delay_opt:", t3-t2) 
            #println("delay_proc:", delay_proc)

            # Send x3 back to server
            data_message = zero_pad(packet_num, 4) * "Z" * zero_pad(RPI_ID, 2) * format_and_zero_pad_vector(x3, 10) * adjust_number(delay_proc, 10) * formatted_t1 * formatted_time2
            send(udpsock, server_ip, Server_PORT, Vector{UInt8}(data_message))
            println("Data Sent")

            time3 = time()
            #println("delay after tx: ", time3-time2)
            println("\n")

        end
    catch e
        println("An error occurred: $e")
    finally
        close(udpsock)
        println("Client socket closed.")
    end
end

# Run the UDP client function
udp_client()