## Centralized solution
using Sockets, JuMP, Ipopt, Printf, Dates, Logging

# set the global logging level to error to suppress warnings
global_logger(ConsoleLogger(stderr, Logging.Error))

#include the network configuraiton file
include("Cent-revised.jl")

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

RPI_ID = 1 # Hardcoded identifier for client1/Area1, never changed

#function for the optimization work
function solve_area1(lambda=zeros(24), z=zeros(24), rho=0)
     area = "area_1"

     opf1 = Model(Ipopt.Optimizer)
     set_optimizer_attribute(opf1, "print_level", 0)
     #set_optimizer_attribute(opf1, "OutputFlag", 0)

     #Branch variables def
     @variable(opf1, Pbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])
     @variable(opf1, Qbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])

     #Bus variables def
     @variable(opf1, v[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
     @variable(opf1, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
     @variable(opf1, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
     @variable(opf1, Qdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])

     ## slackbus constraint
     @constraint(opf1, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                    Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )
     @constraint(opf1, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                    Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )


     #Power balance
     @constraint(opf1, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                    sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                    == Pload[j,phs] - PDGmax[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

     @constraint(opf1, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                    sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                    == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

     #Voltage drop
     @constraint(opf1, [(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                         v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                                  - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

     #DG constraint
     @constraint(opf1, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])

     #Voltage limits
     @constraint(opf1, [i=slack_bus, phs=BUS_PHS_SET[area][slack_bus]], v[i,phs] == 1.0*1.0)
     @constraint(opf1, [i in setdiff(BUS_SET_ex[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)
     #=
     x = [PDGmax[3,:a]-Pload[3,:a], Qdg[3,:a]-Qload[3,:a], v[3,:a], v[4,:a], Pbranch[(3,4),:a], Qbranch[(3,4),:a],PDGmax[4,:a]-Pload[4,:a], Qdg[4,:a]-Qload[4,:a],
          PDGmax[3,:b]-Pload[3,:b], Qdg[3,:b]-Qload[3,:b], v[3,:b], v[4,:b], Pbranch[(3,4),:b], Qbranch[(3,4),:b], PDGmax[4,:b]-Pload[4,:b], Qdg[4,:b]-Qload[4,:b],
          PDGmax[3,:c]-Pload[3,:c], Qdg[3,:c]-Qload[3,:c], v[3,:c], v[4,:c], Pbranch[(3,4),:c], Qbranch[(3,4),:c], PDGmax[4,:c]-Pload[4,:c], Qdg[4,:c]-Qload[4,:c]]
     =#
          x = [PDGmax[3,:a]-Pload[3,:a], Qdg[3,:a], v[3,:a], v[4,:a], Pbranch[(3,4),:a], Qbranch[(3,4),:a],PDGmax[4,:a]-Pload[4,:a], Qdg[4,:a],
               PDGmax[3,:b]-Pload[3,:b], Qdg[3,:b], v[3,:b], v[4,:b], Pbranch[(3,4),:b], Qbranch[(3,4),:b], PDGmax[4,:b]-Pload[4,:b], Qdg[4,:b],
               PDGmax[3,:c]-Pload[3,:c], Qdg[3,:c], v[3,:c], v[4,:c], Pbranch[(3,4),:c], Qbranch[(3,4),:c], PDGmax[4,:c]-Pload[4,:c], Qdg[4,:c] ]

     @expression(opf1, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))

     # Voltage Deviation w/ absolute value
     Vpos = 1.0
     @variable(opf1, aux[i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ] >= 0)
     @constraint(opf1, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
     @constraint(opf1, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
     @expression(opf1, Total_vdev, sum(aux[i, phs] for i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i]) )

     @objective(opf1, Min, Total_vdev
                         + lambda'*(x-z)
                         + rho/2*(x-z)'*(x-z))

     optimize!(opf1)
     #=
     return[ value(PDGmax[3,:a])-Pload[3,:a], value(Qdg[3,:a])-Qload[3,:a], value(v[3,:a]), value(v[4,:a]), value(Pbranch[(3,4),:a]), value(Qbranch[(3,4),:a]),value(PDGmax[4,:a])-Pload[4,:a], value(Qdg[4,:a])-Qload[4,:a],
          value(PDGmax[3,:b])-Pload[3,:b], value(Qdg[3,:b])-Qload[3,:b], value(v[3,:b]), value(v[4,:b]), value(Pbranch[(3,4),:b]), value(Qbranch[(3,4),:b]),value(PDGmax[4,:b])-Pload[4,:b], value(Qdg[4,:b])-Qload[4,:b],
          value(PDGmax[3,:c])-Pload[3,:c], value(Qdg[3,:c])-Qload[3,:c], value(v[3,:c]), value(v[4,:c]), value(Pbranch[(3,4),:c]), value(Qbranch[(3,4),:c]), value(PDGmax[4,:c])-Pload[4,:c], value(Qdg[4,:c])-Qload[4,:c] ], value.(v), opf1
     =#

     return[ value(PDGmax[3,:a])-Pload[3,:a], value(Qdg[3,:a]), value(v[3,:a]), value(v[4,:a]), value(Pbranch[(3,4),:a]), value(Qbranch[(3,4),:a]),value(PDGmax[4,:a])-Pload[4,:a], value(Qdg[4,:a]),
          value(PDGmax[3,:b])-Pload[3,:b], value(Qdg[3,:b]), value(v[3,:b]), value(v[4,:b]), value(Pbranch[(3,4),:b]), value(Qbranch[(3,4),:b]),value(PDGmax[4,:b])-Pload[4,:b], value(Qdg[4,:b]),
          value(PDGmax[3,:c])-Pload[3,:c], value(Qdg[3,:c]), value(v[3,:c]), value(v[4,:c]), value(Pbranch[(3,4),:c]), value(Qbranch[(3,4),:c]), value(PDGmax[4,:c])-Pload[4,:c], value(Qdg[4,:c]) ], value.(v), opf1
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
             sender, data = recvfrom(udpsock)
             #println("RX data: $data")
             time1 = time() 
             initial_msg = String(data)
             # println("String data: $initial_msg")

             # Parse the message into packet_num, lambda, rho, and y
             packet_num = initial_msg[1:4]
             z12_message_segment = initial_msg[5:244]
             rho_message_segment = initial_msg[245:254]    # Next 8 characters for rho
             lambda_message_segment = initial_msg[255:494]     # Last 8 characters for y

             # Convert the parsed strings to Float64
             z12 = parse_formatted_vector(z12_message_segment, 24, 10)
             # println("z12 vector: ", z12)
             rho = parse(Float64, rho_message_segment)
             # println("rho: ", rho) 
             lambda121 = parse_formatted_vector(lambda_message_segment, 24, 10)
             # println("lambda: ", lambda121)
             # Solve for x1 using the received lambda121, rho, z12
             x1, _, _ = solve_area1(lambda121, z12, rho)

             # println("Calculated x1: $x1")
             formatted_x1 = format_and_zero_pad_vector(x1, 10)
             #println("formatted_x1: ", formatted_x1)

             time2 = time()
             delay_proc = time2-time1
             println("delay_proc:",delay_proc)
 
             # Send x1 back to server
             data_message = zero_pad(packet_num, 4) * "X" * zero_pad(RPI_ID, 2) * format_and_zero_pad_vector(x1, 10) * format_and_zero_pad(delay_proc, 10)
             send(udpsock, server_ip, Server_PORT, Vector{UInt8}(data_message))
             println("Data Sent")
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