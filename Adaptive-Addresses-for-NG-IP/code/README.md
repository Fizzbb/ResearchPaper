# p4app based design and simulation

The experiments are based on [p4app](https://github.com/p4lang/p4app) by p4language, a tool that can build, run, debug, and test P4 programs. 

## Code Structure
The strcuture is the same as the p4app. Project specific code is placed in the example folder.

## Installation
Docker needs to be installed first. Then, the p4app command can be executed under the local folder. 
During the first time execution, docker image will be pulled online. If more tools or programs are needed, installation commands can be added to Dockerfile.
## Usage
To run a specific router, the command is the same as the p4app. 
```
p4app run examples/ILR_router.p4app
```
## Experiments Notes
