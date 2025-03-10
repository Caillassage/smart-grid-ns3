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

using namespace ns3;

/*
 * Enable the logs of the file by enabling the component "Cttc3gppChannelSimpleRan",
 * in this way:
 * $ export NS_LOG="Cttc3gppChannelSimpleRan=level_info|prefix_func|prefix_time"
 */
NS_LOG_COMPONENT_DEFINE("Cttc3gppChannelSimpleRan");

static bool g_rxPdcpCallbackCalled = false;
static bool g_rxRxRlcPDUCallbackCalled = false;

/**
 * Function that prints out PDCP delay. This function is designed as a callback
 * for PDCP trace source.
 * @param path The path that matches the trace source
 * @param rnti RNTI of UE
 * @param lcid logical channel id
 * @param bytes PDCP PDU size in bytes
 * @param pdcpDelay PDCP delay
 */
void
RxPdcpPDU(std::string path, uint16_t rnti, uint8_t lcid, uint32_t bytes, uint64_t pdcpDelay)
{
    std::cout << "Packet PDCP delay:" << pdcpDelay << "\n";
    g_rxPdcpCallbackCalled = true;
}

/**
 * Function that prints out RLC statistics, such as RNTI, lcId, RLC PDU size,
 * delay. This function is designed as a callback
 * for RLC trace source.
 * @param path The path that matches the trace source
 * @param rnti RNTI of UE
 * @param lcid logical channel id
 * @param bytes RLC PDU size in bytes
 * @param rlcDelay RLC PDU delay
 */
void
RxRlcPDU(std::string path, uint16_t rnti, uint8_t lcid, uint32_t bytes, uint64_t rlcDelay)
{
    std::cout << "Data received at RLC layer at:" << Simulator::Now() << std::endl;
    std::cout << "rnti:" << rnti << std::endl;
    std::cout << "lcid:" << (unsigned)lcid << std::endl;
    std::cout << "bytes :" << bytes << std::endl;
    std::cout << "delay :" << rlcDelay << std::endl;
    g_rxRxRlcPDUCallbackCalled = true;
}

/**
 * Function that connects PDCP and RLC traces to the corresponding trace sources.
 */
void
ConnectPdcpRlcTraces()
{
    Config::Connect("/NodeList/*/DeviceList/*/LteUeRrc/DataRadioBearerMap/1/LtePdcp/RxPDU",
                    MakeCallback(&RxPdcpPDU));

    Config::Connect("/NodeList/*/DeviceList/*/LteUeRrc/DataRadioBearerMap/1/LteRlc/RxPDU",
                    MakeCallback(&RxRlcPDU));
}

/**
 * Function that connects UL PDCP and RLC traces to the corresponding trace sources.
 */
void
ConnectUlPdcpRlcTraces()
{
    Config::Connect("/NodeList/*/DeviceList/*/LteEnbRrc/UeMap/*/DataRadioBearerMap/*/LtePdcp/RxPDU",
                    MakeCallback(&RxPdcpPDU));

    Config::Connect("/NodeList/*/DeviceList/*/LteEnbRrc/UeMap/*/DataRadioBearerMap/*/LteRlc/RxPDU",
                    MakeCallback(&RxRlcPDU));
}

