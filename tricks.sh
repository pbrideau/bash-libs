#!/usr/bin/env bash

# This is a list of common tricks to be used within bash scripts

function run_awk_within_bash {
	read -r -d '' awk_code <<- _EOF
		#+BEGIN_SRC awk
		BEGIN {
			print "Hello, world!"
		}
		#+END_SRC
	_EOF
	awk "$awk_code"
}
