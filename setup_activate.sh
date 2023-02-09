#!/bin/bash

function _ansible_setup_getdir {(
    set +o physical
    local basenamed="${me##*/}"
    local dirnamed="${me%"$basenamed"}"
    if [[ -n "${dirnamed}" ]] ; then
        builtin cd "${dirnamed}"
    fi
    local absolute="$(builtin pwd -L)" # -L: dont resolve symlinks
    printf "%s" "${absolute}"
)}

function _ansible_setup_main {
    local me="${BASH_SOURCE[0]}"
    local repo="$(_ansible_setup_getdir)"
    if [[ -z HOSTNAME ]] ; then
        echo "HOSTNAME isn't set"  >&2
        return 2
    fi
    local venv="${repo}/venv/${HOSTNAME}"
    mkdir -p "${repo}/venv" || return $?
    if type deactivate &>/dev/null ; then
        deactivate
    fi
    if ! [[ -f "${venv}/bin/activate" ]] ; then
        python3 -m virtualenv "${venv}" || return $?
    fi
    if [[ -f "${venv}/bin/activate" ]] ; then
        echo "Virtual Environment: ${venv}"  >&2
    else
        echo "Don't know where venv is..."  >&2
        return 4
    fi
    source "${venv}/bin/activate" || return $?
    if ! type deactivate &>/dev/null ;  then
        echo "Didn't activate?"  >&2
        return 5
    fi
    PIP="${venv}/bin/pip"
    "${PIP}" install --upgrade --upgrade-strategy eager ansible || return $?
    local cfg="${repo}/ansible.cfg"
    if [[ -f "${cfg}" ]] ; then
        echo "Ansible config: ${cfg}"  >&2
    else
        echo "Don't know where ansible.cfg is..." >&2
    fi
    export ANSIBLE_NOCOWS=1
    export ANSIBLE_CONFIG="${cfg}"
}

if ( return 0 2>/dev/null ) ; then
    _ansible_setup_main || return $?
else
    echo "Source this, don't run it."  >&2
    exit 1
fi
