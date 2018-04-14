# window title
function window_title() {
  #echo -ne "\033]0;\u@\h: \W\007"
  #echo -n -e "\033]0;${PWD##*/}\007"
  echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"
}


# prompt
if [ -n "$SSH_CLIENT" ]; then
  export PROMPT_COMMAND="window_title"
  PS1='\[\033[00m\]::\[\033[01;31m\]SSH\[\033[00m\]:: \[\033[01;33m\]\u\[\033[00m\]@\[\033[01;34m\]\h\[\033[00m\] [\[\033[01;36m\]\W\[\033[00m\]]\$ '
else
  PS1="[\u@\h \W]\\$ "
fi

# bash completion
{% if grains.get('os', '') == 'CentOS' %}
if [ -f /etc/profile.d/bash_completion.sh ] && ! shopt -oq posix; then
    . /etc/profile.d/bash_completion.sh
fi
{% elif grains.get('os', '') == 'Ubuntu' %}
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
{% endif %}

# path
export PATH=$PATH:$HOME/bin

# ls colors
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# aliases
alias ls="ls --color"
alias salt='sudo salt'
alias salt-key='sudo salt-key'
alias docker='sudo docker'
alias yum='sudo yum'
