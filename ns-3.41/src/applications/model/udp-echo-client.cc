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
#include "udp-echo-client.h"

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
#include "ns3/trace-source-accessor.h"
#include "ns3/uinteger.h"

#include <chrono>
#include <fstream>
#include <thread>
#include <unistd.h>

namespace ns3
{

NS_LOG_COMPONENT_DEFINE("UdpEchoClientApplication");

NS_OBJECT_ENSURE_REGISTERED(UdpEchoClient);

static void
sendPacket(Ptr<Packet> responsePacket,
           Address from,
           std::vector<float> result,
           std::string script,
           Ptr<Socket> socket)
{
    std::cout << "Client:\t\tSending to server: ";
    for (size_t i = 0; i < result.size(); ++i)
    {
        std::cout << result[i] << " ";
    }
    std::cout << std::endl;

    int buffSize = result.size() * sizeof(float);
    uint8_t* buffer_ = new uint8_t[buffSize];

    memcpy(buffer_, result.data(), buffSize);

    responsePacket->AddAtEnd(Create<Packet>(buffer_, buffSize));
    socket->SendTo(responsePacket, 0, from);

    NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " client sent "
                           << responsePacket->GetSize() << " bytes to "
                           << InetSocketAddress::ConvertFrom(from).GetIpv4() << " port "
                           << InetSocketAddress::ConvertFrom(from).GetPort());

    std::cout << std::endl;

    delete[] buffer_;
}

TypeId
UdpEchoClient::GetTypeId()
{
    static TypeId tid =
        TypeId("ns3::UdpEchoClient")
            .SetParent<Application>()
            .SetGroupName("Applications")
            .AddConstructor<UdpEchoClient>()
            .AddAttribute(
                "MaxPackets",
                "The maximum number of packets the application will send (zero means infinite)",
                UintegerValue(0),
                MakeUintegerAccessor(&UdpEchoClient::m_count),
                MakeUintegerChecker<uint32_t>())
            .AddAttribute("Interval",
                          "The time to wait between packets",
                          TimeValue(Seconds(1.0)),
                          MakeTimeAccessor(&UdpEchoClient::m_interval),
                          MakeTimeChecker())
            .AddAttribute("RemoteAddress",
                          "The destination Address of the outbound packets",
                          AddressValue(),
                          MakeAddressAccessor(&UdpEchoClient::m_peerAddress),
                          MakeAddressChecker())
            .AddAttribute("RemotePort",
                          "The destination port of the outbound packets",
                          UintegerValue(0),
                          MakeUintegerAccessor(&UdpEchoClient::m_peerPort),
                          MakeUintegerChecker<uint16_t>())
            .AddAttribute(
                "PacketSize",
                "Size of echo data in outbound packets",
                UintegerValue(100),
                MakeUintegerAccessor(&UdpEchoClient::SetDataSize, &UdpEchoClient::GetDataSize),
                MakeUintegerChecker<uint32_t>())
            .AddTraceSource("Tx",
                            "A new packet is created and is sent",
                            MakeTraceSourceAccessor(&UdpEchoClient::m_txTrace),
                            "ns3::Packet::TracedCallback")
            .AddTraceSource("Rx",
                            "A packet has been received",
                            MakeTraceSourceAccessor(&UdpEchoClient::m_rxTrace),
                            "ns3::Packet::TracedCallback")
            .AddTraceSource("TxWithAddresses",
                            "A new packet is created and is sent",
                            MakeTraceSourceAccessor(&UdpEchoClient::m_txTraceWithAddresses),
                            "ns3::Packet::TwoAddressTracedCallback")
            .AddTraceSource("RxWithAddresses",
                            "A packet has been received",
                            MakeTraceSourceAccessor(&UdpEchoClient::m_rxTraceWithAddresses),
                            "ns3::Packet::TwoAddressTracedCallback");
    return tid;
}

UdpEchoClient::UdpEchoClient()
{
    NS_LOG_FUNCTION(this);
    m_sent = 0;
    m_socket = nullptr;
    m_sendEvent = EventId();
    m_data = nullptr;
    m_dataSize = 0;
}

UdpEchoClient::~UdpEchoClient()
{
    NS_LOG_FUNCTION(this);
    m_socket = nullptr;

    delete[] m_data;
    m_data = nullptr;
    m_dataSize = 0;
}

void
UdpEchoClient::SetRemote(Address ip, uint16_t port)
{
    NS_LOG_FUNCTION(this << ip << port);
    m_peerAddress = ip;
    m_peerPort = port;
}

void
UdpEchoClient::SetRemote(Address addr)
{
    NS_LOG_FUNCTION(this << addr);
    m_peerAddress = addr;
}

