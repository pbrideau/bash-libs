#!/bin/bash -

export COMMON_VERSION="2021.01.29"

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  log
#   DESCRIPTION:  Output message to stdout or stderr
#       GLOBALS:  LOG_LEVEL: Don't display logs above this value.
#                            Default to 1 if unset
#    PARAMETERS:  1) string:
#                            Level of log to display (0-3)
#                            OR
#                            Checkbox type to display (chkempty|chkok|chkerr)
#                 2) string: what to display
#        OUTPUT:  message to stdout or stderr
#       RETURNS:
#-------------------------------------------------------------------------------
function log {
	if [ "${COLORS_SET:-unset}" = "unset" ]; then
		set_colors false
	fi

	if [[ "$1" =~ (chkempty|chkok|chkerr) ]]; then
		local chkbox_type=$1
		shift

		case "$chkbox_type" in
			chkempty)
				echo -en "[ ]" "$@"
				;;
			chkok)
				echo -e "${txtcr}${txtrst}[${bldgrn}✔${txtrst}]" "$@"
				;;
			chkerr)
				echo -e "${txtcr}${txtrst}[${bldred}✘${txtrst}]" "$@"
				;;
		esac
	else
		if [[ ! "$1" =~ [0-3] ]]; then
			log 0 "log() argument shoud be [0-3], or (chkempty|chkok|chkerr)"
			log 0 "'$1' given"
			exit "$EX_FAIL"
		fi

		declare -A available_levels=(
			[0]="error"
			[1]="warn "
			[2]="info "
			[3]="debug"
		)
		declare -i level=${1}
		local color=""
		shift
		case $level in
			0) color="$txtred" ;;
			1) color="$txtylw" ;;
			2) color="$txtgrn" ;;
			3) color="$txtblu" ;;
		esac

		if [ "${LOG_LEVEL:-1}" -ge "$level" ]; then
			if [ "$level" -eq 0 ]; then
				echo -e "${txtrst}[${color}${available_levels[$level]}${txtrst}]" "$@" 1>&2
			else
				echo -e "${txtrst}[${color}${available_levels[$level]}${txtrst}]" "$@"
			fi
		fi
	fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  prompt_user_abort
