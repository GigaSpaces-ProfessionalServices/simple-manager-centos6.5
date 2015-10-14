#!/bin/bash -e

. $(ctx download-resource "components/utils")


export AMQPINFLUX_RPM_SOURCE_URL=$(ctx node properties amqpinflux_rpm_source_url)
export AMQPINFLUX_SOURCE_URL=$(ctx node properties amqpinflux_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-amqp-influxdb/archive/3.2.zip")

export AMQPINFLUX_HOME="/opt/amqpinflux"
export AMQPINFLUX_VIRTUALENV_DIR="${AMQPINFLUX_HOME}/env"

CONFIG_INIT_PATH="components/amqpinflux/config/upstart"
CONFIG_INIT_DEST="/etc/init"

ctx logger info "Installing AQMPInflux..."
set_selinux_permissive

copy_notice "amqpinflux"
create_dir "${AMQPINFLUX_HOME}"

# this create the AMQPINFLUX_VIRTUALENV_DIR and installs the module into it.
# yum_install ${AMQPINFLUX_RPM_SOURCE_URL}

# For centos6.5 since we are not using yum we need to create the virtual dir
create_virtualenv "${AMQPINFLUX_VIRTUALENV_DIR}"

# this allows to upgrade amqpinflux if necessary.
[ -z "${AMQPINFLUX_SOURCE_URL}" ] || install_module ${AMQPINFLUX_SOURCE_URL} "${AMQPINFLUX_VIRTUALENV_DIR}"

#configure_systemd_service "amqpinflux"
deploy_blueprint_resource "${CONFIG_INIT_PATH}/cloudify-amqpinflux.conf" "${CONFIG_INIT_DEST}/cloudify-amqpinflux.conf"