void
UdpEchoClient::DoDispose()
{
    NS_LOG_FUNCTION(this);
    Application::DoDispose();
}

void
UdpEchoClient::StartApplication()
{
    NS_LOG_FUNCTION(this);

    if (!m_socket)
    {
        TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
        m_socket = Socket::CreateSocket(GetNode(), tid);
        if (Ipv4Address::IsMatchingType(m_peerAddress))
        {
            if (m_socket->Bind() == -1)
            {
                NS_FATAL_ERROR("Failed to bind socket");
            }
            m_socket->Connect(
                InetSocketAddress(Ipv4Address::ConvertFrom(m_peerAddress), m_peerPort));
        }
        else if (Ipv6Address::IsMatchingType(m_peerAddress))
        {
            if (m_socket->Bind6() == -1)
            {
                NS_FATAL_ERROR("Failed to bind socket");
            }
            m_socket->Connect(
                Inet6SocketAddress(Ipv6Address::ConvertFrom(m_peerAddress), m_peerPort));
        }
        else if (InetSocketAddress::IsMatchingType(m_peerAddress))
        {
            if (m_socket->Bind() == -1)
            {
                NS_FATAL_ERROR("Failed to bind socket");
            }
            m_socket->Connect(m_peerAddress);
        }
        else if (Inet6SocketAddress::IsMatchingType(m_peerAddress))
        {
            if (m_socket->Bind6() == -1)
            {
                NS_FATAL_ERROR("Failed to bind socket");
            }
            m_socket->Connect(m_peerAddress);
        }
        else
        {
            NS_ASSERT_MSG(false, "Incompatible address type: " << m_peerAddress);
        }
    }

    m_socket->SetRecvCallback(MakeCallback(&UdpEchoClient::HandleRead, this));
    m_socket->SetAllowBroadcast(true);
    ScheduleTransmit(Seconds(0.));
}

void
UdpEchoClient::StopApplication()
{
    NS_LOG_FUNCTION(this);

    if (m_socket)
    {
        m_socket->Close();
        m_socket->SetRecvCallback(MakeNullCallback<void, Ptr<Socket>>());
        m_socket = nullptr;
    }

    Simulator::Cancel(m_sendEvent);
}

void
UdpEchoClient::SetDataSize(uint32_t dataSize)
{
    NS_LOG_FUNCTION(this << dataSize);

    //
    // If the client is setting the echo packet data size this way, we infer
    // that she doesn't care about the contents of the packet at all, so
    // neither will we.
    //
    delete[] m_data;
    m_data = nullptr;
    m_dataSize = 0;
    m_size = dataSize;
}

uint32_t
UdpEchoClient::GetDataSize() const
{
    NS_LOG_FUNCTION(this);
    return m_size;
}

void
UdpEchoClient::SetFill(std::string fill)
{
    NS_LOG_FUNCTION(this << fill);

    std::vector<float> vec;
    std::stringstream ss(fill);
    float num;

    while (ss >> num)
    {
        vec.push_back(num);
    }

    uint32_t buffSize = vec.size() * sizeof(float);
    if (buffSize != m_dataSize)
    {
        delete[] m_data;
        m_data = new uint8_t[buffSize];
        m_dataSize = buffSize;
    }

    memcpy(m_data, vec.data(), buffSize); // m_data is sent

    //
    // Overwrite packet size attribute.
    //
    m_size = buffSize;
}

void
UdpEchoClient::SetFill(uint8_t fill, uint32_t dataSize)
{
    NS_LOG_FUNCTION(this << fill << dataSize);
    if (dataSize != m_dataSize)
    {
        delete[] m_data;
        m_data = new uint8_t[dataSize];
        m_dataSize = dataSize;
    }

    memset(m_data, fill, dataSize);

    //
    // Overwrite packet size attribute.
    //
    m_size = dataSize;
}

void
UdpEchoClient::SetFill(uint8_t* fill, uint32_t fillSize, uint32_t dataSize)
{
    NS_LOG_FUNCTION(this << fill << fillSize << dataSize);
    if (dataSize != m_dataSize)
    {
        delete[] m_data;
        m_data = new uint8_t[dataSize];
        m_dataSize = dataSize;
    }

    if (fillSize >= dataSize)
    {
        memcpy(m_data, fill, dataSize);
        m_size = dataSize;
        return;
    }

    //
    // Do all but the final fill.
    //
    uint32_t filled = 0;
    while (filled + fillSize < dataSize)
    {
        memcpy(&m_data[filled], fill, fillSize);
        filled += fillSize;
    }

    //
    // Last fill may be partial
    //
    memcpy(&m_data[filled], fill, dataSize - filled);

    //
    // Overwrite packet size attribute.
    //
    m_size = dataSize;
}

