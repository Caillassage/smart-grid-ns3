#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/wifi-module.h"
#include "ns3/mobility-helper.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/point-to-point-epc-helper.h"
#include "ns3/nr-helper.h"
#include "ns3/nr-module.h"
#include "ns3/antenna-module.h"
#include "ns3/point-to-point-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("WifiSimpleAdhoc");

int main(int argc, char *argv[])
{
    int seed = 1;
    int numberOfNodes = 2;
    float threshold = 9.0;
    float simulationTime = 10.0;

    double centralFrequencyBand1 = 40.0e9;
    int channelWidth = 50e6;
    uint16_t numerology = 0; // Max 5

    CommandLine cmd;
    cmd.AddValue("numberOfNodes", "Number of nodes", numberOfNodes);
    cmd.AddValue("seed", "Seed for random number generation", seed);
    cmd.AddValue("threshold", "Threshold for the algorithm (server initiating new round)", threshold);
    cmd.AddValue("simulationTime", "Simulation time in seconds", simulationTime);

    cmd.Parse(argc, argv);

    SeedManager::SetSeed (seed);  // Changes seed from default of 1 to 3

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

    
    Ptr<NrPointToPointEpcHelper> epcHelper = CreateObject<NrPointToPointEpcHelper>();
    Ptr<IdealBeamformingHelper> idealBeamformingHelper = CreateObject<IdealBeamformingHelper>();
    Ptr<NrHelper> nrHelper = CreateObject<NrHelper>();

    nrHelper->SetBeamformingHelper(idealBeamformingHelper);
    nrHelper->SetEpcHelper(epcHelper);

    // Create one operational band containing one CC with one bandwidth part
    BandwidthPartInfoPtrVector allBwps;
    CcBwpCreator ccBwpCreator;
    const uint8_t numCcPerBand = 1;

    // Create the configuration for the CcBwpHelper
    CcBwpCreator::SimpleOperationBandConf bandConf1(centralFrequencyBand1,
                                                    channelWidth,
                                                    numCcPerBand,
                                                    BandwidthPartInfo::UMi_StreetCanyon_LoS);

    // By using the configuration created, it is time to make the operation band
    OperationBandInfo band1 = ccBwpCreator.CreateOperationBandContiguousCc(bandConf1);

    Config::SetDefault("ns3::ThreeGppChannelModel::UpdatePeriod", TimeValue(MilliSeconds(0)));
    nrHelper->SetSchedulerAttribute("FixedMcsDl", BooleanValue(true));
    nrHelper->SetSchedulerAttribute("StartingMcsDl", UintegerValue(28));
    nrHelper->SetChannelConditionModelAttribute("UpdatePeriod", TimeValue(MilliSeconds(0)));
    nrHelper->SetPathlossAttribute("ShadowingEnabled", BooleanValue(false));

    nrHelper->InitializeOperationBand(&band1);
    allBwps = CcBwpCreator::GetAllBwps({band1});

    // Beamforming method
    idealBeamformingHelper->SetAttribute("BeamformingMethod",
                                         TypeIdValue(DirectPathBeamforming::GetTypeId()));

    // Antennas for all the UEs
    nrHelper->SetUeAntennaAttribute("NumRows", UintegerValue(2));
    nrHelper->SetUeAntennaAttribute("NumColumns", UintegerValue(4));
    nrHelper->SetUeAntennaAttribute("AntennaElement",
                                    PointerValue(CreateObject<IsotropicAntennaModel>()));

    // Antennas for all the gNbs
    nrHelper->SetGnbAntennaAttribute("NumRows", UintegerValue(4));
    nrHelper->SetGnbAntennaAttribute("NumColumns", UintegerValue(8));
    nrHelper->SetGnbAntennaAttribute("AntennaElement",
                                     PointerValue(CreateObject<IsotropicAntennaModel>()));

    /*
     *  Create the gNB and UE nodes according to the network topology
     */
    NodeContainer gNbNodes;
    NodeContainer ueNodes;

    //std::cout << "gnb id: " << gNbNodes.Get(0)->GetId() << std::endl;
    //std::cout << "ue id: " << ueNodes.Get(0)->GetId() << std::endl;

    // Install Mobility Model
    MobilityHelper mobility;
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(gNbNodes);
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(ueNodes);

    /*
    Ptr<Node> node = gNbNodes.Get(0);
        Ptr<MobilityModel> mob = node->GetObject<MobilityModel>();
        Vector pos = mob->GetPosition();
        std::cout << "Node " << 0 << " position: "
                  << "x=" << pos.x << ", y=" << pos.y << ", z=" << pos.z << std::endl;


        node = gNbNodes.Get(1);
        mob = node->GetObject<MobilityModel>();
        pos = mob->GetPosition();
        std::cout << "Node " << 1 << " position: "
                  << "x=" << pos.x << ", y=" << pos.y << ", z=" << pos.z << std::endl;

    */

    // Install nr net devices
    NetDeviceContainer gNbNetDev = nrHelper->InstallGnbDevice(gNbNodes, allBwps);
    NetDeviceContainer ueNetDev = nrHelper->InstallUeDevice(ueNodes, allBwps);

    int64_t randomStream = 1;
    randomStream += nrHelper->AssignStreams(gNbNetDev, randomStream);
    randomStream += nrHelper->AssignStreams(ueNetDev, randomStream);

    for (uint32_t i = 0; i < gNbNodes.GetN(); ++i) { 
        // Set the attribute of the netdevice (enbNetDev.Get (0)) and bandwidth part (0)
        nrHelper->GetGnbPhy(gNbNetDev.Get(i), 0) ->SetAttribute("Numerology", UintegerValue(numerology));
    }

    for (auto it = gNbNetDev.Begin(); it != gNbNetDev.End(); ++it) {
        DynamicCast<NrGnbNetDevice>(*it)->UpdateConfig();
    }

    for (auto it = ueNetDev.Begin(); it != ueNetDev.End(); ++it) {
        DynamicCast<NrUeNetDevice>(*it)->UpdateConfig();
    }

    Ptr<Node> pgw = epcHelper->GetPgwNode();
    NodeContainer remoteHostContainer;
    remoteHostContainer.Create(1);
    Ptr<Node> remoteHost = remoteHostContainer.Get(0);
    InternetStackHelper internet;
    internet.Install(remoteHostContainer);

    // connect a remoteHost to pgw. Setup routing too
    PointToPointHelper p2ph;
    p2ph.SetDeviceAttribute("DataRate", DataRateValue(DataRate("100Gb/s")));
    p2ph.SetDeviceAttribute("Mtu", UintegerValue(2500));
    p2ph.SetChannelAttribute("Delay", TimeValue(Seconds(0.000)));
    NetDeviceContainer internetDevices = p2ph.Install(pgw, remoteHost);
    Ipv4AddressHelper ipv4h;
    ipv4h.SetBase("1.0.0.0", "255.0.0.0");
    Ipv4InterfaceContainer internetIpIfaces = ipv4h.Assign(internetDevices);
    Ipv4StaticRoutingHelper ipv4RoutingHelper;
    Ptr<Ipv4StaticRouting> remoteHostStaticRouting =
        ipv4RoutingHelper.GetStaticRouting(remoteHost->GetObject<Ipv4>());
    remoteHostStaticRouting->AddNetworkRouteTo(Ipv4Address("7.0.0.0"), Ipv4Mask("255.0.0.0"), 1);
    internet.Install(ueNodes);

    Ipv4InterfaceContainer ueIpIface, gnbIpIface;
    gnbIpIface = epcHelper->AssignUeIpv4Address(NetDeviceContainer(gNbNetDev));
    ueIpIface = epcHelper->AssignUeIpv4Address(NetDeviceContainer(ueNetDev));

    /*
    std::cout << "UE IP Interfaces:" << std::endl;
    for (uint32_t i = 0; i < ueIpIface.GetN(); ++i) {
        std::cout << "UE " << i << " (id=" << GetNodeIdFromIpAddress(ueIpIface.GetAddress(i), ueIpIface) << "): " << ueIpIface.GetAddress(i) << std::endl;
    }
    */

    // attach UEs to the closest eNB
    nrHelper->AttachToClosestEnb(ueNetDev, gNbNetDev);

    int echoPort = 9;
    UdpEchoServerHelper echoServer(echoPort); // Port # 9
    echoServer.SetAttribute("Threshold", TimeValue(Seconds(threshold)));
    uint32_t payloadSizeEcho = 1023; //Packet size for Echo UDP App

    ApplicationContainer serverApps = echoServer.Install(centralNode.Get(0));
    serverApps.Start(Seconds(0.0));
    serverApps.Stop(Seconds(11.0));

    for (uint32_t index = 0; index < numberOfNodes; ++index) {
        // This application is to be installed at the central node
        UdpEchoClientHelper echoClient1(centralInterface.GetAddress(0), echoPort); 
      
        echoClient1.SetAttribute("MaxPackets", UintegerValue(10000));
        echoClient1.SetAttribute("Interval", TimeValue(Seconds(10)));
        echoClient1.SetAttribute("PacketSize", UintegerValue(payloadSizeEcho));

        ApplicationContainer clientApp = echoClient1.Install(nodes.Get(index));
        //commInterfaces.GetAddress(0).Print(std::cout);
        clientApp.Start(Seconds(1.0));
        clientApp.Stop(Seconds(11.0));

        /*
        // Create an integer to send
        std::string valueToSend = "1.0 1.0 1.0";
        //Ptr<Packet> packet = Create<Packet>((uint8_t *)&valueToSend, sizeof(int));
        echoClient1.SetFill (clientApp.Get (0), valueToSend);
        */
       
        // Serialize the floats into a string
        /*
        float x = 0.0, rho = 1.0, lambda = 1.0; // x and y have the same values for the first sending
        std::ostringstream oss;
        oss << x << " " << rho << " " << lambda;
        std::string valueToSend = oss.str();
        */

        float x = 0.0;
        uint32_t round = 1; // x and y have the same values for the first sending
        std::ostringstream oss;
        oss << x << " " << round;
        std::string valueToSend = oss.str();

        // Use SetFill to set the packet payload
        echoClient1.SetFill(clientApp.Get(0), valueToSend);
    }

    Ptr<FlowMonitor> flowMonitor;
    FlowMonitorHelper flowHelper;
    flowMonitor = flowHelper.InstallAll();

    /*/ Starting simulation /*/
    Simulator::Stop (Seconds (simulationTime));
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
