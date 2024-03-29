#!/bin/bash -e

. $(ctx download-resource "components/utils")

CONFIG_REL_PATH="components/nginx/config"
SSL_RESOURCES_REL_PATH="resources/ssl"


export NGINX_SOURCE_URL=$(ctx node properties nginx_rpm_source_url)  # (e.g. "https://dl.dropboxusercontent.com/u/407576/3.2/nginx-1.8.0-1.el7.ngx.x86_64.rpm")
export REST_SERVICE_SOURCE_URL=$(ctx node properties rest_service_module_source_url)  # (e.g. "https://github.com/cloudify-cosmo/cloudify-manager/archive/master.tar.gz")


export NGINX_LOG_PATH="/var/log/cloudify/nginx"
# export NGINX_REPO="http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm"
export MANAGER_RESOURCES_HOME="/opt/manager/resources"
export MANAGER_AGENTS_PATH="${MANAGER_RESOURCES_HOME}/packages/agents"
export MANAGER_SCRIPTS_PATH="${MANAGER_RESOURCES_HOME}/packages/scripts"
export MANAGER_TEMPLATES_PATH="${MANAGER_RESOURCES_HOME}/packages/templates"
export SSL_CERTS_ROOT="/root/cloudify"


CONFIG_INIT_PATH="components/nginx/config/upstart"
CONFIG_INIT_DEST="/etc/init"

# this is propagated to the agent retrieval script later on so that it's not defined twice.
ctx instance runtime_properties agent_packages_path "${MANAGER_AGENTS_PATH}"

# TODO can we use static (not runtime) attributes for some of these? how to set them?
ctx instance runtime_properties default_rest_service_port "8100"
ctx instance runtime_properties ssl_rest_service_port "443"
ctx instance runtime_properties internal_rest_service_port "8101"

ctx logger info "Installing Nginx..."
set_selinux_permissive

copy_notice "nginx"
create_dir ${NGINX_LOG_PATH}
create_dir ${MANAGER_RESOURCES_HOME}
create_dir ${SSL_CERTS_ROOT}

create_dir ${MANAGER_AGENTS_PATH}
create_dir ${MANAGER_SCRIPTS_PATH}
create_dir ${MANAGER_TEMPLATES_PATH}

yum_install ${NGINX_SOURCE_URL}

ctx logger info "Deploying Nginx configuration files..."
deploy_blueprint_resource "${CONFIG_REL_PATH}/default.conf" "/etc/nginx/conf.d/default.conf"
deploy_blueprint_resource "${CONFIG_REL_PATH}/rest-location.cloudify" "/etc/nginx/conf.d/rest-location.cloudify"

ctx logger info "Configuring logrotate..."
lconf="/etc/logrotate.d/nginx"

cat << EOF | sudo tee $lconf >/dev/null
$NGINX_LOG_PATH/*.log {
        daily
        missingok
        rotate 7
        compress
        delaycompress
        notifempty
        create 640 nginx adm
        sharedscripts
        postrotate
                [ -f /var/run/nginx.pid ] && kill -USR1 \$(cat /var/run/nginx.pid)
        endscript
}
EOF

sudo chmod 644 $lconf


ctx logger info "Copying SSL Certs..."
deploy_blueprint_resource "${SSL_RESOURCES_REL_PATH}/server.crt" "${SSL_CERTS_ROOT}/server.crt"
deploy_blueprint_resource "${SSL_RESOURCES_REL_PATH}/server.key" "${SSL_CERTS_ROOT}/server.key"

deploy_blueprint_resource "${CONFIG_INIT_PATH}/nginx.conf" "${CONFIG_INIT_DEST}/nginx.conf"
