# Ubuntu 22.04 base
FROM ubuntu:jammy AS base


# Build arguments & environment

ARG DEBIAN_FRONTEND=noninteractive
ARG HOME=/root

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ROS2_DISTRO=humble \
    GZ_RELEASE=garden \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
    TZ=Europe/Zagreb

WORKDIR $HOME


# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # General tools
    atop \
    build-essential \ 
    clang \
    cmake \
    cppcheck \ 
    console-setup \
    curl \
    expect \
    gdb \
    git \
    gnutls-bin \
    htop \
    iputils-ping \
    jq \
    openssh-client \
    nano \
    net-tools \
    vim \
    tmux \
    tmuxinator \ 
    ranger \
    rfkill \
    wget \
    xvfb \
    sudo \
    software-properties-common \
    usbutils \
    # Boost, libusb, graphics
    libboost-filesystem-dev \
    libboost-program-options-dev \ 
    libboost-regex-dev \
    libboost-system-dev \ 
    libboost-thread-dev \
    libbz2-dev \
    libconsole-bridge-dev \ 
    libccd-dev \
    libcwiid-dev \
    libfcl-dev \
    libgl1 \
    libglx-mesa0 \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libgoogle-glog-dev \
    libgpgme-dev \
    libpoco-dev \
    liblog4cxx-dev \ 
    libspnav-dev \
    libspdlog-dev \
    libtinyxml2-dev \
    libusb-dev \
    uuid-dev \
    libbluetooth-dev \
    liblz4-dev \
    libgtest-dev \
    libxcb-xinerama0 \ 
    libxcb-cursor0 \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxkbcommon-dev \ 
    libxkbcommon-x11-dev \ 
    libxrender-dev \
    libfontconfig1-dev \
    libfreetype-dev \
    libx11-dev \
    libx11-xcb-dev \ 
    libxcb-cursor-dev \ 
    libxcb-glx0-dev  \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \ 
    libxcb-randr0-dev  \
    libxcb-render-util0-dev \ 
    libxcb-shape0-dev  \
    libxcb-shm0-dev \
    libxcb-sync-dev \
    libxcb-util-dev \
    libxcb-xfixes0-dev \ 
    libxcb-xinerama0-dev \ 
    libxcb-xkb-dev  \
    libxcb1-dev \
    libncurses-dev \
    libncurses5-dev \
    && add-apt-repository universe \
    && apt-get clean -qq


# Python tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-dbg \
    python3-empy \
    python3-nose \
    python3-mock \
    python3-netifaces \ 
    python3-psutil \
    python3-pycryptodome \
    python3-defusedxml \
    python3-gnupg \
    python3-flake8 \
    python3-flake8-blind-except \ 
    python3-flake8-builtins \
    python3-flake8-class-newline \
    python3-flake8-comprehensions \ 
    python3-flake8-deprecated \
    python3-flake8-docstrings \
    python3-flake8-import-order \
    python3-flake8-quotes \
    python3-pytest \
    python3-pytest-cov \ 
    python3-pytest-repeat \ 
    python3-pytest-rerunfailures \
    python-is-python3\
    && pip install --upgrade pip rowan transforms3d nicegui keyboard 


# SSH agent forwarding setup
ENV GIT_SSH_COMMAND="ssh -v"
USER root
RUN --mount=type=ssh id=default mkdir -p ~/.ssh/ && ssh-keyscan -H github.com >> ~/.ssh/known_hosts

# ROS2 Humble setup
RUN apt-get update && apt-get install -y locales curl gnupg lsb-release \
    && locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
       | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt-get update && apt-get install -y \
        ros-${ROS2_DISTRO}-desktop \
        python3-rosdep \
        ros-dev-tools \
        python3-colcon-common-extensions \
    && apt-get clean -qq


# MCAP CLI
RUN VERSION="releases/mcap-cli/v0.0.55" && \
    curl -fL -o /bin/mcap "https://github.com/foxglove/mcap/releases/download/$VERSION/mcap-linux-amd64" && chmod +x /bin/mcap

#Avoiding venv issues with ROS2 Humble and Python 3.10
RUN PYTHON_VERSION=$(python --version | cut -d " " -f2 | cut -d "." -f1,2) && \
    rm -rf /usr/lib/python${PYTHON_VERSION}/EXTERNALLY-MANAGED

