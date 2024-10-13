#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see $SYSROOT/usr/share/doc/bash/examples/startup-files (in the package bash-doc)
### BASHRC CONFIGS ###
SYSROOT=""  ### empty for /
color_prompt=yes #yes/no
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' #GCC Colors
shopt -s autocd cdspell histverify xpg_echo histappend checkwinsize  ## bash acts
RAMFS_DIR="$SYSROOT/tmp/bashrcFuncDatas" ### path to save bashrc datas
SYSTEM_FETCH="fastfetch"
HISTFILE="$HOME/.bash_history" ## bash history file
PROMPT_DIRTRIM=3 ###how many parent directory will be shown in the prompt
### END CONFIGS ###
### README ###
# This script is only for bash,and it cannot be executed via almost any other shells.
# To check alias,run "alias".
# This script is customized for Arch Linux,and you some extra modify may be needed for other distributions.
# This script depends on these packages: pkgfile($SYSROOT/usr/lib/command-not-found on ubuntu,if theres nothing,try ":/ # find | grep command-not-found".), neofetch(optional), fastfetch(optional), bash-completion, bash, systemd, tput (ncurses on archlinux),sudo ,bc ,tmux
### BEGIN DEPENDENCY CHECKING ###
if [ ! -f $RAMFS_DIR/hasramfsdir ]&&[ $$ -ne 1 ];then 
mkdir $RAMFS_DIR
chmod 777 $RAMFS_DIR
touch $RAMFS_DIR/hasramfsdir
fi
[ ! -f $HISTFILE ]&&touch $HISTFILE
bashrc_deps="pkgfile bash-completion bash systemd ncurses sudo bc tmux git"
if [ -x $SYSROOT/usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
        echo -n "Its the first time to start bash since boot,checking dependencies..."
        if pacman -Qq $bashrc_deps > /dev/null 2>&1;then
                touch $RAMFS_DIR/complete_dependency
                echo -e "\r"
        elif [ -x $SYSROOT/usr/bin/pacman ];then
                echo -n "These packages are needed.To make sure the bashrc will be executed successfully,you have to install them."
                sudo pacman -Sy $bashrc_deps --neede --overwrite '*'
		sudo pkgfile --update
                echo -e "\r"
        fi
elif [ ! -f $SYSROOT/usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
        echo "Cannot check dependencies on the first time to start bash since boot.please make sure the required commands are valid."
        echo "You can view $SYSROOT/etc/bash.bashrc to check which commands are needed."
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
timing(){
        if [ "$1" == pre ];then
[ $in_init == 1 ]&&return
    start_time=$(date +%s%N)
    in_timing="yes"
elif [ "$1" == post ];then
    local end_time=$(date +%s%N)
    local elapsed_time_ns=$((end_time - start_time))
        local command_to_execute=$(history 1 | sed 's/^ *[0-9]\+ *//')
        local elapsed_time_sec=$(echo "scale=2; $elapsed_time_ns / 1000000000" | bc)
        if [ $ret == 0 ];then
                echo -e "\033[1;32m"
        else
                echo -e "\033[1;31m"
        fi
        if [ $post_histsize -eq $pre_histsize ] && [ $deldups_exec -ne 1 ];then
                command_to_execute=''
        fi
        echo -En "$command_to_execute: ${elapsed_time_sec} s"
	echo -e "\033[m"
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
history -a
deldups
if [ $in_init == 0 ];then
        pre_histsize=$(stat -c%s $HISTFILE)
        timing post
fi
time1=$(date +%T|awk -F":" {'print $1":"$2'})
time2=$(date +%T|awk -F":" {'print $3'})
PATH="$(pwd):$SourcePATH"
in_init=0
}
tmuxmgr() {
if [ ! -z "$TMUX" ];then
echo "You have already attached a tmux session!"
return 1
fi
  sessions=$(tmux list-sessions -F "#S" 2>/dev/null)
  if [ -z "$sessions" ];then
  $SYSROOT/usr/bin/tmux new-session -s bash
  return 0
  else
  echo "\033[1;32m$(tmux ls)\033[m"
  fi
  echo "Choose a(ttach), n(ew), k(ill), q(uit)(also exit): "
  read -rsn1 mode
  if [ -z $mode ];then
  echo no choice,exiting
  return 1
  fi
  mode=$(compgen -W "attach new kill quit exit" -- "$mode")
  if [ "$mode"x == "attach"x ]; then
    read -e -p "Session name (or Enter to attach to last session: " session_name
    if [ -z "$session_name" ]; then
	    local empty=yes
      $SYSROOT/usr/bin/tmux a
    else session_name=$(compgen -W "$sessions" -- "$session_name")
    fi
    if [[ "$sessions" == *"$session_name"* ]] && [[ "$empty"x != yesx ]]; then
      $SYSROOT/usr/bin/tmux a -t "$session_name"
elif [[ "$empty"x != yesx ]];then
      echo "Can't find the session name."
      tmuxmgr
    fi
  elif [ "$mode"x == "new"x ]; then
    read -ep "Session name: " new_session
    $SYSROOT/usr/bin/tmux new-session -d -s "$new_session"
    $SYSROOT/usr/bin/tmux a -t "$new_session"
elif [ "$mode"x == "kill"x ];then
	read -ep "Session name: " kill_session
	kill_session=$(compgen -W "$sessions" -- "$kill_session")
	read -ep "Do you really want to kill this session: $kill_session ? [y/N]" kill
	[ -z $kill ]&&kill=n
	[ $kill == y ]&&tmux kill-session -t $kill_session||[ $kill == n ]&&return 1||[ $kill == N ]&&return 1
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
[ -x $SYSROOT/usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
PROMPT_COMMAND=post_exec
command_not_found_handle(){
        cmdnotfound $1
}
### You can modify there for other distributions ###
cmdnotfound(){
if [ -x $SYSROOT/usr/bin/pkgfile ];then
        echo "Searching command $1 ..."
        $SYSROOT/usr/bin/pkgfile $1
elif [ -x $SYSROOT/usr/lib/command-not-found ];then
        $SYSROOT/usr/lib/command-not-found -- "$1"
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
PS1='\[\e[m\]┌─\[\033[1;31m\][\[\033[m\]$0-$$ $(echo -n $time1&&$SYSROOT/usr/bin/tput blink&&echo -n ':'&&$SYSROOT/usr/bin/tput sgr0&&echo -n $time2 $([ $UID = 0 ]&&$SYSROOT/usr/bin/tput smul&&$SYSROOT/usr/bin/tput blink&&echo -n \[\033[1\;31m\]$(whoami)&&$SYSROOT/usr/bin/tput sgr0||echo \[\033[1\;34m\]$(whoami)))\[\033[1;31m\]@\[\033[34m\]\h \[\033[33m\]\w\[\033[31m\]]\[\033[m\]$(git_current_branch yes)\n└─$([ $ret = 0 ]&&echo \[\033[1\;32m\]||echo \[\033[1\;31m\]$ret)\$>>_\[\e[m\] '
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
if [ -x $SYSROOT/usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -v -p -CF'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias cdl='cd $OLDPWD'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls'
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
  if [ -f $SYSROOT/usr/share/bash-completion/bash_completion ]; then
    . $SYSROOT/usr/share/bash-completion/bash_completion
  elif [ -f $SYSROOT/etc/bash_completion ]; then
    . $SYSROOT/etc/bash_completion
  fi
fi
if [ -z $SUDO_USER ]&&[ $$ -ne 1 ];then
eval $SYSTEM_FETCH
fi
PATHS_SAVE_FILE="$RAMFS_DIR/saved_paths.txt"
if [ ! -f "$PATHS_SAVE_FILE" ]; then
    touch "$PATHS_SAVE_FILE"
fi
savepath() {
    local path
    local input="$1"
    [ "$input"x == "--help"x ]&&echo 'Usage:savepath [path] [bpathnumber (bpath*)]'
    if ls $input -d >/dev/null 2>&1; then
    if [ -z "$input" ]; then
            echo "No path entered.will save current directory(pwd)."
            path="$(pwd)"
    else
    path=$(realpath "$input")
    fi
    local number=1
    while grep -q "^bpath$number----bydpath-binding-to----" "$PATHS_SAVE_FILE"; do
        number=$((number + 1))
    done
    echo "bpath$number----bydpath-binding-to----$path" >> "$PATHS_SAVE_FILE"
    echo "Path saved with number bpath$number"
else 
        echo Unavalid path.
    fi
}
rmpath() {
    if [ $# -eq 0 ]; then
        echo "Usage: rmpath [bpathnumber ...]"
        return 1
    fi
	
    for number in "$@"; do
	if grep $number $PATHS_SAVE_FILE >/dev/null 2>&1;then
        $SYSROOT/usr/bin/sed -i "/^$number----bydpath-binding-to----/d" "$PATHS_SAVE_FILE"
        echo "Path with number $number removed"
else 
	echo "No such path number: $number"
	fi
    done
}
lspath() {
    if [ ! -s "$PATHS_SAVE_FILE" ]; then
        return 1
    fi
    $SYSROOT/usr/bin/cat "$PATHS_SAVE_FILE"
}
bydpath() {
    local cmd="$1"
    shift
    local args=()
    local bpath_args=()
    if [ "$cmd"awa == awa ]; then
            echo "Usage: bydpath [command] [command-args]"
            return 1
    fi
    for arg in "$@"; do
        if [[ "$arg" =~ ^bpath[0-9]+$ ]]; then
            local path
            path=$($SYSROOT/usr/bin/grep "^$arg----bydpath-binding-to----" "$PATHS_SAVE_FILE" | $SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $2}')
            if [ -z "$path" ]; then
                echo "Error: No path saved with number $arg"
                return 1
            fi
            args+=("$path")
            bpath_args+=("$arg----bydpath-binding-to----$path")
        elif [[ "$arg" =~ ^([^=]+)=(bpath[0-9]+)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local number="${BASH_REMATCH[2]}"
            local path
            path=$(grep "^$number----bydpath-binding-to----" "$PATHS_SAVE_FILE" | awk -F'----bydpath-binding-to----' '{print $2}')
            if [ -z "$path" ]; then
                echo "Error: No path saved with number $number"
                return 1
            fi
            args+=("$prefix=$path")
            bpath_args+=("$number----bydpath-binding-to----$path")
        else
            args+=("$arg")
        fi
    done
    if [[ "$cmd" == "sudo" || "$EUID" -eq 0 ]]; then
        echo "You are about to execute a command as root:"
        echo "$cmd"
        for bpath_arg in "${bpath_args[@]}"; do
            echo "$bpath_arg"
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
cdpath(){
local path
[ "$1"x == "--help"x ]&&echo "Usage:cdpath pathnumber"
path=$($SYSROOT/usr/bin/grep "^$1----bydpath-binding-to----" "$PATHS_SAVE_FILE" | $SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $2}')
[ -z $path ]&&echo "Error: No Paths save with number $1"&&return 1
eval "ls -d $path"
cd $path
}
_comp_bydbash_lspath(){
    local waiting_to_complete
    waiting_to_complete=$(lspath >/dev/null 2>&1 &&lspath|$SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $1}')
    local ref=$?
    if [ $ref -ne 1 ];then
	cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=($(compgen -W "$waiting_to_complete" -- $cur))
else
	COMPREPLY=(No-Path)
    fi
}

clpath(){
        > "$PATHS_SAVE_FILE"
        echo "Paths cleared."
}

complete -o default -o nospace -F _comp_bydbash_lspath rmpath
complete -o default -o nospace -F _comp_bydbash_lspath cdpath
# 定义补全函数
_comp_bydbash_bydpath() {    
	local waiting_to_complete
    waiting_to_complete=$(lspath >/dev/null 2>&1 &&lspath|$SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $1}')
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
        _comp_command
	COMPREPLY+=($(compgen -W "$waiting_to_complete" -- $cur))
	COMPREPLY+=($(compgen -f -d -- ${cur%"bpath"}bpath))
}


complete -o default -o nospace -F _comp_bydbash_bydpath bydpath
