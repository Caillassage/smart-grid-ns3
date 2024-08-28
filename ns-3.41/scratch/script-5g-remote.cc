/* -*-  Mode: C++; c-file-style: "gnu"; indent-tabs-mode:nil; -*- */

// Copyright (c) 2020 Centre Tecnologic de Telecomunicacions de Catalunya (CTTC)
//
// SPDX-License-Identifier: GPL-2.0-only

/**
 * \ingroup examples
 * \file cttc-3gpp-channel-simple-ran.cc
 * \brief Simple RAN
 *
 * This example describes how to setup a simulation using the 3GPP channel model
 * from TR 38.901. This example consists of a simple topology of 1 UE and 1 gNb,
 * and only NR RAN part is simulated. One Bandwidth part and one CC are defined.
 * A packet is created and directly sent to gNb device by SendPacket function.
 * Then several functions are connected to PDCP and RLC traces and the delay is
 * printed.
 */

#include "ns3/antenna-module.h"
#include "ns3/applications-module.h"
#include "ns3/config-store.h"
#include "ns3/core-module.h"
#include "ns3/eps-bearer-tag.h"
#include "ns3/grid-scenario-helper.h"
#include "ns3/internet-module.h"
#include "ns3/ipv4-global-routing-helper.h"
#include "ns3/log.h"
#include "ns3/mobility-module.h"
#include "ns3/network-module.h"
#include "ns3/nr-helper.h"
#include "ns3/nr-module.h"
#include "ns3/nr-point-to-point-epc-helper.h"
#include "ns3/basic-energy-source-helper.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/point-to-point-module.h"
#include <iomanip>

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("5g-script-remote");

