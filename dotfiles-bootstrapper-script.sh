#!/usr/bin/env bash

echo "Dotfiles Bootstrap Script by Andrei Jiroh"
echo "Starting up in 3 seconds..."
sleep 3

echo "==> Checking for GitLab Auth tokens in env..."

if [[ $GH_PAT == "" ]] && [[ $GH_USERNAME == "" ]]; then
    echo "⚠ GH_USERNAME and GH_PAT can't be blank!"
    exit 1
# Probably change my GitLab SaaS username with yours
elif [[ $GH_USERNAME != "AndreiJirohHaliliDev2006" ]]; then
    echo "⚠ Only Andrei Jiroh can do this!"
    exit 1
elif [[ $GH_USERNAME == "AndreiJirohHaliliDev2006" ]] && [[ $GH_PAT == "" ]]; then
    echo "⚠ Missing GitLab SaaS PAT! Check your Bitwarden vault for that key."
    exit 1
else
    echo "⚠ Proceeding, please don't expect this works if things go brrr..."
fi

if [[ $PWD != $HOME ]]; then
    echo "This script only works if you're in the home directory"
    exit 1
fi

if echo $OSTYPE | grep -qE linux-android.*; then
    # Assuming that you istalled either wget or curl
    echo "==> Installing dependencies..."
    pkg install -y man git nano gnupg openssh proot resolv-conf asciinema openssl-tool
    echo "info: Essientials are installed, if you need Node.js"
    echo "info: just do 'pkg install nodejs' (we recommend"
    echo "info: installing the LTS one for stability) anytime"
    sleep 5

    # Clone our stuff
    echo "==> Cloning the dotfiles repo"
    git clone https://github.com/AndreiJirohHaliliDev2006/dotfiles.git $HOME/.dotfiles
    git clone https://$GH_USERNAME:$GH_PAT@gitlab.com/AndreiJirohHaliliDev2006/dotfiles-secrets $HOME/.dotfiles/secrets

    if [[ $? != 0 ]]; then
       echo "❌ That kinda sus, but either only Andrei Jiroh can proceed"
       echo "   or maybe the PAT you used is invalid."
       exit 1
    else
       chmod 700 $HOME/.dotfiles/secrets
    fi
    sleep 5

    # Importing our SSH keys
    echo "==> Checking if ~/.ssh exists..."
    mkdir ~/.ssh && echo "We made that directory for you." || echo "warning: ~/.ssh exists! Skipping directory creation, probably created during install..."
    echo "==> Copying SSH keys"
    cp $HOME/.dotfiles/secrets/ssh/github-personal ~/.ssh/github-personal
    cp $HOME/.dotfiles/secrets/ssh/github-personal.pub ~/.ssh/github-personal.pub
    cp $HOME/.dotfiles/secrets/ssh/launchpad ~/.ssh/launchpad
    cp $HOME/.dotfiles/secrets/ssh/launchpad.pub ~/.ssh/launchpad.pub
    chmod 600 ~/.ssh/launchpad
    chmod 600 ~/.ssh/github-personal
    echo "==> Creating soft links for OpenSSH client config..."
    ln -s $HOME/.dotfiles/ssh-client/termux ~/.ssh/config
    sleep 5

    # Link softly
    echo "==> Creating soft links for .bashrc and .gitconfig"
    ln -s $HOME/.dotfiles/termux.bashrc ~/.bashrc
    ln -s $HOME/.dotfiles/termux.gitconfig ~/.gitconfig
    sleep 5

    echo "==> Soft-linking your nanorc config..."
    ln -s $HOME/.dotfiles/nanorc/config/termux $HOME/.nanorc
    sleep 5

    echo "==> Installing ShellCheck from GitHub..."
    scversion="stable" # or "v0.4.7", or "latest"
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJv
    cp "shellcheck-${scversion}/shellcheck" $PREFIX/bin

    #echo "==> Installing Cloudflare CLI..."
    #wget -q0- https://github.com/cloudflare/cloudflare-go/releases/download/v0.16.0/flarectl_0.16.0_linux_armv6.tar.xz | tar -xJx

    echo "==> Installing python3-pip:thefuck..."
    pkg install clang -y && pip install thefuck -U

    echo "✔ Task completed successfully."
    echo "==> Cleaning up to ensure no secrets are leaked on env vars..."
    # just add chaos to these secrets to avoid leaks
    export GH_USERNAME=gildedguy
    export GH_PAT=build-guid-sus-among-computers-moment
    rm -rfv ~/{shellcheck,flarectl,LICENSE,README.txt,README.md}
    pkg uninstall clang --yes && apt autoremove --yes
    echo "info: Please also cleanup your shell history with 'history -c' to ensure"
    echo "info: your GitLab SaaS PAT is safe. Enjoy your day!"
    echo "info: Exiting..."
    sleep 2
    exit
#elif echo $OSTYPE | grep linux-gnu.* && ;then
else
    echo "error: Script unsupported for this machine. See the online README for"
    echo "error: guide on manual bootstrapping."
    exit 1
fi