void
UdpEchoClient::ScheduleTransmit(Time dt)
{
    NS_LOG_FUNCTION(this << dt);
    m_sendEvent = Simulator::Schedule(dt, &UdpEchoClient::Send, this);
}

void
UdpEchoClient::Send()
{
    NS_LOG_FUNCTION(this);

    NS_ASSERT(m_sendEvent.IsExpired());

    Ptr<Packet> p;
    if (m_dataSize)
    {
        //
        // If m_dataSize is non-zero, we have a data buffer of the same size that we
        // are expected to copy and send.  This state of affairs is created if one of
        // the Fill functions is called.  In this case, m_size must have been set
        // to agree with m_dataSize
        //
        NS_ASSERT_MSG(m_dataSize == m_size,
                      "UdpEchoClient::Send(): m_size and m_dataSize inconsistent");
        NS_ASSERT_MSG(m_data, "UdpEchoClient::Send(): m_dataSize but no m_data");
        p = Create<Packet>(m_data, m_dataSize);
    }
    else
    {
        //
        // If m_dataSize is zero, the client has indicated that it doesn't care
        // about the data itself either by specifying the data size by setting
        // the corresponding attribute or by not calling a SetFill function.  In
        // this case, we don't worry about it either.  But we do allow m_size
        // to have a value different from the (zero) m_dataSize.
        //
        p = Create<Packet>(m_size);
    }
    Address localAddress;
    m_socket->GetSockName(localAddress);
    // call to the trace sinks before the packet is actually sent,
    // so that tags added to the packet can be sent as well
    m_txTrace(p);
    if (Ipv4Address::IsMatchingType(m_peerAddress))
    {
        m_txTraceWithAddresses(
            p,
            localAddress,
            InetSocketAddress(Ipv4Address::ConvertFrom(m_peerAddress), m_peerPort));
    }
    else if (Ipv6Address::IsMatchingType(m_peerAddress))
    {
        m_txTraceWithAddresses(
            p,
            localAddress,
            Inet6SocketAddress(Ipv6Address::ConvertFrom(m_peerAddress), m_peerPort));
    }
    m_socket->Send(p);
    ++m_sent;

    if (Ipv4Address::IsMatchingType(m_peerAddress))
    {
        NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " client sent " << m_size
                               << " bytes to " << Ipv4Address::ConvertFrom(m_peerAddress)
                               << " port " << m_peerPort);
    }
    else if (Ipv6Address::IsMatchingType(m_peerAddress))
    {
        NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " client sent " << m_size
                               << " bytes to " << Ipv6Address::ConvertFrom(m_peerAddress)
                               << " port " << m_peerPort);
    }
    else if (InetSocketAddress::IsMatchingType(m_peerAddress))
    {
        NS_LOG_INFO(
            "At time " << Simulator::Now().As(Time::S) << " client sent " << m_size << " bytes to "
                       << InetSocketAddress::ConvertFrom(m_peerAddress).GetIpv4() << " port "
                       << InetSocketAddress::ConvertFrom(m_peerAddress).GetPort());
    }
    else if (Inet6SocketAddress::IsMatchingType(m_peerAddress))
    {
        NS_LOG_INFO(
            "At time " << Simulator::Now().As(Time::S) << " client sent " << m_size << " bytes to "
                       << Inet6SocketAddress::ConvertFrom(m_peerAddress).GetIpv6() << " port "
                       << Inet6SocketAddress::ConvertFrom(m_peerAddress).GetPort());
    }

    if (m_sent < m_count || m_count == 0)
    {
        ScheduleTransmit(m_interval);
    }

    std::cout << "Client:\t\tsent " << m_size << " bytes to server" << std::endl;
}

