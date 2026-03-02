alias vim='nvim'
alias vc='vim-claude'
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
        if [[ "$(uname)" == "Darwin" ]]; then
            _glamour="$HOME/Library/Preferences/glow/glamour.json"
        else
            _glamour="$HOME/.config/glow/glamour.json"
        fi
        if [[ ! -f "$_glamour" ]]; then
            printf '🎨 glamour.json not found — run \033[1mupdate-config\033[0m to generate it\n' >&2
            command cat "$@"
            return
        fi
        glow --style "$_glamour" "$@"
    elif command -v bat &>/dev/null; then
        bat --paging=never --style=plain "$@"
    elif command -v batcat &>/dev/null; then
        batcat --paging=never --style=plain "$@"
    else
        command cat "$@"
    fi
}

# eza overrides for ls/ll (must come after initial ls alias)
export EZA_CONFIG_DIR="$HOME/.config/eza"
command -v eza &>/dev/null && alias ls='eza --color=always --icons=auto' && alias ll='eza -l --color=always --icons=auto --git'

# Clipboard (Linux only — macOS has pbcopy/pbpaste built in)
if [ "$(uname)" != "Darwin" ]; then
    alias xclip='xclip -selection clipboard'
    alias xpaste='xclip -selection clipboard -o'
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

alias kitty-reload='kill -SIGUSR1 $(pgrep -x kitty)'

alias grep='grep --color=auto'
alias igrep='grep -i --color=auto'
alias rgrep='grep -r --color=auto'
alias irgrep='grep -ri --color=auto'

# tmux session helpers
# t [name]  — create or attach to a named session (default: "main")
# tms       — create or attach to a session named after the current directory
t()   { tmux new-session -As "${1:-main}"; }
tms() { local name; name="$(basename "$PWD" | tr ' ' '-')"; tmux new-session -As "$name"; }

weather() { curl "wttr.in/${1:-80302}"; }
alias whatsmyip='curl -s ifconfig.me && echo'

alias yt-dl-mp3='yt-dlp --output "%(title)s.%(ext)s" --yes-playlist --cookies ~/Downloads/youtube.com_cookies.txt -x --audio-format mp3'