int
main(int argc, char* argv[])
{
    // Set frequency and bandwidth
    double freq = 3.5e9; // 3.5 GHz
    double bandwidth = 20e6; // 20 MHz

    uint32_t seed = 1;

    // Set subcarrier spacing and slot duration
    //double subcarrierSpacing = 30e3; // 30 kHz
    //double slotDuration = 0.5e-3; // 0.5 ms
    uint8_t numerology = 1; // μ = 1

    // Set packet size and inter-arrival time
    //uint32_t packetSizeBits = 15 * 1000; // 15 Kbits
    uint32_t packetSizeBytes = 6000; // 6000 Bytes
    Time interArrivalTime = MilliSeconds(100); // 100 ms

    // Set transmission power
    double gNbTxPower = 40; // 40 W
    double ueTxPower = 23; // 23 dBm

    // Set node heights
    double gNbHeight = 25.0; // 25 meters
    double ueHeight = 1.5; // 1.5 meters

    // Set BLER
    double bler = 0.0001; // Adjusted BLER to 0.0001

    // Set PRBs
    uint32_t numPrb = 51; // Number of PRBs per time slot
    double p = 1.0; // Full Grid usage,  If ≤ 1, then p% of PRBs are used

    // Set channel model and fading
    std::string channelModel = "UMa"; // Urban Macro
    bool largeScaleFading = true; // Based on 3GPP TS 38.901
    bool smallScaleFading = true; // Rayleigh fading

    // Set antenna configuration
    uint32_t numGnbAntennas = 64; // Number of gNB antennas
    uint32_t numUeAntennas = 1; // Number of gNB antennas

    // Set scenario
    std::string scenario = "SU-MIMO"; // Single User MIMO
    bool interferenceModel = false; // No Interference Model

    // Set number of UEs
    uint32_t numUes = 1; // Number of UEs

    // Set HARQ
    bool harqEnabled = false; // HARQ Disabled

    // Set MCS
    std::string mcsTable = "McsTable1"; // MCS Table 1 3GPP (64 QAM)
    std::string errorModel = "ns3::NrEesmCcT1";  // MCS Table 1 3GPP (64 QAM)

    // Set DL/UL ratio
    double dlUlRatio = 1.0 / 4.0; // DL/UL ratio 1:4
    std::string pattern =
        "DL|DL|UL|UL|UL|UL|UL|UL|UL|UL|"; // Pattern can be e.g. "DL|S|UL|UL|DL|DL|S|UL|UL|DL|"

    // Set distance step size
    double distanceStepSize = 10;/* Define your step size here */

    uint16_t gNbNum = 1;
    bool singleUeTopology = true;

    double simTime = 60; // seconds

    CommandLine cmd(__FILE__);
    cmd.AddValue("numerology", "The numerology to be used in bandwidth part 1", numerology);
    cmd.AddValue("freq",
                 "The system frequency to be used in band 1",
                 freq);
    cmd.AddValue("bandwidth", "The system bandwidth to be used in band 1", bandwidth);
    cmd.AddValue("packetSize", "packet size in bytes", packetSizeBytes);
    cmd.AddValue("singleUeTopology", "Enable a topology with a single UE and a single gNB", singleUeTopology);
    cmd.AddValue("distanceStepSize", "Distance step size between UEs", distanceStepSize);
    cmd.AddValue("seed", "Seed for random number generator", seed);
    cmd.Parse(argc, argv);

    // enable logging or not
    bool logging = true;
    if (logging)
    {
        LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
        LogComponentEnable("UdpServer", LOG_LEVEL_INFO);
        LogComponentEnable("NrAmc", LOG_LEVEL_INFO);
        LogComponentEnable("NrPhy", LOG_LEVEL_INFO);

        LogComponentEnableAll (LOG_PREFIX_FUNC);
        LogComponentEnableAll (LOG_PREFIX_NODE);
        LogComponentEnableAll (LOG_PREFIX_TIME);
    }

    // Set the random seed
    SeedManager::SetSeed(seed);

    std::string propLoss;
    propLoss = "ThreeGppUmaPropagationLossModel";

    Ptr<NrPointToPointEpcHelper> epcHelper = CreateObject<NrPointToPointEpcHelper>();
    Ptr<IdealBeamformingHelper> idealBeamformingHelper = CreateObject<IdealBeamformingHelper>();
    Ptr<NrHelper> nrHelper = CreateObject<NrHelper>();

    //nrHelper->SetAttribute("PathlossModel",StringValue(propLoss));
    nrHelper->SetAttribute("HarqEnabled", BooleanValue(harqEnabled));

    nrHelper->SetBeamformingHelper(idealBeamformingHelper);
    nrHelper->SetEpcHelper(epcHelper);

    // Create one operational band containing one CC with one bandwidth part
    BandwidthPartInfoPtrVector allBwps;
    CcBwpCreator ccBwpCreator;
    const uint8_t numCcPerBand = 1;

    // Create the configuration for the CcBwpHelper
    CcBwpCreator::SimpleOperationBandConf bandConf1(freq,
                                                    bandwidth,
                                                    numCcPerBand,
                                                    BandwidthPartInfo::UMa);

    // By using the configuration created, it is time to make the operation band
    OperationBandInfo band1 = ccBwpCreator.CreateOperationBandContiguousCc(bandConf1);

    Config::SetDefault("ns3::ThreeGppChannelModel::UpdatePeriod", TimeValue(MilliSeconds(0)));
    nrHelper->SetSchedulerAttribute("FixedMcsDl", BooleanValue(true));
    nrHelper->SetSchedulerAttribute("StartingMcsDl", UintegerValue(28));
    //nrHelper->SetSchedulerAttribute("EnableHarqReTx", BooleanValue(harqEnabled));
    nrHelper->SetChannelConditionModelAttribute("UpdatePeriod", TimeValue(MilliSeconds(0)));
    nrHelper->SetPathlossAttribute("ShadowingEnabled", BooleanValue(false));
    
    Config::SetDefault("ns3::NrAmc::ErrorModelType", TypeIdValue(TypeId::LookupByName(errorModel)));
    Config::SetDefault("ns3::NrAmc::AmcModel",
                       EnumValue(NrAmc::ErrorModel)); // NrAmc::ShannonModel or NrAmc::ErrorModel
    
    // Error Model: UE and GNB with same spectrum error model.
    nrHelper->SetUlErrorModel(errorModel);
    nrHelper->SetDlErrorModel(errorModel);

    // Both DL and UL AMC will have the same model behind.
    nrHelper->SetGnbDlAmcAttribute(
        "AmcModel",
        EnumValue(NrAmc::ErrorModel)); // NrAmc::ShannonModel or NrAmc::ErrorModel
    nrHelper->SetGnbUlAmcAttribute(
        "AmcModel",
        EnumValue(NrAmc::ErrorModel)); // NrAmc::ShannonModel or NrAmc::ErrorModel

    nrHelper->InitializeOperationBand(&band1);
    allBwps = CcBwpCreator::GetAllBwps({band1});

    // Beamforming method
    idealBeamformingHelper->SetAttribute("BeamformingMethod",
                                         TypeIdValue(DirectPathBeamforming::GetTypeId()));

    uint32_t numRowsUe = numGnbAntennas / 2;
    uint32_t numColumnsUe = 2;
    // Antennas for all the gNbs
    nrHelper->SetGnbAntennaAttribute("NumRows", UintegerValue(numRowsUe));
    nrHelper->SetGnbAntennaAttribute("NumColumns", UintegerValue(numColumnsUe));
    // Antennas for all the UEs
    nrHelper->SetUeAntennaAttribute("NumRows", UintegerValue(1));
    nrHelper->SetUeAntennaAttribute("NumColumns", UintegerValue(1));
    nrHelper->SetUeAntennaAttribute("AntennaElement",
                                    PointerValue(CreateObject<IsotropicAntennaModel>()));

    uint32_t numRowsGnb = numGnbAntennas / 8;
    uint32_t numColumnsGnb = 8;
    // Antennas for all the gNbs
    nrHelper->SetGnbAntennaAttribute("NumRows", UintegerValue(numRowsGnb));
    nrHelper->SetGnbAntennaAttribute("NumColumns", UintegerValue(numColumnsGnb));
    nrHelper->SetGnbAntennaAttribute("AntennaElement",
                                     PointerValue(CreateObject<IsotropicAntennaModel>()));

    /*
     *  Create the gNB and UE nodes according to the network topology
     */
    NodeContainer gNbNodes;
    NodeContainer ueNodes;
    MobilityHelper mobility;
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    Ptr<ListPositionAllocator> bsPositionAlloc = CreateObject<ListPositionAllocator>();
    Ptr<ListPositionAllocator> utPositionAlloc = CreateObject<ListPositionAllocator>();


    if (singleUeTopology) {
        gNbNodes.Create(1);
        ueNodes.Create(1);
        gNbNum = 1;
        numUes = 1;
        bsPositionAlloc->Add(Vector(0.0, 0.0, gNbHeight));
        utPositionAlloc->Add(Vector(0.0, distanceStepSize, ueHeight));
    }
    else {
        gNbNodes.Create(gNbNum);
        ueNodes.Create(numUes * gNbNum);

        int32_t yValue = 0.0;
        for (uint32_t i = 1; i <= gNbNodes.GetN(); ++i) {
            // 2.0, -2.0, 6.0, -6.0, 10.0, -10.0, ....
            if (i % 2 != 0)
            {
                yValue = static_cast<int>(i) * 30;
            }
            else
            {
                yValue = -yValue;
            }

            bsPositionAlloc->Add(Vector(0.0, yValue, gNbHeight));

            // 1.0, -1.0, 3.0, -3.0, 5.0, -5.0, ...
            double xValue = 0.0;
            for (uint16_t j = 1; j <= numUes; ++j)
            {
                if (j % 2 != 0)
                {
                    xValue = j;
                }
                else
                {
                    xValue = -xValue;
                }

                if (yValue > 0)
                {
                    utPositionAlloc->Add(Vector(xValue, 1, ueHeight));
                }
                else
                {
                    utPositionAlloc->Add(Vector(xValue, -1, ueHeight));
                }
            }
        }
    }

    mobility.SetPositionAllocator(bsPositionAlloc);
    mobility.Install(gNbNodes);

    mobility.SetPositionAllocator(utPositionAlloc);
    mobility.Install(ueNodes);

     // Install nr net devices
    NetDeviceContainer gNbNetDev = nrHelper->InstallGnbDevice(gNbNodes, allBwps);
    NetDeviceContainer ueNetDev = nrHelper->InstallUeDevice(ueNodes, allBwps);

    // UE transmit power
    nrHelper->SetUePhyAttribute("TxPower", DoubleValue(ueTxPower));

    int64_t randomStream = 1;
    randomStream += nrHelper->AssignStreams(gNbNetDev, randomStream);
    randomStream += nrHelper->AssignStreams(ueNetDev, randomStream);

    for (uint32_t i = 0; i < gNbNodes.GetN(); ++i) { 
        // Set the attribute of the netdevice (enbNetDev.Get (0)) and bandwidth part (0)
        // gNB Transmit power
        nrHelper->GetGnbPhy(gNbNetDev.Get(i), 0)->SetAttribute("TxPower", DoubleValue(gNbTxPower));
        nrHelper->GetGnbPhy(gNbNetDev.Get(i), 0)->SetAttribute("Pattern", StringValue(pattern));
        nrHelper->GetGnbPhy(gNbNetDev.Get(i), 0) ->SetAttribute("Numerology", UintegerValue(numerology));
    }

    for (auto it = gNbNetDev.Begin(); it != gNbNetDev.End(); ++it) {
        DynamicCast<NrGnbNetDevice>(*it)->UpdateConfig();
    }

    for (auto it = ueNetDev.Begin(); it != ueNetDev.End(); ++it) {
        DynamicCast<NrUeNetDevice>(*it)->UpdateConfig();
    }

    InternetStackHelper internet;
    internet.Install(ueNodes);
    Ipv4InterfaceContainer ueIpIface, gnbIpIface;
    ueIpIface = epcHelper->AssignUeIpv4Address(NetDeviceContainer(ueNetDev));
    gnbIpIface = epcHelper->AssignUeIpv4Address(NetDeviceContainer(gNbNetDev));

    // attach UEs to the closest eNB
    nrHelper->AttachToClosestEnb(ueNetDev, gNbNetDev);

    // assign IP address to UEs, and install UDP downlink applications
    uint16_t dlPort = 1234;

    ApplicationContainer serverApps;

    // The sink will always listen to the specified ports
    UdpServerHelper dlPacketSinkHelper(dlPort);
    serverApps.Add(dlPacketSinkHelper.Install(gNbNodes));

    UdpClientHelper dlClient;
    dlClient.SetAttribute("RemotePort", UintegerValue(dlPort));
    dlClient.SetAttribute("PacketSize", UintegerValue(packetSizeBytes));
    dlClient.SetAttribute("MaxPackets", UintegerValue(0xFFFFFFFF));

    dlClient.SetAttribute("Interval", TimeValue(interArrivalTime));

    // The bearer that will carry low latency traffic
    EpsBearer bearer(EpsBearer::GBR_CONV_VOICE);

    Ptr<EpcTft> tft = Create<EpcTft>();
    EpcTft::PacketFilter dlpf;
    dlpf.localPortStart = dlPort;
    dlpf.localPortEnd = dlPort;
    tft->Add(dlpf);

    /*
    * Let's install the applications!
    */
    ApplicationContainer clientApps;

    for (uint32_t i = 0; i < ueNodes.GetN(); ++i) {
        Ptr<Node> ue = ueNodes.Get(i);
        Ptr<NetDevice> ueDevice = ueNetDev.Get(i);
        Address gnbAddress = gnbIpIface.GetAddress(0);

        dlClient.SetAttribute("RemoteAddress", AddressValue(gnbAddress));
        clientApps.Add(dlClient.Install(ue));

        // Activate a dedicated bearer for the traffic type
        nrHelper->ActivateDedicatedEpsBearer(ueDevice, bearer, tft);
    }

    // start server and client apps
    //serverApps.Start(Seconds(1.0));
    //clientApps.Start(Seconds(1.0));
    //serverApps.Stop(Seconds(simTime));
    //clientApps.Stop(Seconds(simTime));

    std::cout << "\n Sending data in uplink." << std::endl;
    //Simulator::Schedule(Seconds(0.2), &ConnectUlPdcpRlcTraces);

    nrHelper->EnableTraces();

    // *** Création du flowMonitor et lancement de la simulation ***
    Ptr<FlowMonitor> flowMonitor;
    FlowMonitorHelper flowHelper;
    flowMonitor = flowHelper.InstallAll();

    Simulator::Stop(Seconds(simTime));
    Simulator::Run();
    Simulator::Destroy();

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
    std::cout << "Throughput: " << datarate / simTime << std::endl;

    std::cout << std::fixed;
    // std::cout << std::setprecision(2);

    /*
    if (g_rxPdcpCallbackCalled && g_rxRxRlcPDUCallbackCalled)
    {
        return EXIT_SUCCESS;
    }
    else
    {
        return EXIT_FAILURE;
    }
    */
}
