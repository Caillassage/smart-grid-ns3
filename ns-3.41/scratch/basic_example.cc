#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-helper.h"
#include "ns3/network-module.h"
#include "ns3/wifi-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("WifiSimpleAdhoc");

/*
To compile and execute this program : ./ls3 configure & ./ns3 run basic_example

Be sure to install all required packages and dependencies.

This program creates a simple ad-hoc network with two nodes (a server and a client).
The client sends a series of packets to the server, and the server echoes them back.
The program uses the ns-3 network simulator to simulate the network behavior.
*/

int
main(int argc, char* argv[])
{
    LogComponentEnable("WifiSimpleAdhoc", LOG_LEVEL_INFO);
    LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
    LogComponentEnable("PacketSink", LOG_LEVEL_INFO);
    LogComponentEnable("UdpEchoClientApplication", LOG_LEVEL_INFO);
    LogComponentEnable("UdpEchoServerApplication", LOG_LEVEL_INFO);

    LogComponentEnableAll(LOG_PREFIX_FUNC);
    LogComponentEnableAll(LOG_PREFIX_NODE);
    LogComponentEnableAll(LOG_PREFIX_TIME);

    // -----------------------------------------------------

    // Create server
    NodeContainer server;
    server.Create(1);

    // Create client
    NodeContainer client;
    client.Create(1);

    // -----------------------------------------------------

    // set up Wi-Fi protocol behavior
    WifiHelper wifi;
    wifi.SetStandard(WIFI_STANDARD_80211b);
    wifi.SetRemoteStationManager("ns3::AarfWifiManager");

    // create and configure a wireless channel model, which simulates how radio signals propagate between nodes.
    YansWifiPhyHelper wifiPhy;
    YansWifiChannelHelper wifiChannel = YansWifiChannelHelper::Default();
    wifiPhy.SetChannel(wifiChannel.Create());

    WifiMacHelper wifiMac;
    wifiMac.SetType("ns3::AdhocWifiMac");

    NetDeviceContainer nodeDevice = wifi.Install(wifiPhy, wifiMac, client);
    NetDeviceContainer centralDevice = wifi.Install(wifiPhy, wifiMac, server);

    // -----------------------------------------------------

    MobilityHelper mobility;
    Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator>();
    mobility.SetPositionAllocator("ns3::UniformDiscPositionAllocator",
                                  "rho", DoubleValue(5.0),
                                  "X", DoubleValue(0.0),
                                  "Y", DoubleValue(0.0),
                                  "Z", DoubleValue(1.0));
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(client);
    mobility.Install(server);

    // -----------------------------------------------------

    // Set up Internet stack
    InternetStackHelper stack;
    stack.Install(client);
    stack.Install(server);

    // Assign IP addresses
    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer centralInterface = address.Assign(centralDevice);
    Ipv4InterfaceContainer nodeInterface = address.Assign(nodeDevice);

    // -----------------------------------------------------

    // UDP Echo Server on server
    int echoPort = 9;
    UdpEchoServerHelper echoServer(echoPort); // Port # 9
    ApplicationContainer serverApps = echoServer.Install(server);

    // -----------------------------------------------------

    // UDP Echo Client on node
    UdpEchoClientHelper echoClient(nodeInterface.GetAddress(0), echoPort);
    echoClient.SetAttribute("MaxPackets", UintegerValue(5));
    echoClient.SetAttribute("Interval", TimeValue(Seconds(1.0)));
    echoClient.SetAttribute("PacketSize", UintegerValue(512));
    ApplicationContainer clientApp = echoClient.Install(client);

    // -----------------------------------------------------

    serverApps.Start(Seconds(0.0));
    serverApps.Stop(Seconds(10.0));

    clientApp.Start(Seconds(2.0));
    clientApp.Stop(Seconds(10.0));

    // Simulation
    Simulator::Stop(Seconds(10.0));
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}