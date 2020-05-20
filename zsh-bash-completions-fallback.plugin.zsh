our_path=${0:A:h}

function _bash_completer {
    cmd=${words[@]};
    out=("${(@f)$(bash -c "source ${our_path}/bash-completions-getter.sh; get_completions '$cmd'")}");
    compadd -a out
}

if ! [ -f /etc/bash_completion ] ||
   ! [ -f /usr/share/bash-completion/bash_completion ]; then
   return 1;
fi

_completed_commands=()
if [ "$ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL" != true ]; then
    for command completion in ${(kv)_comps:#-*(-|-,*)}; do
        _completed_commands+=($command)
    done
fi

for i in /usr/share/bash-completion/completions/*; do
    completion=$(basename $i);

    if [[ ${_completed_commands[(ie)${completion}]} -gt ${#_completed_commands} ]]; then
        compdef _bash_completer $completion;
    fi
done
