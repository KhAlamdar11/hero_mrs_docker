# hero_mrs

The Docker environment for the HERO project. Use it to run the **hero_sim** simulator and to fly the real **Crazyflies** and drive the real **herover** robots.

The container has ROS 2 Humble, crazyswarm2, motion capture tracking, cfclient and [hero_sim](https://github.com/larics/hero_sim).

## Installation

Do these three steps at home, before the first session. They take about an hour, mostly downloading. They're in [docs/installation.md](docs/installation.md):

1. [Install Docker](docs/installation.md#step-1-install-docker)
2. [Build the image](docs/installation.md#step-2-build-the-image)
3. [Create the container and run the example](docs/installation.md#step-3-create-the-container-and-run-the-example)

New to Docker, tmux or the robots? Do the [tutorial](docs/tutorial.md) after the installation.

## Quick start

Every time you work with the simulator:

1. On your laptop, start the container. You get a terminal inside it:
   ```bash
   docker start -i hero_mrs_container
   ```
2. Start the simulator with a scenario. RViz opens, and you're in a tmux session called `hero_sim`:
   ```bash
   cd ~/ros2_ws/src/hero_sim/startup
   bash start.sh tether_demo.yaml
   ```
   For your own scenario, give its path instead, see [Your own scenario](#your-own-scenario-obstacles-and-robots).
3. Open a new tmux window with `Ctrl+b`, then `c`, and run your node:
   ```bash
   ros2 run undergrad_project_mrs mission_template
   ```
4. Stop the simulator with `Ctrl+b`, then `k`. Leave the container with `exit`.

In tmux, `Shift` + left/right switches between windows and `Ctrl` + arrows between panes. The [tutorial](docs/tutorial.md#tmux) has the rest.

## Your own node

Your package is `~/undergrad_project_mrs` on your laptop and `~/ros2_ws/src/undergrad_project_mrs` in the container: the same folder. Write your code on your laptop, and build and run it in the container.

1. On your laptop, copy the template to start from it:
   ```bash
   cd ~/undergrad_project_mrs/undergrad_project_mrs
   cp mission_template.py my_mission.py
   ```
   In `my_mission.py`, rename the node: `super().__init__('my_mission')`.
2. Register it in `~/undergrad_project_mrs/setup.py`, under `console_scripts`:
   ```python
   'my_mission = undergrad_project_mrs.my_mission:main',
   ```
3. In the container, build your package and load the build in this terminal:
   ```bash
   cd ~/ros2_ws
   colcon build --symlink-install --packages-select undergrad_project_mrs
   source install/setup.bash
   ```
4. With the simulator running, run it:
   ```bash
   ros2 run undergrad_project_mrs my_mission
   ```

After editing `my_mission.py`, just run it again: there's no need to build. Build again only after changing `setup.py` or adding a file. `mission_template.py` shows how to call every service and topic from Python.

## Your own scenario: obstacles and robots

A **scenario** is a YAML file that says which robots there are, where they start, which obstacles there are, and where the tether, its object and the goal are. Keep your scenarios in your package, so they're saved on your laptop and in your git repository.

1. On your laptop, create `~/undergrad_project_mrs/scenarios/my_world.yaml` and paste this into it. It's the tether demo with two more pillars:
   ```yaml
   ground_robots:                         # drive them with /<name>/cmd_vel or /<name>/go_to
     - name: herover_1                    # the name in the topics: /herover_1/...
       pose: {x: -1.5, y: -1.5, yaw: 0.0} # where it starts: m, m, rad
       drive: omni                        # omni: can drive sideways. diff: can't
       model: herover                     # herover or scout

   crazyflies:                            # named cf_1, cf_2, ... in this order
     - pose: {x: 0.0, y: 1.0, z: 0.03}    # cf_1

   obstacles:                             # pillars, m
     - {x: 1.5, y: 0.5, radius: 0.35}
     - {x: -0.5, y: 0.5, radius: 0.2}
     - {x: 2.0, y: -1.5, radius: 0.3, height: 0.5}   # height: 2 m if left out

   tether:
     winch: {x: -3.0, y: 0.0, z: 0.3}     # where the tether leaves the winch drum
     ugv: herover_1                       # the tether runs over this ground robot
     uav: cf_1                            # then through this drone, down to the object
     object: {x: 0.5, y: -0.5}            # where the object starts on the floor
     goal: {x: 2.5, y: 1.5, radius: 0.4}  # get the object's center into this circle
     slack: 3.0                           # m of loose tether at the start
     max_reel_speed: 0.5                  # m/s, the fastest the winch turns

   sim:
     map: null                            # an empty floor with only your pillars
     collision: true                      # robots stop at pillars. false: they pass through
   ```
2. In the container, start the simulator with the file's path:
   ```bash
   cd ~/ros2_ws/src/hero_sim/startup
   bash start.sh ~/ros2_ws/src/undergrad_project_mrs/scenarios/my_world.yaml
   ```
3. After a change to the file, stop the simulator with `Ctrl+b`, then `k`, and start it again. There's no need to build.

What to change:

| To | Do |
|---|---|
| Add a pillar | Add a line under `obstacles:`. `x`, `y` and `radius` are needed, `height` is optional |
| Add a wall | There are only round pillars. Put several in a row, closer together than their diameter |
| Have no obstacles | Leave out `obstacles:`. Keep `map: null` |
| Add a ground robot | Add an entry under `ground_robots:` with a new `name`, like `herover_2` |
| Add a Crazyflie | Add a `- pose: ...` line under `crazyflies:`. The second one is `cf_2` |
| Move the object or the goal | Change `object:` or `goal:` under `tether:` |
| Drop the tether task | Leave out `tether:` |

How obstacles behave:

- A robot stops when it would hit a pillar, and moves again once you command it away from it.
- Each robot is a circle: herover 0.17 m, scout 0.42 m and Crazyflie 0.1 m in radius. Set `radius:` on a robot to change it.
- Drones are blocked at any height, even above a low pillar: they have to fly around a pillar, not over it. `height` only changes how it's drawn.
- Ground robots block each other. Drones don't collide with ground robots or with each other.
- The tether object gets stuck when it's pulled into a pillar. It can't start inside one.

Every option, with its default, is explained in `~/ros2_ws/src/hero_sim/config/example.yaml`. Other scenarios to start from are in `~/ros2_ws/src/hero_sim/config/`. A typo or an unknown option stops the simulator with an error that names it, in the top pane of the `hero_sim` tmux window.

## Topics and services

`<name>` is a ground robot's `name` in the scenario, like `herover_1`. Crazyflies are `cf_1`, `cf_2`, ... All positions are in meters, in the `world` frame.

**Ground robots**

| Name | Kind | Type | |
|---|---|---|---|
| `/<name>/cmd_vel` | topic, you publish | `geometry_msgs/msg/Twist` | velocity in the robot's own frame: `linear.x` forward, `linear.y` left (only with `drive: omni`), `angular.z` turn. Kept until the next message, so send `{}` to stop |
| `/<name>/go_to` | service | `crazyflie_interfaces/srv/GoTo` | drive to `goal.x`, `goal.y` and `yaw` in about `duration`. Simulator only: on the real herover, use `cmd_vel` |
| `/<name>/pose` | topic, you read | `geometry_msgs/msg/PoseStamped` | where it is |

**Crazyflies**

| Name | Kind | Type | |
|---|---|---|---|
| `/cf_1/takeoff` | service | `crazyflie_interfaces/srv/Takeoff` | rise to `height` in `duration` |
| `/cf_1/go_to` | service | `crazyflie_interfaces/srv/GoTo` | fly to `goal` and `yaw` in `duration` |
| `/cf_1/land` | service | `crazyflie_interfaces/srv/Land` | come down to `height` in `duration` |
| `/all/takeoff`, `/all/go_to`, `/all/land` | service | the same | the same, for every Crazyflie at once |
| `/cf_1/pose` | topic, you read | `geometry_msgs/msg/PoseStamped` | where it is |
| `/cf_1/status` | topic, you read | `crazyflie_interfaces/msg/Status` | `battery_voltage`, among others |

`go_to` takes `relative: true` to move by an offset from where the robot is now.

**Tether task**

| Name | Kind | Type | |
|---|---|---|---|
| `/winch/cmd_rate` | topic, you publish | `std_msgs/msg/Float64` | m/s: negative reels in, positive lets out. Kept until the next message, so send `0.0` to stop |
| `/winch/length` | topic, you read | `std_msgs/msg/Float64` | how much tether is out |
| `/tether/free_length` | topic, you read | `std_msgs/msg/Float64` | how much hangs below the drone |
| `/tether/taut` | topic, you read | `std_msgs/msg/Bool` | the tether is taut |
| `/tether/stuck` | topic, you read | `std_msgs/msg/Bool` | the object is stuck against a pillar |
| `/tether/object_pose` | topic, you read | `geometry_msgs/msg/PoseStamped` | where the object's center is |
| `/tether/goal` | topic, you read | `geometry_msgs/msg/PoseStamped` | where the goal's center is |
| `/tether/goal_reached` | topic, you read | `std_msgs/msg/Bool` | the object's center is inside the goal |

**Obstacles**

| Name | Kind | Type | |
|---|---|---|---|
| `/hero_sim/obstacles` | topic, you read | `visualization_msgs/msg/MarkerArray` | one cylinder per pillar: `pose.position` is its center, `scale.x` its diameter, `scale.z` its height |
| `/projected_map` | topic, you read | `nav_msgs/msg/OccupancyGrid` | the same pillars as a 2D grid, from octomap_server |

`/hero_sim/obstacles` is sent only once, when the simulator starts. To still get it when your node starts later, subscribe with this QoS:

```python
from rclpy.qos import DurabilityPolicy, QoSProfile
from visualization_msgs.msg import Marker, MarkerArray

# in __init__
latched = QoSProfile(depth=1, durability=DurabilityPolicy.TRANSIENT_LOCAL)
self.create_subscription(MarkerArray, '/hero_sim/obstacles', self.on_obstacles, latched)

def on_obstacles(self, msg):
    # x, y and radius of each pillar. Skip the first marker, which isn't a pillar.
    self.pillars = [(m.pose.position.x, m.pose.position.y, m.scale.x / 2)
                    for m in msg.markers if m.type == Marker.CYLINDER]
```

**From the terminal**

Handy to try things out, with the simulator running:

```bash
ros2 topic list                                      # every topic
ros2 topic echo /herover_1/pose                      # watch a topic, Ctrl+c to stop
ros2 topic echo --once /hero_sim/obstacles           # the pillars

ros2 topic pub --once /herover_1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.3}}"
ros2 topic pub --once /herover_1/cmd_vel geometry_msgs/msg/Twist "{}"    # stop
ros2 service call /herover_1/go_to crazyflie_interfaces/srv/GoTo "{goal: {x: 1.0, y: -1.0}, yaw: 1.57, duration: {sec: 3}}"

ros2 service call /cf_1/takeoff crazyflie_interfaces/srv/Takeoff "{height: 1.0, duration: {sec: 2}}"
ros2 service call /cf_1/go_to crazyflie_interfaces/srv/GoTo "{goal: {x: 1.0, y: 1.0, z: 1.0}, duration: {sec: 3}}"
ros2 service call /cf_1/land crazyflie_interfaces/srv/Land "{height: 0.0, duration: {sec: 2}}"

ros2 topic pub --once /winch/cmd_rate std_msgs/msg/Float64 "{data: -0.3}"   # reel in
ros2 topic pub --once /winch/cmd_rate std_msgs/msg/Float64 "{data: 0.0}"    # stop
```

More about the simulator, such as the speed limits and how the tether works, is in the [hero_sim README](https://github.com/larics/hero_sim).

## Docker commands

Run these on your laptop, not inside the container:

| To | Run |
|---|---|
| Start the container and open a terminal in it | `docker start -i hero_mrs_container` |
| Open another terminal in the running container | `docker exec -it hero_mrs_container bash` |
| Stop the container | `docker stop hero_mrs_container` |
| See whether it's running | `docker ps -a` |

- `exit` closes a terminal. Exiting the one opened by `docker start -i` also stops the container.
- After a reboot the container is stopped. Start it again with `docker start -i hero_mrs_container`.

### Start over with a fresh container

```bash
cd ~/hero_mrs_docker
docker rm hero_mrs_container
./first_run.sh
```

This deletes everything inside the container except the `hero_mrs_docker` folder and your package.

## What's saved where

| Inside the container | What it is |
|---|---|
| `~/ros2_ws/src/undergrad_project_mrs` | **your package folder on your laptop**, the one set in `MY_PACKAGE_PATH`. Edit your code there with any editor, then build and run it in the container |
| `~/ros2_ws/src/hero_mrs` | **the `hero_mrs_docker` folder on your laptop** |
| `~/ros2_ws/src/hero_sim` | the simulator |
| everything else | lives only in the container. It survives `docker stop`, but `docker rm` deletes it |

The two folders from your laptop are shared, not copied: a change on either side is a change to the same files, and they survive `docker rm`.

To build the whole workspace, for example after `git pull` in one of its packages, run this in the container, then open a new terminal:
```bash
cd ~/ros2_ws
colcon build --symlink-install
```

## Updating hero_sim

Inside the container:
```bash
cd ~/ros2_ws/src/hero_sim && git pull
cd ~/ros2_ws
colcon build --symlink-install --packages-select hero_sim
```

## Real robots

| What | How | Details |
|---|---|---|
| Real Crazyflies | `cd ~/ros2_ws/src/hero_mrs/startup && ./start.sh` | [tutorial](docs/tutorial.md#crazyflies) |
| Real herover | `ros2 run herover cmd_vel_bridge`, after cloning [herover](https://github.com/larics/herover) into `~/ros2_ws/src` | [tutorial](docs/tutorial.md#herover) |

## Troubleshooting

Problems while installing are in the [installation troubleshooting](docs/installation.md#troubleshooting).

| Problem | What to do |
|---|---|
| `No such container: hero_mrs_container` | Create it with [installation step 3](docs/installation.md#step-3-create-the-container-and-run-the-example) |
| `Conflict. The container name "/hero_mrs_container" is already in use` | The container already exists: `docker start -i hero_mrs_container`. To create it again, [start over](#start-over-with-a-fresh-container) |
| On your laptop, you can't save a file in your package (`permission denied`) | Files made inside the container belong to root. On your laptop: `sudo chown -R $USER ~/undergrad_project_mrs` |
| RViz doesn't open (`could not connect to display`) | Do [installation step 3.4](docs/installation.md#step-3-create-the-container-and-run-the-example), then open a new terminal and try again |
| `Package '...' not found` or `No executable found` | Build (see [Your own node](#your-own-node) step 3) and open a new terminal |
| `[hero_sim] ERROR: config not found` | Check the scenario's path: `ls ~/ros2_ws/src/undergrad_project_mrs/scenarios` |
| `unknown key(s)` when the simulator starts | A typo in your scenario. The error names the key and lists the allowed ones |
| `sim.map and obstacles: are both set` | A scenario has pillars or a map, not both. Set `map: null` |
| `tether.object starts inside obstacles[...]` | Move the object or that pillar. The number counts the pillars from 0 |
| Your node keeps printing `waiting for ... (is the simulator running?)` | Start the simulator. If it's running, check that the robot names in your node match the scenario |
| A robot doesn't move | It may be pressed against an obstacle: command it away. Check that the simulator is running: `ros2 node list` |
| A `go_to` stops right away | Something keeps publishing `cmd_vel` to that robot, such as a `ros2 topic pub` without `--once` |
