#!/usr/bin/env bash

set -e

echo "Dotfiles Bootstrap Script by Andrei Jiroh"
echo "Starting up in 3 seconds..."
sleep 3

useColor() {
  # Only use colors if connected to a terminal
  if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    MAGENTA=$(printf '\033[35m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    BOLD=""
    RESET=""
  fi
}

echoStageName() {
    echo "$(${BOLD})----> $*$(${RESET})"
}

warn() {
    echo "$(${YELLOW})!     $*$(${YELLOW})"
}

error() {
    # this will be long, so I must do "&& exit 1" manually
    echo "$(${RED})X     $*$(${RED})"
}

checkOs() {

    if echo $OSTYPE | grep -qE "linux-android.*"; then
        export DOTFILES_OS_NAME=android-termux
    elif echo $OSTYPE | grep -qE '^linux-gnu.*' && [ -f '/etc/debian_version' ]; then
        # Since Ubuntu is an major Debian fork, they're both LSB-complaint, so
        # we might need to just use grep for this one in the future.
        export DOTFILES_OS_NAME=debian-ubuntu
    # TODO: Write stuff for Arch users and macOS.
    # For WSL, that's an WIP.
    else
        error "Script unsupported for this machine. See the online README for guide on manual bootstrapping." && exit 1
    fi
}

installDeps() {
    echoStageName "Installating essiential dependencies"
    if [[ $DOTFILES_OS_NAME == "android-termux" ]]; then
       pkg install -y man git nano gnupg openssh proot resolv-conf asciinema openssl-tool
       echo "info: Essientials are installed, if you need Node.js just do 'pkg install nodejs' (we recommend installing the LTS one for stability) anytime"
    elif [[ $DOTFILES_OS_NAME == "debian-ubuntu" ]]; then
       sudo apt install gnupg git nano -y

       if [[ $USE_PYENV != "" ]]; then
           # we'll use the pyenv stuff
           echoStageName "Installing Pyenv with pyenv-installer"
           curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
       elif [[ $UPDATE_SYSTEM_PYTHON_INSTALL != "" ]]; then
           echoStageName "Updating Python install"
           sudo apt install python3 python3-pip
       fi
    fi
}

cloneRepo() {
    if [ ! -d "$HOME/.dotfiles" ]; then
        git clone https://github.com/AndreiJirohHaliliDev2006/dotfiles.git $HOME/.dotfiles
    else
        git -C "$HOME/.dotfiles" fetch --all
        git -C "$HOME/.dotfiles" pull origin
    fi

    if [[ $GITLAB_TOKEN == "" ]] && [[ $GITLAB_LOGIN == "" ]]; then
        error "GitLab login and token can't be blank!" && exit 1
    # Probably change my GitLab SaaS username with yours
    elif [[ $GITLAB_LOGIN != "AndreiJirohHaliliDev2006" ]]; then
        error "Only Andrei Jiroh can do this!" && exit 1
    elif [[ $GITLAB_LOGIN == "AndreiJirohHaliliDev2006" ]] && [[ $GITLAB_TOKEN == "" ]]; then
        error "Missing GitLab SaaS PAT! Check your Bitwarden vault for that key." && exit 1
    fi
    if [ ! -d "$HOME/.dotfiles/secrets" ]; then
        git clone https://$GITLAB_LOGIN:$GITLAB_TOKEN@gitlab.com/AndreiJirohHaliliDev2006/dotfiles-secrets $HOME/.dotfiles/secrets
        [ $? == "0" ] && echo "error: That kinda sus, but either only Andrei Jiroh can proceed or maybe the PAT you used is invalid." && exit 1
        chmod 600 $HOME/.dotfiles/secrets/{ssh,pgp}
        sleep 5
    else
        git -C "$HOME/.dotfiles/secrets" fetch --all
    fi
}

cleanup() {
    echoStageName "----> Bootstrapper successfully ran, cleaning up to ensure no secrets are leaked on env vars..."
    # just add chaos to these secrets to avoid leaks
    export GH_USERNAME=gildedguy
    export GH_PAT=build-guid-sus-among-computers-moment
    if echo $OSTYPE | grep -qE "linux-android.*"; then
        rm -rfv ~/{shellcheck,flarectl,LICENSE,README.txt,README.md}
        pkg uninstall clang --yes && apt autoremove --yes
    fi
    echo "info: Please also cleanup your shell history with 'history -c' to ensure your GitLab SaaS PAT is safe. Enjoy your day!"
    echo "info: Exiting..."
    sleep 2
    exit
}

copyKeysSSH() {
    echoStageName "Copying SSH keys"
    if [ ! -d "$HOME/.ssh" ]; then
        mkdir -p $HOME/.ssh
        cp $HOME/.dotfiles/secrets/ssh/launchpad ~/.ssh/launchpad
        cp $HOME/.dotfiles/secrets/ssh/launchpad.pub ~/.ssh/launchpad.pub
        chmod 600 ~/.ssh/launchpad
        chmod 600 ~/.ssh/github-personal
    else
        cp $HOME/.dotfiles/secrets/ssh/launchpad ~/.ssh/launchpad
        cp $HOME/.dotfiles/secrets/ssh/launchpad.pub ~/.ssh/launchpad.pub
        chmod 600 ~/.ssh/launchpad
        chmod 600 ~/.ssh/github-personal
    fi

    echoStageName "Linking config files"
    if echo $OSTYPE | grep -qE "linux-android.*"; then
        [ ! -f "$HOME/.ssh/config" ] && ln -s $HOME/.dotfiles/ssh-client/termux ~/.ssh/config
    # TODO: Write checks if it's Ubuntu or Debian
    # See https://superuser.com/a/741610/1124908 for details
    elif echo $OSTYPE | grep -qE '^linux-gnu.*' && [ -f '/etc/debian_version' ]; then
        [ ! -f "$HOME/.ssh/config" ] && ln -s $HOME/.dotfiles/ssh-client/ubuntu ~/.ssh/config
    fi
    sleep 5
}

copyBashrc() {
    if [[ $DOTFILES_OS_NAME == "android-termux" ]]; then
        ln -s $HOME/.dotfiles/termux.gitconfig ~/.gitconfig
    elif [[ $DOTFILES_OS_NAME == "debian-ubuntu" ]]; then
        if [[ $SKIP_BASHRC_LINKING == "" ]] && [ ! -f "$HOME/.bashrc" ]; then
           ln -s "$HOME/.dotfiles/ubuntu.bashrc" ~/.bashrc
        elif [[ $SKIP_CONFIG_LINKING == "" ]] && [ -f "$HOME/.bashrc" ]; then
           mv ~/.bashrc ~/.bashrc.bak
           ln -s "$HOME/.dotfiles/ubuntu.bashrc" ~/.bashrc
        fi
    fi
}

copyGitConfig() {
    echoStageName "Symlinking Git config"
    if [[ $DOTFILES_OS_NAME == "android-termux" ]]; then
        [ ! -f "$HOME/.ssh/config" ] && ln -s $HOME/.dotfiles/gitconfig/termux ~/.gitconfig || warn "Git configuration on userspace found, please merge them manually!"
    # TODO: Write checks if it's Ubuntu or Debian
    # See https://superuser.com/a/741610/1124908 for details
    elif [[ $DOTFILES_OS_NAME == "debian-ubuntu" ]]; then
        [ ! -f "$HOME/.ssh/config" ] && ln -s $HOME/.dotfiles/linux/ubuntu ~/.gitconfig || warn "Git configuration on userspace found, please merge them manually!"
    fi
}

copyNanoConfig() {
    if [[ $DOTFILES_OS_NAME == "android-termux" ]]; then
        [ "$SKIP_CONFIG_LINKING" == "" ] && ln -s $HOME/.dotfiles/nanorc/config/termux $HOME/.nanorc
    fi

}

installShellCheck() {
    echoStageName "Installing Shellcheck"
    scversion="stable" # or "v0.4.7", or "latest"
    current_shellcheck_path=$(command -v shellcheck)
    isOwnedByUser=$(find $PREFIX/bin -user $USER -file shellcheck)
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJv
    if [[ $current_shellcheck_path == "" ]]; then
       cp "shellcheck-${scversion}/shellcheck" $PREFIX/bin
    else
        if [[ $isOwnedByUser == "" ]]; then
          sudo rm $PREFIX/bin/shellcheck
        else
          rm $PREFIX/bin/shellcheck
        fi
    fi
}

installAscinema() {
    if command -v python3 | grep -qE '^/usr/bin.*'; then
       sudo "$(which python3)" -m pip install asciinema
    elif command -v python3>>/dev/null && [ -f "$HOME/.pyenv/shims/python3" ]; then
       $(which python3) -m pip install asciinema
    else
       if [[ $DOTFILES_OS_NAME == "android-termux" ]]; then
          pkg install asciinema --yes
       else
          sudo apt install asciinema --yes
       fi
    fi
}

installTF() {
    if [[ $DOTFILES_OS_NAME == "android-termux" ]]; then
        pkg install clang -y && pip install thefuck -U
    else
        if command -v python3>>/dev/null && [ -f "$HOME/.pyenv/shims/python3" ]; then
            pip3 install thefuck
        else
            pip3 install thefuck -U
        fi
    fi
}

main() {
    useColor
    
    # step 1: check the OS first
    checkOs

    # step 2: install needed tools
    installDeps

    # step 3: then clone the repo
    cloneRepo

    # step 4: install additional needed tools
    installAscinema
    installTF

    # step 5: copy and symlink files
    copyGitConfig
    copyNanoConfig
    copyBashrc
    copyKeysSSH

    # step : finally clean up bullshit
    cleanup
}

main "$@"