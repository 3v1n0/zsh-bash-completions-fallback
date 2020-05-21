our_path=${0:A:h}

function _bash_completer {
    cmd=${words[@]};
    out=("${(@f)$(bash -c "source ${our_path}/bash-completions-getter.sh; get_completions '$cmd'")}");
    compadd -a out
}

function _bash_completions_load {
    local bash_completions=${ZSH_BASH_COMPLETIONS_FALLBACK_PATH:-/usr/share/bash-completion}

    if ! [ -f /etc/bash_completion ] ||
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

        if [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST" ]; then
            if [[ ${ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST[(ie)${completion}]} -gt \
                ${#ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST} ]]; then
                continue;
            fi
        fi

        if [[ ${_completed_commands[(ie)${completion}]} -gt ${#_completed_commands} ]]; then
            compdef _bash_completer $completion;
        fi
    done
}

_bash_completions_load
