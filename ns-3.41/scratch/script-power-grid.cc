#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-helper.h"
#include "ns3/network-module.h"
#include "ns3/wifi-module.h"

using namespace ns3;

constexpr int nbr_client = 3;

struct Data
{
    std::vector<float> values;
    int vectorSize;
};

NS_LOG_COMPONENT_DEFINE("WifiSimpleAdhoc");

int
main(int argc, char* argv[])
{
    int seed = 1;
    int numberOfNodes = nbr_client;
    float threshold = 8.0;
    float simulationTime = 1000.0;
    float round = 1;
    float rho = 50.0f;

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

    int echoPort = 9;
    UdpEchoServerHelper echoServer(echoPort); // Port # 9
    echoServer.SetAttribute("Threshold", TimeValue(Seconds(threshold)));
    uint32_t payloadSizeEcho = 1023; // Packet size for Echo UDP App

    ApplicationContainer serverApps = echoServer.Install(centralNode.Get(0));
    serverApps.Start(Seconds(0.0));
    serverApps.Stop(Seconds(1000000.0));

    // Data of each client
    std::vector<Data> ClientData(static_cast<std::size_t>(numberOfNodes));

    // values of the first vector sended to the client
    std::vector<std::vector<float>> startingValues(numberOfNodes);
    startingValues[0] = std::vector<float>(96, 1.0f);
    startingValues[1] = std::vector<float>(48, 1.0f);
    startingValues[2] = std::vector<float>(48, 1.0f);

    for (int i = 0; i < numberOfNodes; ++i)
    {
        // adding to the vector the round, the current client number, and rho
        startingValues[i].insert(startingValues[i].begin(), static_cast<float>(i)); // client n°
        startingValues[i].insert(startingValues[i].begin(), round);                 // round
        startingValues[i].push_back(rho);                                           // rho

        // Data client
        ClientData[i].values = startingValues[i];            // data to send
        ClientData[i].vectorSize = startingValues[i].size(); // size of data
    }

    std::cout << "\nSTART SIMULATION" << std::endl;

    for (int index = 0; index < numberOfNodes; ++index)
    {
        // This application is to be installed at the central node
        UdpEchoClientHelper echoClient1(centralInterface.GetAddress(0), echoPort);

        echoClient1.SetAttribute("MaxPackets", UintegerValue(10000));
        echoClient1.SetAttribute("Interval", TimeValue(Seconds(10000)));
        echoClient1.SetAttribute("PacketSize", UintegerValue(payloadSizeEcho));

        ApplicationContainer clientApp = echoClient1.Install(nodes.Get(index));
        clientApp.Start(Seconds(1.0));
        clientApp.Stop(Seconds(1000000.0));

        std::ostringstream oss;

        for (auto&& f : ClientData[index].values)
            oss << " " << f;

        std::string valueToSend = oss.str();

        // Use SetFill to set the packet payload
        echoClient1.SetFill(clientApp.Get(0), valueToSend);
    }

    Ptr<FlowMonitor> flowMonitor;
    FlowMonitorHelper flowHelper;
    flowMonitor = flowHelper.InstallAll();

    /*/ Starting simulation /*/
    Simulator::Stop(Seconds(simulationTime));
    Simulator::Run();

    // *** Récupération des statistiques ***
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
