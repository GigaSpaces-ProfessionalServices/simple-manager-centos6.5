#!/bin/bash -e

export ELASTICSEARCH_HOME="/opt/elasticsearch"
ctx logger info "Starting Elasticsearch...
"
sudo initctl start elasticsearch