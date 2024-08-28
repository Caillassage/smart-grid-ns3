#include "ns3/command-line.h"
#include "ns3/config.h"
#include "ns3/uinteger.h"
#include "ns3/boolean.h"
#include "ns3/double.h"
#include "ns3/string.h"
#include "ns3/log.h"
#include "ns3/yans-wifi-helper.h"
#include "ns3/ssid.h"
#include "ns3/mobility-helper.h"
#include "ns3/internet-stack-helper.h"
#include "ns3/ipv4-address-helper.h"
#include "ns3/udp-client-server-helper.h"
#include "ns3/packet-sink-helper.h"
#include "ns3/on-off-helper.h"
#include "ns3/ipv4-global-routing-helper.h"
#include "ns3/packet-sink.h"
#include "ns3/wifi-net-device.h"
#include "ns3/wifi-mac-header.h"
#include "ns3/wifi-mac.h"
#include "ns3/yans-wifi-channel.h"
#include "ns3/core-module.h"
#include "ns3/energy-module.h"
#include "ns3/wifi-radio-energy-model-helper.h"
#include "ns3/applications-module.h"
#include "ns3/propagation-loss-model.h"
#include "ns3/propagation-delay-model.h"
#include "ns3/flow-monitor-helper.h"
#include <iomanip>
#include "ns3/constant-position-mobility-model.h"
using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("wifi-periodic");

 void
 RemainingEnergy (double oldValue, double remainingEnergy)
 {
   NS_LOG_UNCOND (Simulator::Now ().GetSeconds ()
                  << "s Current remaining energy = " << remainingEnergy << "J");
 }
 
 void
 TotalEnergy (double oldValue, double totalEnergy)
 {
   NS_LOG_UNCOND (Simulator::Now ().GetSeconds ()
                  << "s Total energy consumed by radio = " << totalEnergy << "J");
 }

