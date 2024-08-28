# Install script for directory: /Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "default")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Library/Developer/CommandLineTools/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/build/lib/libns3.41-nr-default.dylib")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-nr-default.dylib" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-nr-default.dylib")
    execute_process(COMMAND /usr/bin/install_name_tool
      -delete_rpath "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/build/lib"
      -add_rpath "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64"
      "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-nr-default.dylib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Library/Developer/CommandLineTools/usr/bin/strip" -x "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-nr-default.dylib")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ns3" TYPE FILE FILES
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-phy-rx-trace.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-mac-rx-trace.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-point-to-point-epc-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-bearer-stats-calculator.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-bearer-stats-connector.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-bearer-stats-simple.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/beamforming-helper-base.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/ideal-beamforming-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/realistic-beamforming-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/node-distribution-scenario-interface.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/grid-scenario-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/hexagonal-grid-scenario-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/file-scenario-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/cc-bwp-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-radio-environment-map-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-spectrum-value-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/scenario-parameters.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/three-gpp-ftp-m1-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-stats-calculator.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/helper/nr-mac-scheduling-stats.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-net-device.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-gnb-net-device.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-ue-net-device.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-phy.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-gnb-phy.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-ue-phy.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-spectrum-phy.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-interference.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-pdu-info.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-header-vs.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-header-vs-ul.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-header-vs-dl.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-header-fs.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-header-fs-ul.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-header-fs-dl.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-short-bsr-ce.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-phy-mac-common.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-tdma-rr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-tdma-pf.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ofdma-rr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ofdma-pf.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-tdma-qos.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ofdma-qos.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-control-messages.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-spectrum-signal-parameters.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-radio-bearer-tag.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-amc.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-sched-sap.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-csched-sap.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-phy-sap.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-lte-mi-error-model.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-gnb-mac.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-ue-mac.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-rrc-protocol-ideal.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-harq-phy.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/bandwidth-part-gnb.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/bandwidth-part-ue.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/bwp-manager-gnb.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/bwp-manager-ue.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/bwp-manager-algorithm.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-harq-process.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-harq-vector.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-harq-rr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-cqi-management.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-lcg.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ns3.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-tdma.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ofdma.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ofdma-mr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-tdma-mr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ue-info.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ue-info-mr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ue-info-rr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ue-info-pf.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-ue-info-qos.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-lc-alg.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-lc-rr.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-lc-qos.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-error-model.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-t1.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-t2.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-ir.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-cc.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-ir-t1.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-ir-t2.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-cc-t1.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-eesm-cc-t2.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-error-model.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-ch-access-manager.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/beam-id.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/beamforming-vector.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/beam-manager.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/beamforming-algorithm.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/ideal-beamforming-algorithm.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/realistic-beamforming-algorithm.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/sfnsf.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/lena-error-model.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-srs.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mac-scheduler-srs-default.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-ue-power-control.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/realistic-bf-manager.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/distance-based-three-gpp-spectrum-propagation-loss-model.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-ftp-single.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-ngmn-ftp-multi.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-ngmn-video.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-ngmn-gaming.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-ngmn-voip.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-3gpp-pose-control.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-3gpp-audio-data.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/model/traffic-generator-3gpp-generic-video.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/helper/traffic-generator-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/utils/traffic-generators/helper/xr-traffic-mixer-helper.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-cb-two-port.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-cb-type-one.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mimo-chunk-processor.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mimo-matrices.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-pm-search-full.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-pm-search.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/src/nr/model/nr-mimo-signal.h"
    "/Users/samirsim/Desktop/Smart Power Grid/power-grid-ns3/ns-3.41/build/include/ns3/nr-module.h"
    )
endif()

