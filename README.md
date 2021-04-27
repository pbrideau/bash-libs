# bash-libs

[![Conventional Commits][conventional-commits-image]][conventional-commits-url]
[![pre-commit][pre-commit-image]][pre-commit-url]

Libraries usefull for clean and quick scripts developments

## Installation

```bash
$ make install
Installing…
install -m 644 common.sh /home/ext11363/.local/lib/bash-libs
install -m 644 bash-template /home/ext11363/.local/share/bash-libs
install -m 644 bash-template-docopt /home/ext11363/.local/share/bash-libs
install -m 755 genbash /home/ext11363/.local/bin
```

## genbash

This script is used to generate a script easily, from a template.  There is two template
available: getopt (`bash-template-getopt`) and docopt (`bash-template-docopt`).

When generating script without `--common` argument, functions `log()` and `set_colors()`
will be inserted inline

### genbash template options

* --common
add sourcing of `common.sh`
* --example
include basic examples
* --config
include the `load_getopt_config()`, works only with the getopt template
* --yes
pre-configure `--yes` argument in target template
* --parseable
pre-configure `--parseable` argument in target template
* --set-e
place `set -e` in the target script
* --sigusr
add `sigusr1()` that can be triggered by `kill -s USR1 <pid>`

```bash
$ genbash ~/foo
[warn ] Function log() and set_colors() are required
[warn ] They will be added inline in your script
Do you want to continue? [y/N] y
[✔] /home/user/foo created successfully

$ genbash --common ~/bar
[✔] /home/user/bar created successfully
```

## common.sh

### `log()`

* Output message to stderr.
* You can enable colored output with: `set_colors true`
* Default `LOG_LEVEL=1` display only logs above warning.
* Checkbox get back at begining of line before writing

```bash
$ log 0 'Error message'
[error] Error message

$ log 1 'Warning message'
[warn ]: Warning message

$ log 2 'This info will not show because default LOG_LEVEL=1'

$ LOG_LEVEL=3 log 3 'Debug message'
[debug]== Debug message

$ log chkempty 'Empty checkbox'
[ ] Empty checkbox

$ log chkok 'OK checkbox'
[✔] OK checkbox

$ log chkerr 'Error checkbox'
[✘] Error checkbox

$ log chkempty 'Sleeping'; sleep 2; log chkok
[✔] Sleeping
```

When using debug, output show indentation from function nest deepness

```bash
$ function foo { LOG_LEVEL=3 log 3 'Debug message'; }
$ function bar { foo; }
$ bar
[debug]==== Debug message
```

### `prompt_user_abort()`

Ask the user to continue

```bash
$ prompt_user_abort 'Continue?'
Continue? [y/N]
```

### `spinner()`

Display while something run in background.  If you want your output to be
more dynamic, you can set `PARSEABLE=false` to display a rotating checkbox.
Otherwise, one dot every second is added.

The example below use subshell `( )` only to supress output of `&`, it is not required

```bash
$ (sleep 5 & spinner $! 'foo')
[ warn] running: foo
.....

$ #Multiple lines displayed here, but real output is only on one line
$ (sleep 5 & PARSEABLE=false spinner $! 'foo')
[\] foo (0s)
[|] foo (1s)
[/] foo (2s)
[-] foo (3s)
[\] foo (4s)
[✔] foo Done in 5 seconds
```

### `set_colors()`

Set the colors variables.

```bash
$ set_colors true
$ echo -e "${txtred}foo${txtrst}"
foo
```

### `load_getopt_config()`

Send file content to be parsed by `load_getopt_arg`.  This function is defined in
`bash-template`.  Arguments will be parsed as if they were given as argument to the
script.  For example, config with `verbose` will be as if `--verbose` was given
as argument.

```bash
load_getopt_args "$@"
load_getopt_config "foo.cfg" "bar.cfg"
```

### `basename()`

bash alternative to `basename` command

### `dirname()`

bash alternative to `dirname` command

### `format_date()`

Display the given date as 'X (seconds/minutes/...) ago' or 'in X (seconds/minutes...)'

```bash
$ format_date "$(date -d '+5 seconds')"
in 5 seconds
```

### `semver_compare()`

Compare semver versions, return 1 when A greater than B, 0 when A equals B
and -1 when A lower than B

```bash
$ semver_compare "1.2.3" "4.5.6"
-1
```

[conventional-commits-image]: https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg
[conventional-commits-url]: https://conventionalcommits.org/
[pre-commit-image]: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
[pre-commit-url]: https://github.com/pre-commit/pre-commit