int main (int argc, char *argv[]) {
  SeedManager::SetSeed (3);  // Changes seed from default of 1 to 3
  SeedManager::SetRun (2);  // Changes run number from default of 1 to 7
  /*/ Input parameters definition /*/
  // Seconds
  double simulationTime = 6;
  std::string propDelay = "ConstantSpeedPropagationDelayModel";
  std::string propLoss = "LogDistancePropagationLossModel";
  // Number of stations
  int nWifi = 12;
  // Number of AP
  int nAP = 2;
  // Modulation and Coding Scheme
  int MCS = 1;
  //-TxPower
  int txPower = 5; // Assuming tx_current represents the TxPower
  // Traffic direction
  std::string trafficDirection = "upstream";
  // Payload size in bytes
  int payloadSize = 1024;
  // Packet period in seconds
  std::string period = "1";
  // Meters between AP and stations
  double distance = 1.0;
  //-Allow or not the packet aggregation
  bool agregation = false;
  // BW Channel Width in MHz
  int channelWidth = 20;
  //-Indicates whether Short Guard Interval is enabled or not
  int sgi = 0;
  // Advanced parameters
  // Delay propagation model
  std::string propagationDelayModel = "ConstantSpeedPropagationDelayModel";
  // Loss propagation model
  std::string propagationLossModel = "LogDistancePropagationLossModel";
  // Number of spatial streams
  int spatialStreams = 4;
  // Tx current draw in mA
  double txCurrent = 107;
  // Rx current draw in mA
  double rxCurrent = 40;
  // CCA_Busy current draw in mA
  double ccaBusyCurrent = 1;
  // Idle current draw in mA
  double idleCurrent = 1;
  // Uncertain fields
  bool latency = true;
  bool energyPower = true;
  bool batteryRV = false;
  // Uncertain ends
  bool hiddenStations = false;

  // Energy parameters
  // Uncertain ends
  double voltage = 12; // in W
  double batteryCap = 5200; // Battery capacity in mAh

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

  cmd.AddValue ("distance", "Distance in meters between the station and the access point", distance);
  cmd.AddValue ("simulationTime", "Simulation time in seconds", simulationTime);
  cmd.AddValue ("MCS", "MCS", MCS);
  cmd.AddValue ("txPower", "TxPower in dBm", txPower);
  cmd.AddValue ("payloadSize", "Payload size in Bytes", payloadSize);
  cmd.AddValue ("channelWidth", "Channel Width in MHz", channelWidth);
  cmd.AddValue ("propDelay", "Delay Propagation Model", propDelay);
  cmd.AddValue ("propLoss", "Distance Propagation Model", propLoss);
  cmd.AddValue ("spatialStreams", "Number of Spatial Streams", spatialStreams);
  cmd.AddValue ("batteryCap", "Battery Capacity in mAh", batteryCap);
  cmd.AddValue ("voltage", "Battery voltage in Volts", voltage);
  cmd.AddValue ("txCurrent", "Tx current draw in mA", txCurrent);
  cmd.AddValue ("rxCurrent", "Rx current draw in mA", rxCurrent);
  cmd.AddValue ("idleCurrent", "Idle current draw in mA", idleCurrent);
  cmd.AddValue ("ccaBusyCurrent", "CCA Busy voltage in Volts", ccaBusyCurrent);
  cmd.AddValue ("period", "Packet period in S", period);
  cmd.AddValue ("nWifi", "Number of stations", nWifi);
  cmd.AddValue ("trafficDirection", "Direction of traffic UL/DL", trafficDirection);
  cmd.AddValue ("latency", "Time a probing packets takes", latency);
  cmd.AddValue ("energyPower", "Energy consumption in Watts", energyPower);
  cmd.AddValue ("batteryRV", "Whether to use the RV model or not", batteryRV);
  cmd.AddValue ("hiddenStations", "If there are hidden nodes or not", hiddenStations);
  cmd.Parse (argc,argv);

  // enable logging or not
  bool logging = true;
  if (logging)
  {
      LogComponentEnable("UdpClient", LOG_LEVEL_INFO);
      LogComponentEnable("PacketSink", LOG_LEVEL_INFO);
      //LogComponentEnable("LtePdcp", LOG_LEVEL_INFO);

      LogComponentEnableAll (LOG_PREFIX_FUNC);
      LogComponentEnableAll (LOG_PREFIX_NODE);
      LogComponentEnableAll (LOG_PREFIX_TIME);
  }

  YansWifiChannelHelper channel;
  channel.AddPropagationLoss ("ns3::"+propLoss);
  channel.SetPropagationDelay("ns3::"+propDelay);

  /*/ Nodes creation and placement /*/
  NodeContainer wifiStaNodes;
  wifiStaNodes.Create (nWifi);
  NodeContainer wifiApNode;
  wifiApNode.Create (nAP);

  NodeContainer wifiProbingNode;

  /*if (latency) {
    wifiProbingNode.Create (1);
  }*/

   // Setting mobility model
  MobilityHelper mobility;
  Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator> ();

  if (hiddenStations) {
    Config::SetDefault ("ns3::WifiRemoteStationManager::RtsCtsThreshold", StringValue ("999999"));
    // Set the maximum wireless range to 5 meters in order to reproduce a hidden nodes scenario, i.e. the distance between hidden stations is larger than 5 meters
    Config::SetDefault ("ns3::RangePropagationLossModel::MaxRange", DoubleValue (distance));

    channel.AddPropagationLoss ("ns3::RangePropagationLossModel"); //wireless range limited to (distance) meters! 

    positionAlloc->Add (Vector (distance, 0.0, 0.0));
    
    for (uint32_t i = 0; i < nWifi/2 ; i++) {
      positionAlloc->Add (Vector (0.0, 0.0, 0.0));
    }
    for (uint32_t i = 0; i < nWifi/2; i++) {
      positionAlloc->Add (Vector (2*distance, 0.0, 0.0));
    }
    // AP is between the two stations, each station being located at 5 meters from the AP.
    // The distance between the two stations is thus equal to 10 meters.
    // Since the wireless range is limited to 5 meters, the two stations are hidden from each other.
    
    mobility.SetPositionAllocator (positionAlloc);

    mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");

    mobility.Install (wifiApNode);
    mobility.Install (wifiStaNodes);
  }
  else {
    // Install Mobility Model
    MobilityHelper mobility;
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(wifiApNode);
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(wifiStaNodes);

    // Set position of each node
    // ENBS
    for (int i = 0; i < nAP; i++) {
        // Translate from lat/lng to rectangular coordinates, in kilometers
        float x = 6371*cos(enbLocations[i][0]*3.14159/180) * cos(enbLocations[i][0]*3.14159/180);
        float y = 6371*cos(enbLocations[i][0]*3.14159/180) * sin(enbLocations[i][0]*3.14159/180);
        float z = 6371*sin(enbLocations[i][0]*3.14159/180);

        // Set the position
        Ptr<ConstantPositionMobilityModel> mm = wifiApNode.Get (i)->GetObject<ConstantPositionMobilityModel>();
        mm->SetPosition(Vector(x,y,z));
    }

    // UES
    for (int i = 0; i < nWifi; i++) {
        // Translate from lat/lng to rectangular coordinates, in kilometers
        float x = 6371*cos(ueLocations[i][0]*3.14159/180) * cos(ueLocations[i][0]*3.14159/180);
        float y = 6371*cos(ueLocations[i][0]*3.14159/180) * sin(ueLocations[i][0]*3.14159/180);
        float z = 6371*sin(ueLocations[i][0]*3.14159/180);

        // Set the position
        Ptr<ConstantPositionMobilityModel> mm = wifiStaNodes.Get (i)->GetObject<ConstantPositionMobilityModel>();
        mm->SetPosition(Vector(x,y,z));
    }
  }
  /* Layers installation */
  YansWifiPhyHelper phy;

  std::string channelStr = "";

  if (channelWidth == 20) {
    channelStr = "{36, 0, BAND_5GHZ, 0}";
  }
  else if (channelWidth == 40) {
    channelStr = "{38, 0, BAND_5GHZ, 0}";
  }
  else if (channelWidth == 80) {
     channelStr = "{42, 0, BAND_5GHZ, 0}";
  }
  else if (channelWidth == 160) {
     channelStr = "{50, 0, BAND_5GHZ, 0}";
  }

  phy.Set("ChannelSettings", StringValue(channelStr));

  phy.SetChannel (channel.Create ());

  WifiMacHelper mac;
  WifiHelper wifi;
  wifi.SetStandard (WIFI_STANDARD_80211ac);

  std::ostringstream oss;
  oss << "VhtMcs" << MCS;
  wifi.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                "DataMode", StringValue (oss.str ()),
                                "ControlMode", StringValue (oss.str ()));

  Ssid ssid = Ssid ("ns3-80211ac");

  // Installing phy & mac layers on the stations
  mac.SetType ("ns3::StaWifiMac",
              "Ssid", SsidValue (ssid));
  NetDeviceContainer staDevices;
  staDevices = wifi.Install (phy, mac, wifiStaNodes);

  NetDeviceContainer probingDevice;
  /*if (latency) {
    probingDevice = wifi.Install(phy, mac, wifiProbingNode);
  }*/

  // Installing phy & mac layers on the AP
  mac.SetType ("ns3::ApWifiMac",   
              "EnableBeaconJitter", BooleanValue (false),
              "Ssid", SsidValue (ssid));
  NetDeviceContainer apDevice;
  apDevice = wifi.Install (phy, mac, wifiApNode);


  /*/ Low-level parameters configuration /*/
  // Set channel width
  //Config::Set ("/NodeList/*/DeviceList/*/$ns3::WifiNetDevice/Phy/ChannelWidth", 
  //            UintegerValue (channelWidth));

  // Set guard interval
  Config::Set ("/NodeList/*/DeviceList/*/$ns3::WifiNetDevice/HtConfiguration/ShortGuardIntervalSupported",
              BooleanValue (sgi));


  /* Internet stack*/
  InternetStackHelper stack;
  stack.Install (wifiApNode);
  stack.Install (wifiStaNodes);

  /*if (latency) {
    stack.Install (wifiProbingNode);
  }*/

  /*/ IP addresses configuration /*/
  Ipv4AddressHelper address;
  address.SetBase ("10.0.0.0", "255.255.0.0");
  Ipv4InterfaceContainer ApInterface;
  ApInterface = address.Assign (apDevice);
  Ipv4InterfaceContainer StaInterface;
  StaInterface = address.Assign (staDevices);

  Ipv4InterfaceContainer wifiProbingInterface;
  /*if (latency) {
    wifiProbingInterface = address.Assign(probingDevice);
  }*/

  Ipv4GlobalRoutingHelper::PopulateRoutingTables ();

  /*/ Setting probing application /*/
  /*if (latency) {
    // UDP Echo Server application to be installed in the AP
    int echoPort = 11;
    UdpEchoServerHelper echoServer(echoPort); // Port # 9
    uint32_t payloadSizeEcho = 1023; //Packet size for Echo UDP App

    if (trafficDirection == "upstream") {
      ApplicationContainer serverApps = echoServer.Install(wifiApNode);
      serverApps.Start(Seconds(0.0));
      serverApps.Stop(Seconds(simulationTime+1));
      
      //wifiApInterface.GetAddress(0).Print(std::cout);
      // UDP Echo Client application to be installed in the probing station
      UdpEchoClientHelper echoClient1(ApInterface.GetAddress(0), echoPort);
      
      echoClient1.SetAttribute("MaxPackets", UintegerValue(10000));
      echoClient1.SetAttribute("Interval", TimeValue(Seconds(2)));
      echoClient1.SetAttribute("PacketSize", UintegerValue(payloadSizeEcho));

      ApplicationContainer clientApp = echoClient1.Install(wifiProbingNode);
      //commInterfaces.GetAddress(0).Print(std::cout);
      clientApp.Start(Seconds(1.0));
      clientApp.Stop(Seconds(simulationTime+1));
    }
    else {
      ApplicationContainer serverApps = echoServer.Install(wifiProbingNode);
      serverApps.Start(Seconds(0.0));
      serverApps.Stop(Seconds(simulationTime+1));

      // UDP Echo Client application to be installed in the probing station
      UdpEchoClientHelper echoClient1(wifiProbingInterface.GetAddress(0), echoPort);
      
      echoClient1.SetAttribute("MaxPackets", UintegerValue(10000));
      echoClient1.SetAttribute("Interval", TimeValue(Seconds(2)));
      echoClient1.SetAttribute("PacketSize", UintegerValue(payloadSizeEcho));

      ApplicationContainer clientApps = echoClient1.Install(wifiApNode);
      //commInterfaces.GetAddress(0).Print(std::cout);
      clientApps.Start(Seconds(1.0));
      clientApps.Stop(Seconds(simulationTime+1));
    }
  }*/

  if (agregation == false) {
    // Disable A-MPDU & A-MSDU in AP
    Ptr<NetDevice> dev = wifiApNode.Get(0)-> GetDevice(0);
    Ptr<WifiNetDevice> wifi_dev = DynamicCast<WifiNetDevice> (dev);
    wifi_dev->GetMac ()->SetAttribute ("BE_MaxAmpduSize", UintegerValue (0));
    wifi_dev->GetMac ()->SetAttribute ("BE_MaxAmsduSize", UintegerValue (0));
  }
  // Set txPower in the stations
  for (uint32_t index = 0; index < nWifi; ++index) {
    Ptr<WifiPhy> phy_tx = dynamic_cast<WifiNetDevice*>(GetPointer((staDevices.Get(index))))->GetPhy();
    phy_tx->SetTxPowerEnd(txPower);
    phy_tx->SetTxPowerStart(txPower);
  }

  // Set txPower in the AP
  for (uint32_t index = 0; index < nWifi; ++index) {
    Ptr<WifiPhy> phy_tx = dynamic_cast<WifiNetDevice*>(GetPointer((apDevice.Get(index))))->GetPhy();
    phy_tx->SetTxPowerEnd(txPower);
    phy_tx->SetTxPowerStart(txPower);
  }

  /*/ Setting traffic applications /*/
  ApplicationContainer sourceApplications, sinkApplications;
  uint32_t portNumber = 9;
  double min = 0.0;
  double max = 0.5;
  double periodSeconds = std::stof(period);

  if (trafficDirection == "upstream") {
    auto ipv4 = wifiApNode.Get (0)->GetObject<Ipv4> ();
    const auto address = ipv4->GetAddress (1, 0).GetLocal ();
    InetSocketAddress sinkSocket (address, portNumber);
    PacketSinkHelper packetSinkHelper ("ns3::UdpSocketFactory", sinkSocket);
    sinkApplications.Add (packetSinkHelper.Install (wifiApNode.Get (0)));
    
    for (uint32_t index = 0; index < nWifi; ++index) {
      if (agregation == false) {
        // Disable A-MPDU & A-MSDU in each station
        Ptr<NetDevice> dev = wifiStaNodes.Get (index)->GetDevice (0);
        Ptr<WifiNetDevice> wifi_dev = DynamicCast<WifiNetDevice> (dev);
        wifi_dev->GetMac ()->SetAttribute ("BE_MaxAmpduSize", 
                                          UintegerValue (0));
        wifi_dev->GetMac ()->SetAttribute ("BE_MaxAmsduSize", 
                                          UintegerValue (0));
      }
      
      // UDP Client application to be installed in the stations
      UdpClientHelper echoClient(address, portNumber);
    
      echoClient.SetAttribute("MaxPackets", UintegerValue(100000));
      echoClient.SetAttribute("Interval", TimeValue(Seconds(periodSeconds)));
      echoClient.SetAttribute("PacketSize", UintegerValue(payloadSize));

      // Desynchronize the sending applications
      Ptr<UniformRandomVariable> x = CreateObject<UniformRandomVariable> ();
      x->SetAttribute ("Min", DoubleValue (min));
      x->SetAttribute ("Max", DoubleValue (max));

      double value = 1 + x->GetValue ();

      ApplicationContainer sourceApplications = echoClient.Install (wifiStaNodes.Get(index));
      sourceApplications.Start(Seconds(value));
      sourceApplications.Stop(Seconds(simulationTime+value));
    }
  }
  else {
    for (uint32_t index = 0; index < nWifi; ++index) {
      if (agregation == false) {
        // Disable A-MPDU & A-MSDU in each station
        Ptr<NetDevice> dev = wifiStaNodes.Get (index)->GetDevice (0);
        Ptr<WifiNetDevice> wifi_dev = DynamicCast<WifiNetDevice> (dev);
        wifi_dev->GetMac ()->SetAttribute ("BE_MaxAmpduSize", UintegerValue (0));
        wifi_dev->GetMac ()->SetAttribute ("BE_MaxAmsduSize", UintegerValue (0));
      }

      auto ipv4 = wifiStaNodes.Get (index)->GetObject<Ipv4> ();
      const auto address = ipv4->GetAddress (1, 0).GetLocal ();
      InetSocketAddress sinkSocket (address, portNumber);
      
      // UDP Client application to be installed in the stations
      UdpClientHelper echoClient2(address, portNumber);
    
      echoClient2.SetAttribute("MaxPackets", UintegerValue(1000000));
      echoClient2.SetAttribute("Interval", TimeValue(Seconds(std::stof(period))));
      echoClient2.SetAttribute("PacketSize", UintegerValue(payloadSize));
      
      Ptr<UniformRandomVariable> x = CreateObject<UniformRandomVariable> ();
      x->SetAttribute ("Min", DoubleValue (min));
      x->SetAttribute ("Max", DoubleValue (max));

      double value = 1 + x->GetValue ();

      ApplicationContainer sourceApplications1 = echoClient2.Install (wifiApNode.Get(0));
      sourceApplications1.Start(Seconds(value));
      sourceApplications1.Stop(Seconds(simulationTime+value));
      
      PacketSinkHelper packetSinkHelper ("ns3::UdpSocketFactory", sinkSocket);
      sinkApplications.Add(packetSinkHelper.Install (wifiStaNodes.Get (index)));    
    }
  }
  /*/ Starting applications /*/
  sinkApplications.Start (Seconds (0.0));
  sinkApplications.Stop (Seconds (simulationTime + 2));

  /*/ Installing energy models /*/
  DeviceEnergyModelContainer deviceModels;

  double capacityJoules = (batteryCap / 1000.0) * voltage * 3600;

  WifiRadioEnergyModelHelper radioEnergyHelper;

  radioEnergyHelper.Set ("IdleCurrentA", DoubleValue (idleCurrent/1000));
  radioEnergyHelper.Set ("TxCurrentA", DoubleValue (txCurrent/1000));
  radioEnergyHelper.Set ("CcaBusyCurrentA", DoubleValue (ccaBusyCurrent/1000));
  radioEnergyHelper.Set ("RxCurrentA", DoubleValue (rxCurrent/1000));

  if (!batteryRV) { // If the battery model is linear
    BasicEnergySourceHelper basicSourceHelper;
    basicSourceHelper.Set ("BasicEnergySupplyVoltageV", 
                          DoubleValue (voltage));
    basicSourceHelper.Set ("BasicEnergySourceInitialEnergyJ", 
                          DoubleValue (capacityJoules));
    EnergySourceContainer sources = basicSourceHelper.Install(wifiStaNodes);

    deviceModels = radioEnergyHelper.Install (staDevices, sources);
  }
  else { // If the battery model is RV
    RvBatteryModelHelper rvModelHelper;
    rvModelHelper.Set ("RvBatteryModelOpenCircuitVoltage", 
                      DoubleValue(2*voltage));
    rvModelHelper.Set ("RvBatteryModelCutoffVoltage", 
                      DoubleValue(0)); 
    rvModelHelper.Set ("RvBatteryModelAlphaValue", 
                      DoubleValue(capacityJoules / voltage));
    EnergySourceContainer sources = rvModelHelper.Install(wifiStaNodes);
    WifiRadioEnergyModelHelper radioEnergyHelper;
    
    deviceModels = radioEnergyHelper.Install (staDevices, sources);
  }    
  //std::string s = "telemetry-23Bytes/"+std::to_string(nWifi)+"-"+period+"-"+std::to_string(MCS)+"-"+std::to_string(payloadSize);
  
  /*/ Traces files generation /*/
  AsciiTraceHelper ascii;
  phy.SetPcapDataLinkType (WifiPhyHelper::DLT_IEEE802_11_RADIO);
  //std::string s = "trace";
  //phy.EnableAsciiAll (ascii.CreateFileStream(s+".tr"));
  //phy.EnablePcap (s+".pcap", apDevice.Get(0), false, true);

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

    double avg_delay = totalDelay / nWifi;

    double pdr = (double)(total_packet_received * 100) / (double)total_packet;

    std::cout << "Latency: " << avg_delay << std::endl;

  std::cout << std::fixed;
  std::cout << std::setprecision(2);
  
  /*/ Gatherting KPIs /*/
  if (energyPower) {
    /*/ Calculating Energy KPIs /*/
    double battery_lifetime = 0;
    DeviceEnergyModelContainer::Iterator iter ;
    for (iter = deviceModels.Begin (); iter != deviceModels.End (); iter ++) {
      double energyConsumed = (*iter)->GetTotalEnergyConsumption ();
      NS_LOG_UNCOND ("End of simulation (" << Simulator::Now ().GetSeconds ()
                    << "s) Total energy consumed by radio (Station) = " 
                    << energyConsumed << "J");
      std::cout << "Total energy consumed by radio (Station): " 
                << energyConsumed << std::endl;
      battery_lifetime = ((capacityJoules / energyConsumed) * simulationTime);
      battery_lifetime = battery_lifetime / 86400; // Days
      std::cout << "Battery lifetime: " << battery_lifetime << std::endl;
      break; // Energy in only one station
    }
  }

  double totalPacketsThrough = 0, throughput = 0;
  if (trafficDirection == "upstream") {
    for (uint32_t index = 0; index < sinkApplications.GetN (); ++index) {
      totalPacketsThrough = DynamicCast<PacketSink> (sinkApplications.Get (index))
                                                    ->GetTotalRx ();
      throughput += ((totalPacketsThrough * 8) / ((simulationTime) * 1024 * 1024)); //Mbit/s
    }
  }
  else {
    for (uint32_t index = 0; index < sinkApplications.GetN (); ++index) {
      totalPacketsThrough += DynamicCast<PacketSink> (sinkApplications.Get (index))->GetTotalRx ();
      throughput += ((totalPacketsThrough * 8) / ((simulationTime) * 1024 * 1024)); //Mbit/s
    }
  }
  std::cout << "Throughput: " << throughput << std::endl;

  double totalSentPackets = (( 1 / periodSeconds * simulationTime ) * nWifi); // Estimation of number of generated packets in the network
  double totalReceivedPackets = totalPacketsThrough / payloadSize; // Number of total received packets

  //std::cout << totalReceivedPackets << " and " << totalSentPackets << std::endl;
  double wholeSuccessRate =  (totalReceivedPackets / totalSentPackets) * 100;
  std::cout << "Success rate: " <<  wholeSuccessRate << std::endl; // Success rate percentage
  
  Simulator::Destroy ();
  return 0;
}