RUN apt-get update &&  apt-get upgrade -y && apt-get install -y \
                   ros-${ROS2_DISTRO}-tf-transformations \
                   ros-${ROS2_DISTRO}-nav2-map-server \
                   ros-${ROS2_DISTRO}-nav2-lifecycle-manager \
                   ros-${ROS2_DISTRO}-rosbridge-suite \
                   ros-${ROS2_DISTRO}-rosbag2-storage-mcap \
                   ros-${ROS2_DISTRO}-octomap \
                   ros-${ROS2_DISTRO}-octomap-ros \
                   ros-${ROS2_DISTRO}-octomap-server \
                   ros-${ROS2_DISTRO}-octomap-msgs \
                   ros-${ROS2_DISTRO}-foxglove-bridge \
                   ros-${ROS2_DISTRO}-rosbag2-storage-mcap \
                   ros-${ROS2_DISTRO}-mqtt-client


# ROS2 Workspace
#   crazyswarm2            fcf51e2 = tag 1.0.7 (2026-08-21)
#   motion_capture_tracking 73da55a (2026-02-21, just after tag 1.0.6)
RUN mkdir -p $HOME/ros2_ws/src \
    && cd $HOME/ros2_ws/src \
    && git clone https://github.com/IMRCLab/crazyswarm2 \
    && cd $HOME/ros2_ws/src/crazyswarm2 \
    && git checkout fcf51e27fe675bbdb564a40f4ca1ee4336c062ea \
    && git submodule sync --recursive && git submodule update --init --recursive\
    && cd $HOME/ros2_ws/src \
    && git clone https://github.com/JMU-ROBOTICS-VIVA/ros2_aruco.git \
    && git clone https://github.com/larics/icuas25_msgs.git \
    && git clone https://github.com/IMRCLab/motion_capture_tracking.git \
    && cd $HOME/ros2_ws/src/motion_capture_tracking \
    && git checkout 73da55a005c3c8ccd26e108ba627dbcd438f30f9 \
    && git submodule sync --recursive && git submodule update --init --recursive


# Bash environment & aliases
RUN echo "alias ros2_ws='source $HOME/ros2_ws/install/setup.bash'" >> $HOME/.bashrc && \
    echo "alias source_ros2='source /opt/ros/${ROS2_DISTRO}/setup.bash'" >> $HOME/.bashrc && \
    echo "alias cd_hero_mrs='cd $HOME/ros2_ws/src/hero_mrs'" >> $HOME/.bashrc && \
    echo "export ROS_LOCALHOST_ONLY=1" >> $HOME/.bashrc && \
    echo "export ROS_DOMAIN_ID=$(shuf -i 1-101 -n 1)" >> $HOME/.bashrc && \
    echo "ros2_ws" >> $HOME/.bashrc && \
    echo "source_ros2" >> $HOME/.bashrc


# User config files
COPY to_copy/aliases $HOME/.bash_aliases
COPY to_copy/nanorc $HOME/.nanorc
COPY to_copy/tmux $HOME/.tmux.conf
COPY to_copy/ranger $HOME/.config/ranger/rc.conf

# setting up Crazyflies environment

RUN  apt-get update && apt-get install -y\
    octovis \
    octomap-tools \
    libusb-1.0-0-dev \
    make gcc-arm-none-eabi \
    swig3.0 \
    && ln -s /usr/bin/swig3.0 /usr/bin/swig

RUN pip install --upgrade pip

RUN cd $HOME && git clone https://github.com/bitcraze/crazyflie-clients-python \
    && cd crazyflie-clients-python \
    && pip install --ignore-installed  -e .

RUN cd $HOME && git clone --recursive https://github.com/bitcraze/crazyflie-firmware.git \
    && cd crazyflie-firmware && git submodule init && git submodule update \
    && make cf2_defconfig \
    && make -j 12 \
    && make bindings_python \
    && cd build \
    && python3 setup.py install --user \
    && export PYTHONPATH=$HOME/crazyflie-firmware/build:$PYTHONPATH

RUN pip install cflib opencv-python
RUN pip install setuptools==64.0.0
RUN pip install opencv-contrib-python==4.6.0.66
RUN pip install --upgrade numpy==1.26.4

# HERO packages
#   Cloned, not bind-mounted, and not pinned: update them with git pull inside the container.
#   Built by first_run.sh together with the rest of the workspace.
ARG HERO_SIM_BRANCH=master
ARG HEROVER_BRANCH=main
RUN cd $HOME/ros2_ws/src \
    && git clone --branch ${HERO_SIM_BRANCH} https://github.com/larics/hero_sim.git 
    # && git clone --branch ${HEROVER_BRANCH} https://github.com/larics/herover.git

# Final setup
ENV USERNAME=root
RUN usermod -aG plugdev $USERNAME && adduser $USERNAME dialout
COPY to_copy/99-bitcraze.rules /etc/udev/rules.d/.

USER root  
WORKDIR $HOME
CMD ["/bin/bash"]
