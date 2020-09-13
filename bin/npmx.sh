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
    Usage: $0 {install, uninstall, update, help} <npm_package_name>

    Subcommands:
        install             Install a new NPM package to it's own subdirectory
        update              Update an existing NPMX installation
        uninstall           Uninstall an existing NPMX installation
        help                Print this help message
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

# unlink previous symbolic links
# usage: unlink_symlinks $SRC_BIN_DIR $DST_BIN_DIR
function unlink_symlinks() {
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
        if [[ -f "$dst_bin_dir/$short_bin_file" ]]; then
            unlink "$dst_bin_dir/$short_bin_file"
        else
            echo "WARNING: Symbolic linke to $dst_bin_dir/$short_bin_file does not exist, not unlinking"
        fi
    done
}

# usage: update $NPMX_PKG_NAME
function install() {

    # create a separate directory for each npm package
    local npmx_pkg_name
    npmx_pkg_name="$1"
    mkdir -p "$NPMX_BASE_DIR/npms/$npmx_pkg_name"

    if [[ -d "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" ]]; then
        echo "ERROR: $npmx_pkg_name already installed, run '$0 update ...' instead. Exiting ..."
        exit 1
    fi
    # run in a sub-shell to return back
    ( \
        cd "$NPMX_BASE_DIR/npms/$npmx_pkg_name"; \
        npm install "$npmx_pkg_name"; \
        create_symlinks \
            "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" \
            "$NPMX_BASE_DIR/bin"
    )
}

# update an installed npmx
# usage: update $NPMX_PKG_NAME
function update() {
    local npmx_pkg_name
    npmx_pkg_name="$1"

    if [[ ! -d "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" ]]; then
        echo "ERROR: $npmx_pkg_name NOT installed, run '$0 install ...' instead. Exiting ..."
        exit 1
    fi

    # unlink all previous links to NOT have stalled links
    unlink_symlinks \
            "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" \
            "$NPMX_BASE_DIR/bin"

    # run in a sub-shell to return back
    ( \
        cd "$NPMX_BASE_DIR/npms/$npmx_pkg_name"; \
        echo "Updating $npmx_pkg_name"; \
        npm update "$npmx_pkg_name"; \
        create_symlinks \
            "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" \
            "$NPMX_BASE_DIR/bin"
    )
}

# uninstall an installed npmx
# usage: uninstall $NPMX_PKG_NAME
function uninstall() {
    local npmx_pkg_name
    npmx_pkg_name="$1"

    if [[ ! -d "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" ]]; then
        echo "ERROR: $npmx_pkg_name NOT installed. Exiting ..."
        exit 1
    fi

    # unlink all previous links
    unlink_symlinks \
            "$NPMX_BASE_DIR/npms/$npmx_pkg_name/node_modules/.bin" \
            "$NPMX_BASE_DIR/bin"

    # run in a sub-shell to return back
    ( \
        cd "$NPMX_BASE_DIR/npms/$npmx_pkg_name"; \
        echo "Updating $npmx_pkg_name"; \
        npm uninstall "$npmx_pkg_name"; \
        echo "Removing $NPMX_BASE_DIR/npms/$npmx_pkg_name directory"; \
        rm -rf "$NPMX_BASE_DIR/npms/$npmx_pkg_name"
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

# run command handler
if [[ "$NPMX_COMMAND" = "install" ]]; then
    install "$NPMX_PACKAGE_NAME"
elif [[ "$NPMX_COMMAND" = "update" ]]; then
    update "$NPMX_PACKAGE_NAME"
elif [[ "$NPMX_COMMAND" = "uninstall" ]]; then
    uninstall "$NPMX_PACKAGE_NAME"
elif [[ "NPMX_COMMAND" = "help" ]] || [[ "NPMX_COMMAND" = "--help" ]]; then
    usage
else
    echo "Command $1 not recognized" >&2
    usage
    exit 1
fi
