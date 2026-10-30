#!/bin/bash
set -e


IMAGE_NAME="hero_mrs_image"
CONTAINER_NAME="hero_mrs_container"

# TODO: the folder of your own ROS 2 package on your laptop, e.g. "/home/ivo/my_package".
# In the container it is ~/ros2_ws/src/<folder name>.
MY_PACKAGE_PATH=""

MY_PACKAGE_PATH="${MY_PACKAGE_PATH/#\~/$HOME}"
if [ -z "$MY_PACKAGE_PATH" ] || [ ! -d "$MY_PACKAGE_PATH" ]; then
    echo "Set MY_PACKAGE_PATH at the top of first_run.sh to an existing folder (now: \"$MY_PACKAGE_PATH\")."
    exit 1
fi
MY_PACKAGE_NAME=$(basename "$MY_PACKAGE_PATH")


# X11 setup
XAUTH=/tmp/.docker.xauth

echo "Preparing Xauthority data..."

xauth_list=$(xauth nlist :0 | tail -n 1 | sed -e 's/^..../ffff/')

if [ ! -f "$XAUTH" ]; then
    if [ -n "$xauth_list" ]; then
        echo "$xauth_list" | xauth -f "$XAUTH" nmerge -
    else
        touch "$XAUTH"
    fi
    chmod a+r "$XAUTH"
fi

echo "Done."

echo ""
echo "Verifying file contents:"
file "$XAUTH"
echo "--> It should say \"X11 Xauthority data\"."
echo ""

echo "Permissions:"
ls -FAlh "$XAUTH"
echo ""


# Run container
echo "Starting container: $CONTAINER_NAME"
echo "Using image: $IMAGE_NAME"

docker run -it \
    --env DISPLAY=$DISPLAY \
    --env QT_X11_NO_MITSHM=1 \
    --env TERM=xterm-256color \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --volume /dev:/dev \
    --volume /var/run/dbus:/var/run/dbus:z \
    --volume "$(pwd)":/root/ros2_ws/src/hero_mrs:rw \
    --volume "$MY_PACKAGE_PATH":/root/ros2_ws/src/"$MY_PACKAGE_NAME":rw \
    --net host \
    --privileged \
    --gpus all \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME" \
    bash -c "

        source /opt/ros/\$ROS2_DISTRO/setup.bash

        cd /root/ros2_ws

        # Build workspace if not built
        if [ ! -d install ]; then
            echo 'Building ROS2 workspace...'
            colcon build --symlink-install
        else
            echo 'Workspace already built.'
        fi

        source install/setup.bash

        exec bash
    "