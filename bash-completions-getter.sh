
# Author: Brian Beffa <brbsix@gmail.com>
# Original source: https://brbsix.github.io/2015/11/29/accessing-tab-completion-programmatically-in-bash/
# License: LGPLv3 (http://www.gnu.org/licenses/lgpl-3.0.txt)
#

compopt() {
    # Override default compopt
    # TODO, to implement when possible
    return 0
}

get_completions(){
    local completion COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS COMPREPLY=()

    # load bash-completion
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

    eval set -- "$@"

    COMP_WORDS=("$@")

    # add '' to COMP_WORDS if the last character of the command line is a space
    [[ "${COMP_LINE[@]: -1}" = ' ' ]] && COMP_WORDS+=('')

    # index of the last word
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

    # load completion
    _completion_loader "$1"

    # detect completion
    completion=$(complete -p "$1" 2>/dev/null | awk '{print $(NF-1)}')

    # ensure completion was detected
    [[ -n $completion ]] || return 1

    # execute completion function
    # Thois may fail if compopt is called, but there's no easy way to pre-fill
    # the bash input with some stuff, using only bashy things.
    "$completion"

    # print completions to stdout
    for ((i = 0; i < ${#COMPREPLY[@]}; i++)); do
        echo "${COMPREPLY[$i]%%*( )}"
    done
}
