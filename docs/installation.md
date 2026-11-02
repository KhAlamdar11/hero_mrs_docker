# Installation

Do these three steps at home, before the first session. They take about an hour, mostly downloading.

> [!IMPORTANT]
> **You need:**
> - **Ubuntu 22.04 or 24.04** on your laptop
> - **20–25 GB of free disk space**. Check the `Avail` column of `df -h /`

1. [Install Docker](#step-1-install-docker)
2. [Build the image](#step-2-build-the-image)
3. [Create the container and run the example](#step-3-create-the-container-and-run-the-example)

If a step fails, look in [Troubleshooting](#troubleshooting).

## Step 1: Install Docker

1. Install the tools you need for the next steps:
   ```bash
   sudo apt update && sudo apt install -y curl git
   ```
2. Install Docker:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   ```
   If Docker is already installed, the script warns you and waits 20 seconds. Let it continue: it updates Docker and keeps your images.
3. Let your user run Docker without `sudo`:
   ```bash
   sudo usermod -aG docker $USER
   ```
   Then restart your laptop.
4. Check that Docker works. It prints `Hello from Docker!`:
   ```bash
   docker run hello-world
   ```
5. Only if your laptop has an NVIDIA GPU, which means `nvidia-smi` prints a table: install the NVIDIA Container Toolkit.
   ```bash
   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
   curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
   sudo apt update && sudo apt install -y nvidia-container-toolkit
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```

## Step 2: Build the image

1. Download this repository:
   ```bash
   cd ~
   git clone https://github.com/KhAlamdar11/hero_mrs_docker.git
   cd hero_mrs_docker
   ```
2. Build the image. This takes 30 to 60 minutes:
   ```bash
   docker build -t hero_mrs_image .
   ```
3. Check that it worked. `hero_mrs_image` should be in the list:
   ```bash
   docker images
   ```

## Step 3: Create the container and run the example

1. Download the student package, where you'll write your code:
   ```bash
   cd ~
   git clone https://github.com/KhAlamdar11/undergrad_project_mrs.git
   ```
2. Open `~/hero_mrs_docker/first_run.sh` and set `MY_PACKAGE_PATH` at the top to that folder:
   ```bash
   MY_PACKAGE_PATH="~/undergrad_project_mrs"
   ```
3. If your laptop has no NVIDIA GPU (you skipped step 1.5), delete the `--gpus all \` line in `first_run.sh`.
4. Allow the container to open windows on your screen. This line makes every new terminal do it:
   ```bash
   echo 'xhost +local: > /dev/null 2>&1' >> ~/.bashrc
   source ~/.bashrc
   ```
5. Create the container. It builds the workspace (a few minutes) and opens a terminal inside the container:
   ```bash
   cd ~/hero_mrs_docker
   ./first_run.sh
   ```
6. In that terminal, start the simulator. RViz opens:
   ```bash
   cd ~/ros2_ws/src/hero_sim/startup
   bash start.sh tether_demo.yaml
   ```
7. Open a new tmux window with `Ctrl+b`, then `c`, and run the example mission:
   ```bash
   ros2 run undergrad_project_mrs mission_template
   ```
   In RViz, the ground robot drives, the drone takes off and lands, and the winch pulls the tether. It prints `done` at the end.
8. Stop the simulator with `Ctrl+b`, then `k`. Leave the container with `exit`.

Your package is in the container at `~/ros2_ws/src/undergrad_project_mrs`. It's the same folder as `~/undergrad_project_mrs` on your laptop, so you can edit the code on your laptop and run it in the container.

The package folder is set when the container is created. To change it later, set `MY_PACKAGE_PATH` again and [start over](../README.md#start-over-with-a-fresh-container).

You're done. From now on, use the [quick start](../README.md#quick-start) in the main README.

## Troubleshooting

| Problem | What to do |
|---|---|
| `sudo apt update` fails with `NO_PUBKEY`, `EXPKEYSIG` or `is not signed` | The error names a repository that's broken on your laptop, often an old ROS one. Fix it or delete its file in `/etc/apt/sources.list.d/`, then try again |
| You already had Docker from snap (`snap list docker` lists it) | Two Dockers clash. Remove the snap one with `sudo snap remove docker` (this deletes its images) and restart |
| You already had Docker Desktop (`docker context ls` marks `desktop-linux` with `*`) | Switch to the Docker from step 1: `docker context use default` |
| `permission denied` when running `docker` | Do [step 1.3](#step-1-install-docker) and restart your laptop |
| The build stops with a network error | Run the same `docker build` again. It continues where it stopped |
| `could not select device driver "" with capabilities: [[gpu]]` | No NVIDIA GPU or toolkit: do [step 3.3](#step-3-create-the-container-and-run-the-example) |
| `Set MY_PACKAGE_PATH at the top of first_run.sh ...` | Do [step 3.2](#step-3-create-the-container-and-run-the-example). The folder must exist |
| `Conflict. The container name "/hero_mrs_container" is already in use` | The container already exists: `docker start -i hero_mrs_container`. To create it again, see [start over](../README.md#start-over-with-a-fresh-container) |
| RViz doesn't open (`could not connect to display`) | Do [step 3.4](#step-3-create-the-container-and-run-the-example), then open a new terminal and try again |
