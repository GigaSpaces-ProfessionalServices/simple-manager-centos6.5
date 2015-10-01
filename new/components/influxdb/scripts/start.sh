#!/bin/bash -e

ctx logger info "Starting InfluxDB..."
#sudo systemctl start cloudify-influxdb.service
sudo initctl start cloudify-influxdb