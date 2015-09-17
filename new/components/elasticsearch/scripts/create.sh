#!/bin/bash -e

. $(ctx download-resource "components/utils")
. $(ctx download-resource "components/elasticsearch/scripts/configure_es")


CONFIG_REL_PATH="components/elasticsearch/config"

export ES_JAVA_OPRT=$(ctx node properties es_java_opts)  # (e.g. "-Xmx1024m -Xms1024m")
export ES_JAVA_OPTS=$(ctx node properties es_java_opts)  # (e.g. "-Xmx1024m -Xms1024m")
export ES_HEAP_SIZE=$(ctx node properties es_heap_size)
export ES_HEAP_SIZE=${ES_HEAP_SIZE:-1g}

export ELASTICHSEARCH_SOURCE_URL=$(ctx node properties es_rpm_source_url)  # (e.g. "https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.6.0.noarch.rpm")

export ELASTICSEARCH_PORT="9200"
export ELASTICSEARCH_HOME="/opt/elasticsearch"
export ELASTICSEARCH_LOG_PATH="/var/log/cloudify/elasticsearch"
export ELASTICSEARCH_CONF_PATH="/etc/elasticsearch"

CONFIG_INIT_PATH="components/elasticsearch/config/upstart"
CONFIG_INIT_DEST="/etc/init"

ctx logger info "Installing Elasticsearch..."

copy_notice "elasticsearch"
create_dir ${ELASTICSEARCH_HOME}
create_dir ${ELASTICSEARCH_LOG_PATH}
	
yum_install ${ELASTICHSEARCH_SOURCE_URL}

ctx logger info "Stop elasticsearch service after Install just in case..."
sudo service elasticsearch stop

# we should treat these as templates.
ctx logger info "Setting Elasticsearch Heap size..."
replace "#ES_HEAP_SIZE=2g" "ES_HEAP_SIZE=${ES_HEAP_SIZE}" "/etc/sysconfig/elasticsearch"

if [ ! -z "${ES_JAVA_OPTS}" ]; then
    ctx logger info "Setting additional Java OPTS..."
    replace "#ES_JAVA_OPTS=" "ES_JAVA_OPTS=${ES_JAVA_OPTS}" "/etc/sysconfig/elasticsearch"
fi

ctx logger info "Deploying Elasticsearch Configuration..."
deploy_blueprint_resource "${CONFIG_REL_PATH}/elasticsearch.yml" "${ELASTICSEARCH_CONF_PATH}/elasticsearch.yml"
sudo chown elasticsearch:elasticsearch ${ELASTICSEARCH_LOG_PATH}
hostName=`hostname`
echo "127.0.0.1   ${hostName}" | sudo tee -a /etc/hosts   

ctx logger info "Starting Elasticsearch for configuration purposes..."
####sudo systemctl enable elasticsearch.service &>/dev/null
deploy_blueprint_resource "${CONFIG_INIT_PATH}/elasticsearch.conf" "${CONFIG_INIT_DEST}/elasticsearch.conf"

sudo rm -f /etc/init.d/elasticsearch
sudo initctl start elasticsearch

ctx logger info "Waiting for Elasticsearch to become available..."
wait_for_port "${ELASTICSEARCH_PORT}"

ctx logger info "Configuring Elasticsearch Indices, Mappings, etc..."
# per a function in configure_es
configure_elasticsearch

ctx logger info "Stopping Elasticsearch Service..."
sudo initctl stop elasticsearch

ctx logger info "Installing Elasticsearch Curator..."
install_module "elasticsearch-curator==3.2.0"

rotator_script=$(ctx download-resource-and-render components/elasticsearch/scripts/rotate_es_indices)

ctx logger info "Configuring Elasticsearch Index Rotation cronjob for logstash-YYYY.mm.dd index patterns..."
# testable manually by running: sudo run-parts /etc/cron.daily
sudo mv ${rotator_script} /etc/cron.daily/rotate_es_indices
sudo chown -R root:root /etc/cron.daily/rotate_es_indices
sudo chmod +x /etc/cron.daily/rotate_es_indices
