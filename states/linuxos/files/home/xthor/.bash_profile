# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# if we want the title set correctly, this is necessary
case "$TERM" in
  screen*) PROMPT_COMMAND='printf %bk%s%b%b \\033 "${HOSTNAME%%.*}" \\033 \\0134';;
  xterm*) PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"';;
esac

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

# start a screen session
if [ -n "$SSH_CLIENT" -a "$TERM" != "screen" -a -n "$SSH_TTY" ]; then
  screen -xRR && exit
fi
