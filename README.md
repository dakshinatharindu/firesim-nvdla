# FireSim-NVDLA: NVDLA Integrated with Rocket Chip SoC on FireSim

This is a fork of the [FireSim](https://github.com/firesim/firesim) repository which we have integrated [NVIDIA Deep Learning Accelerator (NVDLA)](http://nvdla.org) into.

## Using FireSim

To simulate NVDLA, first, you need to learn how to use FireSim. Once you learned that, simulating NVDLA is very easy. We recommend following the steps in the [FireSim documentation](http://docs.fires.im/en/1.4.0) to set up the simulator and run a single-node simulation. The only difference is you use the URL of this repository when cloning FireSim in ["Setting up the FireSim Repo"](http://docs.fires.im/en/1.4.0/Initial-Setup/Setting-up-your-Manager-Instance.html#setting-up-the-firesim-repo):

```
git clone https://github.com/CSL-KU/firesim-nvdla
cd firesim-nvdla
./build-setup.sh fast
```

Once you successfully run a single-node simulation, come back to this guide and follow the rest of instructions.

## Running YOLOv3 on NVDLA
In this section, we guide you through configuring FireSim to run [YOLOv3](https://pjreddie.com/darknet/yolo) object detection algorithm on NVDLA. YOLOv3 runs on a modified version of the [Darknet](https://github.com/CSL-KU/darknet-nvdla) neural network framework that supports NVDLA acceleration. First, download Darknet and rebuild the target software:

```
cd firesim-nvdla/sw/firesim-software
./get-darknet
./sw-manager.py -c br-disk.json build
```

Then, configure FireSim to simulate the target which includes the NVDLA model. In order to do that, in `firesim-nvdla/deploy/config_runtime.ini`, change the parameter `defaulthwconfig` to `firesim-quadcore-no-nic-nvdla-ddr3-llc4mb`. Your final `config_runtime.ini` should look like this:

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

Follow the instructions on the FireSim documentation to launch the simulation then, log into the simulated machine and run:

```
cd /usr/darknet-nvdla/
./solo.sh
```

The command above launches Darknet and runs YOLOv3 on the image `darknet-nvdla/data/dog.jpg`. Once detection is done, the time that it takes to run the algorithm and the probabilities of objects detected in the image appears on the screen:

```
...
data/dog.jpg: Predicted in 0.132563 seconds.
dog: 95%
truck: 90%
bicycle: 100%
```

Darknet saves the output image with bounding boxes around the detected objects in `darknet-nvdla/predictions.png`.

## Building Your Own Hardware
The pre-built target we provided above is for a quad-core processor with no network interface, a last-level cache with the maximum size of 4 MiB, and a DDR3 model with FR-FCFS controller. It is simple and easy to add NVDLA to any other configuration and build your own FPGA image. First, learn how to build a FireSim FPGA image by reading ["Building Your Own Hardware Designs (FireSim FPGA Images)"](http://docs.fires.im/en/1.4.0/Building-a-FireSim-AFI.html) and learn about the meaning and use of parameters in [`config_build_recipes.ini`](http://docs.fires.im/en/1.4.0/Advanced-Usage/Manager/Manager-Configuration-Files.html#config-build-recipes-ini).

Once you know how to build a FireSim FPGA image, building your own custom configuration with NVDLA is easy. Simply, add a new build definition in `config_build_recipes.ini` which matches your custom configuration and add `_WithNVDLALarge` to the end of `TARGET_CONFIG` parameter. For example, use the build definition below to build an image for a single-core processor with a network interface and a latency-bandwidth pipe memory model:

```
[name-of-configuration]
DESIGN=FireSim
TARGET_CONFIG=FireSimRocketChipSingleCoreConfig_WithNVDLALarge
PLATFORM_CONFIG=FireSimConfig
instancetype=c4.4xlarge
deploytriplet=None
```

Replace `name-of-configuration` with the desired name for your new configuration. Follow the instructions on the FireSim documentation to build the AGFI and add it to `config_hwdb.ini`. NVDLA is a large design therefore, it takes about 8 hours to finish the build on a c4.4xlarge instance. To simulate the target you have built, replace `defaulthwconfig` in `config_runtime.ini` with `name-of-configuration`.

You can do all sort of cool things by experimenting with different configurations. For example, you can measure the performance of NVDLA with respect to the memory latency when you choose the latency-bandwidth pipe memory model. The latency of this memory model can be configured at the runtime without having to rebuild the FPGA image. In addition, the Rocket Chip can be further customized by modifying the Chisel code. For example, you can change the memory bus width and see how the NVDLA performance changes.

## EMC<sup>2</sup> Workshop Paper
You can read our EMC<sup>2</sup> workshop paper to learn more about the integration of NVDLA into FireSim and find out how we used this platform to evaluate the perforamnce of NVDLA:

Farzad Farshchi, Qijing Huang, and Heechul Yun, **"Integrating NVIDIA Deep Learning Accelerator (NVDLA) with RISC-V SoC on FireSim"**, 2nd Workshop on Energy Efficient Machine Learning and Cognitive Computing for Embedded Applications (EMC<sup>2</sup> 2019), Washington, DC, February 2019. [Paper](http://www.ittc.ku.edu/~farshchi/nvdla-firesim-emc2-paper.pdf) | [Slides](http://www.ittc.ku.edu/~farshchi/nvdla-firesim-emc2-slides.pdf)
