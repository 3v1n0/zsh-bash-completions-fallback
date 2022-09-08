#!/usr/bin/env bash
# set -x

this_dir="$(dirname "$0")"
src_dir="$this_dir/.."
bash_completer="$src_dir/bash-completions-getter.sh"

exec 535>&2
our_stderr=535

exec 999>/dev/null
completion_out=999

if [ -n "$DEBUG" ]; then
    completion_out=$our_stderr

    if [ "$DEBUG" -gt 1 ]; then
        set -x
    fi
fi

check_completion() {
    local input="$1"
    local expected_completions=("$2")
    local expected_options=("$3")
    local expected_exit_code=${4:-0};
    local -a output
    local -a options

    echo "Checking completion $input" >&2

    # shellcheck source=./bash-completions-getter.sh disable=SC1091
    source "$bash_completer"
    mapfile -t output < <(test_bash_completion "$input" 2>&$completion_out; echo $?)
    echo -n "  output: " >&2; printf "'%s'," "${output[@]}" >&2; echo >&2

    if [ "${#output[@]}" -eq 0 ]; then
        echo "Unepxected output"
        exit 1
    fi

    local exit_code="${output[-1]}"
    unset 'output[-1]';
    echo "  exit code: $exit_code" >&2

    if [ "$exit_code" -ne "$expected_exit_code" ]; then
        echo "! invalid exit code, expecting: $expected_exit_code";
        [ -n "$message" ] && echo "$message"
        exit 1
    fi

    if [ "$exit_code" -ne 0 ]; then
        return 0
    fi

    read -r -a options <<< "${output[0]}"
    local completions=("${output[@]:1}")

    echo -n "  options: " >&2; printf "'%s'," "${options[@]}" >&2; echo >&2
    echo -n "  completions: " >&2; printf "'%s'," "${completions[@]}" >&2; echo >&2

    if [[ "${completions[*]}" != "${expected_completions[*]}" ]]; then
        echo -n "! invalid completions, expecting: "; printf "'%s'," "${expected_completions[@]}"; echo
        exit 1
    fi

    if [[ "${options[*]}" != "${expected_options[*]}" ]]; then
        echo -n "! invalid options, expecting: "; printf "'%s'," "${expected_options[@]}"; echo
        exit 1
    fi
}

expect_failure() {
    check_completion "$1" '' '' 1
}

function test_complete_function() {
    if [[ "$1" != "$EXPECTED_COMPLETE_PROGRAM" ]]; then
        echo "Unexpected complete program: '$1'" >&$our_stderr
        return 1
    fi

    if [[ "$2" != "$EXPECTED_COMPLETE_WORD" ]]; then
        echo "Unexpected complete word: '$2'" >&$our_stderr
        return 2
    fi

    if [[ "$3" != "$EXPECTED_COMPLETE_PRE_WORD" ]]; then
        echo "Unexpected complete previous word: '$3'" >&$our_stderr
        return 3
    fi

    COMPREPLY=("${TEST_COMPLETE_REPLY[@]}")
}

expect_failure hopefully-invalid-command-completion

complete -W "foo" foo-with-word
check_completion foo-with-word "foo"

complete -o nospace -W "foo" foo-with-word-and-option
check_completion foo-with-word-and-option "foo" nospace

complete -W "foo --bar" foo-with-multiple-words
check_completion foo-with-multiple-words "foo --bar"

complete -o nospace -W "foo" foo-with-word-and-option
check_completion foo-with-word-and-option "foo" nospace

complete -o nospace -W "foo" -o nosort foo-with-multiple-options
check_completion foo-with-multiple-options "foo" "nosort nospace"

complete -o nospace -W "foo bar" -o nosort foo-with-multiple-words-and-options
check_completion foo-with-multiple-words-and-options "foo bar" "nosort nospace"

complete -o nospace -o nosort -o default foo-with-only-options
check_completion foo-with-only-options '' "default nosort nospace"

complete -F foo_complete_function_not_existant foo-with-function-invalid
expect_failure foo-with-function-invalid

function foo_complete_function_simple() {
    EXPECTED_COMPLETE_PROGRAM=foo-with-function-simple
    EXPECTED_COMPLETE_WORD="''"
    EXPECTED_COMPLETE_PRE_WORD="'foo-with-function-simple'"
    TEST_COMPLETE_REPLY=(a --b --c)
    test_complete_function "$@"
}

complete -F foo_complete_function_simple foo-with-function-simple
check_completion 'foo-with-function-simple ' "a --b --c"


function foo_complete_function() {
    EXPECTED_COMPLETE_PROGRAM=foo-with-function
    EXPECTED_COMPLETE_WORD="'word'"
    EXPECTED_COMPLETE_PRE_WORD="'pre-word'"
    TEST_COMPLETE_REPLY=(-c -D efgh)
    test_complete_function "$@"
}

complete -F foo_complete_function foo-with-function
check_completion 'foo-with-function pre-word word' "-c -D efgh"

function foo_complete_function_with_options() {
    EXPECTED_COMPLETE_PROGRAM=foo-with-function-and-options
    EXPECTED_COMPLETE_WORD="'word'"
    EXPECTED_COMPLETE_PRE_WORD="'pre-word'"
    TEST_COMPLETE_REPLY=(-c -D efgh)
    compopt -o default +o default +o bar -o nosort -o nospace +o nospace -o nospace
    test_complete_function "$@"
}

complete -F foo_complete_function_with_options foo-with-function-and-options
check_completion 'foo-with-function-and-options pre-word word' "-c -D efgh" "nosort nospace"
