#!/bin/bash -e

NPMX_BASE_DIR="$HOME/.npmx"

function check_npmx_base_dir() {
    if [[ ! -d "$NPMX_BASE_DIR" ]]; then
        echo "Creating npmx base directory $NPMX_BASE_DIR"
        mkdir -p "$NPMX_BASE_DIR"/{bin,npms}
    fi
}

# check if $PATH variable contains $NPMX_BASE_DIR/bin
function check_npmx_is_in_path() {
    if [[ ! ":$PATH:" == *":$NPMX_BASE_DIR/bin:"* ]]; then
        echo "Your path is missing $NPMX_BASE_DIR/bin, please add it with:"
        echo "    export PATH=\"\$PATH:$NPMX_BASE_DIR/bin\"."
        exit 1
    fi
}

# print help message
function usage() {
cat << EOF
    Usage: $0 install <npm_package_name>
        - npm_package_name: Name of a valid npm package name
EOF
}

# create symbolic links with available CLI commands in node_modules/.bin directory
# usage: create_symlinks $SRC_BIN_DIR $DST_BIN_DIR
function create_symlinks() {
    local src_bin_dir
    local dst_bin_dir
    local bin_file
    local short_bin_file

    src_bin_dir="$1"
    dst_bin_dir="$2"

    if [[ ! -d "$src_bin_dir" ]]; then
        echo "ERROR: $src_bin_dir does not exit, exiting ..."
        exit 1
    fi

    if [[ ! -d "$dst_bin_dir" ]]; then
        echo "ERROR: $dst_bin_dir does not exit, exiting ..."
        exit 1
    fi

    for bin_file in "$src_bin_dir"/*; do
        short_bin_file="$(basename $bin_file)"
        if [[ ! -f "$dst_bin_dir/$short_bin_file" ]]; then
            echo "Found commnand $short_bin_file, creating a symlink to it"
            ln -s \
                "$src_bin_dir/$short_bin_file" \
                "$dst_bin_dir/$short_bin_file"
        else
            echo "WARNING: File $dst_bin_dir/$short_bin_file already exists, not creating a symlink"
        fi
    done

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
        create_symlinks \
            "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" \
            "$NPMX_BASE_DIR/bin"
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

# do environment setup checks
check_npmx_base_dir
check_npmx_is_in_path

if [[ "$NPMX_COMMAND" = "install" ]]; then
    install "$NPMX_PACKAGE_NAME"
else
    echo "Command $1 not recognized" >&2
    usage
    exit 1
fi

