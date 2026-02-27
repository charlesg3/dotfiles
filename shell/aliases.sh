alias vim='nvim'
command -v eza &>/dev/null && alias tree='eza --tree --icons=auto --color=always' || alias tree='tree -C'
alias ll='ls -l'
alias dirsize='du -sm ./* | sort -g'
alias ffs='sudo !!'
alias update-config='$HOME/src/dotfiles/install.sh --nvim'
alias update-tools='$HOME/src/dotfiles/update.sh'
command -v colordiff &>/dev/null && alias diff='colordiff'

# cat: syntax highlighting via bat, markdown via glow
unalias cat 2>/dev/null
cat() {
    if [[ "$1" == *.md ]] && command -v glow &>/dev/null; then
        glow "$@"
    elif command -v bat &>/dev/null; then
        bat --paging=never --style=plain "$@"
    elif command -v batcat &>/dev/null; then
        batcat --paging=never --style=plain "$@"
    else
        command cat "$@"
    fi
}

# eza overrides for ls/ll (must come after initial ls alias)
command -v eza &>/dev/null && alias ls='eza --color=always --icons=auto' && alias ll='eza -l --color=always --icons=auto --git'

# Clipboard (Linux only — macOS has pbcopy/pbpaste built in)
if [ "$(uname)" != "Darwin" ]; then
    alias xclip='xclip -selection clipboard'
    alias xpaste='xclip -selection clipboard -o'
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

alias grep='grep --color=auto'
alias igrep='grep -i --color=auto'
alias rgrep='grep -r --color=auto'
alias irgrep='grep -ri --color=auto'

weather() { curl "wttr.in/${1:-80302}"; }
alias whatsmyip='curl -s ifconfig.me && echo'

# Run a command and notify nvim when it finishes (only active inside nvim terminals).
# Usage: notify sleep 10
notify() {
  "$@"
  local exit_code=$?
  local cmd="${1##*/}"
  if [ -n "$NVIM" ]; then
    nvim --server "$NVIM" --remote-expr "v:lua.notify_done('${cmd}', ${exit_code})" &>/dev/null &
  fi
  return $exit_code
}

alias yt-dl-mp3='yt-dlp --output "%(title)s.%(ext)s" --yes-playlist --cookies ~/Downloads/youtube.com_cookies.txt -x --audio-format mp3'
