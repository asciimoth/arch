#!/bin/bash
# Shebang just fot synatx highlight trigger

#echo "<config>/bashrc loaded"

# Append
PATH="$HOME/config/execs:$PATH:/flatpak-aliases"

export EDITOR="sublime"
export VISUAL="sublime"

export XDG_CONFIG_HOME="$HOME/.config"

alias setup="$HOME/config/setup && . ~/.bashrc"
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
alias nsh="nix shell --impure"
alias nopt="sudo nix-store --optimise"
alias ngc="sudo nix-collect-garbage -d"

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye > /dev/null

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

eval "$(zoxide init bash)"

function __secondarg() {
	echo -n "$2"
}

function n3() {
	rm -f "$XDG_CONFIG_HOME/nnn/.lastd"
	export NNN_PLUG="p:preview-tui"
	export NNN_FIFO="$(mktemp -tu "$USER-XXXXXXXXXXXXXXXXXXX-nnn.fifo")"
	command nnn -P p $@
	rm -f "$NNN_FIFO"
	local result="$(cat "$XDG_CONFIG_HOME/nnn/.lastd" 2> /dev/null)"
	local result="$(eval "__secondarg $result")"
	[ -n "$result" ] && zoxide add "$result" && cd -- "$result" 
}

alias nnn="n3"

function n() {
	if [[ "$1" == "" ]]; then
		n3 -de
	else
		z $@
	fi
}

alias nn="n ~"
alias nnn-update-plugins="sh -c \"\$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)\""

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

