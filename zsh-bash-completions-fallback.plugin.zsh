_bash_completions_getter_path=${0:A:h}/bash-completions-getter.sh

function _bash_completer {
    local cmd=${words[@]};
    local out=("${(@f)$(bash -c \
        "source ${_bash_completions_getter_path}; get_completions '$cmd'")}");
    compadd -a out
}

function _bash_completion_lazy_loader {
    local completion=$1

    if [[ -v functions[__bash_complete_${completion}] ]]; then
        unalias $completion
        unfunction __bash_complete_${completion}
    fi

    if ! [[ -v builtins[$completion] ]]; then
        __bash_complete_${completion}() {
            local c=${0#__bash_complete_}
            unfunction $0
            unalias $c
            compdef _bash_completer $c
            $c $@
        }
        alias $completion="__bash_complete_${completion}"
    fi
}

function _bash_completions_load {
    local bash_completions=${ZSH_BASH_COMPLETIONS_FALLBACK_PATH:-/usr/share/bash-completion}
    local reserved_words=(
        "do"
        "done"
        "esac"
        "then"
        "elif"
        "else"
        "fi"
        "for"
        "case"
        "if"
        "while"
        "function"
        "repeat"
        "time"
        "until"
        "select"
        "coproc"
        "nocorrect"
        "foreach"
        "end"
        "declare"
        "export"
        "float"
        "integer"
        "local"
        "readonly"
        "typeset"
    )

    if ! [ -f /etc/bash_completion ] &&
       ! [ -f "$bash_completions/bash_completion" ]; then
        return 1;
    fi

    [ -d ~/.bash_completion.d ] && local local_completions=~/.bash_completion.d/*

    [[ -o extended_glob ]] && local had_exended_glob=true
    setopt extendedglob

    for c in $bash_completions/completions/_* \
             $bash_completions/completions/^_* \
             $local_completions; do
        local completion=${${c:t}#_};
        local available_command=

        if [ ${#ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST} -gt 0 ] &&
           ! ((${ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST[(I)${completion}]})); then
            continue;
        fi

        if  [[ -v commands[$completion] ]] || [[ -v aliases[$completion] ]]; then
            available_command=1
        fi

        if [ -z "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_UNAVAILABLE" ] &&
           [ -z "$ZSH_BASH_COMPLETIONS_FALLBACK_PRELOAD_ALL" ] &&
           [ -z "$available_command" ]; then
            continue;
        elif ((${reserved_words[(I)${completion}]})); then
            continue;
        fi

        if ((${ZSH_BASH_COMPLETIONS_FALLBACK_BLACKLIST[(I)${completion}]})); then
            continue;
        fi

        if ((${ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_LIST[(I)${completion}]})) ||
           [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL" ] ||
           ! [[ -v _comps[$completion] ]]; then

            if [ -z "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_AVAILABLE" ] &&
               [ -z "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_UNAVAILABLE" ]; then
                compdef _bash_completer $completion;
            elif [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_UNAVAILABLE" ] &&
                 [ -n "$available_command" ]; then
                compdef _bash_completer $completion;
            else
                _bash_completion_lazy_loader $completion
            fi
        fi
    done

    [ -z "$had_exended_glob" ] && unsetopt extendedglob
}

_bash_completions_load
