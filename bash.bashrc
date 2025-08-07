# ~/.bashrc: executed by bash(1) for non-login shells.
# see $SYSROOT/usr/share/doc/bash/examples/startup-files (in the package bash-doc)
[[ $- != *i* ]] && return ||true # 非交互式情况下直接退出
# 针对Arch Linux及其派生发行版以及基于pacman包管理的termux的开箱即用的bashrc.
# BASHRC重要变量
SYSROOT=""  # 留空就是/,主要为了适配termux
[ -z $TERMUX_VERSION ]||SYSROOT="/data/data/com.termux/files" # 判断是否termux
color_prompt=yes # 最好别动
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' #GCC Colors
shopt -s autocd cdspell histverify xpg_echo histappend checkwinsize  # bash的一些功能开关
RAMFS_DIR="$SYSROOT/tmp/bashrcFuncDatas" # bashrc数据目录
SYSTEM_FETCH="fastfetch"
HISTFILE="$HOME/.bash_history" # bash 历史记录文件
PROMPT_DIRTRIM=3 # 提示符中显示的目录层级数(~/.../aaa/bbb/ccc/)
CD_HISTFILE=$HOME/.bash_cd_history # cd历史,便于撤销cd
HISTSIZE=100000000
HISTFILESIZE=200000000
HISTCONTROL=ignorespace # ignorespace别动
PATHS_SAVE_FILE="$RAMFS_DIR/saved_paths.txt"
# BASHRC重要变量结束
# 前部命令部分
in_init=1
if [ ! -f $RAMFS_DIR/hasramfsdir ]&&[ $$ -ne 1 ];then 
	mkdir $RAMFS_DIR
	chmod 777 $RAMFS_DIR
	> $RAMFS_DIR/hasramfsdir
fi
[ ! -f $HISTFILE ]&&> $HISTFILE
[ ! -f $CD_HISTFILE ]&&> $CD_HISTFILE
if [ ! -f "$PATHS_SAVE_FILE" ]; then
	> "$PATHS_SAVE_FILE"
