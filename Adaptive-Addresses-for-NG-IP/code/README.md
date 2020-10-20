# p4app based design and simulation

The experiments are based on [p4app](https://github.com/p4lang/p4app) by p4language, a tool that can build, run, debug, and test P4 programs. 

## Code Structure
The top-level strcuture is the same as the p4app.

Each design is placed in a .p4app folder under example folder, and it typically includes the following files 
- header.p4, which defines the protocol header
- parser.p4, which describes the parsing logic, parser and deparser.
- XXX_router.p4, which descibes the main router logic, ingress and egress.
- p4app.json, which describes the topology, router logic file, and prewritten configuration commands for the router.

Python scripts are used to control sending/receiving packets using library Scapy.

## Installation
Docker needs to be installed first. Then, the p4app command can be executed under the local folder. 
During the first time execution, docker image will be pulled online. If more tools or programs are needed, installation commands can be added to Dockerfile.
## Usage
To run a specific router, the command is the same as the p4app. 
```
p4app run examples/ILR_router.p4app
```
## Experiments Notes
