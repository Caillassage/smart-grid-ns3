#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-helper.h"
#include "ns3/network-module.h"
#include "ns3/wifi-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("WifiSimpleAdhoc");

int
main(int argc, char* argv[])
{
    int seed = 1;
    int numberOfNodes = 3; // mettre à 3 pour la suite
    float threshold = 9.0;
    float simulationTime = 1000.0;

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
    // LogComponentEnable("WifiSimpleAdhoc", LOG_LEVEL_INFO);
    // LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
    // LogComponentEnable("PacketSink", LOG_LEVEL_INFO);
    // //LogComponentEnable("MyApp", LOG_LEVEL_INFO);
    // LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_INFO);
    // LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_INFO);

    // LogComponentEnableAll (LOG_PREFIX_FUNC); //
    // LogComponentEnableAll (LOG_PREFIX_NODE); // Log plus précis pour savoir quelle fonction fait
    // quoi et quand LogComponentEnableAll (LOG_PREFIX_TIME); //

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
    serverApps.Stop(Seconds(11.0));

    std::cout << "\nSTART SIMULATION" << std::endl;

    for (uint32_t index = 0; index < numberOfNodes; ++index)
    {
        // This application is to be installed at the central node
        UdpEchoClientHelper echoClient1(centralInterface.GetAddress(0), echoPort);

        echoClient1.SetAttribute("MaxPackets", UintegerValue(10000));
        echoClient1.SetAttribute("Interval", TimeValue(Seconds(10)));
        echoClient1.SetAttribute("PacketSize", UintegerValue(payloadSizeEcho));

        ApplicationContainer clientApp = echoClient1.Install(nodes.Get(index));
        // commInterfaces.GetAddress(0).Print(std::cout);
        clientApp.Start(Seconds(1.0));
        clientApp.Stop(Seconds(11.0));

        /*
        // Create an integer to send
        std::string valueToSend = "1.0 1.0 1.0";
        //Ptr<Packet> packet = Create<Packet>((uint8_t *)&valueToSend, sizeof(int));
        echoClient1.SetFill (clientApp.Get (0), valueToSend);
        */

        std::vector<float> vec = {1.231111111111, 4.56, 7.89, static_cast<float>((index + 1) * 10.0)};
        float round = 1;

        std::ostringstream oss;

        // first value is the current round, second value is the n° of the client
        oss << round << " " << static_cast<float>(index);
        for (size_t i = 0; i < vec.size(); ++i)
        {
            oss << " " << vec[i];
        }

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
