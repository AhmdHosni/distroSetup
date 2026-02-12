#!/bin/sh



#######################
# some more aliases
# ####################
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

alias c='clear'
alias :q='exit'
alias ..='cd ..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'


# Alias to launch a document, file, or URL in it's default X application
if [[ -x "$(command -v xdg-open)" ]]; then
    alias open='runfree xdg-open'
fi

# Alias to launch a document, file, or URL in it's default PDF reader
if [[ -x "$(command -v evince)" ]]; then
    alias pdf='runfree evince'
fi


# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
if [[ -x "$(command -v lazygit)" ]]; then
    alias lg='lazygit'
fi

# Alias for FZF
# Link: https://github.com/junegunn/fzf
if [[ -x "$(command -v fzf)" ]]; then
    if [[ -x "$(command -v bat)" ]]; then alias fzf='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'; fi
    if [[ -x "$(command -v batcat)" ]]; then alias fzf='fzf --preview "batcat --style=numbers --color=always --line-range :500 {}"'; fi

    # Alias to fuzzy find files in the current folder(s), preview them, and launch in an editor
    if [[ -x "$(command -v xdg-open)" ]]; then
        alias preview='open $(fzf --info=inline --query="${@}")'
    else
        alias preview='edit $(fzf --info=inline --query="${@}")'
    fi
fi

# Get local IP addresses
if [[ -x "$(command -v ip)" ]]; then
    alias iplocal="ip -br -c a"
else
    alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
fi

# Get public IP addresses
if [[ -x "$(command -v curl)" ]]; then
    alias ipexternal="curl -s ifconfig.me && echo"
elif [[ -x "$(command -v wget)" ]]; then
    alias ipexternal="wget -qO- ifconfig.me && echo"
fi




######################
# some good Functions
#####################

# FZF with bat and kitty: (Preview images as well)
export FZF_PREVIEW_CMD='
    FILE={}
    MIME=$(file --mime-type -b "$FILE")
    if [[ -d "$FILE" ]]; then
        lsd --tree --depth 2 --color=always "$FILE" | head -200
    elif [[ "$MIME" == image/* ]]; then
        kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" "$FILE"
    else
        if command -v apt-get &>/dev/null; then
            batcat --color=always --style=numbers "$FILE"
        elif command -v pacman &>/dev/null; then
            bat --color=always --style=numbers "$FILE"
        fi


    fi'

# Use it with an alias like this:
alias fp="fzf --preview '$FZF_PREVIEW_CMD'"



# Start a program but immediately disown it and detach it from the terminal
function runfree() {
    "$@" > /dev/null 2>&1 & disown
}

# Copy file with a progress bar
function cpp() {
    if [[ -x "$(command -v rsync)" ]]; then
        # rsync -avh --progress "${1}" "${2}"
        rsync -ah --info=progress2 "${1}" "${2}"
    else
        set -e
        strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
            | awk '{
                count += $NF
                if (count % 10 == 0) {
                    percent = count / total_size * 100
                    printf "%3d%% [", percent
                    for (i=0;i<=percent;i++)
                        printf "="
                        printf ">"
                        for (i=percent;i<100;i++)
                            printf " "
                            printf "]\r"
                        }
                }
        END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
    fi
}

# Copy and go to the directory
function cpg() {
    if [[ -d "$2" ]];then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# Move and go to the directory
function mvg() {
    if [[ -d "$2" ]];then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# Create and go to the directory
function mkdirg() {
    mkdir -p "$@" && cd "$@"
}

# Prints random height bars across the width of the screen
# (great with lolcat application on new terminal windows)
function random_bars() {
    columns=$(tput cols)
    chars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
    for ((i = 1; i <= $columns; i++))
    do
        echo -n "${chars[RANDOM%${#chars} + 1]}"
        done
        echo
    }

# use lsd instead of ls if lsd exists
if [ -f /usr/bin/lsd ]; then
    # alias ls="lsd --color=auto"
    alias ls='lsd -F --group-dirs first'
    alias ll='lsd --header --long --group-dirs first'
    alias lah='lsd --all --header --long --group-dirs first'
	alias tree='lsd --tree'
else 
    alias ls="ls --color=auto"
    alias ll="ls -lh --color=auto"
    alias lah="ls -lah --color=auto"

fi

# use batcat instead of cat if batcat exists
if [ -f /usr/bin/batcat ]; then
    alias cat="batcat --color=auto"
fi

# use bat instead of cat if bat exists
if [ -f /usr/bin/bat ]; then
    alias cat="bat --color=auto"
fi

# other aliases
# alias ll="ls -lh --color=auto"
# alias lah="ls -lah --color=auto"


# os spicific aliases
if [ -f /usr/bin/pacman ]; then
    alias update="echo 1262 | sudo -S -k pacman -Syyu --noconfirm"
elif [ -f /usr/bin/apt ]; then
    alias update="echo 1262 | sudo -S -k apt-get update -y && echo 1262 | sudo -S -k apt-get upgrade -y && echo 1262 | sudo -S -k apt-get dist-upgrade -y"
    alias clean="echo 1262 | sudo -S -k apt-get autoremove"
    alias reboot="echo 1262 | sudo -S -k reboot"
fi

# nvim portable version if non is installed
if [ ! -f /usr/bin/nvim ]; then
alias nvim="/media/ahmdhosni/Storage/Apps/neovim/nvim/nvim-linux.appimage"
alias vi='nvim'
alias vim='nvim'
alias svi='sudo nvim'
alias vis='nvim "+set si"'

fi




