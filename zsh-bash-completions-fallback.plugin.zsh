[[ -o interactive ]] || return 0

_bash_completions_getter_path=${0:A:h}/bash-completions-getter.sh

function _bash_completer {
    local cmd=${words[@]};
    local out=("${(@f)$(ZSH_CURSOR=$CURSOR bash -c \
        "source ${_bash_completions_getter_path}; get_completions '$cmd'")}");
    compadd -a out
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

        if [ ${#ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST} -gt 0 ] &&
           ! ((${ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST[(I)${completion}]})); then
            continue;
        fi

        if [ -z "$ZSH_BASH_COMPLETIONS_FALLBACK_PRELOAD_ALL" ] &&
           ! [[ -v commands[$completion] ]] &&
           ! [[ -v aliases[$completion] ]]; then
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

            compdef _bash_completer $completion
        fi
    done

    [ -z "$had_exended_glob" ] && unsetopt extendedglob
}

function _bash_completion_get_current_tab_completer()
{
    local current_binding=(${$(bindkey '^I')})
    echo "${${current_binding[2]}:-expand-or-complete}"
}

typeset -g _bash_completions_loaded=
typeset -g _bash_completions_available=0

function _bash-completion-init-and-continue()
{
    if [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_AUTO_UPDATE" ]; then
        local bash_completions=${ZSH_BASH_COMPLETIONS_FALLBACK_PATH:-/usr/share/bash-completion}
        local completion_files=($bash_completions/completions/*)

        if [ $_bash_completions_available -ne ${#completion_files[@]} ]; then
            typeset -g _bash_completions_available=${#completion_files[@]}
            typeset -g _bash_completions_loaded=
        fi
    fi

    if [ -n "$_bash_completions_loaded" ]; then
        zle $_bash_completion_previous_binding
        return $?
    fi

    local current_binding=$(_bash_completion_get_current_tab_completer)
    (( ${+functions[_bash_completions_lazy_load]} )) && \
        unset _bash_completions_lazy_load
    _bash_completions_load
    _bash_completions_loaded=1

    if [[ "$current_binding" == "_bash-completion-init-and-continue" ]]; then
        bindkey "^I" $_bash_completion_previous_binding
        unset _bash_completion_previous_binding
        unfunction _bash-completion-init-and-continue
    fi

    zle $_bash_completion_previous_binding
}

function _bash_completions_lazy_load()
{
    local default_binding=$(_bash_completion_get_current_tab_completer)
    typeset -g _bash_completion_previous_binding=$default_binding

    zle -N _bash-completion-init-and-continue
    bindkey "^I" _bash-completion-init-and-continue
}

if [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_DISABLE" ]; then
    _bash_completions_load

    if [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_AUTO_UPDATE" ]; then
        _bash_completions_lazy_load
    fi
else
    _bash_completions_lazy_load
fi
