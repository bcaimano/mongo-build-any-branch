#!/bin/bash

set -euo pipefail

set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Skip to the root folder to make it easy
cd "${MONGO_REPO:-.}"

export VIRTUAL_ENV_DISABLE_PROMPT=1
VENV_DIR=".venv-${VERSION_BRANCH}"
VENV_STAMP="${VENV_DIR}/stamp"
if [[ ! -f ${VENV_STAMP} ]]; then
    # Set up a virtualenv
    rm -rf "${VENV_DIR}"

    if [[ $VERSION_BRANCH == v4.4 || $VERSION_BRANCH == v4.2 ]]; then
        /opt/mongodbtoolchain/v3/bin/python3 -m venv "${VENV_DIR}"
        . "${VENV_DIR}/bin/activate"
    	pip install -r ./etc/pip/toolchain-requirements.txt || true
    elif [[ $VERSION_BRANCH == v4.0 || $VERSION_BRANCH == v3.6 ]]; then
        /opt/mongodbtoolchain/v2/bin/python -m virtualenv "${VENV_DIR}"
        . "${VENV_DIR}/bin/activate"
    	pip install -r ./buildscripts/requirements.txt || true
    fi
    
    date --iso-8601 >${VENV_STAMP}
else
    # Activate an existing virtualenv
    . "${VENV_DIR}/bin/activate"
fi

# Call scons with virtualenv python
SCONS_CMD=(
    "$(which python)"
    "./buildscripts/scons.py"
)

# Set essential flags
SCONS_CMD+=(
    --ssl
    # --disable-warnings-as-errors
)

# Set up the cache
SCONS_CMD+=(
    --cache
    --cache-dir="/data/workspace/build/cache"
)

if [[ $VERSION_BRANCH == v4.4 ]]; then
    # Include the variable files
    VAR_FILE="${DIR}/workstation_variables.py"
    SCONS_CMD+=(
        --variables-files="./etc/scons/mongodbtoolchain_stable_gcc.vars"
        --variables-files="${VAR_FILE}"
    )

    # Set build mode flags explicitly
    SCONS_CMD+=(
        --install-mode=hygienic
        --link-model=dynamic
    )

    # Set the concurrency
    SCONS_CMD+=(
        --jobs=500
        --jlink=4
    )
elif [[ $VERSION_BRANCH == v4.2 ]]; then
    # Include the variable files
    VAR_FILE="${DIR}/workstation_variables.py"
    SCONS_CMD+=(
        --variables-files="./etc/scons/mongodbtoolchain_stable_gcc.vars"
        --variables-files="${VAR_FILE}"
    )

    # Set build mode flags explicitly
    SCONS_CMD+=(
        --install-mode=hygienic
        --link-model=static
    )

    # Set the concurrency
    SCONS_CMD+=(
        --jobs=500
        --jlink=4
    )
elif [[ $VERSION_BRANCH == v4.0 ]]; then
    # Include the variable files
    VAR_FILE="${DIR}/workstation_variables.py"
    SCONS_CMD+=(
        --variables-files="./etc/scons/mongodbtoolchain_stable_gcc.vars ${VAR_FILE}"
    )

    # Set build mode flags explicitly
    SCONS_CMD+=(
        --install-mode=hygienic
        --link-model=static
    )

    # Set the concurrency
    SCONS_CMD+=(
        --jobs=500
        --jlink=4
    )
elif [[ $VERSION_BRANCH == v3.6 ]]; then
    # Include the variable files
    VAR_FILE="${DIR}/workstation_variables.py"
    SCONS_CMD+=(
        --variables-files="./etc/scons/mongodbtoolchain_stable_gcc.vars ${VAR_FILE}"
    )

    # Set build mode flags explicitly
    SCONS_CMD+=(
        --link-model=static
    )

    # Set the concurrency
    SCONS_CMD+=(
        --jobs=64
    )
else
    1>&2 echo 'No $VERSION_BRANCH specified'
    exit 1
fi

# Run the command
time "${SCONS_CMD[@]}" "${@}"
