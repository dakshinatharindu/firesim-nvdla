# FireSim-NVDLA: NVDLA Integrated with Rocket Chip SoC on FireSim

This is a fork of the [FireSim](https://github.com/firesim/firesim) repository which we have integrated [NVIDIA Deep Learning Accelerator (NVDLA)](http://nvdla.org) in.

## Using FireSim

To simulate NVDLA, first, you need to learn how to use FireSim. After that, simulating NVDLA should be very easy. We recommend to follow the steps in the [FireSim documentation](http://docs.fires.im/en/1.4.0) to set up the simulator and run a single-node simulation. The only difference is you need to use the URL of this repository when cloning FireSim in ["Setting up the FireSim Repo"](http://docs.fires.im/en/1.4.0/Initial-Setup/Setting-up-your-Manager-Instance.html#setting-up-the-firesim-repo):

```
git clone https://github.com/CSL-KU/firesim-nvdla
cd firesim-nvdla
./build-setup.sh fast
```

Once you successfully run a single-node simulation, come back to this guide and follow the rest of instructions.

## Running YOLOv3 on NVDLA
In this section, we guide you through configuring FireSim to run [YOLOv3](https://pjreddie.com/darknet/yolo) object detection algorithm on NVDLA. We run YOLOv3 on a modified version of [Darknet](https://github.com/CSL-KU/darknet-nvdla) neural network framework that supports NVDLA acceleration. First, download Darknet and rebuild the target software:

```
cd firesim-nvdla/sw/firesim-software
./get-darknet
./sw-manager.py -c br-disk.json build
```

Then, configure FireSim to simulate the target which has the NVDLA model. In order to do that, in `firesim-nvdla/deploy/config_runtime.ini`, change the parameter `defaulthwconfig` to `firesim-quadcore-no-nic-nvdla-ddr3-llc4mb`. Your final `config_runtime.ini` should look like this:

```
# RUNTIME configuration for the FireSim Simulation Manager
# See docs/Advanced-Usage/Manager/Manager-Configuration-Files.rst for documentation of all of these params.

[runfarm]
runfarmtag=mainrunfarm

f1_16xlarges=0
m4_16xlarges=0
f1_2xlarges=1

runinstancemarket=ondemand
spotinterruptionbehavior=terminate
spotmaxprice=ondemand

[targetconfig]
topology=no_net_config
no_net_num_nodes=1
linklatency=6405
switchinglatency=10
netbandwidth=200
profileinterval=-1

# This references a section from config_hwconfigs.ini
# In homogeneous configurations, use this to set the hardware config deployed
# for all simulators
defaulthwconfig=firesim-quadcore-no-nic-nvdla-ddr3-llc4mb

[tracing]
enable=no
startcycle=0
endcycle=-1

[workload]
workloadname=linux-uniform.json
terminateoncompletion=no
```

Launch the simulation by following the instructions in the FireSim documentation. Then, log into the simulated machine and run:

```
cd /usr/darknet-nvdla/
./solo.sh
```

The command above launches Darknet and runs YOLOv3 on the image `darknet-nvdla/data/dog.jpg`. The time that it takes to run the algorithm and the probabilities of objects detected in the image should appear on the screen:

```
...
data/dog.jpg: Predicted in 0.195189 seconds.
dog: 95%
truck: 90%
bicycle: 100%
```
