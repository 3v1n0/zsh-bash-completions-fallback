[[ -o interactive ]] || return 0

_bash_completions_getter_path=${0:A:h}/bash-completions-getter.sh
_bash_completions_dirs=(
    ~/.local/share
    ${(@s/:/)${XDG_DATA_DIRS}} # in NixOS, it contains /run/current-system/sw/share
    /data/data/com.termux/files/usr/share # Android Termux
    ~/.local/state/nix/profile/share # Nix
    /home/linuxbrew/.linuxbrew/share # Homebrew for Linux
    /opt/share # Homebrew for arm macOS
    /usr/local/share # Homebrew for x86 macOS
    /${MINGW_ARCH:-mingw64}/share # Windows Msys2
    /usr/share
)

function _bash_completions_fallback_completer {
    emulate -L zsh
    unsetopt nomatch badpattern
    local out=("${(@f)$( \
        ZSH_NAME="$name" \
        ZSH_BUFFER="$BUFFER" \
        ZSH_CURSOR="$CURSOR" \
        ZSH_WORDBREAKS="$WORDCHARS" \
        ZSH_WORDS="${words[@]}" \
        ZSH_CURRENT=$((CURRENT-1)) \
        bash -c \
        "source ${_bash_completions_getter_path}; get_completions")}");

    local -a -U bopts=("${(ps: :)${(@f)out:0:1}}");
    local -a -U bactions=("${(ps: :)${(@f)out:1:2}}");
    local -a -U bcompletions=("${(@f)out:2}")
    local -a -U compoptions=()

    if ((${bopts[(Ie)nospace]})); then
        compoptions+=(-S '')
    fi

    if ((${bopts[(Ie)nosort]})); then
        compoptions+=(-o 'nosort')
    fi

    local compadd_opts=("${compoptions[@]}")
    if [ -n "$bcompletions" ]; then
        compadd_opts+=(-Q)

        if ((${bopts[(Ie)filenames]})); then
            compset -P '*/' && \
                bcompletions=(${bcompletions##*/})
            compset -S '/*' && \
                bcompletions=(${bcompletions%%/*})
            compadd_opts+=(-f)
        fi
    fi

    if [ -z "$bcompletions" ] ||
       ! compadd "${compadd_opts[@]}" -a bcompletions; then

        if ((${bopts[(Ie)default]})) || ((${bopts[(Ie)bashdefault]})); then
            _default "${compoptions[@]}"
        elif ((${bopts[(Ie)dirnames]})); then
            _directories "${compoptions[@]}"
        fi
    fi

    if ((${bopts[(Ie)plusdirs]})); then
        _directories "${compoptions[@]}"
    fi

    return $?
}

function _bash_completions_fetch_supported_commands {
    emulate -L zsh
    setopt extended_glob typeset_silent no_short_loops
    unsetopt nomatch

    local dir dirs=($BASH_COMPLETION_USER_DIR)
    for dir in "${_bash_completions_dirs[@]}"; do
        dirs+=("$dir/bash-completion/completions")
    done

    local c
    for dir in "${dirs[@]}"; do
        for c in "$dir"/*; do
            [ ! -f "$c" ] && continue
            local command=${${${c:t}#_}%.bash};
            _bash_completions_commands+=($command)
        done
    done

    if [ -n "${ZSH_BASH_COMPLETIONS_FALLBACK_LOAD_NATIVE_COMPLETIONS-:true}" ]; then
        local out=("${(u@f)$( \
            bash -c \
            "source ${_bash_completions_getter_path}; get_defined_completions")}");
        _bash_completions_commands+=($out)
    fi
}

function _bash_completions_load {
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

    local -a -U _bash_completions_commands=()
    _bash_completions_fetch_supported_commands

    for completion in $_bash_completions_commands; do
        if [ ${#ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST} -gt 0 ] &&
           ! ((${ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST[(I)${completion}]})); then
            continue;
        fi

        if [ -z "$ZSH_BASH_COMPLETIONS_FALLBACK_PRELOAD_ALL" ] &&
           ! [[ -v commands[$completion] ]] &&
           ! [[ -v aliases[$completion] ]]; then
            continue;
        elif ((${reserved_words[(Ie)${completion}]})); then
            continue;
        fi

        if ((${ZSH_BASH_COMPLETIONS_FALLBACK_BLACKLIST[(Ie)${completion}]})); then
            continue;
        fi

        if ((${ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_LIST[(Ie)${completion}]})) ||
           [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL" ] ||
           ! [[ -v _comps[$completion] ]]; then

            compdef _bash_completions_fallback_completer $completion
        fi
    done
}

function _bash_completion_get_current_tab_completer()
{
    local current_binding=(${$(bindkey '^I')})
    echo "${${current_binding[2]}:-expand-or-complete}"
}

typeset -g _bash_completions_loaded=
integer -g _bash_completions_available=0
integer -g _bash_completions_last_checked_timestamp=$EPOCHSECONDS

function _bash-completion-init-and-continue()
{
    local update_threshold=${ZSH_BASH_COMPLETIONS_FALLBACK_AUTO_UPDATE_THRESHOLD:-300}
    if [ -n "$ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_AUTO_UPDATE" ] &&
       [ -n "$EPOCHSECONDS" ] &&
       [ $EPOCHSECONDS -gt \
         $((_bash_completions_last_checked_timestamp + update_threshold)) ]; then
        local -a -U _bash_completions_commands=()
        _bash_completions_fetch_supported_commands

        if [ $_bash_completions_available -ne ${#_bash_completions_commands[@]} ]; then
            typeset -g _bash_completions_available=${#_bash_completions_commands[@]}
            typeset -g _bash_completions_loaded=
        fi
    fi

    if [ -n "$_bash_completions_loaded" ]; then
        zle $_bash_completion_previous_binding
        return $?
    fi

    local current_binding=$(_bash_completion_get_current_tab_completer)
    (( ${+functions[_bash_completions_lazy_load]} )) && \
        unfunction _bash_completions_lazy_load
    _bash_completions_load
    _bash_completions_loaded=1

    if [[ "$current_binding" == "_bash-completion-init-and-continue" ]]; then
        bindkey "^I" $_bash_completion_previous_binding
        zle $_bash_completion_previous_binding
        unset _bash_completion_previous_binding
        unfunction _bash-completion-init-and-continue
        return
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

function _bash_completions_fallback_list_handled_completions()
{
    local -a our_completions=();
    for command completion in ${(kv)_comps}; do
        if [ "$completion" = _bash_completions_fallback_completer ]; then
            our_completions+=($command)
        fi
    done

    printf "%-32s\n" ${(o)our_completions[@]}
}
