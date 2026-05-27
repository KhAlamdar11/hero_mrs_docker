#!/bin/bash
 
export NUM_ROBOTS=3
export KEYWORD=icuas26_2 #icuas26_1 or empty
export COMM_RANGE=2
export ENV_NAME=${KEYWORD}_world
export MIN_BATTERY=3.1
export MAX_VEL=1.0
export MIN_HOR_DIST=0.3
export AGV_VEL=0.1
export AGV_PATH=AGV_path_$KEYWORD.yaml
export TEAM_NAME="LARICS"