fi
bashrc_deps="pkgfile bash-completion bash ncurses bc tmux git"
if [ -x $SYSROOT/usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
	echo -n "Its the first time to start bash since boot,checking dependencies...\r"
	if pacman -Qq $bashrc_deps > /dev/null 2>&1;then
		> $RAMFS_DIR/complete_dependency
		echo -n "\e[K"
	elif [ -x $SYSROOT/usr/bin/pacman ];then
		echo -n "These packages are required.To make sure the bashrc will be executed successfully,you have to install them.\n\n$bashrc_deps"
		type -P sudo&&sudo pacman -Sy $bashrc_deps --neede --overwrite '*'||pacman -Sy $bashrc_deps --neede --overwrite '*'
		type -P sudo&&sudo pkgfile --update||pkgfile --update
		echo -e "\r"
	fi
elif [ ! -f $SYSROOT/usr/bin/pacman ] && [ ! -f $RAMFS_DIR/complete_dependency ];then
	echo "Cannot check dependencies on the first time to start bash since boot.please make sure the required commands are valid."
	echo "You can view $SYSROOT/etc/bash.bashrc to check which commands are needed."
	echo "Running bash normally."
	> $RAMFS_DIR/complete_dependency
fi
unset bashrc_deps
SourcePATH=$PATH
if [ -x $SYSROOT/usr/bin/pkgfile ];then
	##. $SYSROOT/usr/share/doc/pkgfile/command-not-found.bash
	command_not_found_handle () {
		local cmd=$1
		local pkgs
		local FUNCNEST=10
		set +o verbose
		mapfile -t pkgs < <(pkgfile -bv -- "$cmd" 2>/dev/null)
		if (( ${#pkgs[*]} > 0 )); then
			echo "$cmd may be found in the following packages:"
			for ((i = 0; i < ${#pkgs[@]}; i++)); do
				echo "\e[1;34m$((i + 1)). ${pkgs[$i]}\e[m"
			done
		fi
		if (( ${#pkgs[*]} == 1 )); then
			local pkg=${pkgs[0]%% *}
			local reading=$(echo "Install \e[1;34m$pkg\e[m? [\e[1;32mY\e[m/\e[1;31mn\e[m] ===> ")
			read -rp "$reading" response
			[[ -z $response || $response = [Yy] ]] || return 0
			printf '\n'
			type -P sudo > /dev/null 2>&1 &&sudo pacman -Sy --noconfirm -- "$pkg"||pacman -Sy --noconfirm -- "$pkg"
			return
		elif (( ${#pkgs[*]} > 1 )); then
			read -p "Enter the number of the package to install (q = quit,default 1): " choice
			[[ $choice = [Qq] ]]&&return 1
			[ -z $choice ]&&choice=1
			if [[ $choice =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#pkgs[*]} )); then
				local pkg=$(echo "${pkgs[choice - 1]}" | $SYSROOT/usr/bin/awk '{print $1}')
				type -P sudo > /dev/null 2>&1 &&sudo pacman -Sy --noconfirm -- "$pkg"||pacman -Sy --noconfirm -- "$pkg"
				return
			else
				echo "Invalid choice. Aborting."
				return 127
			fi
		fi
		if (( ${#pkgs[*]} == 0 )); then
			printf "bash: %s: command not found\n" "$cmd"
		fi
		return 127
	}
elif [ -x $SYSROOT/usr/lib/command-not-found ];then
	function command_not_found_handle(){
		$SYSROOT/usr/lib/command-not-found $1||(echo bash: $1: command not found&&return 127)
	}
else
	echo "command pkgfile not found,cant search the command."
	echo "you can install extra/pkgfile with sudo pacman -Sy pkgfile."
	echo "If you are not using Arch Linux(or any other pacman-based distribution),try to use other package searcher."
fi
bpfold_oldpwd="none"
# 前部命令部分结束
# 函数定义部分
timing(){ # 命令计时器
	if [ "$1" == pre ];then
		[ $in_init -eq 1 ]&&return
		start_time="$($SYSROOT/usr/bin/date +%s%N)"
		in_timing=yes
	elif [ "$1" == post ];then
		end_time="$($SYSROOT/usr/bin/date +%s%N)"
	fi
}
timing_post(){ # 命令计时器
	local elapsed_time_ns=$((end_time - start_time))
	local elapsed_time_sec=$(echo "scale=2; $elapsed_time_ns / 1000000000" | $SYSROOT/usr/bin/bc)
	if [ $ret == 0 ];then
		echo -e "\e[1;32m"
	else
		echo -e "\e[1;31m"
	fi
	echo -ne "\r\e[k"
	echo -En "$bashcommand: ${elapsed_time_sec} s"
	echo -e "\e[m"
	unset start_time
	unset end_time
	unset in_timing
	unset bashcommand
}
tmuxmgr() { # tmux工具
	if [ ! -z "$TMUX" ];then
		echo "You have already attached a tmux session!"
		return 1
	fi
	sessions=$($SYSROOT/usr/bin/tmux list-sessions -F "#S" 2>/dev/null)
	if [ -z "$sessions" ];then
		$SYSROOT/usr/bin/tmux new-session -s bash
		return 0
	else
		echo "\e[1;32m$(tmux ls)\e[m"
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
		[ $kill == y ]&&$SYSROOT/usr/bin/tmux kill-session -t $kill_session||[ $kill == n ]&&return 1||[ $kill == N ]&&return 1
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
git_current_branch(){ # git分支显示
	local ref
	ref=$($SYSROOT/usr/bin/git symbolic-ref --quiet HEAD 2>/dev/null)
	local return=$?
	if [[ $return -ne 0 ]]; then
		[[ $return -eq 128 ]] && return
		ref=$($SYSROOT/usr/bin/git rev-parse --short HEAD 2>/dev/null) || return
	fi
	if [ "$1" == "yes" ];then
		echo="-\e[1;31m[\e[m${ref#refs/heads/}\e[1;31m]\e[m"
	else 
		echo="-[${ref#refs/heads/}]"
	fi
	echo -ne "$echo"
}
savepath() { # 保存绝对路径->代号
	local path
	local input="$1"
	[ "$input"x == "--help"x ]&&echo -e "Usage:savepath [path] [bpathnumber (bpath*)]\n\nThis function is provided to save a file or a path to a shared file.\n\nCaution: Up to now,This function only supports s single file/dir at a time!\n\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."&&return 0
	[ -z "$input" ]&&local empty=1||local empty=0	
	if [ $empty -eq 1 ]; then
		echo "No path entered.will save current directory(pwd)."
		path="$(builtin pwd)"
	elif ls "$input" -d 2>&1; then
		path="$($SYSROOT/usr/bin/realpath "$input")"
	else 
		echo Unavalid path.&&return 1
	fi
	local number=1
	while $SYSROOT/usr/bin/grep -q "^bpath$number----bydpath-binding-to----" "$PATHS_SAVE_FILE"; do
		number=$((number + 1))
	done
	echo "bpath$number----bydpath-binding-to----$path" >> "$PATHS_SAVE_FILE"
	echo "Path saved with number bpath$number"
}
rmpath() { # 删除代号
	if [ "$1"x == --helpx ]; then
		echo -e "Usage: rmpath [bpathnumber ...]\n\nThis function is to remove a saved path.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
		return 0
	fi
	if [ $# -eq 0 ]; then
		echo -e "Usage: rmpath [bpathnumber ...]\n\nThis function is to remove a saved path.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
		return 1
	fi
	for number in "$@"; do
		if $SYSROOT/usr/bin/grep $number $PATHS_SAVE_FILE >/dev/null 2>&1;then
			$SYSROOT/usr/bin/sed -i "/^$number----bydpath-binding-to----/d" "$PATHS_SAVE_FILE"
			echo "Path with number $number removed"
		else 
			echo "No such path number: $number"
		fi
	done
}
lspath() { # 列出保存的绝对路径
	[ "$1"x == --helpx ]&&echo -e "Usage:lspath\nThis function is provided to list saved path is the shared file.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number.]\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
	if [ ! -s "$PATHS_SAVE_FILE" ]; then
		echo "No paths saved!" >&2
		return 1
	fi
	$SYSROOT/usr/bin/cat "$PATHS_SAVE_FILE"
}
function byd() { # 使命令支持绝对路径
	local cmd="$1"
	shift
	local args=()
	local bpath_args=()
	if [ -z "$cmd" ]; then
		echo -e "Usage: byd [command] [command-args]\n\nThis function is to make bpath is supported in normal commands.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."
		return 1
	fi
	for arg in "$@"; do
		if [[ "$arg" =~ ^bpath[0-9]+$ ]]; then
			local path
			path="'$($SYSROOT/usr/bin/grep "^$arg----bydpath-binding-to----" "$PATHS_SAVE_FILE" | $SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $2}')'"
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
			path="'$($SYSROOT/usr/bin/grep "bpath$number----bydpath-binding-to----" "$PATHS_SAVE_FILE" | $SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $2}')'"
			if [ -z "$path" ]; then
				echo "Error: No path saved with number $number"
				return 1
			fi
			args+=("$prefix=$path")
			bpath_args+=("$number----bydpath-binding-to----$path")
		else
			args+=("'$arg'")
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
	eval $cmd "${args[@]}"
}
function clpath(){ # 清除保存的绝对路径
	[ "$1"x == --helpx ]&&echo -e "Usage:clpath\n\nThis function is provided for clear saved paths.\nTo save a path,use savepath [file or dir].\nTo remove a path,use rmpath [bpath number].\nTo list saved paths,use lspath.\nTo make bpath is supported in normal commands,use byd [command] [command args].\n\nProvided by bydbash."&&return 0
	> "$PATHS_SAVE_FILE"
	echo "Paths cleared."
}
function title(){
	[ -z $set_title ]&&set_title=1&&echo "You've been manually set the title.\nThe varible set_title was set to 1.\nYou can unset it to enable automatically title setting."
	echo -ne "\e]0;"
	echo -n "$@"
	echo -ne "\007"
}
function cd_deldups(){ # 更好的cd的函数前置
	local first_cmd=$($SYSROOT/usr/bin/tail -n 1 $1)
	local sec_cmd=$($SYSROOT/usr/bin/tail -n 2 $1|$SYSROOT/usr/bin/sed '$d')
	if [ "$first_cmd"x == "$sec_cmd"x ];then
		$SYSROOT/usr/bin/sed -i '$d' $CD_HISTFILE
	fi
}
function cd(){ # 更好的cd
	local bcd_OPTS=$($SYSROOT/usr/bin/getopt -o HmlchsLPe@ --longoptions 'help history list search clear help mountpoint' -n 'cd' -- "$@")
	if [ $? != 0 ];then echo "Please check if you gave invalid options." >&2 ; return 1 ;fi
	local bcd_history_mode=0 
	local bcd_list=0 
	local bcd_search=0 
	local bcd_clear=0 
	local bcd_help=0
	local bcd_builtin_cd=0
	local bcd_builtin_opt='-'
	local bcd_mountpoint=0
	local bcd_remaining=()
	for bcd_opt in $bcd_OPTS; do
		case "$bcd_opt" in
			-h | --history ) bcd_history_mode=1; shift ;;
			-l | --list ) bcd_list=1;shift;;
			-s | --search ) bcd_search=1;shift;;
			-c | --clear ) bcd_clear=1;shift;;
			-H | --help ) bcd_help=1;shift ;;
			-m | --mountpoint ) bcd_mountpoint=1;shift ;;
			-L ) bcd_builtin_cd=1;bcd_builtin_opt+="L";shift;;
			-P ) bcd_builtin_cd=1;bcd_builtin_opt+="P";shift;;
			-e ) bcd_builtin_cd=1;bcd_builtin_opt+="e";shift;;
			-@ ) bcd_builtin_cd=1;bcd_builtin_opt+="@";shift;;
			-- ) shift;;
			* ) bcd_remaining+=("$bcd_opt") ;shift ;;
		esac
	done
	[ $bcd_builtin_opt == '-' ]&&bcd_builtin_opt='--'
	[ $bcd_help == 1 ]&&echo -e "$(builtin cd --help)\n\n    bydbash cd options:\n	-h|--history	history mode\n	-l|--list	print cd stack/print cd history\n	-c|--clear	clear cd stack/clear cd history\n	-s|--search	search in the cd history(only works when -h is specified)\n	-m|--mountpoint	find the mountpoint of a filesystem(like findmnt) and cd into it.\n		When This option is specified,cd will not work as normal.It can't process a directory.\n\n	-LPe@ takes precedence over bydbash cd options.If you specified them,bydbash cd options will not work.\n	-lsc cannot be specified at the same time.\n\n	Each time you executed cd (including bash autocd),the variable \$OLDPWD will be appended\n	to file \$CD_HISTFILE\n\nYou can cd back to the last history record by bydbash command "uncd".It will cd back to the last path in \$RAMFS_DIR/"cdstack_\$\$" and then delete it (the path).\n\nSpecify the -h option when you want to trigger cd history completion,\n although it has no real effect.\n\nProvided by bydbash."&&return 0
	local bcd_vars=("bcd_list" "bcd_search" "bcd_clear")
	local count=0
	for var in "${bcd_vars[@]}"; do
		[ "${!var}" -eq 1 ]&&((count++))
	done
	[ $count -gt 1 ]&&echo "-l -s -c should not be specified at the same time.">&2&&return 1
	if [ $bcd_mountpoint -eq 1 ];then
		local in fs subvol fullpre=() fullpost=() targetpre=() targetpost=() mountpoint number=0 volnum=() do_grep=0 aifs=$IFS # 初始化
		in=$(eval echo $bcd_remaining)           # 初始化
		fs=$(echo -ne $in | $SYSROOT/usr/bin/awk -F"[" '{print $1}'); # 获取目标文件系统
		subvol=$(echo $in | $SYSROOT/usr/bin/awk -F"[" '{print "[" $2}') # 获取目标子卷
		[ "$subvol" != "[" ]&&do_grep=1					# 有子卷则尝试匹配
		IFS=$'\n' 
		for line in $(eval $SYSROOT/usr/bin/findmnt -Arn $fs);do 	# 准备完整输出数组.
			fullpre+=("$line")
		done
		[ -z "${fullpre[*]}" ]&&echo "cd: cannot find the mountpoint." >&2 &&return 1
		IFS=$'\n' 
		for line in $(eval $SYSROOT/usr/bin/findmnt -Arno TARGET $fs);do # 准备挂载点数组.
			targetpre+=("$line")
		done
		if [ $do_grep -eq 1 ];then
			for ((i=0;i<${#fullpre[@]};i++));do 			# 匹配:findmnt原完整输出中的某子卷挂载点.
				[[ ${fullpre[$i]} =~ "$subvol" ]]&&volnum+=("$i")&&fullpost+=("${fullpre[$i]}")         # 使用数组支持单子卷多挂载点.
			done
			for ((i=0;i<${#volnum[@]};i++));do
				targetpost+=("${targetpre[${volnum[$i]}]}")
			done
		else
			fullpost=("${fullpre[@]}")
			targetpost=("${targetpre[@]}")
		fi
		IFS=$aifs
		unset fullpre targetpre aifs in subvol
		[ -z "${fullpost[*]}" ]&&echo "cd: cannot find the mountpoint.">&2&&return 1
		if [ ${#fullpost[*]} -gt 1 ];then
			for ((i=0;i < ${#fullpost[*]};i++));do
				echo "\e[1;31m${i} \e[1;34m- \e[1;35m${fullpost[$i]}"
			done
			read -rep "$(echo -e "\n\e[1;34mWhich mountpoint do you want to select? \e[1;35m(Enter the number,default 0) \e[1;32m===>\e[m")" number
			if ! ([[ "$number" =~ ^[0-9]+$ ]]||[ -z $number ]) ;then echo "Please enter a number.">&2;return 1;fi
			if ! [[ -n ${targetpost[$number]} ]];then echo "Please enter a valid number.">&2;return 1;fi
		fi
		mountpoint="${targetpost[$number]}"
		echo "Will cd to found mountpoint: \e[1;32m$mountpoint\e[m"
		builtin cd "$mountpoint"&&echo $OLDPWD >> $RAMFS_DIR/"cdstack_$$" &&echo $PWD >> $CD_HISTFILE
		cd_deldups "$CD_HISTFILE"
		[ -f $RAMFS_DIR/"cdstack_$$" ]&&cd_deldups $RAMFS_DIR/"cdstack_$$"
		return
	fi
	if [ $bcd_history_mode -eq 0 ]&&[ $bcd_builtin_cd -eq 0 ];then
		if [ $bcd_list -eq 1 ];then
			[ -s $RAMFS_DIR/"cdstack_$$" ]&&$SYSROOT/usr/bin/cat $RAMFS_DIR/"cdstack_$$"||echo "cd stack is empty!";return 1
		elif [ $bcd_search -eq 1 ];then
			echo "-s should be spcified only when -h is spcified."
			return 1
		elif [ $bcd_clear -eq 1 ];then
			local confirm;read -ep "Are you sure you want to clear the cd stack?(Y/n)" confirm
			[[ "$confirm"x != nx && "$confirm"x != Nx ]]&& > $RAMFS_DIR/"cdstack_$$"&&return 0||return 1
		fi
	elif [ $bcd_builtin_cd -eq 0 ];then
		if [ $bcd_list -eq 1 ];then
			[ -s $CD_HISTFILE ]&&($SYSROOT/usr/bin/cat $CD_HISTFILE||echo "cd history file is empty.";return 1);return
		elif [ $bcd_search -eq 1 ];then
			[ -z "$bcd_remaining" ]&&echo "Needs at least one char to search!"&&return 1||eval "cat $CD_HISTFILE | grep $bcd_remaining";return
		elif [ $bcd_clear -eq 1 ];then
			read -ep "Are you sure you want to clear the cd history?(Y/n)" confirm
			[[ "$confirm"x != nx && "$confirm"x != Nx ]]&& > $CD_HISTFILE&&return 0||return 1
			return
		fi
	fi
	local bpath
	bpath="$(echo -ne "${bcd_remaining[@]}"|$SYSROOT/usr/bin/sed s/\'//g)"
	[[ "$bpath" =~ bpath.* ]]&&bpath=$($SYSROOT/usr/bin/grep "^$bpath----bydpath-binding-to----" "$PATHS_SAVE_FILE" | $SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $2}')||bpath=""
	if [ -z "$bpath" ];then
		eval builtin cd $bcd_builtin_opt "${bcd_remaining[@]}"&&echo $OLDPWD >> $RAMFS_DIR/"cdstack_$$" &&echo "$PWD" >> $CD_HISTFILE
		cd_deldups "$CD_HISTFILE"
		[ -f $RAMFS_DIR/"cdstack_$$" ]&&cd_deldups $RAMFS_DIR/"cdstack_$$"
		return 0
	else
		echo "$bpath"
		eval builtin cd $bcd_builtin_opt \'$bpath\'&&echo $OLDPWD >> $RAMFS_DIR/"cdstack_$$" &&echo "$PWD" >> $CD_HISTFILE
		cd_deldups "$CD_HISTFILE"
		[ -f $RAMFS_DIR/"cdstack_$$" ]&&cd_deldups $RAMFS_DIR/"cdstack_$$"
		return 0
	fi
}
function uncd(){ # cd的撤回系统
	[ "$1"x == "--helpx" ]&&echo -e "Usage:uncd\n\nThis function is provided to realize the undo function on cd.\ncd history will be saved in both $RAMFS_DIR/"cdstack_$$" and $CD_HISTFILE.Use cd -c to clear the cd stack,use cdhist -c to clear the cd history.\n\nProvided by bydbash."&&return
	local uncd
	[ ! -s $RAMFS_DIR/"cdstack_$$" ]&&echo "cd stack is empty!"&&return 1
	uncd=$($SYSROOT/usr/bin/tail -n 1 $RAMFS_DIR/"cdstack_$$")
	echo "will cd to $uncd"
	eval "$(echo "builtin cd '$uncd'")"
	$SYSROOT/usr/bin/sed -i '$d' $RAMFS_DIR/"cdstack_$$"
}
function loop(){ # bash自动循环执行命令
	local bloop_OPTS
	if ! bloop_OPTS="$($SYSROOT/usr/bin/getopt -o ut: --long help -n "loop" -- "$@")";then echo "Please check if you gave invalid options." >&2;return 1;fi
	local bloop_dont_exit_when_fail=0
	local bloop_enable_times=0
	local bloop_times=0
	local bloop_help=0
	local end_opt=0
	local bloop_remaining=()
	for bloop_opt in $bloop_OPTS; do
		case "$bloop_opt" in
			-u ) bloop_dont_exit_when_fail=1; shift;;
			-t ) bloop_enable_times=1;shift 2;;
			--help ) bloop_help=1;shift;;
			-- ) end_opt=1;;
			* ) [ "$end_opt" -ne 1 ]&&bloop_times=${bloop_opt//\'/}||bloop_remaining+=("$bloop_opt");;
		esac
	done
	[ $bloop_help -eq 1 ]&&echo -ne "Usage: loop [-u] [-t <times>] [command]\n\n	This function is used to execute a bash command for many times\n	Options:\n		-u don't stop when command returned a non-zero value\n		-t <times> execute <command> for <times> times\n	<times> must be a integer.\n\nProvided by bydbash.\n"&&return 0
	[ -z "${bloop_remaining[*]}" ]&&return 0
	local bloop_cmd="${bloop_remaining[*]//\'/}"
	if [ $bloop_dont_exit_when_fail -eq 1 ];then
		if [ $bloop_enable_times -eq 0 ];then
			for((;;)){ eval "$bloop_cmd"; }
		else
			for (( i=1; i<=$bloop_times; i++));do
				eval "$bloop_cmd"
			done
		fi
	elif [ $bloop_enable_times -eq 0 ];then
		while true 
		do
		{
			eval "$bloop_cmd"
			local returning=$?
			if [ $returning -ne 0 ];then 
				break
			fi
		}
		done
		return $returning
	else
		for ((i=1;i <= $bloop_times;i++))
		do 
			eval "$bloop_cmd"
			returning=$?
			if [ $returning -ne 0 ];then
				break
			fi
		done
		return $returning
	fi
}
smart_pwd(){
	[ "$PWD" = "$bpfold_oldpwd" ]||smart_pwd="$(smart_pwd_get)"
	bpfold_oldpwd="$PWD"
}
smart_pwd_get(){
	local ifs="${IFS}"
	local bpfold_in="${PWD}"
	local colorhome="\e[1;35m~\e[0;32m"
	IFS='/'
	if [ "${PWD}" != "/" ]&&[ "${PWD}" != "${HOME}" ]; then
		local bpfold_colorout="${PWD/#${HOME}/${colorhome}}"
		unset colorhome
		bpfold_in="${PWD/#${HOME}/\~}"
		IFS='/' elements=($bpfold_colorout) #分片
		IFS='/' ckments=(${bpfold_in})
		local len=${#elements[@]}
		len=$((len-1))
		local elemcolor
		for ((i=2; i<len; i++));do 
			local elem="${elements[i]}"
			[ -n "$elem" ]||continue
			elemcolor="\e[1;34m"
			local ckmenti="${ckments[*]:0:((i+1))}"
			[ -L "${ckmenti/\~/~}" ]&&elemcolor="\e[1;36m"
			[ -a "${ckmenti/\~/~}" ]||elemcolor="\e[1;31m"
			[ "${elem:0:1}" == "." ]&&elements[i]="${elemcolor}${elem:0:2}\e[0;32m"||elements[i]="${elemcolor}${elem:0:1}\e[0;32m" 
		done
		if [ 1 -lt $len ];then
		elemcolor="\e[1;34m"
		local ckment1="${ckments[*]:0:2}"
		[ -L "${ckment1/\~/~}" ]&&elemcolor="\e[1;36m"
		[ -a "${ckment1/\~/~}" ]||elemcolor="\e[1;31m"
		elements[1]="${elemcolor}${elements[1]:0:5}$([ ${#ckments[1]} -gt 5 ]&&echo -ne '.')\e[0;32m"
		unset ckment1
		fi
		elemcolor="\e[1;34m"
		local elem="${elements[len]}"
		[ -L "${PWD}" ]&&elemcolor="\e[1;36m"
		elements[len]="${elemcolor}${elem}\e[0;32m"
				IFS='/' bpfold_colorout="${elements[*]}"
	else
		case "${bpfold_in}" in
			/) local bpfold_colorout=/ ;;
			"${HOME}") local bpfold_colorout="${colorhome}" ;;
		esac
	fi
	IFS="${ifs}"
	unset ifs
	echo -e "\e[0;31m${bpfold_colorout}\e[m"
	unset bpfold_colorout
}
pre_exec(){ # 命令执行之前由trap触发的函数
	[ $in_init -eq 1 ]&&return 0
	[ -z $preexec  ]&&[ "$BASH_COMMAND" != "post_exec" ]&&[ $in_init == 0 ]&&bashcommand="$BASH_COMMAND"
	preexec=1
	[ "$in_timing"x == yesx ]||timing pre
	[ -z $set_title ]&&echo -ne "\e]0;Proc: $bashcommand\007"
}
post_exec(){ # 命令执行之后由PROMPT_COMMAND触发的函数
	ret=$?
	timing post
	if [ $in_init == 0 ];then
		timing_post
	fi
	time1=$($SYSROOT/usr/bin/date +%T|$SYSROOT/usr/bin/awk -F":" '{print $1":"$2}')
	time2=$($SYSROOT/usr/bin/date +%T|$SYSROOT/usr/bin/awk -F":" '{print $3}')
	smart_pwd
	PATH="$(pwd):$SourcePATH"
	unset preexec
	[ -z $set_title ]&&echo -n "\e]0;*I bash-$$ [$(whoami)@$HOSTNAME]\007"
PS1="\[\e[m\]┌─\[\e[1;31m\][\[\e[m\]$0-$$ $(echo -n "$time1\[\e[25m\]:\[\e[m\]$time2" $([ $UID = 0 ]&&echo -ne "\[\e[4m\]\[\e[5m\]\[\e[1;31m\]$(whoami)\[\e[m\]"||echo "\[\e[1;34m\]$(whoami)"))\[\e[1;31m\]@\[\e[34m\]\h $smart_pwd\[\e[1;31m\]]\[\e[m\]$(ps1addons)\n└─$([ $ret = 0 ]&&echo -ne "\[\e[1;32m\]"||echo -en "\[\e[1;31m\]$ret")\$>>_\[\e[m\] "
PS2='$(echo -n \[\033[1\;33m\])[Line $LINENO]>$(echo -n \[\033[m\])'
PS3='$(echo -n \[\033[1\;35m\])\[[$0]Select > $(echo -n \[\033[m\])'
PS4='$(echo -n \[\033[1\;35m\])\[[$0] Line $LINENO:> $(echo -n \[\033[m\])'
	in_init=0
}
# 函数部分结束
# 别名部分
if [ -x $SYSROOT/usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$($SYSROOT/usr/bin/dircolors -b ~/.dircolors)" || eval "$($SYSROOT/usr/bin/dircolors -b)"
	test -r /etc/DIR_COLORS && eval "$($SYSROOT/usr/bin/dircolors -b /etc/DIR_COLORS)"
	alias ls='ls --color=auto -v -p -CF'
	alias dir='dir --color=auto'
	alias vdir='vdir --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi
alias cdl='builtin cd -'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls'
alias lf='ls -alFA --color=auto'
alias lh='lf -h'
alias nf='neofetch'
alias ff='fastfetch'
alias ip='command ip -color=auto'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|$SYSROOT/usr/bin/tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
if [ $UID -ne 0 ];then
	alias sus='sudo -s '
	alias sudo='sudo '
	alias _='sudo '
fi
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
# 别名部分结束
# 补全部分
if ! shopt -oq posix; then
	if [ -f $SYSROOT/usr/share/bash-completion/bash_completion ]; then
		. $SYSROOT/usr/share/bash-completion/bash_completion
	elif [ -f $SYSROOT/etc/bash_completion ]; then
		. $SYSROOT/etc/bash_completion
	fi
fi
_cd # 有用
## 补全函数
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
_comp_bydbash_bydpath() {    
	local waiting_to_complete
	waiting_to_complete=$(lspath >/dev/null 2>&1 &&lspath|$SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $1}')
	local cur prev 
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	_comp_command
	COMPREPLY+=($(compgen -W "$waiting_to_complete" -- $cur))
	COMPREPLY+=($(compgen -f -d -- ${cur%"bpath"}bpath))
}
function _comp_bydbash_cd(){
	local bpathcomp
	bpathcomp=$(lspath >/dev/null 2>&1 &&lspath|$SYSROOT/usr/bin/awk -F'----bydpath-binding-to----' '{print $1}')
	[ $? != 0 ]&&local bpathfucked=1
	local cur prev
	cur="${COMP_WORDS[COMP_CWORD]}"
	_get_comp_words_by_ref cur prev words cword
	if $SYSROOT/usr/bin/getopt -o m -- "$prev" >/dev/null 2>&1 && $SYSROOT/usr/bin/getopt -o m -- "$prev" 2>/dev/null | $SYSROOT/usr/bin/grep -- -m 2>/dev/null >&2;then
		local DEV_MPOINT
		DEV_MPOINT=$($SYSROOT/usr/bin/findmnt -rno TARGET,SOURCE)
		for line in $(compgen -W "$DEV_MPOINT" -- "$cur");do
			COMPREPLY+=("$line")
		done
		#return 0
	else
	if $SYSROOT/usr/bin/getopt -o h -- "$prev"  >/dev/null 2>&1  && $SYSROOT/usr/bin/getopt -o h -- "$prev" 2>/dev/null| $SYSROOT/usr/bin/grep -- -h 2>/dev/null >&2;then
		local do_histcomp=set
	fi
	if [[ "$do_histcomp"x = "set"x ]]&&[ ! -z $cur ];then
		compopt -o filenames
		compopt +o dirnames 
		compopt -o plusdirs
		compopt +o noquote
		local ifs=$IFS
		local i=0
		IFS=$'\n'
		for line in $([ -f $CD_HISTFILE ]&&$SYSROOT/usr/bin/grep "$cur" "$CD_HISTFILE");do
			[ -d "$line" ]&&COMPREPLY+=("$line")
			i=$((i + 1))
		done
		IFS=$ifs
		unset do_histcomp
	else
		_comp_cmd_cd
	fi
	local bpathcomprslt
	bpathcomprslt="$(compgen -W "$bpathcomp" -- "$cur")";:
	[ "$bpathfucked" == "1" ]||COMPREPLY+=("$bpathcomprslt")
	[ "$bpathfucked" == "1" ]||COMPREPLY+=("$(compgen -f -d -- "${cur%"bpath"}"bpath)")
	fi
	return 0
}
## 补全函数结束
complete -o default -o nospace -F _comp_bydbash_cd cd
complete -E -F _comp_complete_longopt
complete -o default -o nospace -F _comp_bydbash_bydpath byd
complete -o default -o nospace -F _comp_bydbash_lspath rmpath
complete -o default -o nospace -F _comp_complete_longopt savepath
# 补全部分结束
# 命令提示符部分
#-------被移动至post_exec
# 命令提示符部分结束
# bind部分
bind 'set show-all-if-ambiguous on'
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set menu-complete-display-prefix on'
bind -x '"\C-x\C-t": tmuxmgr'
# bind部分结束
# # 后部命令部分
history -a # 命令计时器
# [ -f $HOME/.bashrc ]&&source $HOME/.bashrc||true
PROMPT_COMMAND=("post_exec")
if [ -z "$SUDO_USER" ]&&[ "$$" -ne 1 ];then
	eval "$SYSTEM_FETCH"
fi
trap '[ -f $RAMFS_DIR/cdstack_$$ ]&&rm $RAMFS_DIR/cdstack_$$' EXIT
trap 'pre_exec' DEBUG
# 后部命令部分结束
