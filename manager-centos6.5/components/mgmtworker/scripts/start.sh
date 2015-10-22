#!/bin/bash -e

ctx logger info "Starting Management Worker..."
sudo initctl start cloudify-mgmtworker
	
# sudo ${MGMTWORKER_HOME}/startup.sh