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


export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye > /dev/null

tere() {
	local result=$(command tere "$@")
	[ -n "$result" ] && cd -- "$result"
}

function 2() {
	tere
}
