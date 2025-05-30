# Install script for directory: /mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src

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
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
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

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/antenna/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/aodv/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/applications/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/bridge/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/brite/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/buildings/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/click/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/config-store/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/core/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/csma/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/csma-layout/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/dsdv/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/dsr/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/energy/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/fd-net-device/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/flow-monitor/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/internet/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/internet-apps/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/lr-wpan/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/lte/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/mesh/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/mobility/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/netanim/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/network/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/nix-vector-routing/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/nr/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/olsr/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/openflow/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/point-to-point/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/point-to-point-layout/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/propagation/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/sixlowpan/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/spectrum/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/stats/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/tap-bridge/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/topology-read/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/traffic-control/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/uan/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/virtual-net-device/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/wifi/cmake_install.cmake")
  include("/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/build/src/wimax/cmake_install.cmake")

endif()

