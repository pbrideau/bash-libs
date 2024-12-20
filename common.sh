#!/usr/bin/env bash
# Copyright (C) 2020-2024 Patrick Brideau
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# You can get the lastest version here:
# https://github.com/pbrideau/bash-libs

export COMMON_VERSION="2024.12.03"

# Make sure we set PARSEABLE=true when not in interactive shell
if ! tty -s; then
	PARSEABLE=true
elif [[ "$(lsof -a -p $$ -d 1 -F 2> /dev/null || true)" =~ npipe ]]; then
	PARSEABLE=true
fi

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  log
#   DESCRIPTION:  Output message to stderr
#       GLOBALS:  LOG_LEVEL: Don't display logs above this value.
#                            Default to 1 if unset
#    PARAMETERS:  1) string:
#                            Level of log to display (0-3)
#                            OR
#                            Checkbox type to display (chkempty|chkok|chkerr)
#                 2) string: what to display
#        OUTPUT:  message to stderr
#       RETURNS:
#-------------------------------------------------------------------------------
function log {
	if [[ "${COLORS_SET:-unset}" = "unset" ]]; then
		set_colors false
	fi

	if [[ "$1" =~ (chkempty|chkok|chkerr) ]]; then
		local chkbox_type=$1
		shift

		if [[ "${LOG_LEVEL:-1}" -ge 1 ]]; then
			case "${chkbox_type}" in
				chkempty)
					# Only output the empty checkbox when we are in interactive shell
					if [[ "${PARSEABLE:-false}" == false ]]; then
						echo -en "[ ]" "$@" 1>&2
					fi
					;;
				chkok)
					if [[ "${PARSEABLE:-false}" == false ]]; then
						echo -e "${txtcr}${txtrst}[${bldgrn}✔${txtrst}]" "$@" 1>&2
					else
						echo -e "[✔]" "$@" 1>&2
					fi
					;;
				chkerr)
					if [[ "${PARSEABLE:-false}" == false ]]; then
						echo -e "${txtcr}${txtrst}[${bldred}✘${txtrst}]" "$@" 1>&2
					else
						echo -e "[✘]" "$@" 1>&2
					fi
					;;
				*)
					# Should never get here
					echo "Something went wrong!"
					exit 1
					;;
			esac
		fi
	elif [[ "$1" =~ [0-3] ]]; then
		declare -A available_levels=(
			[0]="error"
			[1]="warn "
			[2]="info "
			[3]="debug"
		)
		declare -i level=${1}
		local color=""
		shift
		case "${level}" in
			0) color="${txtred}" ;;
			1) color="${txtylw}" ;;
			2) color="${txtgrn}" ;;
			3) color="${txtblu}" ;;
			*) color="${txtrst}" ;;
		esac

		local func_depth
		if [[ "${level}" -eq 3 ]]; then
			# shellcheck disable=SC2046 # I do want word splitting here
			func_depth=$(printf "==%.0s" $(seq 1 $((${#FUNCNAME[@]} - 1)) || true))
		else
			func_depth=
		fi

		local logstr="${txtrst}[${color}${available_levels[${level}]}${txtrst}]"
		if [[ "${LOG_LEVEL:-1}" -ge "${level}" ]]; then
			echo -e "${logstr}${func_depth}" "$@" 1>&2
		fi
	else
		log 0 "log() shoud be [0-3], or (chkempty|chkok|chkerr)"
		log 0 "'$1' given"
		exit "${EX_FAIL}"
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
	log 3 "${FUNCNAME[0]}()"

	local question="Are you sure?"
	local auto_answer=false
	local response
	if [[ $# -eq 1 ]]; then
		question=$1
	fi
	if [[ $# -eq 2 ]]; then
		question=$1
		auto_answer=$2
	fi

	question="${question} [y/N] "
	if [[ "${auto_answer}" = false ]]; then
		trap 'log 0 "Aborting..."' EXIT
		read -r -p "${question}" response
		trap - EXIT
		case "${response}" in
			[yY][eE][sS] | [yY]) ;;
			*)
				log 0 "Aborting..."
				exit "${EX_ERROR}"
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
#                    (This can be a command to run every second)
#        OUTPUT:  spinner
#       RETURNS:
#         USAGE:  sleep 10 &
#                 spinner $! job_name
#
#                 sleep 10 &
#                 spinner $! "\$(date +%s)" #will show current epoch
#-------------------------------------------------------------------------------
function spinner {
	log 3 "${FUNCNAME[0]}()"
	local job=$1
	local process_name
	local eval_process_name=false
	if [[ ${#} -gt 1 ]]; then
		process_name=$2
		if [[ "${process_name}" =~ \$ ]]; then
			eval_process_name=true
			eval_process=$(eval echo "$2")
			log 3 "dollar sign ($) in process_name: ${bldred}${process_name}${txtrst}"
			log 3 "Will be run by eval function: ${bldylw}${eval_process}${txtrst}"
		fi
	else
		process_name=$(ps -q "${job}" -o comm=)
	fi
	local spinstr='\|/-'
	local start_time="${SECONDS}"
	declare -i run_time
	local temp

	log 3 "background job pid: ${job}"
	if [[ "${PARSEABLE:-false}" = true ]]; then
		log 1 "running: ${process_name}"
	fi
	while ps -q "${job}" &> /dev/null; do
		if [[ "${LOG_LEVEL:-1}" -ne 0 ]]; then
			if [[ "${eval_process_name}" == true ]]; then
				process_name=$(eval echo "$2")
			fi
			if [[ "${PARSEABLE:-false}" == true ]]; then
				echo -n '.'
			else
				temp="${spinstr#?}"
				run_time=$((SECONDS - start_time))
				if [[ "${run_time}" -lt 60 ]]; then
					printf "${txtcr}[%c] %s (%ds)" \
						"${spinstr}" \
						"${process_name}" \
						"${run_time}"
				elif [[ "${run_time}" -lt 3600 ]]; then
					printf "${txtcr}[%c] %s (%dm%02ds)" \
						"${spinstr}" \
						"${process_name}" \
						"$((run_time / 60))" \
						"$((run_time % 60))"
				else
					printf "${txtcr}[%c] %s (%dh%02dm%02ds)" \
						"${spinstr}" \
						"${process_name}" \
						"$((run_time / 3600))" \
						"$((run_time / 60 % 60))" \
						"$((run_time % 60))"
				fi
				spinstr=${temp}${spinstr%"${temp}"}
			fi
		fi
		sleep 1
	done
	if [[ "${LOG_LEVEL:-1}" -ne 0 ]] && [[ "${PARSEABLE:-false}" = false ]]; then
		local str_time
		if [[ "${run_time}" -lt 60 ]]; then
			str_time=$(printf '%ds' "${run_time}")
		elif [[ "${run_time}" -lt 3600 ]]; then
			str_time=$(printf '%dm%02ds' "$((run_time / 60))" "$((run_time % 60))")
		else
			str_time=$(
				printf '%dh%02dm%02ds' \
					"$((run_time / 3600))" "$((run_time / 60 % 60))" "$((run_time % 60))"
			)
		fi
		log chkok "${process_name} Done in ${str_time}"
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
	local colors=${1:-true}
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

	function yes_colors_ansi {
		txtblk="\033[30m"
		txtred="\033[31m"
		txtgrn="\033[32m"
		txtylw="\033[33m"
		txtblu="\033[34m"
		txtpur="\033[35m"
		txtcyn="\033[36m"
		txtwht="\033[37m"
		bakblk="\033[40m"
		bakred="\033[41m"
		bakgrn="\033[42m"
		bakylw="\033[43m"
		bakblu="\033[44m"
		bakpur="\033[45m"
		bakcyn="\033[46m"
		bakwht="\033[47m"
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
	txtcr=
	no_colors

	export COLORS_SET=true

	if [[ "${colors}" == true ]]; then
		if [[ "${PARSEABLE:-false}" == true ]]; then
			log 1 "Not interactive shell, disabling colors"
			colors=false
		elif ! command -v tput &> /dev/null; then
			log 1 "tput command not found, ANSI escape code will be used"
			colors=ANSI
		fi
	fi

	if [[ "${colors}" == true ]]; then
		txtund=$(tput smul) # Underline
		txtbld=$(tput bold) # Bold
		txtrst=$(tput sgr0) # Reset
		txtcr=$(tput cr)    # Carriage return (start of line)
		local ncolors
		ncolors=$(tput colors)
		if [[ -n "${ncolors}" ]] && [[ "${ncolors}" -ge 8 ]]; then
			yes_colors
		fi
	elif [[ "${colors}" = "ANSI" ]]; then
		txtund="\033[4m" # Underline
		txtbld="\033[1m" # Bold
		txtrst="\033[0m" # Reset
		txtcr="\r"       # Carriage return (start of line)
		yes_colors_ansi
	fi

	export txtund txtbld txtrst txtcr
	export txtblk txtred txtgrn txtylw txtblu txtpur txtcyn txtwht
	export bakblk bakred bakgrn bakylw bakblu bakpur bakcyn bakwht
	export bldblk bldred bldgrn bldylw bldblu bldpur bldcyn bldwht
	export undblk undred undgrn undylw undblu undpur undcyn undwht
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  load_config
#   DESCRIPTION:  Send file content to be parsed by load_getopt_arg
#                 Stop at the first config file loaded
#       GLOBALS:  END_LOAD_ARG
#    PARAMETERS:  1) string array: config files to parse
#        OUTPUT:  Debug or error logs
#       RETURNS:
#-------------------------------------------------------------------------------
declare -a END_LOAD_ARG
function load_getopt_config {
	log 3 "${FUNCNAME[0]}()"
	declare -a config_files=("$@")
	declare -i linenum=1
	for f in "${config_files[@]}"; do
		if [[ -e "${f}" ]]; then
			if [[ -r "${f}" ]]; then
				local regex="^#"
				while read -r line; do
					# shellcheck disable=SC2250 # This is regex matching
					if [[ ! "${line}" =~ $regex ]]; then
						eval set -- "--${line}"
						log 3 "Loading argument '$*'"
						load_getopt_arg "$@"
						if [[ "${#END_LOAD_ARG[@]}" -gt 0 ]]; then
							log 0 "Could not parse config file (${f}) correctly"
							log 0 "Error on line ${linenum}:"
							log 0 "> ${line}"
							exit "${EX_USAGE}"
						fi
					fi
					_=$((linenum++))
				done < "${f}"
				log 2 "Config '${f}' loaded"
				# Load only the first config we can find, not every config files
				break
			else
				log 1 "Cannot read config '${f}' (do you have permission to do so?)"
				log 1 "It might cause you problems"
			fi
		else
			log 3 "Config '${f}' does not exists, skipping"
		fi
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

	if [[ $# -eq 2 ]]; then
		tmp=${tmp%"${2/"${tmp}"/}"}
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

	[[ "${tmp}" != *[!/]* ]] && {
		printf '/\n'
		return
	}

	tmp=${tmp%%"${tmp##*[!/]}"}

	[[ "${tmp}" != */* ]] && {
		printf '.\n'
		return
	}

	tmp=${tmp%/*}
	tmp=${tmp%%"${tmp##*[!/]}"}

	printf '%s\n' "${tmp:-/}"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  format_date
#   DESCRIPTION:  Return more human readable date ( X seconds ago)
#       GLOBALS:
#    PARAMETERS:  1) string: date to parse
#        OUTPUT:
#       RETURNS:  string
#         USAGE:  format_date "DATE"
#-------------------------------------------------------------------------------
function format_date {
	if [[ "$#" -ne 1 ]]; then
		log 0 "format_date() require an argument, none given"
		exit "${EX_FAIL}"
	fi

	if ! date -d "$1" &> /dev/null; then
		log 0 "format_date() argument shoud be a date, parseable with date"
		log 0 "'$1' given"
		exit "${EX_FAIL}"
	fi

	local sec_per_minute sec_per_hour sec_per_day sec_per_month sec_per_year

	sec_per_minute=$((60))
	sec_per_hour=$((60 * 60))
	sec_per_day=$((60 * 60 * 24))
	sec_per_month=$((60 * 60 * 24 * 30))
	sec_per_year=$((60 * 60 * 24 * 365))

	local last_unix now_unix delta_s
	last_unix="$(date --date="$1" +%s)" # convert date to unix timestamp
	now_unix="$(date +'%s')"
	delta_s=$((now_unix - last_unix))

	if [[ "${delta_s}" -gt 0 ]]; then
		if ((delta_s < sec_per_minute * 2)); then
			echo "$((delta_s)) seconds ago"
			return
		elif ((delta_s < sec_per_hour * 2)); then
			echo "$((delta_s / sec_per_minute)) minutes ago"
			return
		elif ((delta_s < sec_per_day * 2)); then
			echo "$((delta_s / sec_per_hour)) hours ago"
			return
		elif ((delta_s < sec_per_month * 2)); then
			echo "$((delta_s / sec_per_day)) days ago"
			return
		elif ((delta_s < sec_per_year * 2)); then
			echo "$((delta_s / sec_per_month)) months ago"
			return
		else
			echo "$((delta_s / sec_per_year)) years ago"
			return
		fi
	else
		delta_s=$((-delta_s))
		if ((delta_s > sec_per_year * 2)); then
			echo "in $((delta_s / sec_per_year)) years"
			return
		elif ((delta_s > sec_per_month * 2)); then
			echo "in $((delta_s / sec_per_month)) months"
			return
		elif ((delta_s > sec_per_day * 2)); then
			echo "in $((delta_s / sec_per_day)) days"
			return
		elif ((delta_s > sec_per_hour * 2)); then
			echo "in $((delta_s / sec_per_hour)) hours"
			return
		elif ((delta_s > sec_per_minute * 2)); then
			echo "in $((delta_s / sec_per_minute)) minutes"
			return
		else
			echo "in $((delta_s)) seconds"
		fi
	fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  semver_compare
#   DESCRIPTION:  Check if first version is greater than second version
#                 https://github.com/Ariel-Rodriguez/sh-semversion-2/blob/main/semver2.sh
#       GLOBALS:
#    PARAMETERS:  1) string: semver version (x.x.x)
#                 2) string: semver version (x.x.x)
#        OUTPUT:
#       RETURNS:  1 when A greater than B
#                 0 when A equals B
#                 -1 when A lower than B
#         USAGE:  semver_compare '1.2.3' '4.5.6'
#-------------------------------------------------------------------------------
function semver_compare {
	function ord {
		# params char
		# returns Integer
		printf '%d' "'$1"
	}
	function isNumber {
		string=$1
		char=""
		while true; do
			substract="${string#?}"         # All but the first character of the string
			char="${string%"${substract}"}" # Remove $rest, and you're left with the first character
			string="${substract}"
			# no more chars to compare then success
			if [[ -z "${char}" ]]; then
				#printf "true"
				return 0
			fi
			# break if some of the chars is not a number
			ord_char=$(ord "${char}")
			if [[ "${ord_char}" -lt 48 ]] || [[ "${ord_char}" -gt 57 ]]; then
				#printf "false"
				return 1
			fi
		done
	}
	function getChar {
		# params string {String}, Index {Number}
		# returns char
		string=$1
		index=$2
		cursor=-1
		char=""
		while [[ "${cursor}" != "${index}" ]]; do
			substract="${string#?}"         # All but the first character of the string
			char="${string%"${substract}"}" # Remove ${rest}, and you're left with the first character
			string="${substract}"
			cursor=$((cursor + 1))
		done
		printf "%s${char}"
	}
	function outcome {
		result=$1
		printf "%s${result}\n"
	}
	function compareNumber {
		if [[ -z "$1" ]] && [[ -z "$2" ]]; then
			printf "%s" "0"
			return
		fi

		sub=$(($2 - $1))
		[[ "${sub}" -gt 0 ]] && printf "%s" "-1"
		[[ "${sub}" -lt 0 ]] && printf "1"
		[[ "${sub}" == 0 ]] && printf "0"
	}
	function compareString {
		result=false
		index=0
		while true; do
			a=$(getChar "$1" "${index}")
			b=$(getChar "$2" "${index}")

			if [[ -z "${a}" ]] && [[ -z "${b}" ]]; then
				printf "0"
				return
			fi

			ord_a=$(ord "${a}")
			ord_b=$(ord "${b}")

			n=$(compareNumber "${ord_a}" "${ord_b}")
			if [[ "${n}" != "0" ]]; then
				printf "%s" "${n}"
				return
			fi

			index=$((index + 1))
		done
	}
	function includesString {
		string="$1"
		substring="$2"
		if [[ "${string#*"${substring}"}" != "${string}" ]]; then
			printf "1"
			return 1 # $substring is in $string
		fi
		printf "0"
		return 0 # $substring is not in $string
	}
	function removeLeadingV {
		printf "%s${1#v}"
	}
	function isSingleIdentifier {
		substract="${2#?}"
		if [[ "${1%"$2"}" == "" ]]; then
			printf "true"
			return 1
		fi
		return 0
	}

	firstParam=$1  #1.2.4-alpha.beta+METADATA
	secondParam=$2 #1.2.4-alpha.beta.2+METADATA

	version_a=$(printf %s "${firstParam}" | cut -d'+' -f 1)
	version_a=$(removeLeadingV "${version_a}")
	version_b=$(printf %s "${secondParam}" | cut -d'+' -f 1)
	version_b=$(removeLeadingV "${version_b}")

	a_major=$(printf %s "${version_a}" | cut -d'.' -f 1)
	a_minor=$(printf %s "${version_a}" | cut -d'.' -f 2)
	# shellcheck disable=SC2312
	a_patch=$(printf %s "${version_a}" | cut -d'.' -f 3 | cut -d'-' -f 1)
	a_pre=""
	if [[ "$(includesString "${version_a}" - || true)" = 1 ]]; then
		a_pre=$(printf %s"${version_a#"${a_major}"."${a_minor}"."${a_patch}"-}")
	fi

	b_major=$(printf %s "${version_b}" | cut -d'.' -f 1)
	b_minor=$(printf %s "${version_b}" | cut -d'.' -f 2)
	# shellcheck disable=SC2312
	b_patch=$(printf %s "${version_b}" | cut -d'.' -f 3 | cut -d'-' -f 1)
	b_pre=""
	if [[ "$(includesString "${version_b}" - || true)" = 1 ]]; then
		b_pre=$(printf %s"${version_b#"${b_major}"."${b_minor}"."${b_patch}"-}")
	fi

	unit_types="MAJOR MINOR PATCH"
	a_normalized="${a_major} ${a_minor} ${a_patch}"
	b_normalized="${b_major} ${b_minor} ${b_patch}"

	log 3 "Detected: ${a_major} ${a_minor} ${a_patch} identifiers: ${a_pre}"
	log 3 "Detected: ${b_major} ${b_minor} ${b_patch} identifiers: ${b_pre}"

	#####
	#
	# Find difference between Major Minor or Patch
	#

	cursor=1
	while [[ "${cursor}" -lt 4 ]]; do
		a=$(printf %s "${a_normalized}" | cut -d' ' -f "${cursor}")
		b=$(printf %s "${b_normalized}" | cut -d' ' -f "${cursor}")
		o=$(printf %s "${unit_types}" | cut -d' ' -f "${cursor}")
		if [[ "${a}" != "${b}" ]]; then
			log 3 "${o} is different"
			outcome "$(compareNumber "${a}" "${b}" || true)"
			return
		fi
		log 3 "${o} are equal"
		cursor=$((cursor + 1))
	done

	#####
	#
	# Find difference between pre release identifiers
	#

	if [[ -z "${a_pre}" ]] && [[ -z "${b_pre}" ]]; then
		log 3 "Because both are equals"
		outcome "0"
		return
	fi

	# Spec 11.3 a pre-release version has lower precedence than a normal version:
	# Example: 1.0.0-alpha < 1.0.0.

	if [[ -z "${a_pre}" ]]; then
		log 3 "Pre-release version has lower precedence than a normal version"
		outcome "1"
		return
	fi

	if [[ -z "${b_pre}" ]]; then
		log 3 "Pre-release version has lower precedence than a normal version"
		outcome "-1"
		return
	fi

	cursor=1
	while [[ "${cursor}" -lt 4 ]]; do
		a=$(printf %s "${a_pre}" | cut -d'.' -f "${cursor}")
		b=$(printf %s "${b_pre}" | cut -d'.' -f "${cursor}")

		log 3 "Comparing identifier ${a} with ${b}"

		# Exit when there is nothing else to compare.
		# Most likely because they are equals
		if [[ -z "${a}" ]] && [[ -z "${b}" ]]; then
			log 3 "are equals"
			outcome "0"
			return
		fi

		# Spec #11 https://semver.org/#spec-item-11
		# Precedence for two pre-release versions with the same major, minor, and patch version
		# MUST be determined by comparing each dot separated identifier from left to right until a difference is found

		# Spec 11.4.4: A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal.
		if [[ -n "${a}" ]] && [[ -z "${b}" ]]; then
			# When A is larger than B
			log 3 "Because A has more pre-identifiers"
			outcome "1"
			return
		fi

		# When A is shorter than B
		if [[ -z "${a}" ]] && [[ -n "${b}" ]]; then
			log 3 "Because B has more pre-identifiers"
			outcome "-1"
			return
		fi

		# Spec #11.4.1
		# Identifiers consisting of only digits are compared numerically.
		if isNumber "${a}" || isNumber "${b}"; then

			# if both identifiers are numbers, then compare and proceed
			# shellcheck disable=SC2312
			if isNumber "${a}" && isNumber "${b}"; then
				if [[ "$(compareNumber "${a}" "${b}")" != "0" ]]; then
					log 3 "Number is not equal $(compareNumber "${a}" "${b}")"
					outcome "$(compareNumber "${a}" "${b}")"
					return
				fi
			fi

			# Spec 11.4.3
			if ! isNumber "${a}"; then
				log 3 "Numeric ident have lower precedence than non-numeric ident."
				outcome "1"
				return
			fi

			if ! isNumber "${b}"; then
				log 3 "Numeric ident have lower precedence than non-numeric ident."
				outcome "-1"
				return
			fi
		else
			# Spec 11.4.2
			# Identifiers with letters or hyphens are compared lexically in ASCII sort order.

			s=$(compareString "${a}" "${b}")
			if [[ "${s}" != "0" ]]; then
				log 3 "cardinal is not equal ${s}"
				outcome "${s}"
				return
			fi
		fi

		# Edge case when there is single identifier exaple: x.y.z-beta
		if [[ "${cursor}" = 1 ]]; then

			# When both versions are single return equals
			if [[ -n "$(isSingleIdentifier "${b_pre}" "${b}" || true)" ]]; then
				if [[ -n "$(isSingleIdentifier "${a_pre}" "${a}" || true)" ]]; then
					log 3 "Because both have single identifier"
					outcome "0"
					return
				fi
			fi

			# Return greater when has more identifiers
			# Spec 11.4.4: A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal.

			# When A is larger than B
			if [[ -n "$(isSingleIdentifier "${b_pre}" "${b}" || true)" ]]; then
				if [[ -z "$(isSingleIdentifier "${a_pre}" "${a}" || true)" ]]; then
					log 3 "Because of single identifier, A has more pre-identifiers"
					outcome "1"
					return
				fi
			fi

			# When A is shorter than B
			if [[ -z "$(isSingleIdentifier "${b_pre}" "${b}" || true)" ]]; then
				if [[ -n "$(isSingleIdentifier "${a_pre}" "${a}" || true)" ]]; then
					log 3 "Because of single identifier, B has more pre-identifiers"
					outcome "-1"
					return
				fi
			fi
		fi

		# Proceed to the next identifier because previous comparition was equal.
		cursor=$((cursor + 1))
	done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  on_exit
#   DESCRIPTION:  add command to be run when script exit
#                 From: https://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
#       GLOBALS:
#    PARAMETERS:  1) string: command to execute when shell exit
#        OUTPUT:
#       RETURNS:
#         USAGE:  on_exit "rm -f /tmp/foo"
#-------------------------------------------------------------------------------
ON_EXIT_ITEMS=()
function on_exit {
	log 3 "${FUNCNAME[0]}()"
	# shellcheck disable=SC2317 # This function is called indirectly by trap
	function __run_on_exit {
		log 3 "${FUNCNAME[0]}()"
		for i in "${ON_EXIT_ITEMS[@]}"; do
			log 3 "running: ${i}"
			eval "${i}"
		done
	}
	local n=${#ON_EXIT_ITEMS[*]}
	ON_EXIT_ITEMS[n]="$*"
	if [[ "${n}" -eq 0 ]]; then
		log 3 "Setting trap __run_on_exit()"
		trap __run_on_exit EXIT
	fi
	log 3 "Trap '$*' added on exit"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  is_in_array
#   DESCRIPTION:  check if element is in array
#       GLOBALS:
#    PARAMETERS:  1) string: element to search for
#                 2) array: array to search in
#        OUTPUT:
#       RETURNS:  0 when element is in array
#                 1 when element is NOT in array
#         USAGE:  declare -a array=('foo' 'bar' 'baz')
#                 is_in_array 'foo' "${array[@]}"
#-------------------------------------------------------------------------------
function is_in_array {
	local item=$1
	shift
	declare -a array=("$@")

	for e in "${array[@]}"; do
		if [[ "${item}" == "${e}" ]]; then
			return
		fi
	done

	return 1
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  is_in_regex_array
#   DESCRIPTION:  check if element is in regex array
#       GLOBALS:
#    PARAMETERS:  1) string: element to search for
#                 2) array: array of regex to search in
#        OUTPUT:
#       RETURNS:  0 when element is in regex array
#                 1 when element is NOT in regex array
#         USAGE:  declare -a array=('.*\.bar$' '.*\.baz$')
#                 is_in_array 'foo.bar' "${array[@]}"
#-------------------------------------------------------------------------------
function is_in_regex_array {
	local item=$1
	shift
	declare -a array=("$@")

	for r in "${array[@]}"; do
		# shellcheck disable=SC2250 # This is regex matching
		if [[ "${item}" =~ $r ]]; then
			return
		fi
	done

	return 1
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

# Custom return codes
# Limit user-defined exit codes to the range 64-113
# See /usr/include/sysexits.h for common examples
export EX_USAGE=64 # Command line usage error
