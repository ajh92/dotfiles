test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish ; or true
if type -q rbenv; and status --is-interactive; and rbenv init - fish | source ; or true; end;

direnv hook fish | source

# Created by `pipx` on 2024-06-08 21:27:34
set PATH $PATH /Users/andrew/.local/bin
