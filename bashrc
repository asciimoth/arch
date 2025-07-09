#!/bin/bash
# Shebang just fot synatx highlight trigger

#echo "<config>/bashrc loaded"

# Append
export PATH="$HOME/config/execs:$PATH:/flatpak-aliases"

export EDITOR="micro"
export VISUAL="sublime"
export GTERM="kitty"

export XDG_CONFIG_HOME="$HOME/.config"

export GDK_DPI_SCALE=1.1
export GTK_THEME=Adwaita:dark

export RUSTUP_HOME=$HOME/.local/rustup
export CARGO_HOME=$HOME/.local/cargo
export RUSTUP_TOOLCHAIN=stable

HISTSIZE=1000000
HISTFILESIZE=1000000

alias c="cd"
alias setup="$HOME/config/setup.py && . ~/.bashrc"
alias open="xdg-open"
alias fkill="ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -9"
alias rf="rm -rf"
alias srf="sudo rm -rf"
alias l="eza --oneline -L -T -F --group-directories-first --icons"
alias ll="eza --oneline -L -T -F --group-directories-first -l --icons"
alias la="eza --oneline -L -T -F --group-directories-first -la --icons"
alias tre="eza --oneline -T -F --group-directories-first -a --icons"
alias gtr="eza --oneline -T -F --group-directories-first -a --git-ignore --ignore-glob .git --icons"
alias md="mkdir -p"
alias h="history | rg"
alias bat="bat --paging never"
alias pwgen="pwgen -s"
alias sstat="systemctl status"
alias jour="journalctl -u"
alias size="du -shP"
alias root="sudo -i"
alias dropproxy='export ALL_PROXY="" && export all_proxy="" && export SOCKS_PROXY="" && export socks_proxy="" && export HTTP_PROXY="" && export http_proxy="" && export HTTPS_PROXY="" && export https_proxy=""'
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias .......="cd ../../../../../.."
alias qr="qrencode -t UTF8 -o -"
alias xclip="xclip -sel clip"
alias clip="xclip -sel clip"
alias nix="sudo mkdir -p /nix/var/nix/daemon-socket && NIXPKGS_ALLOW_UNFREE=1 nix"
alias nsh="nshell"
alias nopt="sudo nix-store --optimise"
alias ngc="sudo nix-collect-garbage -d"
alias ble="bluetoothctl"
alias pwgen="pwgen -s 30 1"
alias upgrade="sudo pacman -Syu"
alias todo="rg TODO"
alias newpyenv="python -m venv"
alias loadenv="set -a; source .env; set +a"

alias nvim="~/.config/nvim/nvim.sh"
alias nvproj="~/.config/nvim/proj.sh"

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye > /dev/null

function NEWGPGENV() {
	export GNUPGHOME="$(mktemp -d)"
}

function loadpyenv() {
	local PTH="$1"
	source "$PTH/bin/activate"
}

complete -c man which
complete -cf sudo

export HISTCONTROL="erasedups:ignorespace"

source /usr/share/doc/pkgfile/command-not-found.bash

shopt -s autocd
shopt -s checkwinsize

if [[ "$(command -v carapace)" != "" ]]; then
	#export CARAPACE_BRIDGES="bash"
	source <(carapace _carapace)
fi

if command -v "zoxide" 2>&1 > /dev/null
then
	eval "$(zoxide init bash)"
else
	alias z="cd"
fi

function __secondarg() {
	echo -n "$2"
}

function n3() {
	nn $@
	local result="$(cat "$XDG_CONFIG_HOME/nnn/.lastd" 2> /dev/null)"
	local result="$(eval "__secondarg $result")"
	[ -n "$result" ] && zoxide add "$result" && cd -- "$result"
}

function n() {
	if [[ "$1" == "" ]]; then
		n3 -de
	else
		z $@
	fi
}

alias nnn="n"
alias n="n"

#if command -v "nnn" 2>&1 > /dev/null
#then
#	alias cd="n"
#fi

alias nnn-update-plugins="sh -c \"\$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)\""

alias ~="z ~"

function prompt() {
	local excode="$?"
	if [[ "$excode" == "0" ]]; then
		local excode=""
	else
		local excode=" [$excode]"
	fi
	local login=""
	if [[ "$LOGNAME" != "$USER" ]]; then
		local login=" $USER"
	fi
	local shlvl=" ($SHLVL)"
	if [[ "$shlvl" == " (2)" ]]; then
		local shlvl=""
	fi
	echo "$(pwd)$excode$login$shlvl"
}

# Prompts
PS1="\$(prompt)\n$ "
PS2="$ "


if [ -e "/usr/bin/direnv" ]; then
	_direnv_hook() {
	  local previous_exit_status=$?;
	  trap -- '' SIGINT;
	  eval "$("/usr/bin/direnv" export bash)";
	  trap - SIGINT;
	  return $previous_exit_status;
	};

	if [[ ";${PROMPT_COMMAND[*]:-};" != *";_direnv_hook;"* ]]; then
	  if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
	    PROMPT_COMMAND=(_direnv_hook "${PROMPT_COMMAND[@]}")
	  else
	    PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
	  fi
	fi
fi

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

if command -v "zoxide" 2>&1 > /dev/null
then
	eval "$(zoxide init bash)"
fi
