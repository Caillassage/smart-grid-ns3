#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/point-to-point-module.h"
#include <vector>
#include <cstring>

using namespace ns3;

// Function to send a vector of floats
void SendVector(Ptr<Socket> socket, Address address, const std::vector<float>& data) {
    size_t dataSize = data.size() * sizeof(float);
    uint8_t* buffer = new uint8_t[dataSize];
    std::memcpy(buffer, data.data(), dataSize);

    Ptr<Packet> packet = Create<Packet>(buffer, dataSize);
    socket->SendTo(packet, 0, address);

    delete[] buffer;
}

// Callback to receive a packet
void ReceivePacket(Ptr<Socket> socket) {
    Ptr<Packet> packet = socket->Recv();

    uint32_t packetSize = packet->GetSize();
    uint8_t* buffer = new uint8_t[packetSize];
    packet->CopyData(buffer, packetSize);

    std::vector<float> receivedData(packetSize / sizeof(float));
    std::memcpy(receivedData.data(), buffer, packetSize);

    std::cout << "Received Data:";
    for (float value : receivedData) {
        std::cout << "  " << value << std::endl;
    }

    delete[] buffer;
}

int main(int argc, char* argv[]) {
    // Create two nodes
    NodeContainer nodes;
    nodes.Create(2);

    // Install internet stack
    InternetStackHelper stack;
    stack.Install(nodes);

    // Assign IP addresses
    PointToPointHelper p2p;
    p2p.SetDeviceAttribute("DataRate", StringValue("5Mbps"));
    p2p.SetChannelAttribute("Delay", StringValue("2ms"));

    NetDeviceContainer devices = p2p.Install(nodes);

    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer interfaces = address.Assign(devices);

    // Create and bind a UDP socket on the receiver
    TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
    Ptr<Socket> recvSocket = Socket::CreateSocket(nodes.Get(1), tid);
    InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), 8080);
    recvSocket->Bind(local);
    recvSocket->SetRecvCallback(MakeCallback(&ReceivePacket));

    // Create a UDP socket on the sender
    Ptr<Socket> sendSocket = Socket::CreateSocket(nodes.Get(0), tid);
    InetSocketAddress remote = InetSocketAddress(interfaces.GetAddress(1), 8080);
    sendSocket->Connect(remote);

    // Schedule sending of data
    Simulator::Schedule(Seconds(1.0), &SendVector, sendSocket, remote, std::vector<float>{1.231111111111, 4.56, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89, 7.89});

    // Run the simulation
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}
