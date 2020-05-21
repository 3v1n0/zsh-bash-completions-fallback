_bash_completions_getter_path=${0:A:h}/bash-completions-getter.sh

function _bash_completer {
    local cmd=${words[@]};
    local out=("${(@f)$(bash -c \
        "source ${_bash_completions_getter_path}; get_completions '$cmd'")}");
    compadd -a out
}

function _bash_completions_load {
    local bash_completions=${ZSH_BASH_COMPLETIONS_FALLBACK_PATH:-/usr/share/bash-completion}

    if ! [ -f /etc/bash_completion ] &&
       ! [ -f "$bash_completions/bash_completion" ]; then
        return 1;
    fi

    local _completed_commands=()
    if [ "$ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL" != true ]; then
        for command completion in ${(kv)_comps:#-*(-|-,*)}; do
            _completed_commands+=($command)
        done
    fi

    [ -d ~/.bash_completion.d ] && local local_completions=~/.bash_completion.d/*

    for c in $bash_completions/completions/* $local_completions; do
        local completion=$c:t;

        if [ ${#ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST} -gt 0 ] &&
           ! ((${ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST[(I)${completion}]})); then
            continue;
        fi

        if ((${ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_LIST[(I)${completion}]})) ||
           ! ((${_completed_commands[(I)${completion}]})); then
            compdef _bash_completer $completion;
        fi
    done
}

_bash_completions_load
