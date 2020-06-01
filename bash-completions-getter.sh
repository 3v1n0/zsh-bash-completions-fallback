
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

source_bash_completion() {
    local src_name='bash_completion'
    if [ -n "${ZSH_BASH_COMPLETIONS_FALLBACK_PATH}" ] &&
       [ -f "${ZSH_BASH_COMPLETIONS_FALLBACK_PATH}/$src_name" ]; then
        source "${ZSH_BASH_COMPLETIONS_FALLBACK_PATH}/$src_name"
    elif [ -f "/etc/$src_name" ]; then
        source "/etc/$src_name"
    elif [[ $BASH_SOURCE == */* ]] &&
         [ -f "${BASH_SOURCE%/*}/$src_name" ]; then
            source "${BASH_SOURCE%/*}/$src_name"
    else
        local -a dirs=()
        local OIFS=$IFS IFS=: dir
        local lookup_dirs=(${XDG_DATA_DIRS:-/usr/local/share:/usr/share})
        IFS=$OIFS

        for dir in ${lookup_dirs[@]}; do
            if [ -f "$dir/bash-completion/$src_name" ]; then
                source "$dir/bash-completion/$src_name"
                return 0
            fi
        done
    fi

    return 1
}

parse_complete_options() {
    unset COMPLETE_ACTION
    unset COMPLETE_ACTION_TYPE
    unset COMPLETE_SUPPORTED_COMMANDS

    COMPLETE_ACTION=
    COMPLETE_SUPPORTED_COMMANDS=()

    while [ ${#@} -gt 0 ]; do
        case "$1" in
            -F|-C)
                [ -n "$COMPLETE_ACTION" ] &&
                    return 2

                local optarg="${2#\'}"
                COMPLETE_ACTION="${optarg%\'}"
                COMPLETE_ACTION_TYPE=${1#-}
                shift 2
            ;;
            -pr|-D|-E|-o|-A|-G|-F|-C|-P|-S)
                shift 2
            ;;
            -X|-W)
                # TODO, but to support this we also need to handle compopt and -o
                shift 2
            ;;
            -*)
                shift
            ;;
            *)
                break
            ;;
        esac
    done

    [ -z "$COMPLETE_ACTION" ] \
        && return;

    while [ ${#@} -gt 0 ]; do
        COMPLETE_SUPPORTED_COMMANDS+=("$1")
        shift
    done
}

get_completions() {
    local COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS COMP_WORDBREAKS
    local completion COMPREPLY=() cmd_name

    COMP_LINE=${ZSH_BUFFER}
    COMP_POINT=${ZSH_CURSOR:-${#COMP_LINE}}
    COMP_WORDBREAKS=${ZSH_WORDBREAKS}
    COMP_WORDS=(${ZSH_WORDS[@]})
    cmd_name=${ZSH_NAME}


    # add '' to COMP_WORDS if the last character of the command line is a space
    [[ "${COMP_LINE[@]: -1}" = ' ' ]] && COMP_WORDS+=('')

    # index of the last word as fallback
    COMP_CWORD=${ZSH_CURRENT:-$(( ${#COMP_WORDS[@]} - 1 ))}

    # load completion
    source_bash_completion
    _completion_loader "$cmd_name"

    # detect completion function or command
    if [[ "$(complete -p "$cmd_name" 2>/dev/null)" =~ \
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
    local cmd=("$completion")
    cmd+=("$cmd_name")
    cmd+=("'${COMP_WORDS[$COMP_CWORD]}'")

    if [ ${COMP_CWORD} -gt 0 ]; then
        cmd+=("'${COMP_WORDS[$((COMP_CWORD-1))]}'");
    else
        cmd+=('');
    fi

    if [ "$COMPLETE_ACTION_TYPE" == 'C' ]; then
        export COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS COMP_WORDBREAKS
        COMPREPLY=($(${cmd[@]}))
    else
        ${cmd[@]}
    fi

    # print completions to stdout
    for ((i = 0; i < ${#COMPREPLY[@]}; i++)); do
        echo "${COMPREPLY[$i]%%*( )}"
    done
}
