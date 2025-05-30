/*
 * Copyright 2007 University of Washington
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "udp-echo-server.h"

#include "ns3/address-utils.h"
#include "ns3/inet-socket-address.h"
#include "ns3/inet6-socket-address.h"
#include "ns3/internet-module.h"
#include "ns3/ipv4-address.h"
#include "ns3/ipv6-address.h"
#include "ns3/log.h"
#include "ns3/nstime.h"
#include "ns3/packet.h"
#include "ns3/simulator.h"
#include "ns3/socket-factory.h"
#include "ns3/socket.h"
#include "ns3/udp-socket.h"
#include "ns3/uinteger.h"

#include <filesystem>
#include <fstream>
#include <nlohmann/json.hpp>

namespace ns3
{

NS_LOG_COMPONENT_DEFINE("UdpEchoServerApplication");

NS_OBJECT_ENSURE_REGISTERED(UdpEchoServer);

static int counter = 0;       // number of areas responded between round
static int current_round = 1; // current round
static float THRESHOLD;       // threshold before resending data
static float rho;

static std::vector<std::pair<Address, std::string>> m_addressList; // Static list of address-string pairs

static std::vector<float> z12;
static std::vector<float> z13;
static std::vector<float> lambda_121;
static std::vector<float> lambda_131;
static std::vector<float> lambda_122;
static std::vector<float> lambda_133;

static nlohmann::json args;                 // flexible container for JSON data storing
static std::string JSON_file = "args.json"; // JSON file

struct Data
{
    std::vector<float> vector;        // vector received from client
    std::vector<float> initialVector; // first vector received
    float t;                          // value of t
    float obj;                        // value of obj
    std::string client;               // client name (x1, x2...)
    int nbr_response = 0;             // number of responses received in time
};

constexpr int total_of_node = 3;                   // number of clients
static std::array<Data, total_of_node> ClientData; // structure holding datas from each client

static void TimerExpired(Ptr<Socket> socket);
static void CalculateAndSendDataBackToAreas(float round, Ptr<Socket> socket);
static std::vector<float> parseFloatVector(const std::string& str);

static void
TimerExpired(Ptr<Socket> socket)
{
    if (counter != total_of_node)
    {
        std::cout << "Server:\t\tThreshold expired. Received " << counter
                  << " responses from clients, but expected " << total_of_node << std::endl;

        bool clients_responded_first_round = true;

        // Server received at least one response from a client,
        // start the calculation with data from previous round.
        if (counter > 0)
        {
            // if a client didn't even respond once,
            // we can't calculate anything
            for (auto& data : ClientData)
                if (data.nbr_response <= 1)
                {
                    clients_responded_first_round = false;
                    counter = 0; // set counter to 0 to resend data, as if Server didn't receive any response
                    break;
                }

            if (clients_responded_first_round)
            {
                std::cout << "Server:\t\tBeginning of the calculation using previous data if client didn't respond" << std::endl;
                CalculateAndSendDataBackToAreas(current_round, socket);
            }
        }

        // Server didn't receive any response, resending
        // data back to each client without starting calculation
        if (counter == 0)
        {
            if (clients_responded_first_round)
                std::cout << "Server:\t\tNo data received, resending data without calculation" << std::endl;
            else
            {
                std::cout << "Server:\t\tAt least one client didn't respond during the first round, resendending initial data without calculation" << std::endl;
                for (auto& data : ClientData)
                    data.vector = data.initialVector; // reset vector to initial value
            }
            
            current_round++;
            std::string variable = "";

            float cli_num = 0;                     // get the client num
            for (const auto& pair : m_addressList) // send the result to the clients
            {
                Address address = pair.first;
                variable = pair.second;

                int buffSize = 0;
                uint8_t* buffer_ = nullptr;

                for (auto& data : ClientData)
                {
                    if (data.client == variable)
                    {
                        data.vector[0] = (float)current_round; // update round

                        // Fill buffer_ to send it to the client
                        buffSize = data.vector.size() * sizeof(float);
                        buffer_ = new uint8_t[buffSize];
                        memcpy(buffer_, data.vector.data(), buffSize);
                    }
                }

                // Create an fill the packet sended to the client
                Ptr<Packet> responsePacket = Create<Packet>();
                responsePacket->AddAtEnd(Create<Packet>(buffer_, buffSize));
                socket->SendTo(responsePacket, 0, address);

                // print sended values
                std::cout << "Server:\t\tsent at " << variable << " -> ";
                for (size_t i = 0; i < buffSize / sizeof(float); ++i)
                {
                    float value;
                    std::memcpy(&value, buffer_ + i * sizeof(float), sizeof(float));
                    std::cout << value << " ";
                }
                std::cout << std::endl;

                if (buffer_ != nullptr)
                    delete[] buffer_;

                cli_num++;
            }
        }
        counter = 0;
        // Set the timer to expire after m_threshold seconds
        Simulator::Schedule(Seconds(THRESHOLD), &TimerExpired, socket);
        std::cout << "Server:\t\tset threshold to " << THRESHOLD << std::endl;

        NS_LOG_INFO("At time (after expiration) " << Simulator::Now().As(Time::S)
                                                  << " server sent packet to the clients");
    }
}

TypeId
UdpEchoServer::GetTypeId()
{
    static TypeId tid =
        TypeId("ns3::UdpEchoServer")
            .SetParent<Application>()
            .SetGroupName("Applications")
            .AddConstructor<UdpEchoServer>()
            .AddAttribute("Port",
                          "Port on which we listen for incoming packets.",
                          UintegerValue(9),
                          MakeUintegerAccessor(&UdpEchoServer::m_port),
                          MakeUintegerChecker<uint16_t>())
            .AddAttribute("Threshold",
                          "Threshold for the algorithm (server initiating new round)",
                          TimeValue(Seconds(10.0)),
                          MakeTimeAccessor(&UdpEchoServer::m_threshold),
                          MakeTimeChecker())
            .AddTraceSource("Rx",
                            "A packet has been received",
                            MakeTraceSourceAccessor(&UdpEchoServer::m_rxTrace),
                            "ns3::Packet::TracedCallback")
            .AddTraceSource("RxWithAddresses",
                            "A packet has been received",
                            MakeTraceSourceAccessor(&UdpEchoServer::m_rxTraceWithAddresses),
                            "ns3::Packet::TwoAddressTracedCallback");
    return tid;
}

UdpEchoServer::UdpEchoServer()
{
    NS_LOG_FUNCTION(this);
}

UdpEchoServer::~UdpEchoServer()
{
    NS_LOG_FUNCTION(this);
    m_socket = nullptr;
    m_socket6 = nullptr;
}

void
UdpEchoServer::DoDispose()
{
    NS_LOG_FUNCTION(this);
    Application::DoDispose();
}

void
UdpEchoServer::StartApplication()
{
    NS_LOG_FUNCTION(this);

    if (!m_socket)
    {
        TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
        m_socket = Socket::CreateSocket(GetNode(), tid);
        InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), m_port);
        if (m_socket->Bind(local) == -1)
        {
            NS_FATAL_ERROR("Failed to bind socket");
        }
        if (addressUtils::IsMulticast(m_local))
        {
            Ptr<UdpSocket> udpSocket = DynamicCast<UdpSocket>(m_socket);
            if (udpSocket)
            {
                // equivalent to setsockopt (MCAST_JOIN_GROUP)
                udpSocket->MulticastJoinGroup(0, m_local);
            }
            else
            {
                NS_FATAL_ERROR("Error: Failed to join multicast group");
            }
        }
    }

    if (!m_socket6)
    {
        TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
        m_socket6 = Socket::CreateSocket(GetNode(), tid);
        Inet6SocketAddress local6 = Inet6SocketAddress(Ipv6Address::GetAny(), m_port);
        if (m_socket6->Bind(local6) == -1)
        {
            NS_FATAL_ERROR("Failed to bind socket");
        }
        if (addressUtils::IsMulticast(local6))
        {
            Ptr<UdpSocket> udpSocket = DynamicCast<UdpSocket>(m_socket6);
            if (udpSocket)
            {
                // equivalent to setsockopt (MCAST_JOIN_GROUP)
                udpSocket->MulticastJoinGroup(0, local6);
            }
            else
            {
                NS_FATAL_ERROR("Error: Failed to join multicast group");
            }
        }
    }

    m_socket->SetRecvCallback(MakeCallback(&UdpEchoServer::HandleRead, this));
    m_socket6->SetRecvCallback(MakeCallback(&UdpEchoServer::HandleRead, this));
}

void
UdpEchoServer::StopApplication()
{
    NS_LOG_FUNCTION(this);

    if (m_socket)
    {
        m_socket->Close();
        m_socket->SetRecvCallback(MakeNullCallback<void, Ptr<Socket>>());
    }
    if (m_socket6)
    {
        m_socket6->Close();
        m_socket6->SetRecvCallback(MakeNullCallback<void, Ptr<Socket>>());
    }
}

static std::vector<float>
parseFloatVector(const std::string& str)
{
    std::vector<float> result;

    // Trim brackets from the input string
    std::string trimmed = str.substr(1, str.size() - 2); // remove [ and ]
    std::stringstream ss(trimmed);
    std::string item;

    // Parse the rest of the floats
    while (std::getline(ss, item, ','))
    {
        try
        {
            result.push_back(std::stof(item));
        }
        catch (const std::exception& e)
        {
            std::cerr << "Error converting '" << item << "' to float: " << e.what() << std::endl;
        }
    }

    return result;
}

void
UdpEchoServer::HandleRead(Ptr<Socket> socket)
{
    NS_LOG_FUNCTION(this << socket);
    Ptr<Packet> packet;
    Address from;
    Address localAddress;
    while ((packet = socket->RecvFrom(from)))
    {
        socket->GetSockName(localAddress);
        m_rxTrace(packet);
        m_rxTraceWithAddresses(packet, from, localAddress);
        if (InetSocketAddress::IsMatchingType(from))
        {
            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " server received "
                                   << packet->GetSize() << " bytes from "
                                   << InetSocketAddress::ConvertFrom(from).GetIpv4() << " port "
                                   << InetSocketAddress::ConvertFrom(from).GetPort());
        }
        else if (Inet6SocketAddress::IsMatchingType(from))
        {
            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " server received "
                                   << packet->GetSize() << " bytes from "
                                   << Inet6SocketAddress::ConvertFrom(from).GetIpv6() << " port "
                                   << Inet6SocketAddress::ConvertFrom(from).GetPort());
        }

        packet->RemoveAllPacketTags();
        packet->RemoveAllByteTags();

        // Get the ipv4 address of the sender
        InetSocketAddress iaddr = InetSocketAddress::ConvertFrom(from);
        Ipv4Address sender = iaddr.GetIpv4();

        std::string filename = "config/variable-conf.csv";
        std::string variable = "";

        std::ifstream file(filename);
        std::string line_, ip, area;
        std::map<Ipv4Address, std::string> addressToAreaMap;

        if (file.is_open())
        {
            while (std::getline(file, line_))
            {
                std::stringstream ss(line_);
                std::getline(ss, ip, ',');
                std::getline(ss, area, ',');

                Ipv4Address addr(ip.c_str());
                addressToAreaMap[addr] = area;
            }
            file.close();
        }
        else
        {
            std::cerr << "Unable to open file: " << filename << std::endl;
        }

        // Find the area associated with the current node's address
        auto it = addressToAreaMap.find(sender);
        if (it != addressToAreaMap.end())
            variable = it->second;
        else
            std::cerr << "Address not found in the file" << std::endl;

        //
        // Convert data from packet receive into vector of float
        // We dont check if the packet is empty
        //

        // Size of the data received
        uint32_t packetSize = packet->GetSize();

        // temporary buffer to store raw data from packet
        uint8_t* buffer_ = new uint8_t[packetSize];
        packet->CopyData(buffer_, packetSize);

        // vector of float received
        std::vector<float> receivedVector(packetSize / sizeof(float));
        memcpy(receivedVector.data(), buffer_, packetSize);

        delete[] buffer_;

        float round = receivedVector[0];      // round of the message received
        float client_num = receivedVector[1]; // client number

        if (round == current_round)
        { // Else the packet is from the previous round, ignore it

            ClientData[client_num].vector = receivedVector; // store the received vector
            ClientData[client_num].client = variable;       // store the client name
            ClientData[client_num].nbr_response++;          // increase the number of responses received

            // print data received
            std::cout << "Server:\t\treceive from client " << ClientData[client_num].client << ": ";
            for (std::size_t i = 0; i < ClientData[client_num].vector.size(); i++)
                std::cout << ClientData[client_num].vector[i] << " ";
            std::cout << "| round: " << round << std::endl;

            // Check if the address is already in the list
            // If not found, append the address and associated string to the static list
            if (std::find_if(m_addressList.begin(), m_addressList.end(), [&from](const std::pair<Address, std::string>& pair) { return pair.first == from; }) == m_addressList.end())
                m_addressList.emplace_back(from, variable);

            counter += 1;

            if (counter == total_of_node)
            { // If all packets have been received from all the areas
                NS_LOG_INFO("Current iteration: " << current_round);

                counter = 0;
                THRESHOLD = m_threshold.GetSeconds();

                // Calculate with received data and send them back result
                CalculateAndSendDataBackToAreas(round, socket);
            }
        }
    }
}

static void
CalculateAndSendDataBackToAreas(float round, Ptr<Socket> socket)
{
    /************************************** OPEN JSON FILE ***************************************/

    // Open the JSON file used to pass arguments to the Julia script
    std::ifstream in(JSON_file);
    if (in) // if file exist, extract data
        args = nlohmann::json::parse(in);

    else // if file doesn't exist, create it
    {
        std::cerr << "File " << JSON_file << " doesn't exist. Creating a default empty JSON file." << std::endl;
        args = nlohmann::json::object();
    }
    in.close();

    /************************************ SET INITIAL VALUES *************************************/

    // Set the initial values for each client if it was their first message
    for (auto& data : ClientData)
        if (data.nbr_response <= 1)
            data.initialVector = data.vector; // store initial vector

    /******************************* RESENDING DATA FOR FIRST ROUND ******************************/

    current_round += 1;
    std::string client_name;

    if (round == 1) // For the first round, just resend data
    {
        std::cout << "Server:\t\tRound 1, re-sending data to clients" << std::endl;

        for (const auto& pair : m_addressList)
        {
            Address address = pair.first; // client ip addr
            client_name = pair.second;    // client name

            int buffSize = 0;           // buffer_ size
            uint8_t* buffer_ = nullptr; // buffer_ to send

            std::vector<float> VecToSend; // data from client

            for (auto& data : ClientData)
            {
                if (data.client == client_name)
                {
                    buffSize = data.vector.size() * sizeof(float); // buffer_ needs to be
                    buffer_ = new uint8_t[buffSize];               // initialized by each client

                    VecToSend = data.vector;
                    VecToSend[0] = (float)current_round; // update round
                }
            }

            memcpy(buffer_, VecToSend.data(), buffSize);

            Ptr<Packet> responsePacket = Create<Packet>();
            responsePacket->AddAtEnd(Create<Packet>(buffer_, buffSize));
            socket->SendTo(responsePacket, 0, address);

            if (buffer_ != nullptr)
                delete[] buffer_;
        }

        // Define rho value
        rho = ClientData[0].vector.back();

        // Set data into JSON file to pass arguments to the Julia script
        z12.assign(ClientData[1].vector.end() - 24, ClientData[1].vector.end());                 //
        z13.assign(ClientData[2].vector.end() - 24, ClientData[2].vector.end());                 // Not a scalable method, but because
        lambda_121.assign(ClientData[0].vector.begin(), ClientData[0].vector.begin() + 24);      // each client doesn't expect the same
        lambda_131.assign(ClientData[0].vector.begin() + 24, ClientData[0].vector.begin() + 48); // data, it has to be done this way
        lambda_122.assign(ClientData[1].vector.begin(), ClientData[1].vector.begin() + 24);      //
        lambda_133.assign(ClientData[2].vector.begin(), ClientData[2].vector.begin() + 24);      //
    }

    /************************ CALCULATE & RESENDING DATA FOR OTHER ROUNDS ************************/

    else // For round > 1, execute Julia script with received data
    {
        for (auto& data : ClientData)
        {
            data.vector.erase(data.vector.begin(), data.vector.begin() + 2); // erase client num and round
            data.t = data.vector[0];                                         // store t value
            data.obj = data.vector[1];                                       // store obj value
            data.vector.erase(data.vector.begin(), data.vector.begin() + 2); // erase t and obj value

            for (size_t i = 0; i < data.vector.size(); i++)
                std::cout << data.vector[i] << " ";
            std::cout << " | t: " << data.t << " | obj: " << data.obj << std::endl;
        }

        // Store rho value and current round
        args["rho"] = rho;
        args["round"] = current_round;

        // Store data of each client
        for (auto& data : ClientData)
        {
            args[data.client] = {
                {"t_val", data.t},
                {"obj_val", data.obj},
                {"vect", data.vector}};
        }

        std::ofstream out(JSON_file); //
        out << args.dump(4);          // store data into JSON file
        out.close();                  //

        // Define the command to run the Julia script
        std::string juliaCommand = "julia config/Dist_rev.jl " + JSON_file + " > output_server.txt";

        // Run the Julia script
        std::cout << "Server:\t\tRunning Julia script... (" << juliaCommand << ")" << std::endl;
        if (std::system(juliaCommand.c_str()) != 0)
            std::cerr << "Server:\t\tError running Julia script!" << std::endl;
        else
            std::cout << "Server:\t\tJulia script finished successfully" << std::endl;

        // Optionally read the output from the file
        std::ifstream outputFile("output_server.txt");

        std::string line;
        std::string z12_Line;
        std::string z13_Line;
        std::string lambda_121_Line;
        std::string lambda_122_Line;
        std::string lambda_131_Line;
        std::string lambda_133_Line;

        // Loop through the file to get the last lines
        while (std::getline(outputFile, line))
        {
            z12_Line = z13_Line; // Shift the previous lines up
            z13_Line = lambda_121_Line;
            lambda_121_Line = lambda_122_Line;
            lambda_122_Line = lambda_131_Line;
            lambda_131_Line = lambda_133_Line;
            lambda_133_Line = line; // Update lambda_133_Line to the current line
        }
        outputFile.close();

        z12 = parseFloatVector(z12_Line);
        z13 = parseFloatVector(z13_Line);
        lambda_121 = parseFloatVector(lambda_121_Line);
        lambda_122 = parseFloatVector(lambda_122_Line);
        lambda_131 = parseFloatVector(lambda_131_Line);
        lambda_133 = parseFloatVector(lambda_133_Line);

        float cli_num = 0;                     // get the client num
        for (const auto& pair : m_addressList) // send the result to the clients
        {
            Address address = pair.first;
            client_name = pair.second;

            int buffSize = 0;
            uint8_t* buffer_ = nullptr;
            std::vector<float> VecToSend;

            // for each client, determine which vector has to be sended
            std::vector<std::vector<float>> VecToConcat;
            if (client_name == "x1")                              //
                VecToConcat = {lambda_121, lambda_131, z12, z13}; // Not a scalable method, but because
            else if (client_name == "x2")                         // each client doesn't expect the same
                VecToConcat = {lambda_122, z12};                  // data, it has to be done this way
            else if (client_name == "x3")                         //
                VecToConcat = {lambda_133, z13};                  //

            for (auto& data : ClientData)
            {
                if (data.client == client_name)
                {
                    // Concatenate all vectors
                    for (const auto& vec : VecToConcat)
                        VecToSend.insert(VecToSend.end(), vec.begin(), vec.end());

                    // add cli num, round and rho
                    VecToSend.insert(VecToSend.begin(), cli_num);
                    VecToSend.insert(VecToSend.begin(), static_cast<float>(current_round));
                    VecToSend.push_back(rho);

                    // fill the buffer
                    buffSize = VecToSend.size() * sizeof(float);
                    buffer_ = new uint8_t[buffSize];

                    // used if timer expire
                    data.vector = VecToSend;
                }
            }

            // Fill buffer_ to send it to the client
            memcpy(buffer_, VecToSend.data(), buffSize);

            // Create an fill the packet sended to the client
            Ptr<Packet> responsePacket = Create<Packet>();
            responsePacket->AddAtEnd(Create<Packet>(buffer_, buffSize));
            socket->SendTo(responsePacket, 0, address);

            // print sended values
            std::cout << "Server:\t\tsent at " << client_name << " -> ";
            for (size_t i = 0; i < VecToSend.size(); ++i)
            {
                float value;
                std::memcpy(&value, buffer_ + i * sizeof(float), sizeof(float));
                std::cout << value << " ";
            }
            std::cout << std::endl;

            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S)
                                   << " server sent " << responsePacket->GetSize()
                                   << " bytes to " << address
                                   << " port 9"); // Hardcoded port here

            if (buffer_ != nullptr)
                delete[] buffer_;

            cli_num++;
        }
    }

    /****************************** SET THRESHOLD & FILL JSON FILE *******************************/

    // Set threshold to resend data if client take too long
    Simulator::Schedule(Seconds(THRESHOLD), &TimerExpired, socket);
    std::cout << "Server:\t\tset threshold to " << THRESHOLD << std::endl;

    // Store vector sended to areas
    args["z12"] = z12;
    args["z13"] = z13;
    args["lambda_121"] = lambda_121;
    args["lambda_131"] = lambda_131;
    args["lambda_122"] = lambda_122;
    args["lambda_133"] = lambda_133;

    std::ofstream out(JSON_file); //
    out << args.dump(4);          // store data into JSON file
    out.close();                  //
}

} // Namespace ns3
