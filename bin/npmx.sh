#!/bin/bash -e

NPMX_BASE_DIR="$HOME/.npmx"
NPMX_SHORT_COMMAND=$(basename "$0")

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

# check if 'npm' command is present
function check_npm_is_installed() {
    if ! command -v npm &> /dev/null; then
        echo "'npm' could not be found"
        exit 1
    fi
}

# print help message
function usage() {
cat << EOF
    Usage: $NPMX_SHORT_COMMAND {list, install, uninstall, update, help} [<npm_package_name>]

    Subcommands:
        list                                List installed NPMs
        install <npm_package_name>          Install a new NPM package to it's own subdirectory
        update <npm_package_name>           Update an existing NPMX installation
        uninstall <npm_package_name>        Uninstall an existing NPMX installation
        help                                Print this help message
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
        short_bin_file=$(basename "$bin_file")
        if [[ ! -f "$dst_bin_dir/$short_bin_file" ]]; then
            echo "Found commnand $short_bin_file, creating a symlink to it"
            ln -s \
                "$src_bin_dir/$short_bin_file" \
                "$dst_bin_dir/$short_bin_file" || true
        else
            echo "WARNING: File $dst_bin_dir/$short_bin_file already exists, not creating a symlink"
        fi
    done
}

# print a missing argument error and usage
# usage: echo_missing_arg subcommand
function echo_missing_arg() {
    local subcommnand
    subcommnand="$1"
    echo "\"$NPMX_SHORT_COMMAND $subcommnand <npm_pkg_name>\" requires a package name" >&2
    echo
    usage
    exit 1
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
        short_bin_file=$(basename "$bin_file")
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
        echo "ERROR: $npmx_pkg_name already installed, run '$NPMX_SHORT_COMMAND update ...' instead. Exiting ..."
        exit 1
    fi
    # run in a sub-shell to return back
    ( \
        cd "$NPMX_BASE_DIR/npms/$npmx_pkg_name"; \
        npm install "$npmx_pkg_name" --loglevel=error; \
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
        echo "ERROR: $npmx_pkg_name NOT installed, run '$NPMX_SHORT_COMMAND install ...' instead. Exiting ..."
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
        npm update "$npmx_pkg_name" --loglevel=error; \
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
        npm uninstall "$npmx_pkg_name" --loglevel=error; \
        echo "Removing $NPMX_BASE_DIR/npms/$npmx_pkg_name directory"; \
        rm -rf "$NPMX_BASE_DIR/npms/$npmx_pkg_name"
    )
}

# list installed npmx
function list() {
    local npm_dir

    for npm_dir in "$NPMX_BASE_DIR/npms/"*; do
        ( \
            cd "$npm_dir"; \
            npm list "$(basename "$npm_dir")"; \
        )
    done
}
### MAIN CODE
# basic argument check
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

# do environment setup checks
check_npm_is_installed
check_npmx_base_dir
check_npmx_is_in_path

NPMX_COMMAND="$1"
# run command handler
case "$NPMX_COMMAND" in
    list)
        list
        ;;
    install)
        NPMX_PACKAGE_NAME="$2"
        [[ -z "$NPMX_PACKAGE_NAME" ]] && echo_missing_arg "$NPMX_COMMAND"
        install "$NPMX_PACKAGE_NAME"
        ;;
    uninstall)
        NPMX_PACKAGE_NAME="$2"
        [[ -z "$NPMX_PACKAGE_NAME" ]] && echo_missing_arg "$NPMX_COMMAND"
        uninstall "$NPMX_PACKAGE_NAME"
        ;;
    update)
        NPMX_PACKAGE_NAME="$2"
        [[ -z "$NPMX_PACKAGE_NAME" ]] && echo_missing_arg "$NPMX_COMMAND"
        update "$NPMX_PACKAGE_NAME"
        ;;
    help)
        usage
        ;;
    --help)
        usage
        ;;
    *)
        echo "Command $1 not recognized" >&2
        usage
        exit 1
        ;;
esac
