#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/wifi-module.h"
#include "ns3/mobility-helper.h"
#include "ns3/flow-monitor-helper.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("WifiSimpleAdhoc");

int main(int argc, char *argv[])
{

    int numberOfNodes = 6;

    // Configure logging
    LogComponentEnable("WifiSimpleAdhoc", LOG_LEVEL_INFO);
    LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
    LogComponentEnable("PacketSink", LOG_LEVEL_INFO);
    //LogComponentEnable("MyApp", LOG_LEVEL_INFO);
    LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_INFO);
    LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_INFO);

    LogComponentEnableAll (LOG_PREFIX_FUNC);
    LogComponentEnableAll (LOG_PREFIX_NODE);
    LogComponentEnableAll (LOG_PREFIX_TIME);

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
    Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator> ();
    mobility.SetPositionAllocator ("ns3::UniformDiscPositionAllocator", "rho", DoubleValue (5.0),
                                  "X", DoubleValue (0.0), "Y", DoubleValue (0.0), "Z", DoubleValue(1.0));
    mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
    mobility.Install(nodes);
    mobility.Install(centralNode);

    // Assign IP addresses
    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer centralInterface = address.Assign(centralDevice);
    Ipv4InterfaceContainer nodeInterfaces = address.Assign(nodeDevices);

    uint16_t port = 9;  // Arbitrary port number
    /*
    // Create MyApp on node 0
    
    Address serverAddress = InetSocketAddress(interfaces.GetAddress(1), port);
    Ptr<MyApp> app = CreateObject<MyApp>();
    app->Setup(nodes.Get(0), serverAddress, 1024, 5, DataRate("1Mbps"));  // Setup with 1024-byte packet size
    nodes.Get(0)->AddApplication(app);
    app->SetStartTime(Seconds(1.0));
    app->SetStopTime(Seconds(10.0));

    Address serverAddress_2 = InetSocketAddress(interfaces.GetAddress(0), port);
    Ptr<MyApp> app_2 = CreateObject<MyApp>();
    app_2->Setup(nodes.Get(1), Address(), 0, 0, DataRate("0Mbps"));  // Setup with 1024-byte packet size
    nodes.Get(1)->AddApplication(app_2);
    app_2->SetStartTime(Seconds(1.0));
    app_2->SetStopTime(Seconds(10.0));
    
    
    // Create a packet sink on node 1 to receive packets
    MyAppHelper packetSinkHelper("ns3::UdpSocketFactory", InetSocketAddress(Ipv4Address::GetAny(), port));
    ApplicationContainer sinkApps = packetSinkHelper.Install(nodes.Get(0));
    sinkApps.Start(Seconds(0.0));
    sinkApps.Stop(Seconds(10.0));

    PacketSinkHelper packetSinkHelper_("ns3::UdpSocketFactory", InetSocketAddress(Ipv4Address::GetAny(), port));
    ApplicationContainer sinkApps_ = packetSinkHelper_.Install(nodes.Get(1));
    sinkApps_.Start(Seconds(0.0));
    sinkApps_.Stop(Seconds(10.0));

    auto ipv4 = nodes.Get (0)->GetObject<Ipv4> ();
    const auto address_ = ipv4->GetAddress (1, 0).GetLocal ();

    // UDP Client application to be installed in the stations
    UdpClientHelper echoClient(address_, port);
    
    echoClient.SetAttribute("MaxPackets", UintegerValue(100000));
    echoClient.SetAttribute("Interval", TimeValue(Seconds(1)));
    echoClient.SetAttribute("PacketSize", UintegerValue(1024));

    ApplicationContainer sourceApplications = echoClient.Install (nodes.Get(1));
    sourceApplications.Start(Seconds(0.0));
    sourceApplications.Stop(Seconds(10.0));
    */

    int echoPort = 9;
    UdpEchoServerHelper echoServer(echoPort); // Port # 9
    uint32_t payloadSizeEcho = 1023; //Packet size for Echo UDP App

    ApplicationContainer serverApps = echoServer.Install(nodes);
    serverApps.Start(Seconds(0.0));
    serverApps.Stop(Seconds(11.0));

    for (uint32_t index = 0; index < numberOfNodes; ++index) {
        UdpEchoClientHelper echoClient1(nodeInterfaces.GetAddress(index), echoPort); 
      
        echoClient1.SetAttribute("MaxPackets", UintegerValue(10000));
        echoClient1.SetAttribute("Interval", TimeValue(Seconds(10)));
        echoClient1.SetAttribute("PacketSize", UintegerValue(payloadSizeEcho));

        ApplicationContainer clientApp = echoClient1.Install(centralNode.Get(0));
        //commInterfaces.GetAddress(0).Print(std::cout);
        clientApp.Start(Seconds(1.0));
        clientApp.Stop(Seconds(11.0));

        // Create an integer to send
        std::string valueToSend = "1.0";
        //Ptr<Packet> packet = Create<Packet>((uint8_t *)&valueToSend, sizeof(int));
        echoClient1.SetFill (clientApp.Get (0), valueToSend);
    }

    Ptr<FlowMonitor> flowMonitor;
    FlowMonitorHelper flowHelper;
    flowMonitor = flowHelper.InstallAll();

    // Start the simulation
    /*/ Starting simulation /*/
    Simulator::Stop (Seconds (1.2));
    Simulator::Run ();

    // *** Récupération des statistiques ***
    flowMonitor->CheckForLostPackets();
    auto stats = flowMonitor->GetFlowStats();
    double totalDelay = 0;
    uint32_t packet_lost = 0;
    uint32_t total_packet_received = 0;
    uint32_t total_packet = 0;
    uint32_t datarate = 0;
    for (auto it = stats.begin(); it != stats.end(); it++)
    {
        totalDelay += it->second.delaySum.GetSeconds() / it->second.rxPackets;
        packet_lost += it->second.lostPackets;
        // equivalent to server.GetServer()->GetReceived()
        total_packet_received += it->second.rxPackets;
        total_packet += it->second.txPackets;
        datarate += it->second.rxBytes;
    }
    std::cout << "Total delay: " << totalDelay << std::endl;
    std::cout << "Packet lost: " << packet_lost << std::endl;
    std::cout << "Total packet received: " << total_packet_received << std::endl;   
    std::cout << "Data rate: " << datarate << std::endl;

    return 0;
}
