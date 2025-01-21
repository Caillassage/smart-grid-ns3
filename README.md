# power-grid-ns3

This project integrates a power grid simulation using the ns-3 network simulator and leverages Julia scripts for distributed computation across nodes.

## Getting Started

### Prerequisites
- ns-3.41
- Julia
- Additional libraries and dependencies required by ns-3 and Julia

### Setup

1. Ensure ns-3.41 is properly installed on your system.

## Project Structure

### Scripts Description

#### Primary Script
- **`script-power-grid.cc`**: 
  The main script for this simulation. It creates:
  - One server running an updated `UdpEchoServer` object.
  - Two clients running the `UdpEchoClient` object.

#### Core Functionalities

- **`udp-echo-server.cc`**: 
  Implements the behavior of the central server node:
  - Broadcasts packets to all clients.
  - Collects responses from the clients.
  - Validates responses using a corresponding Julia script.
  - Restarts the sending cycle with old values if responses are delayed or invalid.
  - Initiates a timer after every broadcast; if the timer elapses, it resumes the sending round with previous data until updates are received.

- **`udp-echo-client.cc`**: 
  Implements the client node behavior:
  - Processes received packets using the specified Julia script.
  - Sends the computed results back to the server.

### Configuration Files

- **`config/variable-conf.csv`**: 
  Maps each client (identified by a fixed IP address, as specified in `script-power-grid.cc`) to the variable it manages.

- **`config/script-conf.csv`**: 
  Maps each client (identified by a fixed IP address, as specified in `script-power-grid.cc`) to the corresponding Julia script it executes for computation.

## Future Updates
- Additional use cases and examples.
