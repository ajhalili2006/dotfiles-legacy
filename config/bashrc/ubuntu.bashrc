#!/usr/bin/bash
# shellcheck disable=SC1090,SC1091,SC2088,SC2155,SC2046

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

############################################################################

# https://packaging.ubuntu.com/html/getting-set-up.html#configure-your-shell
export DEBFULLNAME="Andrei Jiroh Halili"
# Temporary Gmail address for devel stuff, even through my longer email one is, well,
# on my public GPG key btw, so YOLO it.
export DEBEMAIL="ajhalili2006@gmail.com"

## Update path and inject some vars before the shell interactivity checks ##
export DOTFILES_HOME="$HOME/.dotfiles"
export DOTFILES_STUFF_BIN="$DOTFILES_HOME/bin"
export PATH="$HOME/.asdf/shims:$HOME/.local/bin:$HOME/.cargo/bin:$DOTFILES_STUFF_BIN:$PATH"

## Add homebrew to path ##
export HOMEBREW_HOME=${HOMEBREW_HOME:-"/home/linuxbrew/.linuxbrew"}
test -d "$HOMEBREW_HOME" && eval "$($HOMEBREW_HOME/bin/brew shellenv)"
[[ -r "$HOMEBREW_HOME/etc/profile.d/bash_completion.sh" ]] && . "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh"

export GPG_TTY=$(tty) # in case shit happens

############################################################################

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=10000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . "~/.bash_aliases"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Deta CLI
export PATH="$HOME/.deta/bin:$PATH"

# use nano instead of vi by default when on SSH
# for git, there's the option of firing up VS Code, if you prefered.
#export VISUAL="code --wait"
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
	export EDITOR=nano
else
	# We'll do some checks here btw, Currently I use GNOME and Xfce4 as my desktop environments, but
	# I also consider adding KDE here in the future.
	case $(ps -o comm= -p $PPID) in
	sshd | */sshd) export EDITOR="code --wait" ;;
	xfce*) export EDITOR="$(which code >>/dev/null && echo code --wait || which gedit >>/dev/null && echo gedit || echo nano)" ;;
	gnome*) export EDITOR="$(which code >>/dev/null && echo code --wait || which gedit >>/dev/null && echo gedit || echo nano)" ;;
	code) export EDITOR="code --wait";;
	*) export EDITOR="nano" ;;
	esac
fi

# As long as possible, attempt to setup our GnuPG agent when we're on an SSH session.
KEYCHAIN_FLAGS_NOGUI="--nogui --noinherit"
#KEYCHAIN_FLAGS=""
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
	eval $(keychain --agents gpg,ssh --eval $KEYCHAIN_FLAGS_NOGUI) || true
	export GPG_TTY=$(tty)
else
	# We'll do some checks here btw, Currently I use GNOME and Xfce4 as my desktop environments
	case $(ps -o comm= -p $PPID) in
        	# Sometimes, $SSH_CLIENT and/or $SSH_TTY doesn't exists so we'll pull what ps says
		sshd | */sshd) eval $(keychain --agents gpg,ssh --eval $KEYCHAIN_FLAGS_NOGUI) || true;;
		xfce*) eval $(keychain --agents gpg,ssh --eval) || true;;
		gnome*) eval $(keychain --agents gpg,ssh --eval) || true;;
                
		# Don't forget VS Code and code-server!
		code) eval $(keychain --agents gpg,ssh --eval) || true;;
		*) eval $(keychain --agents gpg,ssh --eval $KEYCHAIN_FLAGS_NOGUI) || true;;
	esac
fi

# autocompletion for GitHub CLI
eval "$(gh completion -s bash)"

# Source both the custom aliases and shell functions in one go
source "$DOTFILES_HOME/config/bashrc/chain-source"

# Golang, probably we need to tweak this btw
export PATH="$HOME/go/bin:$PATH" GOPATH="$HOME/go"

# Use native builds when doing 'docker build' instead of 'docker buildx build'
export DOCKER_BUILDKIT=1

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# direnv
eval "$(direnv hook bash)"

# Don't install gems globally, that would be chaos for file permissions
export GEM_HOME="$HOME/.gems" PATH="$HOME/.gems/bin:$PATH"

# bashbox
[ -s "$HOME/.bashbox/env" ] && source "$HOME/.bashbox/env";
source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc"