void
UdpEchoClient::HandleRead(Ptr<Socket> socket)
{
    NS_LOG_FUNCTION(this << socket);
    Ptr<Packet> packet;
    Address from;
    Address localAddress;
    while ((packet = socket->RecvFrom(from)))
    {
        std::cout << std::endl;

        if (InetSocketAddress::IsMatchingType(from))
        {
            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " client received "
                                   << packet->GetSize() << " bytes from "
                                   << InetSocketAddress::ConvertFrom(from).GetIpv4() << " port "
                                   << InetSocketAddress::ConvertFrom(from).GetPort());
        }
        else if (Inet6SocketAddress::IsMatchingType(from))
        {
            NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " client received "
                                   << packet->GetSize() << " bytes from "
                                   << Inet6SocketAddress::ConvertFrom(from).GetIpv6() << " port "
                                   << Inet6SocketAddress::ConvertFrom(from).GetPort());
        }

        // Size of the data received
        int bufferSize = (m_dataSize + 2) * sizeof(float);

        std::ostringstream oss;
        packet->CopyData(&oss, bufferSize);
        std::string rawData = oss.str();

        // Allocate a properly aligned buffer
        std::vector<uint8_t> buffer_(rawData.begin(), rawData.end());

        // Ensure correct memory alignment when reinterpreting as float*
        float* floatPtr = reinterpret_cast<float*>(buffer_.data());

        // Copy first m_dataSize elements
        std::vector<float> vectorResult(floatPtr, floatPtr + m_dataSize / sizeof(float));
        float z12Result = floatPtr[m_dataSize / sizeof(float)];
        float rhoResult = floatPtr[m_dataSize / sizeof(float) + 1];

        float round, client_num;
        float x, z12, rho;

        memcpy(&round, &vectorResult[0], sizeof(float));
        memcpy(&client_num, &vectorResult[1], sizeof(float));
        memcpy(&x, &vectorResult[2], sizeof(float));
        memcpy(&z12, &z12Result, sizeof(float));
        memcpy(&rho, &rhoResult, sizeof(float));

        std::cout << "Client n°" << client_num << ":\treceived: ";
        for (size_t i = 0; i < buffer_.size() / sizeof(float); ++i)
        {
            std::cout << floatPtr[i] << " ";
        }
        std::cout << "| x: " << x << ", rho: " << rho << " , z12: " << z12 << std::endl;

        Ptr<Packet> responsePacket = Create<Packet>();

        // Get the ipv4 address of the node
        Ptr<Ipv4> ipv4 = GetNode()->GetObject<Ipv4>();
        Ipv4Address address = ipv4->GetAddress(1, 0).GetLocal();

        std::string filename = "config/script-conf.csv";
        std::string script;

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
        auto it = addressToAreaMap.find(address);
        if (it != addressToAreaMap.end())
        {
            script = it->second;
        }
        else
        {
            std::cerr << "Address not found in the file" << std::endl;
        }

        // Define the command to run the Julia script
        std::string juliaCommand = "julia config/" + script + " " + std::to_string(x) + " " +
                                   std::to_string(z12) + " " + std::to_string(rho) +
                                   " > output_client.txt";

        // Run the Julia script
        std::cout << "Client n°" << client_num << ":\tRunning " << script << "..." << std::endl;

        float result = std::system(juliaCommand.c_str());
        if (result != 0)
        {
            std::cerr << "Error running Julia script!" << std::endl;
            // return 1;
        }

        std::ifstream outputFile("output_client.txt");
        std::string line, lastLine, secondLastLine;

        // Loop through the file to get the last two lines
        while (std::getline(outputFile, line))
        {
            secondLastLine = lastLine; // Move the previous last line
            lastLine = line;           // Update last line to the current line
        }

        outputFile.close();

        // // Convert the last two lines to the required variables
        float optimizationTime = std::stof(lastLine);
        vectorResult[2] = std::stof(secondLastLine);

        // // Output the values to verify
        NS_LOG_INFO("Optimization Time: " << optimizationTime);

        std::cout << "Client n°" << client_num << ":\tRunning " << script
                  << " finished successfully after " << optimizationTime << "sec" << std::endl;

        // Schedule the next events in ns-3 to continue after the real-time delay
        Simulator::Schedule(Seconds(optimizationTime),
                            &sendPacket,
                            responsePacket,
                            from,
                            vectorResult,
                            script,
                            socket);

        /*
        // Optionally read the output from the file
        std::ifstream outputFile("output.txt");
        std::string line; std::string store_line;
        while (std::getline(outputFile, line)) {
            //std::cout << line << std::endl; // Print each line from the Julia script's output
            store_line = line;
        }
        result = std::stof(store_line);
        outputFile.close();

        std::cout << script << " julia script result: " << result << std::endl;

        memcpy(buffer_, &result, sizeof(float));
        memcpy(buffer_ + sizeof(float), &round, sizeof(uint32_t));

        responsePacket->AddAtEnd(Create<Packet>(buffer_, sizeof(buffer_)));

        //Ptr<Packet> responsePacket = Create<Packet> ((uint8_t *)msg.c_str(), msg.size());
        socket->SendTo (responsePacket, 0, from);

        NS_LOG_INFO("At time " << Simulator::Now().As(Time::S) << " client sent "
                               << responsePacket->GetSize() << " bytes to "
                               << InetSocketAddress::ConvertFrom(from).GetIpv4() << " port "
                               << InetSocketAddress::ConvertFrom(from).GetPort());
        */
    }
}

} // Namespace ns3