#   DESCRIPTION:  Ask user if he wants to continue, stop script otherwise
#       GLOBALS:
#    PARAMETERS:  1) string: Question to as user, optional
#                 2) bool: Automatically answer, optional
#        OUTPUT:  May output logs
#                 Question
#       RETURNS:
#-------------------------------------------------------------------------------
function prompt_user_abort {
	log 3 "========== function ${FUNCNAME[0]}"

	local question="Are you sure?"
	local auto_answer=false
	local response
	if [ $# -eq 1 ]; then
		question=$1
	fi
	if [ $# -eq 2 ]; then
		question=$1
		auto_answer=$2
	fi

	question="${question} [y/N] "
	if [ "${auto_answer}" = false ]; then
		read -r -p "$question" response
		case "$response" in
			[yY][eE][sS] | [yY]) ;;
			*)
				log 0 "Aborting..."
				exit "$EX_ERROR"
				;;
		esac
	fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  spinner
#   DESCRIPTION:  Display a spinner while a function is running in background
#       GLOBALS:  PARSEABLE
#                 LOG_LEVEL
#    PARAMETERS:  1) pid of process to listen to
#                 2) Name of the process to display (optional)
#        OUTPUT:  spinner
#       RETURNS:
#         USAGE:  sleep 10 &
#                 spinner $! job_name
#-------------------------------------------------------------------------------
function spinner {
	log 3 "========== function ${FUNCNAME[0]}"
	local job=$1
	local process_name
	if [ $# -gt 1 ]; then
		process_name=$2
	else
		process_name=$(ps -q "$job" -o comm=)
	fi
	local spinstr='\|/-'
	local start_time=$SECONDS
	local temp

	log 3 "background job pid: $job"
	if [ "$PARSEABLE" = true ]; then
		log 1 "running: $process_name"
	fi
	while ps -q "$job" &> /dev/null; do
		if [ "$LOG_LEVEL" -ne 0 ]; then
			if [ "$PARSEABLE" = true ]; then
				echo -n '.'
			else
				temp="${spinstr#?}"
				printf "${txtcr}[%c] %s (%ds)" \
					"${spinstr}" \
					"$process_name" \
					"$((SECONDS - start_time))"
				spinstr=${temp}${spinstr%"$temp"}
			fi
		fi
		sleep 1
	done
	if [ "$LOG_LEVEL" -ne 0 ]; then
		echo -e "${txtcr}[${bldgrn}✔${txtrst}]"
	fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  set_colors
#   DESCRIPTION:  Set colors variables to be used later
#       GLOBALS:  Set a lot of global variables
#    PARAMETERS:  1) bool: do we set colors or not
#        OUTPUT:  May output logs
#       RETURNS:
#-------------------------------------------------------------------------------
function set_colors {
	local colors=$1
	function no_colors {
		txtblk=
		txtred=
		txtgrn=
		txtylw=
		txtblu=
		txtpur=
		txtcyn=
		txtwht=
		bakblk=
		bakred=
		bakgrn=
		bakylw=
		bakblu=
		bakpur=
		bakcyn=
		bakwht=
		set_bldund
	}

	function yes_colors {
		txtblk=$(tput setaf 0)
		txtred=$(tput setaf 1)
		txtgrn=$(tput setaf 2)
		txtylw=$(tput setaf 3)
		txtblu=$(tput setaf 4)
		txtpur=$(tput setaf 5)
		txtcyn=$(tput setaf 6)
		txtwht=$(tput setaf 7)
		bakblk=$(tput setab 0)
		bakred=$(tput setab 1)
		bakgrn=$(tput setab 2)
		bakylw=$(tput setab 3)
		bakblu=$(tput setab 4)
		bakpur=$(tput setab 5)
		bakcyn=$(tput setab 6)
		bakwht=$(tput setab 7)
		set_bldund
	}

	function set_bldund {
		bldblk=${txtbld}${txtblk}
		bldred=${txtbld}${txtred}
		bldgrn=${txtbld}${txtgrn}
		bldylw=${txtbld}${txtylw}
		bldblu=${txtbld}${txtblu}
		bldpur=${txtbld}${txtpur}
		bldcyn=${txtbld}${txtcyn}
		bldwht=${txtbld}${txtwht}
		undblk=${txtund}${txtblk}
		undred=${txtund}${txtred}
		undgrn=${txtund}${txtgrn}
		undylw=${txtund}${txtylw}
		undblu=${txtund}${txtblu}
		undpur=${txtund}${txtpur}
		undcyn=${txtund}${txtcyn}
		undwht=${txtund}${txtwht}
	}

	txtund=
	txtbld=
	txtrst=
	txtcr="\r"
	no_colors

	export COLORS_SET=true

	if ! command -v tput &> /dev/null; then
		log 1 "tput command not found, no colors will be displayed"
		colors=false
	elif ! tty -s; then
		log 1 "Not interractive shell, disabling colors"
		colors=false
	fi

	if [ "$colors" = true ]; then
		txtund=$(tput smul) # Underline
		txtbld=$(tput bold) # Bold
		txtrst=$(tput sgr0) # Reset
		txtcr=$(tput cr)    # Carriage return (start of line)
		local ncolors
		ncolors=$(tput colors)
		if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
			yes_colors
		fi
	fi

	export txtund txtbld txtrst txtcr
	export txtblk txtred txtgrn txtylw txtblu txtpur txtcyn txtwht
	export bakblk bakred bakgrn bakylw bakblu bakpur bakcyn bakwht
	export bldblk bldred bldgrn bldylw bldblu bldpur bldcyn bldwht
	export undblk undred undgrn undylw undblu undpur undcyn undwht
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  load_config
#   DESCRIPTION:  Send file content to be parsed by load_arg
#                 Stop at the first config file loaded
#       GLOBALS:  END_LOAD_ARG
#    PARAMETERS:  1) string array: config files to parse
#        OUTPUT:  Debug or error logs
#       RETURNS:
#-------------------------------------------------------------------------------
function load_config {
	log 3 "========== function ${FUNCNAME[0]}"
	declare -a config_files=("$@")
	declare -i linenum=1
	for f in "${config_files[@]}"; do
		if [ -r "$f" ]; then
			local regex="^#"
			while read -r line; do
				if [[ ! "$line" =~ $regex ]]; then
					eval set -- "--${line}"
					log 3 "Loading argument '$*'"
					load_arg "$@"
					if [ "${#END_LOAD_ARG[@]}" -gt 0 ]; then
						log 0 "Could not parse config file ($f) correctly"
						log 0 "Error on line ${linenum}:"
						log 0 "> $line"
						exit "$EX_USAGE"
					fi
				fi
				_=$((linenum++))
			done < "$f"
			log 2 "Config '$f' loaded"
			# Load only the first config we can find, not every config files
			break
		fi
		log 3 "Config '$f' does not exists"
	done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  basename
#   DESCRIPTION:  Alternative to the `basename` command
#                 From: https://github.com/dylanaraps/pure-bash-bible
#       GLOBALS:
#    PARAMETERS:  1) string: path to parse
#                 2) string: suffix to remove (optional)
#        OUTPUT:
#       RETURNS:  string
#         USAGE:  basename "path" ["suffix"]
#-------------------------------------------------------------------------------
function basename {
	local tmp

	tmp=${1%"${1##*[!/]}"}
	tmp=${tmp##*/}

	if [ $# -eq 2 ]; then
		tmp=${tmp%"${2/"$tmp"/}"}
	fi

	printf '%s\n' "${tmp:-/}"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  dirname
#   DESCRIPTION:  Alternative tho the `dirname` command
#                 From: https://github.com/dylanaraps/pure-bash-bible
#       GLOBALS:
#    PARAMETERS:  1) string: path to parse
#        OUTPUT:
#       RETURNS:  string
#         USAGE:  dirname "path"
#-------------------------------------------------------------------------------
function dirname {
	local tmp=${1:-.}

	[[ $tmp != *[!/]* ]] && {
		printf '/\n'
		return
	}

	tmp=${tmp%%"${tmp##*[!/]}"}

	[[ $tmp != */* ]] && {
		printf '.\n'
		return
	}

	tmp=${tmp%/*}
	tmp=${tmp%%"${tmp##*[!/]}"}

	printf '%s\n' "${tmp:-/}"
}

# Reserved return codes
# 128+signal (Specific x86)
# see kill -l or man 7 signal
export EX_OK=0          # No error
export EX_ERROR=1       # General error
export EX_BLTIN=2       # Misuse of shell builtins
export EX_TMOUT=124     # Command times out
export EX_FAIL=125      # Command itself fail
export EX_NOEXEC=126    # Command is found but cannot be invoked
export EX_NOTFOUND=127  # Command not found
export EX_INVAL=128     # Invalid argument
export EX_SIGHUP=129    # Hangup detected on controlling terminal
export EX_SIGINT=130    # Interrupt from keyboard
export EX_SIGQUIT=131   # Quit from keyboard
export EX_SIGILL=132    # Illegal instruction
export EX_SIGTRAP=133   # Trace/breakpoint trap
export EX_SIGABRT=134   # Abort signal from abort(3)
export EX_SIGBUS=135    # Bus error (bad memory access)
export EX_SIGFPE=136    # Floating point exception
export EX_SIGKILL=137   # Kill signal
export EX_SIGUSR1=138   # User-defined signal 1
export EX_SIGSEGV=139   # Invalid memory reference
export EX_SIGUSR2=140   # User-defined signal 2
export EX_SIGPIPE=141   # Broken pipe: write to pipe with no readers
export EX_SIGALRM=142   # Timer signal from alarm(2)
export EX_SIGTERM=143   # Termination signal
export EX_SIGCHLD=145   # Child stopped or terminated
export EX_SIGCONT=146   # Continue if stopped
export EX_SIGSTOP=147   # Stop process
export EX_SIGTSTP=148   # Stop typed at terminal
export EX_SIGTTIN=149   # Terminal input for background process
export EX_SIGTTOU=150   # Terminal output for background process
export EX_SIGURG=151    # Urgent condition on socket (4.2BSD)
export EX_SIGXCPU=152   # CPU time limit exceeded (4.2BSD)
export EX_SIGXFSZ=153   # File size limit exceeded (4.2BSD)
export EX_SIGVTALRM=154 # Virtual alarm click (4.2BSD)
export EX_SIGPROF=155   # Profiling timer expired
export EX_SIGWINCH=156  # Window resize signal (4.3BSD, Sun)
export EX_SIGIO=157     # I/O now possible (4.2BSD)
export EX_SIGPWR=158    # Power failure (System V)
export EX_SIGSYS=159    # Bad system call (SVr4)
