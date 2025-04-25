# Install script for directory: /mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications

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

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so"
         RPATH "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/build/lib/libns3.41-applications-debug.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so"
         OLD_RPATH "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/build/lib:"
         NEW_RPATH "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-applications-debug.so")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ns3" TYPE FILE FILES
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/bulk-send-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/on-off-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/packet-sink-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/three-gpp-http-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/udp-client-server-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/udp-echo-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/helper/MyApp-helper.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/application-packet-probe.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/bulk-send-application.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/onoff-application.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/packet-loss-counter.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/packet-sink.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/seq-ts-echo-header.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/seq-ts-header.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/seq-ts-size-header.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/three-gpp-http-client.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/three-gpp-http-header.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/three-gpp-http-server.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/three-gpp-http-variables.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/MyApp.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/udp-client.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/udp-echo-client.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/udp-echo-server.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/udp-server.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/applications/model/udp-trace-client.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/build/include/ns3/applications-module.h"
    )
endif()

