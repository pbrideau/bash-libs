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
	[ "${lines[0]}" = "[error] Error" ]
	# No way to check if it's stdout or stderr with bats...
	# Assume it's in stderr
}
function Should_LogWarningToStdout_When_Log1 { #@test
	# Given
	export LOG_LEVEL=1

	# When
	run log 1 'Warning'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "[warn ] Warning" ]
}
function Should_LogInfoToStdout_When_Log2 { #@test
	# Given
	export LOG_LEVEL=2

	# When
	run log 2 'Info'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "[info ] Info" ]
}
function Should_LogDebugToStdout_When_Log3 { #@test
	# Given
	export LOG_LEVEL=3

	# When
	run log 3 'Debug'

	# Then
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "[debug] Debug" ]
}
function Should_Fail_When_LogAnythingElse { #@test
	# Given

	# When
	run log 'debug' 'Should fail'

	# Then
	[ "$status" -eq 125 ]
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
