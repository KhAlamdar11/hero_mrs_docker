import os
import yaml
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration, PythonExpression
from launch.conditions import IfCondition
from launch_ros.actions import Node, SetParameter

def generate_launch_description():
    
    # load crazyflies
    cfs_yaml="crazyflies_real.yaml"
        
    crazyflies_yaml = os.path.join(
        get_package_share_directory('icuas26_finals'),
        'config',
        cfs_yaml)

    with open(crazyflies_yaml, 'r') as ymlfile:
        crazyflies = yaml.safe_load(ymlfile)
    
    fileversion = 1
    if "fileversion" in crazyflies:
        fileversion = crazyflies["fileversion"]

    # server params
    server_yaml = os.path.join(
        get_package_share_directory('crazyflie'),
        'config',
        'server.yaml')

    with open(server_yaml, 'r') as ymlfile:
        server_yaml_content = yaml.safe_load(ymlfile)

    server_params = [crazyflies] + [server_yaml_content['/crazyflie_server']['ros__parameters']]
    # robot description
    urdf = os.path.join(
        get_package_share_directory('crazyflie'),
        'urdf',
        'crazyflie_description.urdf')
    
    with open(urdf, 'r') as f:
        robot_desc = f.read()

    server_params[1]['robot_description'] = robot_desc
    
    charging_file = os.environ.get('CHARGING_FILE', '')
    charge_yaml = os.path.join(
        get_package_share_directory('icuas26_finals'),
        'config',
        charging_file)
    
    # construct motion_capture_configuration
    motion_capture_yaml = os.path.join(
                                get_package_share_directory('icuas26_finals'),
                                'config',
                                'motion_capture.yaml')
    with open(motion_capture_yaml, 'r') as ymlfile:
        motion_capture_content = yaml.safe_load(ymlfile)

    motion_capture_params = motion_capture_content['/motion_capture_tracking']['ros__parameters']
    motion_capture_params['rigid_bodies'] = dict()
    for key, value in crazyflies['robots'].items():
        type = crazyflies['robot_types'][value['type']]
        if value['enabled'] and \
            ((fileversion == 1 and type['motion_capture']['enabled']) or \
            ((fileversion >= 2 and type['motion_capture']['tracking'] == "librigidbodytracker"))):
            motion_capture_params['rigid_bodies'][key] =  {
                    'initial_position': value['initial_position'],
                    'marker': type['motion_capture']['marker'],
                    'dynamics': type['motion_capture']['dynamics'],
                }
    # copy relevent settings to server params
    server_params[1]['poses_qos_deadline'] = motion_capture_params['topics']['poses']['qos']['deadline']
    

    launch_description = []
    cfs_server_node = 'crazyflie_server_reconnect_new.py'   
    launch_description.append(
        Node(
            package='icuas26_finals',
            executable=cfs_server_node,
            name='crazyflie_server',
            output='screen',
            parameters=server_params
        ))
    
   
    launch_description.append(
    Node(
        package='motion_capture_tracking',
        executable='motion_capture_tracking_node',
        name='motion_capture_tracking',
        output='screen',
        parameters= [motion_capture_params],
    ))
    
    num_bots = int(os.environ.get('NUM_ROBOTS', '4'))
    
    # Add vel_mux nodes dynamically based on the number parameter
    for i in range(1, int(num_bots) + 1):
        namespace = f'cf_{i}'
        vel_mux_node = Node(
            package='crazyflie',
            executable='vel_mux.py',
            name=f'vel_mux{i}',
            output='screen',
            namespace=namespace,
            parameters=[
                {"hover_height": 1.0},
                {"incoming_twist_topic": "cmd_vel"},
                {"robot_prefix": f"/{namespace}"}
            ]
        )
        launch_description.append(vel_mux_node)
    AGV_path = os.environ.get('AGV_PATH', '')
    
    AGV_yaml_path = os.path.join(
        get_package_share_directory('icuas26_finals'),
        'config',
        AGV_path)
    
    AGV_vel = float(os.environ.get('AGV_VEL', '0.3'))
    
    launch_description.append(
        Node(
           package='icuas26_finals',
           executable='AGV.py',
           name='AGV',
           namespace='AGV',
           output='screen',
           parameters=[
                {"velocity": AGV_vel},
                {"publish_rate": 10.0},
                {"yaml_path": AGV_yaml_path}
            ]
       ))
    
    launch_description.append(       
        Node(
            package='rviz2',
            namespace='',
            executable='rviz2',
            name='rviz2',
            arguments=['-d' + os.path.join(get_package_share_directory('icuas26_finals'), 'config', 'config.rviz')]
        )
        
    )
    return LaunchDescription(launch_description)
