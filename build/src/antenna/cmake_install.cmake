# Install script for directory: /mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna

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
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so"
         RPATH "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/build/lib/libns3.41-antenna-debug.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so"
         OLD_RPATH "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/build/lib:"
         NEW_RPATH "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.41-antenna-debug.so")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ns3" TYPE FILE FILES
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/angles.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/antenna-model.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/cosine-antenna-model.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/isotropic-antenna-model.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/parabolic-antenna-model.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/phased-array-model.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/three-gpp-antenna-model.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/src/antenna/model/uniform-planar-array.h"
    "/mnt/c/Users/pierr/Desktop/Cours/COURS_M1/s8/TER/smart-grid-ns3/ns-3.41/build/include/ns3/antenna-module.h"
    )
endif()

