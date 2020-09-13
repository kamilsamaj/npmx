#!/bin/bash -e

NPMX_BASE_DIR="$HOME/npmx"

function check_npmx_base_dir() {
    if [[ ! -d "$NPMX_BASE_DIR" ]]; then
        echo "Creating npmx base directory $NPMX_BASE_DIR"
        mkdir -p "$NPMX_BASE_DIR/{bin,npms}"
    fi
}

function usage() {
cat << EOF
    Usage: $0 install <npm_package_name>
        - npm_package_name: Name of a valid npm package name
EOF
}

function create_symlinks() {
    echo
}

# usage:
# install npm_package_name
function install() {
    # create a separate directory for each npm package
    local npmx_pkg_name
    npmx_pkg_name="$1"
    mkdir -p "$NPMX_BASE_DIR/npms/$npmx_pkg_name"

    # run in a sub-shell to return back
    ( \
        cd "$NPMX_BASE_DIR/npms/$npmx_pkg_name"; \
        npm install "$npmx_pkg_name"; \
        cd "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin"
        for FILE in *; do
            ln -s \
                "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin/$FILE" \
                "$NPMX_BASE_DIR/bin/$FILE"
        done
    )
}

### MAIN CODE
# basic argument check
if [[ $# -ne 2 ]]; then
    usage
    exit 1
fi


NPMX_COMMAND="$1"
NPMX_PACKAGE_NAME="$2"

check_npmx_base_dir

if [[ "$NPMX_COMMAND" = "install" ]]; then
    install "$NPMX_PACKAGE_NAME"
else
    echo "Command $1 not recognized" >&2
    usage
    exit 1
fi

