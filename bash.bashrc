#!/data/data/com.termux/files/usr/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see $SYSROOT/usr/share/doc/bash/examples/startup-files (in the package bash-doc)
### BASHRC 配置 ###


SYSROOT=""  ### 留空就是/,主要为了适配termux
color_prompt=yes #yes/no
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' #GCC Colors
shopt -s autocd cdspell histverify xpg_echo histappend checkwinsize  ## bash的一些功能开关
RAMFS_DIR="$SYSROOT/tmp/bashrcFuncDatas" ### bashrc数据目录
SYSTEM_FETCH="fastfetch"
HISTFILE="$HOME/.bash_history" ## bash 历史记录文件
PROMPT_DIRTRIM=3 ###提示符中显示的目录层级数(效果类似~/.../aaa/bbb/ccc/)
CD_HISTFILE=$HOME/.bash_cd_history ### cd历史,便于撤销cd

###看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我看我###
# 最好别拿别的shell跑这个
# 用alias命令查看别名
# ArchLinux几乎可以开箱即用,别的发行版要改改
# 脚本有依赖的嗷, pkgfile(搜命令的),bash-completion(补全的),bash(应该不用多说了),ncurses(提供tput),bc(bashrc用作数据处理),tmux(好东西),git(好东西)




### 这开始检查依赖 ###
if [ ! -f $RAMFS_DIR/hasramfsdir ]&&[ $$ -ne 1 ];then 
mkdir $RAMFS_DIR
chmod 777 $RAMFS_DIR
touch $RAMFS_DIR/hasramfsdir
fi
[ ! -f $HISTFILE ]&&touch $HISTFILE
[ ! -f $CD_HISTFILE ]&&touch $CD_HISTFILE
bashrc_deps="pkgfile bash-completion bash ncurses bc tmux git"
if [ -x $SYSROOT/usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
        echo -n "Its the first time to start bash since boot,checking dependencies..."
        if pacman -Qq $bashrc_deps > /dev/null 2>&1;then
                touch $RAMFS_DIR/complete_dependency
                echo -e "\r"
        elif [ -x $SYSROOT/usr/bin/pacman ];then
                echo -n "These packages are needed.To make sure the bashrc will be executed successfully,you have to install them.\n\n$bashrc_deps"
		type -P sudo&&sudo pacman -Sy $bashrc_deps --neede --overwrite '*'||pacman -Sy $bashrc_deps --neede --overwrite '*'
		type -P sudo&&sudo pkgfile --update||pkgfile --update
                echo -e "\r"
        fi
elif [ ! -f $SYSROOT/usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
        echo "Cannot check dependencies on the first time to start bash since boot.please make sure the required commands are valid."
        echo "You can view $SYSROOT/etc/bash.bashrc to check which commands are needed."
        echo "Running bash normally."
        touch $RAMFS_DIR/complete_dependency
fi
unset bashrc_deps
### 检查好了
in_init=1
###进入init状态
SourcePATH=$PATH
bind 'set show-all-if-ambiguous on'
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
complete -F _comp_command sudo
complete -F _comp_command _
complete -E
#这给命令计时用的
timing(){
	if [ "$1" == pre ];then
		[ $in_init -eq 1 ]&&return
		start_time="$(date +%s%N)"
		in_timing=yes
	elif [ "$1" == post ];then
		end_time="$(date +%s%N)"
	fi
}
timing_post(){
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
    unset end_time
    unset in_timing
    post_histsize=$pre_histsize
    unset pre_histsize
}
###辅助命令计时器的
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
###命令执行之前由trap触发
pre_exec(){
        [ "$in_timing"x == yesx ]||timing pre
}
###命令执行之后由PROMPT_COMMAND触发
post_exec(){
ret=$?
timing post
history -a
deldups
if [ $in_init == 0 ];then
        pre_histsize=$(stat -c%s $HISTFILE)
        timing_post
fi
time1=$(date +%T|awk -F":" {'print $1":"$2'})
time2=$(date +%T|awk -F":" {'print $3'})
PATH="$(pwd):$SourcePATH"
in_init=0
}
###tmux小工具
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
###命令找不到就调用这个(这是bash内建的小功能,debian的bashrc好像就自带这个)
### 不同发行版有不同的搜索工具,这里只写了俩,需要的自己改 ###
if [ -x $SYSROOT/usr/bin/pkgfile ];then
	. $SYSROOT/usr/share/doc/pkgfile/command-not-found.bash
elif [ -x $SYSROOT/usr/share/command-not-found/command-not-found ];then
	function command_not_found_handle(){
		$SYSROOT/usr/share/command-not-found/command-not-found $1||(echo bash: $1: command not found&&return 127)
	}
else
        echo "command pkgfile not found,cant search the command."
        echo "you can install extra/pkgfile with sudo pacman -Sy pkgfile."
        echo "If you are not using Arch Linux(or any other pacman-based distribution),try to use other package searcher."
fi
###显示git分支的
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
### 设置提示符的 ###
PS1='\[\e[m\]┌─\[\033[1;31m\][\[\033[m\]$0-$$ $(echo -n $time1&&$SYSROOT/usr/bin/tput blink&&echo -n ':'&&$SYSROOT/usr/bin/tput sgr0&&echo -n $time2 $([ $UID = 0 ]&&$SYSROOT/usr/bin/tput smul&&$SYSROOT/usr/bin/tput blink&&echo -n \[\033[1\;31m\]$(whoami)&&$SYSROOT/usr/bin/tput sgr0||echo \[\033[1\;34m\]$(whoami)))\[\033[1;31m\]@\[\033[34m\]\h \[\033[33m\]\w\[\033[31m\]]\[\033[m\]$(git_current_branch yes)\n└─$([ $ret = 0 ]&&echo \[\033[1\;32m\]||echo \[\033[1\;31m\]$ret)\$>>_\[\e[m\] '
PS2='$(echo -n \[\033[1\;33m\])[Line $LINENO]>'
PS3='$(echo -n \[\033[1\;35m\])\[[$0]Select > '
PS4='$(echo -n \[\033[1\;35m\])\[[$0] Line $LINENO:> '
#if [ $color_prompt = no ];then 
#	PS1='┌─[$0-$$ $(echo -n "$time1:$time2") $(whoami)@\h \w]\[\033[m\]$(git_current_branch no)\n└─$([ $ret = 0 ]||echo -n $ret)\$>>_\[\e[m\] '
#    PS2='[Line $LINENO]> '
#    PS3='\[[$0]Select > '
#    PS4='\[[$0] Line $LINENO:> '
#fi
#unset color_prompt
###一些别名
if [ -x $SYSROOT/usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -v -p -CF'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias cdl='builtin cd $OLDPWD'
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
###整个fastfetch也不错(前头可以改嗷)
if [ -z $SUDO_USER ]&&[ $$ -ne 1 ];then
eval $SYSTEM_FETCH
fi
PATHS_SAVE_FILE="$RAMFS_DIR/saved_paths.txt"
if [ ! -f "$PATHS_SAVE_FILE" ]; then
    touch "$PATHS_SAVE_FILE"
fi
###路径实用小工具
###保存绝对路径
savepath() {
    local path
    local input="$1"
    [ "$input"x == "--help"x ]&&echo -e "Usage:savepath [path] [bpathnumber (bpath*)]\n\nThis function is provided to save a file or a path to a shared file.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."&&return
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
###删除绝对路径的保存
rmpath() {
    if [ $# -eq 0 ]|| [ "$1"x == --helpx ]; then
        echo -e "Usage: rmpath [bpathnumber ...]\n\nThis function is to remove a saved path.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
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
###列出保存的路径
lspath() {
    [ "$1"x == --helpx ]&&echo -e "Usage:lspath\nThis function is provided to list saved path is the shared file.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number.]\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
    if [ ! -s "$PATHS_SAVE_FILE" ]; then
        return 1
    fi
    $SYSROOT/usr/bin/cat "$PATHS_SAVE_FILE"
}
###使命令支持使用保存的路径编号
byd() {
    local cmd="$1"
    shift
    local args=()
    local bpath_args=()
    if [ "$cmd"awa == awa ]; then
            echo -e "Usage: byd [command] [command-args]\n\nThis function is to make bpath is supported in normal commands.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
            return
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
	    unset confirm
            return 1
        fi
	unset confirm
    fi
    eval "$cmd ${args[@]}"
}
complete -o default -o nospace -F _comp_complete_longopt savepath
###路径小工具的补全
_comp_bydbash_lspath(){
    local waiting_to_complete
    waiting_to_complete=$(echo -n "--help ";lspath>/dev/null 2>&1 &&lspath|$SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $1}')
    local ref=$?
    if [ $ref -ne 1 ];then
	cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=($(compgen -W "$waiting_to_complete" -- $cur))
else
	COMPREPLY=(No-Path)
    fi
}
###清空保存的路径
clpath(){
	[ "$1"x == --helpx ]&&echo -e "Usage:clpath\n\nThis function is provided for clear saved paths.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."&&return
        > "$PATHS_SAVE_FILE"
        echo "Paths cleared."
}
complete -o default -o nospace -F _comp_bydbash_lspath rmpath
###还是补全
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
function _comp_bydbash_cd(){
### 对bpath的支持
	local bpathcomp
    bpathcomp=$(lspath >/dev/null 2>&1 &&lspath|$SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $1}')
    local cur prev opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    _get_comp_words_by_ref cur prev words cword
    if getopt -o h -- "$prev"  >/dev/null 2>&1  && getopt -o h -- "$prev" 2>/dev/null| grep -- -h 2>/dev/null >&2;then
    local do_histcomp=set
    fi
        	###done
	if [[ "$do_histcomp"x = "set"x ]]&&[ ! -z $cur ];then
	###历史记录的补全
	compopt -o dirnames 
	compopt -o plusdirs
	local histcomp
	local ifs=$IFS
	local i=0
	IFS=$'\n'
	for line in $([ -f $CD_HISTFILE ]&&grep "$cur" "$CD_HISTFILE");do
		COMPREPLY+=("$line")
		i=$((i + 1))
	done
	IFS=$ifs
	unset do_histcomp
	###done
	###原版cd补全
else
_comp_cmd_cd
compopt +o filenames
compopt -o dirnames
compopt -o plusdirs
local new_completions=()
    local item
    for item in "${COMPREPLY[@]}"; do
        if [[ $item == *['#@ *?[];|&$\']* ]]; then
            item="${item//\'/\'\\\'\'}"
        fi
        new_completions+=("$item")
    done
    COMPREPLY=("${new_completions[@]}")
###done
	fi
	COMPREPLY+=($(compgen -W "$bpathcomp" -- $cur))
        COMPREPLY+=($(compgen -f -d -- ${cur%"bpath"}bpath))

	}
complete -o default -o nospace -F _comp_bydbash_bydpath byd
#超级cd
cd_deldups(){
        local first_cmd=$(tail -n 1 $1)
        local sec_cmd=$(tail -n 2 $1|sed '$d')
        if [ "$first_cmd"x == "$sec_cmd"x ];then
                sed -i '$d' $CD_HISTFILE
        fi
}
function cd(){
	local bcd_OPTS=$(getopt -o lchsLPe@ --long help -n 'cd' -- "$@")
	if [ $? != 0 ];then echo "Please check if you gave invalid options." >&2 ; return 1 ;fi
	eval set -- "$bcd_OPTS"
	local bcd_history_mode=0 
	local bcd_list=0 
	local bcd_search=0 
	local bcd_clear=0 
	local bcd_help=0
	local bcd_builtin_cd=0
	local bcd_builtin_opt='-'
	while true; do
		case "$1" in
			-h ) local bcd_history_mode=1; shift ;;
			-l ) local bcd_list=1;shift;;
			-s ) local bcd_search=1;shift;;
			-c ) local bcd_clear=1;shift;;
			--help ) local bcd_help=1;shift ;;
			-L ) local bcd_builtin_cd=1;bcd_builtin_opt+="L";shift ;;
			-P ) local bcd_builtin_cd=1;bcd_builtin_opt+="P";shift;;
			-e ) local bcd_builtin_cd=1;bcd_builtin_opt+="e";shift;;
			-@ ) local bcd_builtin_cd=1;bcd_builtin_opt+="@";shift;;
			-- ) shift; break ;;
			* ) break ;;
		esac
	done
	[ $bcd_builtin_opt == '-' ]&&bcd_builtin_opt='--'
	local bcd_remaining="$@"
	[ $bcd_help == 1 ]&&echo -e "$(builtin cd --help)\n\n    bydbash cd options:\n	-h	history mode\n	-l	print cd stack/print cd history\n	-c	clear cd stack/clear cd history\n	-s	search in the cd history(only works when -h is specified)\n\n	-LPe@ takes precedence over bydbash cd options.If you specified them,bydbash cd options will not work.\n	-lsc cannot be specified at the same time.\n\n	Each time you executed cd (including bash autocd),the variable \$OLDPWD will be appended\n	to file \$CD_HISTFILE\n\nYou can cd back to the last history record by bydbash command "uncd".It will cd back to the last path in \$RAMFS_DIR/"cdstack_\$\$" and then delete it (the path).\n\nSpecify the -h option when you want to trigger cd history completion,\n although it has no real effect.\n\nProvided by bydbash."&&return 0
	local bcd_vars=("bcd_list" "bcd_search" "bcd_clear")
	local count=0
	for var in "${bcd_vars[@]}"; do
		[ "${!var}" -eq 1 ]&&((count++))
	done
	[ $count -gt 1 ]&&echo "-l -s -c should not be specified at the same time.">&2&&return 1
	if [ $bcd_history_mode -eq 0 -a $bcd_builtin_cd -eq 0 ];then
		if [ $bcd_list -eq 1 ];then
			[ -s $RAMFS_DIR/"cdstack_$$" ]&&cat $RAMFS_DIR/"cdstack_$$"||echo "cd stack is empty!";return
		elif [ $bcd_search -eq 1 ];then
			echo "-s should be spcified only when -h is spcified."
			return 1
		elif [ $bcd_clear -eq 1 ];then
			local confirm;read -ep "Are you sure you want to clear the cd stack?(Y/n)" confirm
			[[ "$confirm"x != nx && "$confirm"x != Nx ]]&& > $RAMFS_DIR/"cdstack_$$"&&return 0||return 1
		fi
	elif [ $bcd_builtin_cd -eq 0 ];then
		if [ $bcd_list -eq 1 ];then
			[ -s $CD_HISTFILE ]&&(cat $CD_HISTFILE||echo "cd history file is empty.";return 1);return
		elif [ $bcd_search -eq 1 ];then
			[ -z "$bcd_remaining" ]&&echo "Needs at least one char to search!"&&return 1||cat $CD_HISTFILE | grep "$bcd_remaining";return
		elif [ $bcd_clear -eq 1 ];then
			read -ep "Are you sure you want to clear the cd history?(Y/n)" confirm
			[[ "$confirm"x != nx && "$confirm"x != Nx ]]&& > $CD_HISTFILE&&return 0||return 1
			return
		fi
	fi
	[ ! -z "$bcd_remaining" ]&&bcd_remaining="'$bcd_remaining'"
	local bpath
	bpath=$($SYSROOT/usr/bin/grep "^$1----bydpath-binding-to----" "$PATHS_SAVE_FILE" | $SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $2}')
        if [ -z "$bpath" ];then
        eval "builtin cd $bcd_builtin_opt $bcd_remaining";echo $OLDPWD >> $RAMFS_DIR/"cdstack_$$" ;echo "$PWD" >> $CD_HISTFILE
        cd_deldups "$CD_HISTFILE"
        [ -f $RAMFS_DIR/"cdstack_$$" ]&&cd_deldups $RAMFS_DIR/"cdstack_$$"
