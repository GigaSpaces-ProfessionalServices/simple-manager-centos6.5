#!/bin/bash -e

ctx logger info "Starting Riemann..."
#sudo systemctl start cloudify-riemann.service
sudo initctl start cloudify-riemann