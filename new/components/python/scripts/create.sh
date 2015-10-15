#!/bin/bash -e

. $(ctx download-resource "components/utils")


PIP_SOURCE_RPM_URL=$(ctx node properties pip_source_rpm_url)
INSTALL_PYTHON_COMPILERS=$(ctx node properties install_python_compilers)

ctx logger info "Installing Python requirements..."
set_selinux_permissive
copy_notice "python"

ctx logger info "No need to install pip, pip 2.7 already installed..."
# not need for python installation at this point since 2.7 was already installed
#yum_install ${PIP_SOURCE_RPM_URL}

# already installed on setup

#if [ ! -z "${INSTALL_PYTHON_COMPILERS}" ]; then
#    ctx logger info "Installing Compilers..."
#    yum_install "python-devel gcc" >/dev/null
#fi
