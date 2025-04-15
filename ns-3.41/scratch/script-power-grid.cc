#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-helper.h"
#include "ns3/network-module.h"
#include "ns3/simulator.h"
#include "ns3/wifi-module.h"

using namespace ns3;
constexpr int nbr_client = 3;

struct Data
{
    std::vector<float> values;
    int vectorSize;
    Ipv4Address address;
};

NS_LOG_COMPONENT_DEFINE("WifiSimpleAdhoc");

void
TimerExpired(Ptr<Socket> socket, std::vector<Data>& ClientData)
{
    for (uint32_t i = 0; i < nbr_client; ++i)
    {
        // Prepare data
        int buffSize = ClientData[i].vectorSize * sizeof(float);
        uint8_t* buffer_ = new uint8_t[buffSize];
        memcpy(buffer_, ClientData[i].values.data(), buffSize);

        // Create and send packet
        Ptr<Packet> firstPacket = Create<Packet>(buffer_, buffSize);
        socket->SendTo(firstPacket, 0, ClientData[i].address);

        delete[] buffer_; // cleanup
    }
}

int
main(int argc, char* argv[])
{
    int seed = 1;
    int numberOfNodes = nbr_client;
    float threshold = 10.0;
    float simulationTime = 1000.0;
    float round = 1;
    float rho = 50.0f;

    std::vector<Data> ClientData(static_cast<std::size_t>(numberOfNodes));

    CommandLine cmd;
    cmd.AddValue("numberOfNodes", "Number of nodes", numberOfNodes);
    cmd.AddValue("seed", "Seed for random number generation", seed);
    cmd.AddValue("threshold",
                 "Threshold for the algorithm (server initiating new round)",
                 threshold);
    cmd.AddValue("simulationTime", "Simulation time in seconds", simulationTime);

    cmd.Parse(argc, argv);

    SeedManager::SetSeed(seed); // Changes seed from default of 1 to 3

    // Configure logging
    LogComponentEnable("WifiSimpleAdhoc", LOG_LEVEL_INFO);
    LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
    LogComponentEnable("PacketSink", LOG_LEVEL_INFO);
    // LogComponentEnable("MyApp", LOG_LEVEL_INFO);
    LogComponentEnable("UdpEchoClientApplication", LOG_LEVEL_INFO);
    LogComponentEnable("UdpEchoServerApplication", LOG_LEVEL_INFO);

    LogComponentEnableAll(LOG_PREFIX_FUNC); //
    LogComponentEnableAll(LOG_PREFIX_NODE); // Log plus précis pour savoir quelle fonction fait
    LogComponentEnableAll(LOG_PREFIX_TIME); // quoi et quand

    // Create nodes
    NodeContainer nodes;
    nodes.Create(numberOfNodes);

    NodeContainer centralNode;
    centralNode.Create(1);

    // Set up Wi-Fi
    WifiHelper wifi;
    wifi.SetStandard(WIFI_STANDARD_80211b);
    YansWifiPhyHelper wifiPhy;
    YansWifiChannelHelper wifiChannel = YansWifiChannelHelper::Default();
    wifiPhy.SetChannel(wifiChannel.Create());

    WifiMacHelper wifiMac;
    wifi.SetRemoteStationManager("ns3::AarfWifiManager");

    wifiMac.SetType("ns3::AdhocWifiMac");
    NetDeviceContainer nodeDevices = wifi.Install(wifiPhy, wifiMac, nodes);
    NetDeviceContainer centralDevice = wifi.Install(wifiPhy, wifiMac, centralNode);

    // Set up Internet stack
    InternetStackHelper stack;
    stack.Install(nodes);
    stack.Install(centralNode);

    MobilityHelper mobility;
    Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator>();
    mobility.SetPositionAllocator("ns3::UniformDiscPositionAllocator",
                                  "rho",
                                  DoubleValue(5.0),
                                  "X",
                                  DoubleValue(0.0),
                                  "Y",
                                  DoubleValue(0.0),
                                  "Z",
                                  DoubleValue(1.0));
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(nodes);
    mobility.Install(centralNode);

    // Assign IP addresses
    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer centralInterface = address.Assign(centralDevice);
    Ipv4InterfaceContainer nodeInterfaces = address.Assign(nodeDevices);

    // Create a UDP Echo Server on the server
    int echoPort = 9;
    UdpEchoServerHelper echoServer(echoPort); // Port #9
    ApplicationContainer serverApp = echoServer.Install(centralNode.Get(0));
    serverApp.Start(Seconds(1.0)); // Start server after 1 second
    serverApp.Stop(Seconds(10.0)); // Stop server after 10 seconds

    // Installing client on nodes
    for (uint32_t i = 0; i < nodes.GetN(); i++)
    {
        // Configure the echo client to send to each client's IP address
        UdpEchoClientHelper echoClient(nodeInterfaces.GetAddress(i), echoPort);

        ApplicationContainer clientApp = echoClient.Install(nodes.Get(i));
        clientApp.Start(Seconds(1.0));
        clientApp.Stop(Seconds(11.0));
    }

    // Initialize vector sended to the client
    std::vector<std::vector<float>> startingValues(numberOfNodes);
    startingValues[0] = std::vector<float>(96, 1.0f);
    startingValues[1] = std::vector<float>(48, 1.0f);
    startingValues[2] = std::vector<float>(48, 1.0f);

    for (int i = 0; i < numberOfNodes; ++i)
    {
        // adding to the vector the round, the current client number, and rho
        startingValues[i].insert(startingValues[i].begin(), round);
        startingValues[i].insert(startingValues[i].begin(), static_cast<float>(i));
        startingValues[i].push_back(rho);

        // Data client
        ClientData[i].values = startingValues[i];            // data to send
        ClientData[i].vectorSize = startingValues[i].size(); // size of data
    }

    // Create and bind the socket on the central node
    Ptr<Socket> socket =
        Socket::CreateSocket(centralNode.Get(0), TypeId::LookupByName("ns3::UdpSocketFactory"));
    socket->Bind();

    for (uint32_t index = 0; index < nodes.GetN(); ++index)
    {
        // Address of the client
        ClientData[index].address = nodeInterfaces.GetAddress(index);

        // Prepare data
        int buffSize = ClientData[index].vectorSize * sizeof(float);
        uint8_t* buffer_ = new uint8_t[buffSize];
        memcpy(buffer_, ClientData[index].values.data(), buffSize);

        // Create and send packet
        Ptr<Packet> firstPacket = Create<Packet>(buffer_, buffSize);
        InetSocketAddress socketAddress(ClientData[index].address, echoPort);
        socket->SendTo(firstPacket, 0, socketAddress);


        std::cout << "Server " << centralInterface.GetAddress(0) <<  " sended " << buffSize << " bytes to " << ClientData[index].address << " ( value: ";
        for (int j = 0; j < 3; j++) { std::cout << ClientData[index].values[j] << " ";}
        std::cout << "... ";

        for (size_t j = ClientData[index].values.size() - 3; j < ClientData[index].values.size(); j++){std::cout << ClientData[index].values[j] << " ";}
        std::cout << ")" << std::endl;

        delete[] buffer_; // cleanup
    }

    Simulator::Schedule(Seconds(threshold), &TimerExpired, socket, ClientData);

    /*/ Starting simulation /*/
    Simulator::Stop(Seconds(simulationTime));
    Simulator::Run();

    // *** Récupération des statistiques ***
    Ptr<FlowMonitor> flowMonitor;
    FlowMonitorHelper flowHelper;
    flowMonitor = flowHelper.InstallAll();
    flowMonitor->CheckForLostPackets();

    auto stats = flowMonitor->GetFlowStats();
    double totalDelay = 0;
    uint32_t packet_lost = 0;
    uint32_t total_packet_received = 0;
    uint32_t datarate = 0;

    for (auto it = stats.begin(); it != stats.end(); it++)
    {
        totalDelay += it->second.delaySum.GetSeconds() / it->second.rxPackets;
        packet_lost += it->second.lostPackets;
        // equivalent to server.GetServer()->GetReceived()
        total_packet_received += it->second.rxPackets;
        datarate += it->second.rxBytes;
    }
    std::cout << "Total delay: " << totalDelay << std::endl;
    std::cout << "Packet lost: " << packet_lost << std::endl;
    std::cout << "Total packet received: " << total_packet_received << std::endl;
    std::cout << "Data rate: " << datarate << std::endl;

    return 0;
}
