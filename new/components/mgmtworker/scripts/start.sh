#!/bin/bash -e

ctx logger info "Starting Management Worker..."
sudo initctl start mgmtworker
	
# sudo ${MGMTWORKER_HOME}/startup.sh