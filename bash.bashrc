# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
### BASHRC CONFIGS ###
color_prompt=yes #yes/no
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' #GCC Colors
shopt -s autocd cdspell histverify xpg_echo histappend checkwinsize  ## bash acts
RAMFS_DIR="/tmp/bashrcFuncDatas" ### path to save bashrc datas
SYSTEM_FETCH="fastfetch"
HISTFILE="$HOME/.bash_history" ## bash history file
### END CONFIGS ###
### README ###
# This script is only for bash,and it cannot be executed via almost any other shells.
# To check alias,run "alias".
# This script is customized for Arch Linux,and you some extra modify may be needed for other distributions.
# This script depends on these packages: pkgfile(/usr/lib/command-not-found on ubuntu,if theres nothing,try ":/ # find | grep command-not-found".), neofetch(optional), fastfetch(optional), bash-completion, bash, systemd, tput (ncurses on archlinux),sudo ,bc ,tmux
### BEGIN DEPENDENCY CHECKING ###
if [ ! -f $RAMFS_DIR/hasramfsdir ];then 
mkdir $RAMFS_DIR
chmod 777 $RAMFS_DIR
touch $RAMFS_DIR/hasramfsdir
fi
bashrc_deps="pkgfile bash-completion bash systemd ncurses sudo bc tmux"
if [ -x /usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
        echo "Its the first time to start bash since boot,checking dependencies..."
        if pacman -Qq $bashrc_deps > /dev/null 2>&1;then
                touch $RAMFS_DIR/complete_dependency
                clear
        elif [ -x /usr/bin/pacman ];then
                echo "These packages are needed.To make sure the bashrc will be executed successfully,you have to install them."
                sudo pacman -Sy $bashrc_deps --neede --overwrite '*'
                clear
        fi
elif [ ! -f /usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
        echo "Cannot check dependencies on the first time to start bash since boot.please make sure the required commands are valid."
        echo "You can view /etc/bash.bashrc to check which commands are needed."
        echo "Running bash normally."
        touch $RAMFS_DIR/complete_dependency
fi
in_init=1
SourcePATH=$PATH
bind 'set show-all-if-ambiguous on'
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
complete -F _comp_command sudo
complete -F _comp_command _
complete -E
complete -E -F _comp_complete_longopt
# Command timing
timing(){
        local args=$1
        if [ "$args" == pre ];then
if [ $in_init == 1 ];then
            return
    fi
    start_time=$(date +%s%N)
    in_timing="yes"
elif [ "$args" == post ];then
        local command_to_execute="$(history 1 | sed 's/^ *[0-9]\+ *//')"
    local end_time=$(date +%s%N)
    local elapsed_time_ns=$((end_time - start_time))
        local elapsed_time_sec=$(echo "scale=2; $elapsed_time_ns / 1000000000" | bc)
        if [ $ret == 0 ];then
                echo -e "\033[1;32m"
        else
                echo -e "\033[1;31m"
        fi
        if [ $post_histsize -eq $pre_histsize ] && [ $deldups_exec -ne 1 ];then
                command_to_execute=''
        fi
        echo -e "$command_to_execute: ${elapsed_time_sec} s\033[m"
    unset start_time
    unset in_timing
    post_histsize=$pre_histsize
    unset pre_histsize
        fi
}
deldups(){
        local first_cmd=$(tail -n 1 $HISTFILE)
        local sec_cmd=$(tail -n 2 $HISTFILE|sed '$d')
        if [ "$first_cmd"x == "$sec_cmd"x ];then
                sed -i '$d' $HISTFILE
                deldups_exec=1
        else
                deldups_exec=0
        fi
        history -r
}
history -a
pre_histsize=$(stat -c%s $HISTFILE)
post_histsize=$pre_histsize
pre_exec(){
        [ "$in_timing"x == yesx ]||timing pre
}
post_exec(){
ret=$?
time1=$(date +%T|awk -F":" {'print $1":"$2'})
time2=$(date +%T|awk -F":" {'print $3'})
PATH="$(pwd):$SourcePATH"
history -a
deldups
if [ $in_init == 0 ];then
        pre_histsize=$(stat -c%s $HISTFILE)
        timing post
fi
in_init=0
}
tmuxmgr() {
if [ ! -z "$TMUX" ];then
echo "You have already attached a tmux session!"
return 1
fi
  sessions=$(tmux list-sessions -F "#S" 2>/dev/null)
  if [ -z "$sessions" ];then
  /usr/bin/tmux new-session -s bash
  return 0
  else
  echo "\033[1;32m$(tmux ls)\033[m"
  fi
  echo "Choose a(ttach), n(ew), q(uit)(also exit): "
  read -rsn1 mode
  if [ -z $mode ];then
  echo no choice,exiting
  return 1
  fi
  mode=$(compgen -W "attach new quit exit" -- "$mode")
  if [ "$mode"x == "attach"x ]; then
    read -e -p "Session name (or Enter to attach to last session: " session_name
    if [ -z "$session_name" ]; then
	    local empty=yes
      /usr/bin/tmux a
    else session_name=$(compgen -W "$sessions" -- "$session_name")
    fi
    if [[ "$sessions" == *"$session_name"* ]] && [[ "$empty"x != yesx ]]; then
      /usr/bin/tmux a -t "$session_name"
elif [[ "$empty"x != yesx ]];then
      echo "Can't find the session name."
      tmuxmgr
    fi
  elif [ "$mode"x == "new"x ]; then
    read -ep "Session name: " new_session
    /usr/bin/tmux new-session -d -s "$new_session"
    /usr/bin/tmux a -t "$new_session"
  elif [ "$mode"x == "quit"x ]; then
    echo "canceled."
    return 1
  elif [ "$mode"x == "exit"x ];then
  echo "canceled."
  return 1
  else
    echo "No such mode."
    tmuxmgr
  fi
}
bind -x '"\C-t": tmuxmgr'
trap 'pre_exec' DEBUG
HISTCONTROL=ignorespace
HISTSIZE=100000
HISTFILESIZE=200000
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
PROMPT_COMMAND=post_exec
command_not_found_handle(){
        cmdnotfound $1
}
### You can modify there for other distributions ###
cmdnotfound(){
if [ -x /usr/bin/pkgfile ];then
        echo "Searching command $1 ..."
        /usr/bin/pkgfile $1
elif [ -x /usr/lib/command-not-found ];then
        /usr/lib/command-not-found -- "$1"
else
        echo "command pkgfile not found,cant search the command."
        echo "you can install extra/pkgfile with sudo pacman -Sy pkgfile."
        echo "If you are not using Arch Linux(or any other pacman-based distribution),try to use other package searcher."
fi
}
git_current_branch(){
	local ref
	ref=$(git symbolic-ref --quiet HEAD 2>/dev/null)
	local return=$?
	if [[ $return -ne 0 ]]; then
		[[ $return -eq 128 ]] && return
		ref=$(git rev-parse --short HEAD 2>/dev/null) || return
	fi
	if [ "$1" == "yes" ];then
		echo="-\033[1;31m[\033[m${ref#refs/heads/}\033[1;31m]\033[m"
        else 
		echo="-[${ref#refs/heads/}]"
	fi
	echo -ne "$echo"
}
### Done ###
PS1='\[\e[m\]┌─\[\033[1;31m\][\[\033[m\]$0-$$ $(echo -n $time1&&/usr/bin/tput blink&&echo -n ':'&&/usr/bin/tput sgr0&&echo -n $time2 $([ $UID = 0 ]&&/usr/bin/tput smul&&/usr/bin/tput blink&&echo -n \[\033[1\;31m\]$(whoami)&&/usr/bin/tput sgr0||echo \[\033[1\;34m\]$(whoami)))\[\033[1;31m\]@\[\033[34m\]\h \[\033[33m\]\w\[\033[31m\]]\[\033[m\]$(git_current_branch yes)\n└─$([ $ret = 0 ]&&echo \[\033[1\;32m\]||echo \[\033[1\;31m\]$ret)\$>>_\[\e[m\] '
PS2='$(echo -n \[\033[1\;33m\])[Line $LINENO]>'
PS3='$(echo -n \[\033[1\;35m\])\[[$0]Select > '
PS4='$(echo -n \[\033[1\;35m\])\[[$0] Line $LINENO:> '
if [ $color_prompt = no ];then 
	PS1='┌─[$0-$$ $(echo -n "$time1:$time2") $(whoami)@\h \w]\[\033[m\]$(git_current_branch no)\n└─$([ $ret = 0 ]||echo -n $ret)\$>>_\[\e[m\] '
    PS2='[Line $LINENO]> '
    PS3='\[[$0]Select > '
    PS4='\[[$0] Line $LINENO:> '
fi
unset color_prompt
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -v -p'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias cdl='cd $OLDPWD'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lf='ls -alFA --color=auto'
alias lh='lf -h'
alias nf='neofetch'
alias ff='fastfetch'
alias ip='command ip -color=auto'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
if [ $UID -ne 0 ];then
        alias sus='sudo -s'
        alias _='sudo'
fi
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
if [ -z $SUDO_USER ];then
command $SYSTEM_FETCH
fi
SAVE_FILE="$RAMFS_DIR/saved_paths.txt"
if [ ! -f "$SAVE_FILE" ]; then
    touch "$SAVE_FILE"
fi
savepath() {
    local path
    local input="$1"
    if ls $input -d; then
    if [ -z "$input" ]; then
            echo "No path entered.will save current directory(pwd)."
            path="$(pwd)"
    else
    path=$(realpath "$input")
    fi
    local number=1
    while grep -q "^fm$number::::::" "$SAVE_FILE"; do
        number=$((number + 1))
    done
    echo "fm$number::::::$path" >> "$SAVE_FILE"
    echo "Path saved with number fm$number"
else 
        echo Unavalid path.
    fi
}
unspath() {
    if [ $# -eq 0 ]; then
        echo "Usage: unspath fmnumber [fmnumber ...]"
        return 1
    fi

    for number in "$@"; do
        /usr/bin/sed -i "/^$number::::::/d" "$SAVE_FILE"
        echo "Path with number $number removed"
    done
}
lspath() {
    if [ ! -s "$SAVE_FILE" ]; then
        echo "No paths saved"
        return 1
    fi
    cat "$SAVE_FILE"
}
fm() {
    local cmd="$1"
    shift
    local args=()
    local fm_args=()
    if [ "$cmd"awa == awa ]; then
            echo "Usage: fm [command] [command-args]"
            return 1
            echo 1
    fi
    echo 2
    for arg in "$@"; do
        if [[ "$arg" =~ ^fm[0-9]+$ ]]; then
            local path
            path=$(/usr/bin/grep "^$arg::::::" "$SAVE_FILE" | /usr/bin/awk -F'::::::' '{print $2}')
            if [ -z "$path" ]; then
                echo "Error: No path saved with number $arg"
                return 1
            fi
            args+=("$path")
            fm_args+=("$arg::::::$path")
        elif [[ "$arg" =~ ^([^=]+)=(fm[0-9]+)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local number="${BASH_REMATCH[2]}"
            local path
            path=$(grep "^$number::::::" "$SAVE_FILE" | awk -F'::::::' '{print $2}')
            if [ -z "$path" ]; then
                echo "Error: No path saved with number $number"
                return 1
            fi
            args+=("$prefix=$path")
            fm_args+=("$number::::::$path")
        else
            args+=("$arg")
        fi
    done
    if [[ "$cmd" == "sudo" || "$EUID" -eq 0 ]]; then
        echo "You are about to execute a command as root or using sudo:"
        echo "$cmd"
        for fm_arg in "${fm_args[@]}"; do
            echo "$fm_arg"
        done
        read -p "Are you sure you want to proceed? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Command not executed."
            return 1
        fi
    fi
    "$cmd" "${args[@]}"
}
complete -o default -o nospace -F _comp_complete_longopt savepath
complete -o default -o nospace -F _comp_complete_longopt unspath
complete -o default -o nospace -F _comp_command fm
clpath(){
        > "$SAVE_FILE"
        echo "Paths cleared."
}
