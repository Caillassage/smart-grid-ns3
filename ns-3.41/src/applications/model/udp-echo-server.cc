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

#include <fstream>

namespace ns3
{

NS_LOG_COMPONENT_DEFINE("UdpEchoServerApplication");

NS_OBJECT_ENSURE_REGISTERED(UdpEchoServer);

static int counter = 0;
static int current_round = 1;
static float z12 = 1.0;
static float rho = 1.0;
static float THRESHOLD = 1.0;
static std::vector<std::pair<Address, std::string>>
    m_addressList; // Static list of address-string pairs
static int STOP = 0;
static double lambda_121 = 0;
static double lambda_122 = 0;

// History containers
static std::vector<double> x_121_hist;
static std::vector<double> x_122_hist;
static std::vector<double> lambda_121_hist;
static std::vector<double> lambda_122_hist;
static std::vector<double> z12_hist;
static std::vector<std::vector<double>> primal_residual_hist;
static std::vector<std::vector<double>> dual_residual_hist;

constexpr int total_of_node = 3;

struct Data
{
    std::vector<float> values;
    std::string client;
    int vectorSize;
    float x;
};

static std::array<Data, total_of_node> ClientData;

static void
TimerExpired(Ptr<Socket> socket, std::array<Data, total_of_node>& ClientData)
{
    if ((counter != total_of_node) && (STOP == 0))
    {
        std::cout << "Server:\t\tThreshold expired" << std::endl;

        current_round += 1;
        counter = 0;
        std::string variable = "";

        for (const auto& pair : m_addressList)
        {
            Address address = pair.first;
            variable = pair.second;

            int dataSize;
            int buffSize = 0;
            uint8_t* buffer_ = nullptr;
            std::vector<float> VecToSend;

            for (auto& data : ClientData)
            {
                if (data.client == variable)
                {
                    dataSize = data.vectorSize;
                    buffSize = (dataSize + 2) * sizeof(float);
                    buffer_ = new uint8_t[buffSize];

                    VecToSend = data.values;
                    VecToSend[0] = (float)current_round;
                    VecToSend[2] = data.x;
                }
            }

            memcpy(buffer_, VecToSend.data(), dataSize * sizeof(float));
            memcpy(buffer_ + dataSize * sizeof(float), &rho, sizeof(float));
            memcpy(buffer_ + (dataSize + 1) * sizeof(float), &z12, sizeof(float));

            Ptr<Packet> responsePacket = Create<Packet>();
            responsePacket->AddAtEnd(Create<Packet>(buffer_, buffSize));

            std::cout << "Server:\t\tsent at " << variable << ": ";
            float* floatPtr = reinterpret_cast<float*>(buffer_);
            for (int i = 0; i < dataSize + 2; i++)
            {
                std::cout << floatPtr[i] << " ";
            }
            std::cout << std::endl;

            socket->SendTo(responsePacket, 0, address);

            if (buffer_ != nullptr)
                delete[] buffer_;
        }
        // Set the timer to expire after 5 seconds
        Simulator::Schedule(Seconds(THRESHOLD), &TimerExpired, socket, ClientData);

        NS_LOG_INFO("At time (after expiration) " << Simulator::Now().As(Time::S)
                                                  << " server sent packet to the clients");

        exit(1);
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
        {
            variable = it->second;
        }
        else
        {
            std::cerr << "Address not found in the file" << std::endl;
        }

        //
        // Convert data from packet receive into vector of float
        // We dont check if the packet is empty
        //
        uint32_t packetSize = packet->GetSize();

        // temporary buffer to store raw data from packet
        uint8_t* buffer_ = new uint8_t[packetSize];
        packet->CopyData(buffer_, packetSize);

        // vector of float received
        std::vector<float> receivedVector(packetSize / sizeof(float));
        memcpy(receivedVector.data(), buffer_, packetSize);

        delete[] buffer_;

        float round = receivedVector[0];
        float client_num = receivedVector[1];

        ClientData[client_num].values = receivedVector;
        ClientData[client_num].vectorSize = receivedVector.size();

        // Check if the address is already in the list
        if (std::find_if(m_addressList.begin(),
                         m_addressList.end(),
                         [&from](const std::pair<Address, std::string>& pair) {
                             return pair.first == from;
                         }) == m_addressList.end())
        {
            // If not found, append the address and associated string to the static list
            m_addressList.emplace_back(from, variable);
        }

        memcpy(&ClientData[client_num].x, ClientData[client_num].values.data() + 2, sizeof(float));
        ClientData[client_num].client = variable;
        counter += 1;

        std::cout << "Server:\t\treceive from client " << ClientData[client_num].client << ": ";
        for (std::size_t i = 0; i < ClientData[client_num].values.size(); i++)
        {
            std::cout << ClientData[client_num].values[i] << " ";
        }
        std::cout << "| x1: " << ClientData[client_num].x << std::endl;

        if (round ==  1)
        {
            std::vector<float> lambda_121(24, 1);
            std::vector<float> lambda_122(24, 1);

            std::vector<float> lambda_131(24, 1);
            std::vector<float> lambda_133(24, 1);
            
            std::vector<float> z12(24, 1);
            std::vector<float> z13(24, 1);

            float rho = 50.0;

            // client 1
            std::vector<float> to_client_1;
            to_client_1.insert(to_client_1.end(), lambda_121.begin(), lambda_121.end());
            to_client_1.insert(to_client_1.end(), lambda_131.begin(), lambda_131.end());
            to_client_1.insert(to_client_1.end(), z12.begin(), z12.end());
            to_client_1.insert(to_client_1.end(), z13.begin(), z13.end());
            to_client_1.push_back(rho);


            // client 2
            std::vector<float> to_client_2;
            to_client_2.insert(to_client_2.end(), lambda_122.begin(),lambda_122.end());
            to_client_2.insert(to_client_2.end(), z12.begin(),z12.end());
            to_client_2.push_back(rho);

            // client 3
            std::vector<float> to_client_3;
            to_client_3.insert(to_client_3.end(), lambda_133.begin(),lambda_133.end());
            to_client_3.insert(to_client_3.end(), z13.begin(),z13.end());
            to_client_3.push_back(rho);

        }

        else if (round == current_round)
        { // Else the packet is from the previous round, ignore it
            // NS_LOG_INFO("counter: " << counter);

            if (counter == total_of_node)
            { // If all packets have been received from all the areas
                NS_LOG_INFO("Current iteration: " << current_round);
                current_round += 1;
                counter = 0;
                // packet->AddHeader(SeqTsHeader()); // Ensure there is a header for timestamp

                // Define the command to run the Julia script
                // std::string juliaCommand = "julia config/Server.jl ";
                std::string juliaCommand = "julia config/BasicServerScript.jl ";

                for (auto& data : ClientData)
                {
                    juliaCommand += std::to_string(data.x) + " ";
                }
                juliaCommand +=
                    std::to_string(rho) + " " + std::to_string(z12) + " > output_server.txt";

                std::cout << "Server:\t\trunning Julia script... (" << juliaCommand << ")"
                          << std::endl;

                // Run the Julia script
                float result = std::system(juliaCommand.c_str());
                if (result != 0)
                {
                    std::cerr << "Error running Julia script!" << std::endl;
                    // return 1;
                }

                // Updating the lists
                // Add border solutions
                x_121_hist.push_back(ClientData[0].x); // Not optimal and scalable
                x_122_hist.push_back(ClientData[1].x); //

                // Add dual variables
                lambda_121_hist.push_back(lambda_121);
                lambda_122_hist.push_back(lambda_122);

                // Add consensus variable
                z12_hist.push_back(z12);

                // Optionally read the output from the file
                std::ifstream outputFile("output_server.txt");
                std::string line, line1, line2, line3, line4;

                // Loop through the file to get the last four lines
                while (std::getline(outputFile, line))
                {
                    line1 = line2; // Shift the previous lines up
                    line2 = line3;
                    line3 = line4;
                    line4 = line; // Update line4 to the current line
                }

                outputFile.close();

                // Convert the last four lines to the required variables
                try
                {
                    ClientData[0].x = std::stof(line1); // MODIFY THESE LINES WITH
                    ClientData[1].x = std::stof(line2); // THE PROPER JULIA SCRIPT
                    rho = std::stof(line3);
                    z12 = std::stof(line4);

                    // Output the values to verify
                    // std::cout << "x1: " << x1 << std::endl;
                    // std::cout << "x2: " << x2 << std::endl;
                    // std::cout << "rho: " << rho << std::endl;
                    // std::cout << "z12: " << z12 << std::endl;

                    for (const auto& pair : m_addressList) // send the result to the clients
                    {
                        Address address = pair.first;
                        variable = pair.second;

                        int buffSize = 0;
                        int vectorSize;
                        uint8_t* buffer_ = nullptr;
                        std::vector<float> VecToSend;

                        for (auto& data : ClientData)
                        {
                            if (data.client == variable)
                            {
                                vectorSize = data.vectorSize;
                                buffSize = (vectorSize + 2) * sizeof(float);
                                buffer_ = new uint8_t[buffSize];

                                VecToSend = data.values;
                                VecToSend[0] = (float)current_round;
                                VecToSend[2] = data.x;
                            }
                        }

                        memcpy(buffer_, VecToSend.data(), vectorSize * sizeof(float));
                        memcpy(buffer_ + vectorSize * sizeof(float), &rho, sizeof(float));
                        memcpy(buffer_ + (vectorSize + 1) * sizeof(float), &z12, sizeof(float));

                        Ptr<Packet> responsePacket = Create<Packet>();
                        responsePacket->AddAtEnd(Create<Packet>(buffer_, buffSize));
                        socket->SendTo(responsePacket, 0, address);

                        std::cout << "Server:\t\tsent at " << variable << " -> ";
                        float* floatPtr = reinterpret_cast<float*>(buffer_);
                        for (int i = 0; i < vectorSize + 2; i++)
                        {
                            std::cout << floatPtr[i] << " ";
                        }
                        std::cout << std::endl;

                        NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " server sent "
                                               << packet->GetSize() << " bytes to " << address
                                               << " port 9"); // Hardcoded port here

                        if (buffer_ != nullptr)
                            delete[] buffer_;
                    }
                    THRESHOLD = m_threshold.GetSeconds();

                    Simulator::Schedule(Seconds(THRESHOLD), &TimerExpired, socket, ClientData);

                    std::cout << "Server:\t\tset threshold to " << THRESHOLD << std::endl;
                }
                catch (const std::invalid_argument& e)
                {
                    STOP = 1;
                    std::cout << line4 << std::endl;
                }
            }
        }
    }
}

} // Namespace ns3
