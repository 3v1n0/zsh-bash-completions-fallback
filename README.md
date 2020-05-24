# zsh-bash-completions-fallback

This plugin is intended to use the bash completions when a zsh completion is not
available.

While this could be supported natively via `bashcompinit`, this doesn't
actually work most of the times, as completion scripts may use syntax not
supported by zsh, and so it's just better to implement this querying the bash
itself, using a bash script called at completion time (based on [Brian Baffa
implementation](https://brbsix.github.io/2015/11/29/accessing-tab-completion-programmatically-in-bash/)
and including various fixes to support commands and completion parameters).

Make sure you load this after other plugins to prevent their completions to be
replaced by the (simpler) bash ones.

Not all the bash completions can work as they precisely do in bash, as per
missing `compopt` support, that may be used to control the output or avoid
adding spaces or limit the results. However this could be implemented at later
times.

If a new bash completion has been installed in the system, it would be too
expensive to monitor the completions directroy for new files, so just restart
zsh or call `_bash_completions_load`.

Once loaded you can see all the completions available via bash using

      for command completion in ${(kv)_comps}; do printf "%-32s %s\n" $command $completion; done | sort | grep _bash_completer


Requirements
------------------------------------------------------------------------------

* [ZSH](http://zsh.sourceforge.net) 4.3 or newer
* [GNU Bash](https://www.gnu.org/software/bash/) 4 or newer

Install
------------------------------------------------------------------------------

Using [Oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh):

1. Clone this repository in oh-my-zsh's plugins directory:

        git clone https://github.com/3v1n0/zsh-bash-completions-fallback ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-bash-completions-fallback

2. Activate the plugin in `~/.zshrc` (make sure it's set as the last one not to
   replace completions provided by other plugins):

        plugins=( [plugins...] zsh-bash-completions-fallback)

3. Source `~/.zshrc`  to take changes into account:

        source ~/.zshrc

Configuration
------------------------------------------------------------------------------

This script defines the following global variables. You may override their
default values only after having loaded this script into your ZSH session.

* `ZSH_BASH_COMPLETIONS_FALLBACK_PATH` overrides the default bash completions
  path that is set to `/usr/share/bash-completion` by default.

* `ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL` set (to any value) to allow to
  replace all the zsh completions, even if we already have one for the given
  command.

* `ZSH_BASH_COMPLETIONS_FALLBACK_WHITELIST` an array of commands for which we
  want to enable the bash completions, this allow to filter the commands to use
  a bash completion for. Set it to a value such as `(gdbus zramctl)` to enable
  it only for the `gdbus` and `zramctl` commands.
  This also can be used with `$ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL` to
  only use a subset of completions from bash only.

* `ZSH_BASH_COMPLETIONS_FALLBACK_BLACKLIST` an array of commands for which we
  want to disable the bash completions.

* `ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_LIST` an array of commands for which we
  want to give priority to the bash completions over the zsh ones.
  So, in case a zsh completion for such commands is available, we just ignore it
  and replace it with the bash ones.
  This has no effect if `$ZSH_BASH_COMPLETIONS_FALLBACK_REPLACE_ALL` is set.

* `ZSH_BASH_COMPLETIONS_FALLBACK_PRELOAD_ALL` set this variable (to any value)
  to always preload completions even for non-available commands. We don't do it
  by default and if any command is added at later times, the user can manually
  call `_bash_completions_load` (or source this file again)

* `ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_AVAILABLE` set this variable (to any
  value) in order to generate aliases for lazy loading the completions so that
  the completions are loaded only when the command is triggered the first time.
  Setting this variable will conflict with
  `$ZSH_BASH_COMPLETIONS_FALLBACK_PRELOAD_ALL`, and may lead to an undefined
  behavior.

* `ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_UNAVAILABLE` set this variable (to any
  value) in order to generate aliases for lazy loading the completions in case
  the command is not available. Setting this variable will conflict with
  `$ZSH_BASH_COMPLETIONS_FALLBACK_PRELOAD_ALL`, and so the former will be
  ignored
