#!/bin/bash -e

. $(ctx download-resource "components/utils")


export AMQPINFLUX_HOME="/opt/amqpinflux"
export AMQPINFLUX_VIRTUALENV_DIR="${AMQPINFLUX_HOME}/env"
export AMQPINFLUX_SOURCE_URL=$(ctx node properties amqpinflux_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-amqp-influxdb/archive/master.tar.gz")

CONFIG_INIT_PATH="components/amqpinflux/config/upstart"
CONFIG_INIT_DEST="/etc/init"

ctx logger info "Installing AQMPInflux..."

copy_notice "amqpinflux"
create_dir "${AMQPINFLUX_HOME}"
create_virtualenv "${AMQPINFLUX_VIRTUALENV_DIR}"
install_module "${AMQPINFLUX_SOURCE_URL}" "${AMQPINFLUX_VIRTUALENV_DIR}"

####configure_systemd_service "amqpinflux"
deploy_blueprint_resource "${CONFIG_INIT_PATH}/amqpinflux.conf" "${CONFIG_INIT_DEST}/amqpinflux.conf"