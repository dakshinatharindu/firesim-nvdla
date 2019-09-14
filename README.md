# FireSim-NVDLA: NVDLA Integrated with Rocket Chip SoC on FireSim

FireSim-NVDLA is a fork of the [FireSim](https://github.com/firesim/firesim) FPGA-accelerated full-system simulator integrated with [NVIDIA Deep Learning Accelerator (NVDLA)](http://nvdla.org). This integration is maintained by the Computer Systems Design Laboratory at the University of Kansas. FireSim-NVDLA runs on the Amazon FPGA cloud (EC2 F1 instance). The figure below shows the overview of FireSim-NVDLA:

<p align="center">
<img src="http://ittc.ku.edu/~farshchi/firesim-nvdla/overview.png" width="450">
</p>

## Contents

1. [Using FireSim](#using-firesim)
2. [Running YOLOv3 on NVDLA](#running-yolov3-on-nvdla)
3. [Building Your Own Hardware](#building-your-own-hardware)
4. [RTL Simulation (MIDAS-Level)](#rtl-simulation-midas-level)
5. [Questions and Reporting Bugs](#questions-and-reporting-bugs)
6. [EMC<sup>2</sup> Workshop Paper](#emc2-workshop-paper)

## Using FireSim

To work with FireSim-NVDLA, first, you need to learn how to use FireSim. We recommend following the steps in the [FireSim documentation (v1.5.0)](http://docs.fires.im/en/1.5.0) to set up the simulator and run a single-node simulation. Please make sure that you are following the right version of the documentation (not the latest version). The only difference in setup is you use the URL of this repository when cloning the repository in [Setting up the FireSim Repo](http://docs.fires.im/en/1.5.0/Initial-Setup/Setting-up-your-Manager-Instance.html#setting-up-the-firesim-repo):

```
git clone https://github.com/CSL-KU/firesim-nvdla
cd firesim-nvdla
./build-setup.sh fast
```

After successfully running a single-node simulation, come back to this guide and follow the rest of instructions.

**Note:** Due to an issue with Python 3.4, please use the commands below instead of the text in the step 4 at [Launching a “Manager Instance”](https://docs.fires.im/en/latest/Initial-Setup/Setting-up-your-Manager-Instance.html#launching-a-manager-instance). This will install Python 3.6.
```
#!/bin/bash
echo "machine launch script started" > /home/centos/machine-launchstatus
sudo yum install -y mosh
sudo yum groupinstall -y "Development tools"
sudo yum install -y gmp-devel mpfr-devel libmpc-devel zlib-devel vim git java java-devel
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
sudo yum install -y sbt texinfo gengetopt
sudo yum install -y expat-devel libusb1-devel ncurses-devel cmake "perl(ExtUtils::MakeMaker)"
# deps for poky
sudo yum install -y python36 patch diffstat texi2html texinfo subversion chrpath git wget
# deps for qemu
sudo yum install -y gtk3-devel
# deps for firesim-software (note that rsync is installed but too old)
sudo yum install -y python36-pip python36-devel rsync
# install DTC. it's not available in repos in FPGA AMI
DTCversion=dtc-1.4.4
wget https://git.kernel.org/pub/scm/utils/dtc/dtc.git/snapshot/$DTCversion.tar.gz
tar -xvf $DTCversion.tar.gz
cd $DTCversion
make -j16
make install
cd ..
rm -rf $DTCversion.tar.gz
rm -rf $DTCversion

# get a proper version of git
sudo yum -y remove git
sudo yum -y install epel-release
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -y install git2u

# install verilator
git clone http://git.veripool.org/git/verilator
cd verilator/
git checkout v4.002
autoconf && ./configure && make -j16 && sudo make install
cd ..

# bash completion for manager
sudo yum -y install bash-completion

# graphviz for manager
sudo yum -y install graphviz python-devel

# these need to match what's in deploy/requirements.txt
sudo pip2 install fabric==1.14.0
sudo pip2 install boto3==1.6.2
sudo pip2 install colorama==0.3.7
sudo pip2 install argcomplete==1.9.3
sudo pip2 install graphviz==0.8.3
# for some of our workload plotting scripts
sudo pip2 install --upgrade --ignore-installed pyparsing
sudo pip2 install matplotlib==2.2.2
sudo pip2 install pandas==0.22.0
# this is explicitly installed to downgrade it to a version without deprec warnings
sudo pip2 install cryptography==2.2.2

sudo activate-global-python-argcomplete

# get a regular prompt
echo "PS1='\u@\H:\w\\$ '" >> /home/centos/.bashrc
echo "machine launch script completed" >> /home/centos/machine-launchstatus
```

## Running YOLOv3 on NVDLA
In this part, we guide you through configuring FireSim to run [YOLOv3](https://pjreddie.com/darknet/yolo) object detection algorithm on NVDLA. YOLOv3 runs on a modified version of the [Darknet](https://github.com/CSL-KU/darknet-nvdla) neural network framework that supports NVDLA acceleration. First, download Darknet and rebuild the target software:

```
cd firesim-nvdla/sw/firesim-software
./get-darknet.sh
./marshal -v build workloads/darknet-nvdla.json
./marshal install workloads/darknet-nvdla.json
```

Next, configure FireSim to simulate the target which has the NVDLA model. For that, in `firesim-nvdla/deploy/config_runtime.ini`, change the parameter `defaulthwconfig` to `firesim-quadcore-no-nic-nvdla-ddr3-llc4mb`. Additionally, change `workloadname` to `darknet-nvdla.json`. Your final `config_runtime.ini` should look like this:

```
# RUNTIME configuration for the FireSim Simulation Manager
# See docs/Advanced-Usage/Manager/Manager-Configuration-Files.rst for documentation of all of these params.

[runfarm]
runfarmtag=mainrunfarm

f1_16xlarges=0
m4_16xlarges=0
f1_4xlarges=0
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
workloadname=darknet-nvdla.json
terminateoncompletion=no
```

Follow the instructions on the FireSim documentation to launch the simulation, open the console for the target RISC-V machine, and log in. Then run:

```
cd darknet-nvdla
./solo.sh
```

The command above launches Darknet and runs YOLOv3 on the image `darknet-nvdla/data/person.jpg`. Once detection is done, the time that it takes to run the algorithm and the probabilities of objects detected in the image appear on the screen:

```
...
data/person.jpg: Predicted in 0.129548 seconds.
horse: 100%
dog: 99%
person: 100%
```

Darknet saves the image with bounding boxes around the detected objects in `darknet-nvdla/predictions.png`:

<p align="center">
<img src="http://www.ittc.ku.edu/~farshchi/firesim-nvdla/person-detected.png" width="550">
</p>

## Building Your Own Hardware
The pre-built target we provided above is for a quad-core processor with no network interface, a last-level cache with the maximum size of 4 MiB, and a DDR3 memory with FR-FCFS controller. It is simple and easy to add NVDLA to any other configuration and build your own FPGA image. First, read [Building Your Own Hardware Designs (FireSim FPGA Images)](http://docs.fires.im/en/1.5.0/Building-a-FireSim-AFI.html) to learn how to build a FireSim FPGA image and make sure you know the meaning and use of parameters in [`config_build_recipes.ini`](http://docs.fires.im/en/1.5.0/Advanced-Usage/Manager/Manager-Configuration-Files.html#config-build-recipes-ini).

Once you know how to build a FireSim FPGA image, building your own custom configuration with NVDLA is easy. Simply, add a new build definition in `config_build_recipes.ini` and add `_WithNVDLALarge` to the end of `TARGET_CONFIG` parameter. For example, use the build definition below to build an image for a single-core processor with a network interface and a latency-bandwidth pipe memory model with the FPGA host frequency of 75MHz:

```
[name-of-your-configuration]
DESIGN=FireSim
TARGET_CONFIG=FireSimRocketChipSingleCoreConfig_WithNVDLALarge
PLATFORM_CONFIG=FireSimConfig75MHz
instancetype=c5.4xlarge
deploytriplet=None
```

Replace `name-of-your-configuration` with the desired name for your new configuration. Follow the instructions on the FireSim documentation to build the AGFI and add it to `config_hwdb.ini`. NVDLA is a large design therefore, it takes about 10 hours to finish the build on a c5.4xlarge instance. To simulate the target you have built, replace `defaulthwconfig` in `config_runtime.ini` with `name-of-your-configuration`.

You can do all sort of cool things by experimenting with different configurations. For example, you can measure the performance of NVDLA with respect to the memory latency when you choose the latency-bandwidth pipe memory model. The latency of this memory model can be configured at the runtime without having to rebuild the FPGA image. In addition, the Rocket Chip SoC can be further customized by modifying the Chisel code. For example, you can change the memory bus width and see how this affects the performance of NVDLA.

## RTL Simulation (MIDAS-Level)
The following steps show how to build the Verilator simulator for a Quad-core Rocket Chip with NVDLA and test it. We have provided a simple bare-metal program named `nvdla.c` to test NVDLA. To compile the program:
```
cd firesim-nvdla/target-design/firechip/tests
make
```

To build the simulator and run the test program:
```
cd firesim-nvdla/sim
export DESIGN=FireSimNoNIC TARGET_CONFIG=FireSimRocketChipQuadCoreConfig_WithNVDLALarge \
PLATFORM_CONFIG=FireSimDDR3FRFCFSLLC4MBConfig75MHz
make run-verilator-debug SIM_BINARY=../target-design/firechip/tests/nvdla.riscv -j
```

The test program configures NVDLA, triggers the process and then pools the NVDLA's interrupt status register. Once the job is finished, it prints the number of elapsed cycles:
```
cycle1: 5969, cycle2: 10682, diff: 4713
```

The simulator saves the .out file and the waveform in `generated-src/f1/$DESIGN-$TARGET_CONFIG-$PLATFORM_CONFIG`. For more information on using the RTL simulator, please refer to [Debugging & Testing with RTL Simulation](https://docs.fires.im/en/1.5.0/Advanced-Usage/Debugging/RTL-Simulation.html#debugging-testing-with-rtl-simulation).

## Questions and Reporting Bugs
If you have a question about using FireSim-NVDLA or you want to report a bug, please file an issue on this repository.

## EMC<sup>2</sup> Workshop Paper
You can read our EMC<sup>2</sup> workshop paper to learn more about the integration of NVDLA into FireSim and find out how we used this platform to evaluate the perforamnce of NVDLA:

Farzad Farshchi, Qijing Huang, and Heechul Yun, **"Integrating NVIDIA Deep Learning Accelerator (NVDLA) with RISC-V SoC on FireSim"**, 2nd Workshop on Energy Efficient Machine Learning and Cognitive Computing for Embedded Applications (EMC<sup>2</sup> 2019), Washington, DC, February 2019. [Paper PDF](http://www.ittc.ku.edu/~farshchi/papers/nvdla-firesim-emc2-paper.pdf) | [Slides](http://www.ittc.ku.edu/~farshchi/papers/nvdla-firesim-emc2-slides.pdf)
