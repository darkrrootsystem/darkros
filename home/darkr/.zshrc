HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch
unsetopt beep
bindkey -e
zstyle :compinstall filename '/home/darkr/.zshrc'
autoload -Uz compinit
alias update='sudo nixos-rebuild switch --flake /etc/nixos --upgrade && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot'
alias ghost-ai='/home/darkr/ghost-ai'
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
compinit
