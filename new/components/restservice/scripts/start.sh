#!/bin/bash -e

ctx logger info "Starting Rest Service via Gunicorn..."
sudo initctl start cloudify-restservice
	