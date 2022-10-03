#!/usr/bin/env bats
# shellcheck disable=SC2154

function setup {
	source common.sh
}

function main {
	bash "${BATS_TEST_DIRNAME}/common.sh"
}

function Should_LogErrorToStderr_When_Log0 { #@test
	# Given
	export LOG_LEVEL=0

	# When
	run log 0 'Error'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$(tput cr)[error] Error" ]
	# No way to check if it's stdout or stderr with bats...
	# Assume it's in stderr
}
function Should_LogWarningToStderr_When_Log1 { #@test
	# Given
	export LOG_LEVEL=1

	# When
	run log 1 'Warning'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$(tput cr)[warn ] Warning" ]
}
function Should_LogInfoToStderr_When_Log2 { #@test
	# Given
	export LOG_LEVEL=2

	# When
	run log 2 'Info'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$(tput cr)[info ] Info" ]
}
function Should_LogDebugToStderr_When_Log3 { #@test
	# Given
	export LOG_LEVEL=3

	# When
	run log 3 'Debug'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$(tput cr)[debug]========== Debug" ]
	# Note this debug run 4 funtions deep within the bats stack
	# This is why there is this much '=='
}
function Should_Fail_When_LogAnythingElse { #@test
	# Given

	# When
	run log 'debug' 'Should fail'

	# Then
	[ "$status" -eq 125 ]
}

function Should_LogEmptyCheckbox_When_EmptyCheckbox { #@test
	# When
	run log chkempty 'Foo bar'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "[ ] Foo bar" ]
}
function Should_LogFailedCheckbox_When_ErrorCheckbox { #@test

	# When
	run log chkerr 'Foo bar'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$(tput cr)[✘] Foo bar" ]
}
function Should_LogSuccessCheckbox_When_OkCheckbox { #@test

	# When
	run log chkok 'Foo bar'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$(tput cr)[✔] Foo bar" ]
}

function Should_Fail_When_AnswerNoToPromptUserAbort { #@test
	# Given

	# When
	run prompt_user_abort "Are you sure?" <<<'No'

	# Then
	[ "$status" -eq 1 ]
}
function Should_Succeed_When_AnswerYesToPromptUserAbort { #@test
	# Given

	# When
	run prompt_user_abort "Are you sure?" <<<'Yes'

	# Then
	[ "$status" -eq 0 ]
}
function Should_Succeed_When_AutoAnswerToPromptUserAbort { #@test
	# Given

	# When
	run prompt_user_abort "Are you sure?" true

	# Then
	[ "$status" -eq 0 ]
}

function Should_ReturnName_When_FullPath { #@test
	# Given

	# When
	run basename "/foo/bar/baz"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "baz" ]
}
function Should_ReturnName_When_FullPathWithSpaces { #@test
	# Given

	# When
	run basename "/foo/bar bar/baz"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "baz" ]
}
function Should_ReturnNameWithoutExtension_When_FullPathWithExclude { #@test
	# Given

	# When
	run basename "/foo/bar.baz" ".baz"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "bar" ]
}

function Should_ReturnDirName_When_FullPath { #@test
	# Given

	# When
	run dirname "/foo/bar/baz"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "/foo/bar" ]
}
function Should_ReturnDir_When_FullPathWithSpaces { #@test
	# Given

	# When
	run dirname "/foo/bar bar/baz"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "/foo/bar bar" ]
}

function Should_Return5SecondsAgo_When_Asked5SecondsAgo { #@test
	# Given

	# When
	run format_date "$(date -d "5 seconds ago")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "5 seconds ago" ]
}
function Should_Return5MinutesAgo_When_Asked5MinutesAgo { #@test
	# Given

	# When
	run format_date "$(date -d "5 minutes ago")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "5 minutes ago" ]
}
function Should_Return5HoursAgo_When_Asked5HoursAgo { #@test
	# Given

	# When
	run format_date "$(date -d "5 hours ago")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "5 hours ago" ]
}
function Should_Return5DaysAgo_When_Asked5DaysAgo { #@test
	# Given

	# When
	run format_date "$(date -d "5 days ago")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "5 days ago" ]
}
function Should_Return5MonthsAgo_When_Asked5MonthsAgo { #@test
	# Given

	# When
	run format_date "$(date -d "5 months ago")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "5 months ago" ]
}
function Should_Return5YearsAgo_When_Asked5YearsAgo { #@test
	# Given

	# When
	run format_date "$(date -d "5 years ago")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "5 years ago" ]
}

function Should_Returnin5Seconds_When_AskedPlus5Seconds { #@test
	# Given

	# When
	run format_date "$(date -d "+5 seconds")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "in 5 seconds" ]
}
function Should_Returnin5Minutes_When_AskedPlus5Minutes { #@test
	# Given

	# When
	run format_date "$(date -d "+5 minutes")"
	format_date "$(date -d "+5 minutes")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "in 5 minutes" ]
}
function Should_Returnin5Hours_When_AskedPlus5Hours { #@test
	# Given

	# When
	run format_date "$(date -d "+5 hours")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "in 5 hours" ]
}
function Should_Returnin5Days_When_AskedPlus5Days { #@test
	# Given

	# When
	run format_date "$(date -d "+5 days")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "in 5 days" ]
}
function Should_Returnin5Months_When_AskedPlus5Months { #@test
	# Given

	# When
	run format_date "$(date -d "+5 months")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "in 5 months" ]
}
function Should_Returnin5Years_When_AskedPlus5Years { #@test
	# Given

	# When
	run format_date "$(date -d "+5 years")"

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "in 5 years" ]
}

function Should_RemoveFileOnExit_When_TrapRemoveOnExit { #@test
	# Given
	touch /tmp/fileToRemoveOnExit

	# When
	run on_exit "rm -f /tmp/fileToRemoveOnExit"

	# Then
	[ "$status" -eq 0 ]
	[ ! -e "/tmp/fileToRemoveOnExit" ]
}

#Clean up if something went wrong
function teardown {
	rm -f /tmp/fileToRemoveOnExit
}
