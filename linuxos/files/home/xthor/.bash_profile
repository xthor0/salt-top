# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

{% if "tmux" in salt['grains.get']('roles', []) %}
# start tmux session
if [[ -z "$TMUX" ]] && [ "$SSH_CONNECTION" != "" ]; then
	tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux; exit
fi
{% endif %}

{% if "screen" in salt['grains.get']('roles', []) %}
# start screen session, but only via ssh
if [[ -z "$STY" ]] && [ "$SSH_CONNECTION" != "" ]; then
	screen -RR; exit
fi
{% endif %}
