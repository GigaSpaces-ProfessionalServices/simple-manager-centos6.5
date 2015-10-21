#!/bin/bash -e

. $(ctx download-resource "components/utils")


export MANAGEMENT_WORKER_RPM_SOURCE_URL=$(ctx node properties management_worker_rpm_source_url)
export REST_CLIENT_SOURCE_URL=$(ctx node properties rest_client_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-rest-client/archive/3.3m5.tar.gz")
export PLUGINS_COMMON_SOURCE_URL=$(ctx node properties plugins_common_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-plugins-common/archive/3.3m5.tar.gz")
export SCRIPT_PLUGIN_SOURCE_URL=$(ctx node properties script_plugin_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-script-plugin/archive/1.3m5.tar.gz")
export REST_SERVICE_SOURCE_URL=$(ctx node properties rest_service_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-manager/archive/3.3m5.tar.gz")
export AGENT_SOURCE_URL=$(ctx node properties agent_module_source_url)

# This will only be used if the management worker is not installed via an RPM
export CELERY_VERSION="3.1.17"

# these must all be exported as part of the start operation. they will not persist, so we should use the new agent
# don't forget to change all localhosts to the relevant ips
export MGMTWORKER_HOME="/opt/mgmtworker"
export MGMTWORKER_VIRTUALENV_DIR="${MGMTWORKER_HOME}/env"
export CELERY_WORK_DIR="${MGMTWORKER_HOME}/work"
export CELERY_LOG_DIR="/var/log/cloudify/mgmtworker"


CONFIG_INIT_PATH="components/mgmtworker/config/upstart"
CONFIG_INIT_DEST="/etc/init"


ctx logger info "Installing Management Worker..."
set_selinux_permissive

copy_notice "mgmtworker"
create_dir ${MGMTWORKER_HOME}
create_dir ${MGMTWORKER_HOME}/config
create_dir ${CELERY_LOG_DIR}
create_dir ${CELERY_WORK_DIR}

# this create the MGMTWORKER_VIRTUALENV_DIR and installs the relevant modules into it.
## rpm is not support on centos6.5
#yum_install ${MANAGEMENT_WORKER_RPM_SOURCE_URL}

# in centos6.5 we are not using yum so we need to create the virtualenv dir
create_virtualenv "${MGMTWORKER_VIRTUALENV_DIR}"

# this allows to upgrade modules if necessary.
ctx logger info "Installing Optional Management Worker Modules..."
#[ -z ${MANAGEMENT_WORKER_RPM_SOURCE_URL} ] && install_module "celery==${CELERY_VERSION}" ${MGMTWORKER_VIRTUALENV_DIR}
install_module "celery==${CELERY_VERSION}" ${MGMTWORKER_VIRTUALENV_DIR}
install_module ${REST_CLIENT_SOURCE_URL} ${MGMTWORKER_VIRTUALENV_DIR}
install_module ${PLUGINS_COMMON_SOURCE_URL} ${MGMTWORKER_VIRTUALENV_DIR}
install_module ${SCRIPT_PLUGIN_SOURCE_URL} ${MGMTWORKER_VIRTUALENV_DIR}
install_module ${AGENT_SOURCE_URL} ${MGMTWORKER_VIRTUALENV_DIR}

if [ ! -z ${REST_SERVICE_SOURCE_URL} ]; then
    ctx logger info "Downloading cloudify-manager Repository..."
    manager_repo=$(download_file ${REST_SERVICE_SOURCE_URL})
    ctx logger info "Extracting Manager Repository..."
    tar -xzvf ${manager_repo} --strip-components=1 -C "/tmp" >/dev/null

    ctx logger info "Installing Management Worker Plugins..."
    # shouldn't we extract the riemann-controller and workflows modules to their own repos?
    install_module "/tmp/plugins/riemann-controller" ${MGMTWORKER_VIRTUALENV_DIR}
    install_module "/tmp/workflows" ${MGMTWORKER_VIRTUALENV_DIR}
fi

deploy_blueprint_resource "${CONFIG_INIT_PATH}/cloudify-mgmtworker.conf" "${CONFIG_INIT_DEST}/cloudify-mgmtworker.conf"