else 
        eval "builtin cd $bcd_builtin_opt '$bpath'";echo $OLDPWD >> $RAMFS_DIR/"cdstack_$$" ;echo "$PWD" >> $CD_HISTFILE
        fi
}
function uncd(){
	[ "$1"x == "--helpx" ]&&echo -e "Usage:uncd\n\nThis function is provided to realize the undo function on cd.\ncd history will be saved in both $RAMFS_DIR/"cdstack_$$" and $CD_HISTFILE.Use cd -c to clear the cd stack,use cdhist -c to clear the cd history.\n\nProvided by bydbash."&&return
	local uncd
	[ ! -s $RAMFS_DIR/"cdstack_$$" ]&&echo "cd stack is empty!"&&return 1
	uncd=$(tail -n 1 $RAMFS_DIR/"cdstack_$$")
	echo "will cd to $uncd"
	eval "$(echo "builtin cd '$uncd'")"
	sed -i '$d' $RAMFS_DIR/"cdstack_$$"
}
function loop(){
	local bloop_OPTS
	bloop_OPTS=$(getopt -o ut: --long help -n "$0" -- "$@")
	if [ $? != 0 ];then echo "Please check if you gave invalid options." >&2;return 1;fi
	eval set -- "$bloop_OPTS"
	local bloop_dont_exit_when_fail=0
	local bloop_enable_times=0
	local bloop_times=0
	local bloop_help=0
	local bloop_remaining=''
	while true; do
		case "$1" in
			-u ) bloop_dont_exit_when_fail=1; shift;;
			-t ) bloop_enable_times=1
				bloop_times=$(echo -n $2 | tr -d ' ')
				if [[ ! "$bloop_times" =~ ^[0-9]+$ ]];then
					echo "You should give a number after option -t." >&2
					return 1
				fi
				shift 2;;
			--help ) bloop_help=1;shift;;
			-- ) shift;break;;
		esac
	done
	bloop_remaining="$@"
	[ $bloop_help -eq 1 ]&&(echo -ne "Usage: $0 [-u] [-t <times>] [command]\n\n	This function is used to execute a bash command for many times\n	Options:\n		-u don't return when command returned a non-zero value\n		-t <times> execute <command> for <times> times\n	<times> must be a integer.\n\nProvided by bydbash.")&&return 0
	[ -z "$bloop_remaining" ]&&return 0
	if [ $bloop_dont_exit_when_fail -eq 1 ];then
		if [ $bloop_enable_times -eq 0 ];then
			while true;do eval ""$bloop_remaining"";done
		else
			for (( i=0; i<=$bloop_times; i++));do
			       	eval ""$bloop_remaining""
			done
		fi
	elif [ $bloop_enable_times -eq 0 ];then
		while true;do 
			eval ""$bloop_remaining""
			local returning=$?
			if [ $returning -ne 0 ];then 
				break
			fi
		done
		return $returning
	else
		for ((i=0;i <= $bloop_times;i++))
		do 
			eval ""$bloop_remaining""
			returning=$?
			if [ $returning -ne 0 ];then
				break
				return $returning
			fi
		done
	fi

}
trap "[ -f $RAMFS_DIR/cdstack_$$ ]&&rm $RAMFS_DIR/cdstack_$$" EXIT
complete -E -F _comp_complete_longopt
_cd  ##这个地方...好像不执行这个命令那么_comp_cmd_cd这个函数不会出来...
complete -o default -o nospace -F _comp_bydbash_cd cd
[ -f $HOME/.bashrc ]&&source $HOME/.bashrc||true
###完事嗷