int
main(int argc, char* argv[])
{
    SeedManager::SetSeed (3);  // Changes seed from default of 1 to 3
    SeedManager::SetRun (2);  // Changes run number from default of 1 to 7
    /*/ Input parameters definition /*/
    // Seconds
    double simulationTime = 10;
    std::string propDelay = "ConstantSpeedPropagationDelayModel";
    std::string propLoss = "LogDistancePropagationLossModel";

    uint16_t numGnbs = 2;
    uint16_t numUes = 6;

    // TxPower
    int txPower = 5; // Assuming tx_current represents the TxPower
    // Traffic direction
    std::string trafficDirection = "upstream";
    // Payload size in bytes
    int payloadSize = 1024;
    // Packet period in seconds
    std::string period = "1";
    
    double centralFrequencyBand1 = 40.0e9;
    int channelWidth = 50e6;
    uint16_t numerology = 0; // Max 5

    // Advanced parameters
    // Delay propagation model
    std::string propagationDelayModel = "ConstantSpeedPropagationDelayModel";
    // Loss propagation model
    std::string propagationLossModel = "LogDistancePropagationLossModel";

    /* Energy-related parameters 
    // Tx current draw in mA
    double txCurrent = 107;
    // Rx current draw in mA
    double rxCurrent = 40;
    // CCA_Busy current draw in mA
    double ccaBusyCurrent = 1;
    // Idle current draw in mA
    double idleCurrent = 1;
    
    // Uncertain fields
    double tx = 0.52;  // in W
    double rx = 0.16;  // in W
    double txFactor = 0.93; // in mJ
    double rxFactor = 0.93; // in mJ
    // Uncertain ends
    double voltage = 12; // in W
    double batteryCap = 5200; // Battery capacity in mAh
    */
    
    float enbLocations[8][2] = {{42.88877399624981, -78.8772842010498},
        {42.88823946201802, -78.87820688095093},
        {42.88781497565173, -78.8804170211792},
        {42.88899409723419, -78.87947288360596},
        {42.888585337638126, -78.8779493888855},
        {42.88863250234514, -78.87968746032715},
        {42.88767347954715, -78.8785072883606},
        {42.88907270453826, -78.88078180160522}};
    float ueLocations[12][2] = {{42.887264711199556, -78.87664047088623},
        {42.88638427786601, -78.87666192855835},
        {42.88847528651483, -78.87573924865723},
        {42.88680877407775, -78.87960162963867},
        {42.886714441838706, -78.88067451324463},
        {42.88636855572801, -78.8785072883606},
        {42.8852994409423, -78.88018098678589},
        {42.88468626380735, -78.87567487564087},
        {42.88503215935073, -78.87758460845947},
        {42.88490637937754, -78.87872186508179},
        {42.88627422281574, -78.88013807144165},
        {42.88688738416677, -78.87711253967285}};
    CommandLine cmd (__FILE__);

    cmd.AddValue ("simulationTime", "Simulation time in seconds", simulationTime);
    cmd.AddValue ("txPower", "TxPower in dBm", txPower);
    cmd.AddValue ("payloadSize", "Payload size in Bytes", payloadSize);
    cmd.AddValue ("channelWidth", "Channel Width in MHz", channelWidth);
    cmd.AddValue ("propDelay", "Delay Propagation Model", propDelay);
    cmd.AddValue ("propLoss", "Distance Propagation Model", propLoss);
    cmd.AddValue ("period", "Packet period in S", period);
    cmd.AddValue ("trafficDirection", "Direction of traffic UL/DL", trafficDirection);
    cmd.AddValue("numerology", "The numerology to be used in bandwidth part 1", numerology);
    cmd.AddValue("centralFrequencyBand1", "The system frequency to be used in band 1", centralFrequencyBand1);
    cmd.Parse (argc,argv);

    // enable logging or not
    bool logging = true;
    if (logging)
    {
        LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
        LogComponentEnable("UdpServer", LOG_LEVEL_INFO);
        //LogComponentEnable("LtePdcp", LOG_LEVEL_INFO);

        LogComponentEnableAll (LOG_PREFIX_FUNC);
        LogComponentEnableAll (LOG_PREFIX_NODE);
        LogComponentEnableAll (LOG_PREFIX_TIME);
    }

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

    gNbNodes.Create(numGnbs);
    ueNodes.Create(numUes);

    // Install Mobility Model
    MobilityHelper mobility;
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(gNbNodes);
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(ueNodes);

    // Set position of each node
    // GNBS
    for (int i = 0; i < gNbNodes.GetN(); i++) {
        // Translate from lat/lng to rectangular coordinates, in kilometers
        float x = 6371*cos(enbLocations[i][0]*3.14159/180) * cos(enbLocations[i][0]*3.14159/180);
        float y = 6371*cos(enbLocations[i][0]*3.14159/180) * sin(enbLocations[i][0]*3.14159/180);
        float z = 6371*sin(enbLocations[i][0]*3.14159/180);

        // Set the position
        Ptr<ConstantPositionMobilityModel> mm = gNbNodes.Get (i)->GetObject<ConstantPositionMobilityModel>();
        mm->SetPosition(Vector(x,y,z));
    }

    // UES
    for (int i = 0; i < ueNodes.GetN(); i++) {
        // Translate from lat/lng to rectangular coordinates, in kilometers
        float x = 6371*cos(ueLocations[i][0]*3.14159/180) * cos(ueLocations[i][0]*3.14159/180);
        float y = 6371*cos(ueLocations[i][0]*3.14159/180) * sin(ueLocations[i][0]*3.14159/180);
        float z = 6371*sin(ueLocations[i][0]*3.14159/180);

        // Set the position
        Ptr<ConstantPositionMobilityModel> mm = ueNodes.Get (i)->GetObject<ConstantPositionMobilityModel>();
        mm->SetPosition(Vector(x,y,z));
    }

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

    // create the internet and install the IP stack on the UEs
    // get SGW/PGW and create a single RemoteHost
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

    Ipv4InterfaceContainer ueIpIface = epcHelper->AssignUeIpv4Address(NetDeviceContainer(ueNetDev));

    // Set the default gateway for the UEs
    for (uint32_t j = 0; j < ueNodes.GetN(); ++j)
    {
        Ptr<Ipv4StaticRouting> ueStaticRouting =
            ipv4RoutingHelper.GetStaticRouting(ueNodes.Get(j)->GetObject<Ipv4>());
        ueStaticRouting->SetDefaultRoute(epcHelper->GetUeDefaultGatewayAddress(), 1);
    }

    // attach UEs to the closest eNB
    nrHelper->AttachToClosestEnb(ueNetDev, gNbNetDev);

    // assign IP address to UEs, and install UDP downlink applications
    uint16_t dlPort = 1234;

    ApplicationContainer serverApps;

    // The sink will always listen to the specified ports
    UdpServerHelper dlPacketSinkHelper(dlPort);
    serverApps.Add(dlPacketSinkHelper.Install(remoteHost));
    
    // The bearer that will carry low latency traffic
    EpsBearer bearer(EpsBearer::GBR_CONV_VOICE);

    Ptr<EpcTft> tft = Create<EpcTft>();
    EpcTft::PacketFilter dlpf;
    dlpf.localPortStart = dlPort;
    dlpf.localPortEnd = dlPort;
    tft->Add(dlpf);

    UdpClientHelper dlClient;
    dlClient.SetAttribute("RemotePort", UintegerValue(dlPort));
    dlClient.SetAttribute("PacketSize", UintegerValue(payloadSize));
    dlClient.SetAttribute("MaxPackets", UintegerValue(0xFFFFFFFF));
    dlClient.SetAttribute("Interval", TimeValue(Seconds(std::stod(period))));

    ApplicationContainer clientApps;

    for (uint32_t i = 0; i < ueNodes.GetN(); ++i)
    {
        Ptr<Node> ue = ueNodes.Get(i);
        Ptr<NetDevice> ueDevice = ueNetDev.Get(i);
        Address ueAddress = ueIpIface.GetAddress(i);

        // The client, who is transmitting, is installed in the remote host,
        // with destination address set to the address of  the UE
        dlClient.SetAttribute("RemoteAddress", AddressValue(Ipv4Address("1.0.0.2")));
        clientApps.Add(dlClient.Install(ue));

        // Activate a dedicated bearer for the traffic type
        nrHelper->ActivateDedicatedEpsBearer(ueDevice, bearer, tft);
    }

    serverApps.Start(Seconds(0.0));
    clientApps.Start(Seconds(0.0));
    serverApps.Stop(Seconds(simulationTime+2));
    clientApps.Stop(Seconds(simulationTime+2));

    //std::cout << "\n Sending data in uplink." << std::endl;
    //Simulator::Schedule(Seconds(0.2), &ConnectUlPdcpRlcTraces);

    nrHelper->EnableTraces();


  // *** Création du flowMonitor et lancement de la simulation ***
    Ptr<FlowMonitor> flowMonitor;
    FlowMonitorHelper flowHelper;
    flowMonitor = flowHelper.InstallAll();

    /*/ Starting simulation /*/
    Simulator::Stop (Seconds (simulationTime + 2));
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

    double avg_delay = totalDelay / numUes;

    double pdr = (double)(total_packet_received * 100) / (double)total_packet;

    std::cout << "Latency: " << avg_delay << std::endl;
    std::cout << "Throughput: " << datarate / simulationTime << std::endl;

    Simulator::Destroy();
    return 0;
}
