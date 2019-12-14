# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

# start screen session, but only via ssh
if [[ -z "$STY" ]] && [ "$SSH_CONNECTION" != "" ]; then
	screen -RR; exit
fi
