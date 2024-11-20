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
#include "ns3/internet-module.h"
#include "ns3/inet-socket-address.h"
#include "ns3/inet6-socket-address.h"
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
static float x = 0.0;
static float y = 0.0;
static float rho = 1.0;
static float lambda = 1.0;
static float THRESHOLD = 10.0;
static std::vector<std::pair<Address, std::string>> m_addressList;  // Static list of address-string pairs
static int STOP = 0;

static void TimerExpired(Ptr<Socket> socket) {
    if ((counter != 2) && (STOP == 0)) {
        std::cout << "Threshold expired " << counter << std::endl;
        current_round += 1;
        counter = 0;

        std::string filename = "config/variable-conf.csv";
        std::string variable = "";
        Ptr<Packet> responsePacket = Create<Packet>();
        
        for (const auto &pair : m_addressList)
                {
                    Address address = pair.first;
                    variable = pair.second;

                    if (variable == "x") {
                        uint8_t buffer_[16];
                        memcpy(buffer_, &x, sizeof(float));
                        memcpy(buffer_ + sizeof(float), &rho, sizeof(float));
                        memcpy(buffer_ + 2 * sizeof(float), &lambda, sizeof(float));
                        memcpy(buffer_ + 3 * sizeof(float), &current_round, sizeof(uint32_t));

                        responsePacket->AddAtEnd(Create<Packet>(buffer_, sizeof(buffer_)));

                        //Ptr<Packet> responsePacket = Create<Packet> ((uint8_t *)msg.c_str(), msg.size());
                        socket->SendTo (responsePacket, 0, address);
                    }
                    else if (variable == "y") {
                        uint8_t buffer_[16];
                        memcpy(buffer_, &y, sizeof(float));
                        memcpy(buffer_ + sizeof(float), &rho, sizeof(float));
                        memcpy(buffer_ + 2 * sizeof(float), &lambda, sizeof(float));
                        memcpy(buffer_ + 3 * sizeof(float), &current_round, sizeof(uint32_t));

                        Ptr<Packet> responsePacket = Create<Packet>();
                        responsePacket->AddAtEnd(Create<Packet>(buffer_, sizeof(buffer_)));

                        //Ptr<Packet> responsePacket = Create<Packet> ((uint8_t *)msg.c_str(), msg.size());
                        socket->SendTo (responsePacket, 0, address);
                    }
                }
                // Set the timer to expire after 5 seconds
                Simulator::Schedule(Seconds(THRESHOLD), &TimerExpired, socket);

        NS_LOG_INFO("At time (after expiration) " << Simulator::Now().As(Time::S) << " server sent packet to the clients");
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

        if (file.is_open()) {
            while (std::getline(file, line_)) {
                std::stringstream ss(line_);
                std::getline(ss, ip, ',');
                std::getline(ss, area, ',');

                Ipv4Address addr(ip.c_str());
                addressToAreaMap[addr] = area;
            }
            file.close();
        } else {
            std::cerr << "Unable to open file: " << filename << std::endl;
        }

        // Find the area associated with the current node's address
        auto it = addressToAreaMap.find(sender);
        if (it != addressToAreaMap.end()) {
            variable = it->second;
        } else {
            std::cerr << "Address not found in the file" << std::endl;
        }

        uint8_t buffer_[16];
        packet->CopyData(buffer_, sizeof(buffer_));
        float x; float y; uint32_t round = 0;

        // Check if the address is already in the list
        if (std::find_if(m_addressList.begin(), m_addressList.end(),
                        [&from](const std::pair<Address, std::string>& pair) {
                            return pair.first == from;
                        }) == m_addressList.end())
        {
            // If not found, append the address and associated string to the static list
            m_addressList.emplace_back(from, variable);
        }

        //std::cout << variable << std::endl;

        if (variable == "x") {
            memcpy(&x, buffer_, sizeof(float));
            memcpy(&round, buffer_ + sizeof(float), sizeof(uint32_t));
            std::cout << "Server: Received x round: " << x << " " << round << std::endl;
            counter += 1;
        }
        else if (variable == "y") {
            memcpy(&y, buffer_, sizeof(float));
            memcpy(&round, buffer_ + sizeof(float), sizeof(uint32_t));
            std::cout << "Server: Received y round: " << y << " " << round << std::endl;
            counter += 1;
        }
        //std::cout << "round: " << round << " current round: " << current_round << std::endl;
        if (round == current_round) { // Else the packet is from the previous round, ignore it
            //NS_LOG_INFO("counter: " << counter);

            if (counter == 2) { // If all packets have been received from all the areas
                NS_LOG_INFO("Current iteration: " << current_round);
                current_round += 1;
                counter = 0;
                Ptr<Packet> responsePacket = Create<Packet>();
                //packet->AddHeader(SeqTsHeader()); // Ensure there is a header for timestamp

                std::cout << "Sent variables to the script are: " << x << " " << y << " " << lambda << std::endl;

                // Define the command to run the Julia script
                std::string juliaCommand = "julia config/Server.jl " + std::to_string(x) + " " + std::to_string(y) + " " + std::to_string(lambda) + " " + std::to_string(rho) +  " > output_server.txt";

                // Run the Julia script
                float result = std::system(juliaCommand.c_str());
                if (result != 0) {
                    std::cerr << "Error running Julia script!" << std::endl;
                    //return 1;
                }

                // Optionally read the output from the file
                std::ifstream outputFile("output_server.txt");
                std::string line, line1, line2, line3, line4;

                // Loop through the file to get the last four lines
                while (std::getline(outputFile, line)) {
                    line1 = line2;  // Shift the previous lines up
                    line2 = line3;
                    line3 = line4;
                    line4 = line;   // Update line4 to the current line
                }

                outputFile.close();

                // Convert the last four lines to the required variables
                try {
                    x = std::stof(line1);
                    y = std::stof(line2);
                    lambda = std::stof(line3);
                    rho = std::stof(line4);

                    // Output the values to verify
                    std::cout << "x: " << x << std::endl;
                    std::cout << "y: " << y << std::endl;
                    std::cout << "lambda: " << lambda << std::endl;
                    std::cout << "rho: " << rho << std::endl;

                    for (const auto &pair : m_addressList)
                    {
                        Address address = pair.first;
                        variable = pair.second;

                        if (variable == "x") {
                            uint8_t buffer_[16];
                            memcpy(buffer_, &x, sizeof(float));
                            memcpy(buffer_ + sizeof(float), &lambda, sizeof(float));
                            memcpy(buffer_ + 2 * sizeof(float), &rho, sizeof(float));
                            memcpy(buffer_ + 3 * sizeof(float), &current_round, sizeof(uint32_t));

                            responsePacket->AddAtEnd(Create<Packet>(buffer_, sizeof(buffer_)));

                            //Ptr<Packet> responsePacket = Create<Packet> ((uint8_t *)msg.c_str(), msg.size());
                            socket->SendTo (responsePacket, 0, address);

                            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " server sent "
                                                << packet->GetSize() << " bytes to " << address << " port 9"); // Hardcoded port here

                        }
                        else if (variable == "y") {
                            uint8_t buffer_[16];
                            memcpy(buffer_, &y, sizeof(float));
                            memcpy(buffer_ + sizeof(float), &lambda, sizeof(float));
                            memcpy(buffer_ + 2 * sizeof(float), &rho, sizeof(float));
                            memcpy(buffer_ + 3 * sizeof(float), &current_round, sizeof(uint32_t));

                            Ptr<Packet> responsePacket = Create<Packet>();
                            responsePacket->AddAtEnd(Create<Packet>(buffer_, sizeof(buffer_)));

                            //Ptr<Packet> responsePacket = Create<Packet> ((uint8_t *)msg.c_str(), msg.size());
                            socket->SendTo (responsePacket, 0, address);

                            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " server sent "
                                                << packet->GetSize() << " bytes to " << address << " port 9");

                        }
                    }
                    THRESHOLD = m_threshold.GetSeconds();

                    // Set the timer to expire after 5 seconds
                    Simulator::Schedule(Seconds(THRESHOLD), &TimerExpired, socket);
                    //std::cout << "here setting timer" << std::endl;
                } catch (const std::invalid_argument& e) {
                    STOP = 1;
                    std::cout << line4 << std::endl;
                }
                
            }
        }
    }
}

} // Namespace ns3
