
# Author: Brian Beffa <brbsix@gmail.com>
# Updated by: Marco Trevisan <mail@3v1n0.net>
# Original source: https://brbsix.github.io/2015/11/29/accessing-tab-completion-programmatically-in-bash/
# License: LGPLv3 (http://www.gnu.org/licenses/lgpl-3.0.txt)
#

compopt() {
    # Override default compopt
    # TODO, to implement when possible
    return 0
}

parse_complete_options() {
    unset COMPLETE_ACTION
    unset COMPLETE_ACTION_TYPE

    while getopts ":abcdefgjksuvp:D:o:A:G:W:F:C:X:P:S:" opt; do
        case ${opt} in
            F|C)
                [ -n "$COMPLETE_ACTION" ] && return 2
                COMPLETE_ACTION=${OPTARG//\'/}
                COMPLETE_ACTION_TYPE=${opt}
            ;;
            X)
                # TODO, but to support this we also need to handle compopt and -o
            ;;
            W)
                # TODO, but to support this we also need to handle compopt and -o
            ;;
        esac
    done

    [ -z "$COMPLETE_ACTION" ] && return 1

    for ((i = $OPTIND; i <= ${#@}; i++)); do
        COMPLETE_ACTION+=" ${@:$i:1}"
        break # We only care about the first fix-position
    done
}

get_completions() {
    local COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS COMP_WORDBREAKS
    local completion COMPREPLY=() cmd

    # load bash-completion if necessary
    declare -F _completion_loader &>/dev/null || {
        if [ -n "${ZSH_BASH_COMPLETIONS_FALLBACK_PATH}" ] &&
           [ -f "${ZSH_BASH_COMPLETIONS_FALLBACK_PATH}/completions" ]; then
            source "${ZSH_BASH_COMPLETIONS_FALLBACK_PATH}/completions"
        elif [ -f /etc/bash_completion ]; then
            source /etc/bash_completion
        elif [ -f /usr/share/bash-completion/bash_completion ]; then
            source /usr/share/bash-completion/bash_completion
        fi
    }

    COMP_LINE=$*
    COMP_POINT=${#COMP_LINE}
    [ -z "$COMP_WORDBREAKS" ] && COMP_WORDBREAKS="\"'><;|&("

    eval set -- "$@"

    COMP_WORDS=("$@")

    # add '' to COMP_WORDS if the last character of the command line is a space
    [[ "${COMP_LINE[@]: -1}" = ' ' ]] && COMP_WORDS+=('')

    # index of the last word
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

    # load completion
    _completion_loader "$1"

    # detect completion function or command
    if [[ "$(complete -p "$1" 2>/dev/null)" =~ \
          ^complete[[:space:]]+(.+) ]]; then
        local args=${BASH_REMATCH[1]};
        parse_complete_options $args
        completion="$COMPLETE_ACTION"
    else
        return 1;
    fi

    # ensure completion was detected
    [[ -n "$completion" ]] || return 1

    # execute completion function or command (exporting the needed variables)
    # This may fail if compopt is called, but there's no easy way to pre-fill
    # the bash input with some stuff, using only bashy things.
    cmd="${completion} '${COMP_WORDS[$COMP_CWORD]}' '${COMP_WORDS[$((COMP_CWORD-1))]}'"
    if [ "$COMPLETE_ACTION_TYPE" == 'C' ]; then
        export COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS COMP_WORDBREAKS
        COMPREPLY=($($cmd))
    else
        $cmd
    fi

    # print completions to stdout
    for ((i = 0; i < ${#COMPREPLY[@]}; i++)); do
        echo "${COMPREPLY[$i]%%*( )}"
    done
}
