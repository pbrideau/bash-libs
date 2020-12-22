#!/usr/bin/env bats
# shellcheck disable=SC2154

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

cmd_hard_to_parse='./template'
cmd=(./template --parseable)
FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures"

function Should_FailAndPrintUsageInColor_When_NoCommand { #@test
	run "$cmd_hard_to_parse"

	assert_failure 64
	assert_line "$(tput sgr0)[$(tput setaf 1)error$(tput sgr0)] No command given"
	assert_line --partial 'Usage:'
}

function Should_SucceedAndPrintUsage_When_HelpArgument { #@test
	run "${cmd[@]}" --help

	assert_success
	assert_line --partial 'Usage:'
}

function Should_FailAndPrintUsage_When_NoCommand { #@test
	run "${cmd[@]}"

	assert_failure 64
	assert_line --index 0 '[error] No command given'
	assert_line --index 1 --partial 'Usage:'
}

function Should_Fail_When_BadCommand { #@test
	run "${cmd[@]}" "BadCommand"

	assert_failure 64
	assert_line '[error] No such command: BadCommand'
}

function Should_Fail_when_TooManyCommands { #@test
	run "${cmd[@]}" Many Commands

	assert_failure 64
	assert_line --index 0 '[error] Too many commands given: Many Commands'
}

function Should_SucceedAndPrintLog0_When_RunQuiet { #@test
	run "${cmd[@]}" run --quiet

	assert_success
	assert_line '[error] This show an error to stderr'
}

function Should_SucceedAndPrintLog1_When_Run { #@test
	run "${cmd[@]}" run

	assert_success
	assert_line '[warn ] This show a warning to stdout'
	assert_line '[error] This show an error to stderr'
}

function Should_SucceedAndPrintLog2_When_RunVerbose { #@test
	run "${cmd[@]}" run --verbose

	assert_success
	assert_line '[info ] This show an info to stdout, when --verbose'
	assert_line '[warn ] This show a warning to stdout'
	assert_line '[error] This show an error to stderr'
}

function Should_SucceedAndPrintLog3_When_RunDebug { #@test
	run "${cmd[@]}" run --debug

	assert_success
	assert_line '[debug] This show a debug to stdout, when --debug'
}

function Should_SucceedAndPrintLog3_When_RunVerboseVerbose { #@test
	run "${cmd[@]}" run -vv

	assert_success
	assert_line '[debug] This show a debug to stdout, when --debug'
}

function Should_SucceedAndLoadConfig_When_ConfigArgument { #@test
	run "$cmd_hard_to_parse" \
		--config "$FIXTURE_ROOT/config_parseable.cfg" \
		run

	assert_success
	assert_line '[warn ] This show a warning to stdout'
	assert_line '[error] This show an error to stderr'
}

function Should_Fail_When_AskInNonInteractiveShell { #@test
	: | {
		run "${cmd[@]}" ask

		assert_failure
		assert_line '[error] Aborting...'
	}
}

function Should_Succeed_When_AskAlwaysYesArgument { #@test
	run "${cmd[@]}" --yes ask

	# Then
	assert_success
}

function Should_Succeed_When_AskInNonInteractiveShellAlwaysYesArgument { #@test
	: | {
		run "${cmd[@]}" --yes ask

		# Then
		assert_success
	}
}
