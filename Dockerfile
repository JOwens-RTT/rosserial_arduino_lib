FROM ros:indigo-ros-base

RUN apt-get update &&\
  apt-get install -y ros-$ROS_DISTRO-rosserial-arduino ros-$ROS_DISTRO-rosserial git gcc g++ wget &&\
  apt-get -y clean &&\
  apt-get -y purge &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN <<EOF
#!/bin/bash

# Download and extract cmake    
cmake_version="3.29.2"
cmake_url="https://gitlab.kitware.com/cmake/cmake/-/archive/v${cmake_version}/cmake-v${cmake_version}.tar.gz"

# Download cmake
mkdir -p /tmp/cmake
cd /tmp/cmake
wget -qO- $cmake_url | tar --strip-components=1 -xz

# Build cmake
./bootstrap
make
make install

# Cleanup
cd /
rm -rf /tmp/cmake
EOF

# Create a Catkin Workspace
SHELL ["/bin/bash", "-c"]
ENV CATKIN_WS=/catkin_ws
RUN source /opt/ros/$ROS_DISTRO/setup.bash &&\
  mkdir -p $CATKIN_WS/src &&\
  cd $CATKIN_WS/ &&\
  catkin_make -DCMAKE_CXX_COMPILER=g++

# Build ROS Serial
RUN source /opt/ros/$ROS_DISTRO/setup.bash &&\
  cd $CATKIN_WS/src &&\
  git clone https://github.com/ros-drivers/rosserial.git &&\
  cd $CATKIN_WS &&\
  catkin_make_isolated -DCMAKE_CXX_STANDARD=11 &&\
  catkin_make_isolated --install

# Create ROS Serial Arduino builder
RUN source /opt/ros/$ROS_DISTRO/setup.bash &&\
  cd /tmp &&\
  rosrun rosserial_arduino make_libraries.py .
