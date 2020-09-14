# npmx - Install `npm` distributed CLI tools into separate environments and have them available globally.
This simple tool is inspired by Python's [pipx](https://github.com/pipxproject/pipx).

## Why do I need it?
`npm` based tools often recommend to install a CLI-based tool globally by running `npm install -g <npm_pkg_name>`.
This is often done only because of having the exported CLI scripts available in a PATH that's resolvable for a user. Unfortunately, globally installed packages
share the same root `node_modules` and having many CLI tools installed globally will sooner or later cause a conflict between installed dependencies.

## How does it work?
The main idea is to install each `npm` CLI package into a separate directory under `$HOME/.npmx/npms/<npm_pkg_name>/`, find the exported binaries in `$HOME/.npmx/npms/<npm_pkg_name>/.bin/` and symlink them to a well-known path `$HOME/.npmx/bin`. Once this path is added to your `$PATH`, you'll have all CLIs easily available.

## Installation
```bash
git clone https://github.com/kamilsamaj/npmx.git
sudo ln -s "$PWD/npmx/bin/npmx.sh" /usr/local/bin/npmx
```

## Usage
```bash
npmx {list, install, uninstall, update, help} [<npm_package_name>]

    Subcommands:
        list                                List installed NPMs
        install <npm_package_name>          Install a new NPM package to it's own subdirectory
        update <npm_package_name>           Update an existing NPMX installation
        uninstall <npm_package_name>        Uninstall an existing NPMX installation
        help                                Print this help message
```
