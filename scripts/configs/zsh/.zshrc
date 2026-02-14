#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          zshrc_kali_with_zinit.sh
# Created:       Wednesday, 28 January 2026 - 11:14 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:          
# Description:   .zshrc file inspired by Kali-linux default zsh prompt with dual prompt:
#                   1. in GUI -> zinit with p10k prompt
#                   2. in NON-GUI -> default kali prompt with 2 lines 
#--------------------------------------------------------------------------------

# .zshrc file with zinit for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

################################################################################
#                              PATH CONFIGURATION                              #
################################################################################

# Add user's private bin directory to PATH if it exists
if [ -d "$HOME/.local/bin" ]; then PATH="$HOME/.local/bin:$PATH"; fi



################################################################################
#                              SHELL OPTIONS                                   #
################################################################################

setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form 'anything=expression'
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

# Don't consider certain characters (like forward slash) part of the word
WORDCHARS=${WORDCHARS//\/}

# Hide EOL sign ('%')
PROMPT_EOL_MARK=""

################################################################################
#                            KEY BINDINGS                                      #
################################################################################

bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action

################################################################################
#                         COMPLETION SYSTEM                                    #
################################################################################

autoload -Uz compinit
compinit -u -d ~/.cache/zcompdump   # -u flag ignores the 'insecure directories' warning
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

################################################################################
#                         HISTORY CONFIGURATION                                #
################################################################################

HISTFILE=~/.config/zsh/zsh_history
HISTSIZE=5000
SAVEHIST=$HISTSIZE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt appendhistory
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

################################################################################
#                            TIME FORMAT                                       #
################################################################################

TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

################################################################################
#                          CHROOT DETECTION                                    #
################################################################################
# Set variable identifying the chroot you work in (used in the prompt below)

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

################################################################################
#                      COLOR PROMPT CONFIGURATION                              #
################################################################################
# Set a fancy prompt (non-color, unless we know we "want" color)

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt

# Force color prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

################################################################################
#                        GIT SUPPORT & TIMER                                   #
################################################################################

# Load version control information for git branch display in prompt
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )

# Format the vcs_info_msg_0_ variable to show git branch in yellow
zstyle ':vcs_info:git:*' formats '%F{yellow}(%b)%f '

# Timer logic - tracks command execution time
zmodload zsh/datetime
function preexec() {
    timer=${timer:-$EPOCHREALTIME}
}

precmd() {
    # Print the previously configured title
    print -Pnr -- "$TERM_TITLE"

    # Print a new line before the prompt, but only if it is not the first line
    if [ "$NEWLINE_BEFORE_PROMPT" = yes ]; then
        if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi

    if [ $timer ]; then
        timer_show=$(printf "%.2fs" $(($EPOCHREALTIME - $timer)))
        unset timer
    fi
}

################################################################################
#                        PROMPT CONFIGURATION                                  #
################################################################################

# --- GUI Detection Helper ---
# A small helper function that returns true (exit 0) if a graphical desktop
# session is currently active. It checks three indicators, any one is enough:
#   1. $DISPLAY is set         → an X11 server is running
#   2. $WAYLAND_DISPLAY is set → a Wayland compositor is running
#   3. $XDG_SESSION_TYPE        # "x11" or "wayland" — the modern, reliable way
#   4. $XDG_CURRENT_DESKTOP     # "GNOME", "KDE", "XFCE", etc. — set only in GUI sessions
#   5. X11 socket files exist  → X11 is running but env vars may not be inherited
#   6. Wayland socket files    → same fallback for Wayland
# The double-underscore prefix (__) is a naming convention that signals this
# is an internal/private helper — not meant to be called by the user directly.

__has_gui() {
    # --- Environment variable checks (fast, no disk I/O) ---
    [[ -n "$DISPLAY" ]] && return 0                     # X11 env var
    [[ -n "$WAYLAND_DISPLAY" ]] && return 0             # Wayland env var
    [[ "$XDG_SESSION_TYPE" == x11 ]] && return 0        # Modern freedesktop: X11
    [[ "$XDG_SESSION_TYPE" == wayland ]] && return 0    # Modern freedesktop: Wayland
    [[ -n "$XDG_CURRENT_DESKTOP" ]] && return 0         # Desktop env is set (GNOME, KDE, etc.)

    # --- Socket file checks (fallback if env vars weren't inherited) ---
    ls /tmp/.X11-unix/X* >/dev/null 2>&1 && return 0   # X11 socket exists
    ls /run/user/*/wayland-* >/dev/null 2>&1 && return 0 # Wayland socket exists

    return 1  # No GUI detected
}

# Kali's prompt 
configure_prompt() {
    prompt_symbol=㉿
    # Skull emoji for root terminal
    #[ "$EUID" -eq 0 ] && prompt_symbol=💀
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.cyan)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{cyan}$)%b%F{reset} '
            # Right-side prompt with exit codes and background processes
            #RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
            ;;

        oneline)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{%(#.red.blue)}%n@%m%b%F{reset}:%B%F{%(#.blue.green)}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
        backtrack)
                PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{red}%n@%m%b%F{reset}:%B%F{blue}%~%b%F{reset}%(#.#.$) '
                RPROMPT=
                ;;
        esac
        unset prompt_symbol
    }

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

################################################################################
#              ZINIT PLUGIN MANAGER & POWERLEVEL10K SETUP                      #
################################################################################
# Checks if Zinit is installed in the system directory. If found, loads
# Zinit along with Powerlevel10k theme and git plugin snippet.
# Falls back to basic prompt if Zinit is not available.
################################################################################

# 1. Determine if Zinit directory exists in system path
#if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]] || ls /tmp/.X11-unix/X* >/dev/null 2>&1 || ls /run/user/*/wayland-* >/dev/null 2>&1; then
if __has_gui && [[ -d /etc/zsh/zshExtras/zinit ]]; then
    # GUI Mode 
    # load zinit only when you are in graphical interface
    # Override Zinit internals to use the shared system path
    export ZINIT_HOME="/etc/zsh/zshExtras/zinit/zinit.git"

    # Define the associative array ZINIT before sourcing to override default paths
    typeset -gA ZINIT
    ZINIT[HOME_DIR]="/etc/zsh/zshExtras/zinit"
    ZINIT[PLUGINS_DIR]="/etc/zsh/zshExtras/zinit/plugins"
    ZINIT[SNIPPETS_DIR]="/etc/zsh/zshExtras/zinit/snippets"
    ZINIT[COMPLETIONS_DIR]="/etc/zsh/zshExtras/zinit/completions"

    # 2. AUTO-INSTALL ZINIT
    if [ ! -d "$ZINIT_HOME" ]; then
        print -P "%F{33}▓▒░ %F{220}Installing Shared Zinit Manager...%f"
        mkdir -p "$(dirname $ZINIT_HOME)"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi

    source "${ZINIT_HOME}/zinit.zsh"

    # # Add in zsh plugins
    # zinit light zdharma-continuum/fast-syntax-highlighting 
    # zinit light zsh-users/zsh-completions
    # zinit light zsh-users/zsh-autosuggestions
    # zinit light Aloxaf/fzf-tab
    # zinit light jeffreytse/zsh-vi-mode

    # # Add in snippets
    zinit snippet OMZP::git
    # zinit snippet OMZP::sudo
    # zinit snippet OMZP::tmuxinator
    # zinit snippet OMZP::docker
    # zinit snippet OMZP::command-not-found


    # 4. POWERLEVEL10K SETUP
    zinit ice depth=1 nocd
    zinit light romkatv/powerlevel10k


    # CONDITIONAL LOAD: Prompt styles
    if [[ $UID -eq 0 ]]; then
        [[ ! -f "$XDG_CONFIG_HOME/zsh/.p10k-root.zsh" ]] || source "$XDG_CONFIG_HOME/zsh/.p10k-root.zsh"
        print -P "%F{1}                   WARNING: ROOT PRIVILEGES ACTIVE%f"
        alias rm='rm -i' cp='cp -i' mv='mv -i'
    else
        [[ ! -f "$XDG_CONFIG_HOME/zsh/.p10k-home.zsh" ]] || source "$XDG_CONFIG_HOME/zsh/.p10k-home.zsh"
    fi

else
    # Zinit not found - use basic prompt
    configure_prompt
fi

################################################################################
#                       SYNTAX HIGHLIGHTING                                    #
################################################################################
# Enables zsh-syntax-highlighting plugin if available and configures
# color schemes for various syntax elements
################################################################################

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1

    
#if [[ ! -n "$DISPLAY" || ! -n "$WAYLAND_DISPLAY" ]] || ! ls /tmp/.X11-unix/X* >/dev/null 2>&1 || ! ls /run/user/*/wayland-* >/dev/null 2>&1; then     
if [[ ! -d /etc/zsh/zshExtras/zinit ]]; then     
 # Not in a GUI Mode run configure_prompt
        configure_prompt
    fi


    # enable zsh-syntax-highlighting
    if [ -f /etc/zsh/zshExtras/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        . /etc/zsh/zshExtras/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
        ZSH_HIGHLIGHT_STYLES[default]=none
        ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=white,underline
        ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[global-alias]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[path]=bold
        ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[command-substitution]=none
        ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[process-substitution]=none
        ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[assign]=none
        ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
        ZSH_HIGHLIGHT_STYLES[named-fd]=none
        ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
        ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan
        ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
fi
unset color_prompt force_color_prompt

################################################################################
#                      PROMPT TOGGLE FUNCTION                                  #
################################################################################
# Function to toggle between oneline and twoline prompt styles
# Bound to Ctrl+P for quick switching
################################################################################

toggle_oneline_prompt(){
    if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
        PROMPT_ALTERNATIVE=twoline
    else
        PROMPT_ALTERNATIVE=oneline
    fi

#if [[ ! -n "$DISPLAY" || ! -n "$WAYLAND_DISPLAY" ]] || ! ls /tmp/.X11-unix/X* >/dev/null 2>&1 || ! ls /run/user/*/wayland-* >/dev/null 2>&1; then     
if [[ ! -d /etc/zsh/zshExtras/zinit ]]; then     
     # Not in a GUI Mode run configure_prompt
        configure_prompt
    fi

    zle reset-prompt
}
zle -N toggle_oneline_prompt
bindkey ^P toggle_oneline_prompt

################################################################################
#                          TERMINAL TITLE                                      #
################################################################################
# Set terminal title to user@host:dir for supported terminal emulators

case "$TERM" in
    xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
        TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
        ;;
    *)
        ;;
esac

################################################################################
#                    COLOR SUPPORT & DIRCOLORS                                 #
################################################################################
# Enable color support for ls, less, man pages, and add color aliases
################################################################################

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    # export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions
    export LS_COLORS="$LS_COLORS:ow=00;36:" # 00 is transparent background, 01 is for bold, and 36 is cyan
    #alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    # Colorize man pages
    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

################################################################################
#                          BASIC ALIASES                                       #
################################################################################

#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

# Quick shortcuts
alias c='clear'
alias q='exit'
alias ..='cd ..'

# Safe file operations with interactive prompts and verbose output
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'

# Color grep aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

################################################################################
#                      CONDITIONAL TOOL ALIASES                                #
################################################################################
# Aliases that depend on installed tools
################################################################################

# Neovim or Vim aliases
if [[ -x "$(command -v nvim)" ]]; then
    alias vi='nvim'
    alias vim='nvim'
    alias svi='sudo nvim'
    alias vis='nvim "+set si"'
elif [[ -x "$(command -v vim)" ]]; then
    alias vi='vim'
    alias svi='sudo vim'
    alias vis='vim "+set si"'
fi

# LSD (modern ls replacement) aliases
if [[ -x "$(command -v lsd)" ]]; then
    alias ls='lsd -F --group-dirs first'
    alias ll='lsd --all --header --long --group-dirs first'
    alias tree='lsd --tree'
fi

# xdg-open alias for opening files in default application
if [[ -x "$(command -v xdg-open)" ]]; then
    alias open='runfree xdg-open'
fi

# Evince PDF reader alias
if [[ -x "$(command -v evince)" ]]; then
    alias pdf='runfree evince'
fi

# Lazygit alias
# Link: https://github.com/jesseduffield/lazygit
if [[ -x "$(command -v lazygit)" ]]; then
    alias lg='lazygit'
fi

# FZF with preview using bat/batcat
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

# Get public IP address
if [[ -x "$(command -v curl)" ]]; then
    alias ipexternal="curl -s ifconfig.me && echo"
elif [[ -x "$(command -v wget)" ]]; then
    alias ipexternal="wget -qO- ifconfig.me && echo"
fi

################################################################################
#                          UTILITY FUNCTIONS                                   #
################################################################################

# Start a program but immediately disown it and detach it from the terminal
function runfree() {
    "$@" > /dev/null 2>&1 & disown
}

# Copy file with a progress bar using rsync or strace
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

################################################################################
#                        ZSH PLUGIN INTEGRATIONS                               #
################################################################################

# Enable auto-suggestions based on command history
if [ -f /etc/zsh/zshExtras/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /etc/zsh/zshExtras/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color to gray
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# Enable command-not-found suggestions if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

################################################################################
#                      ADDITIONAL CUSTOM SETTINGS                              #
################################################################################

# Import external aliases file if it exists
if [ -f /etc/zsh/zshExtras/aliases/aliases.zsh ]; then . /etc/zsh/zshExtras/aliases/aliases.zsh; fi

# Remove text copy/paste highlights
zle_highlight+=(paste:none)

################################################################################
#                         SHELL INTEGRATIONS                                   #
################################################################################

# Yazi terminal file explorer integration
# y shell wrapper that provides the ability to change the current working 
# directory when exiting yazi.
# Yazi portable
YAZI_DIR="/media/$USER/Storage/Apps/yazi"
# adding yazi portable to the path
[[ -d $YAZI_DIR ]] && PATH=$PATH:$YAZI_DIR
if [[ -x "$(command -v yazi)" ]]; then
    function yy() {
    # Create a local temp file in your Yazi folder instead of /tmp
    #local tmp="/media/ahmdhosni/Storage/Apps/yazi/yazi-cwd.tmp"
    local tmp="$YAZI_DIR/yazi-cwd.tmp"
    
    # Run the portable binary and force it to write the CWD to that file
    yazi "$@" --cwd-file="$tmp"
    
    # Read the file and change directory if it's different
    if [ -f "$tmp" ]; then
        local cwd="$(cat -- "$tmp")"
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
        fi
        #rm -f -- "$tmp"
    fi
    }


fi

# FZF key bindings and fuzzy completion
source <(fzf --zsh)

# Zoxide - smarter cd command that learns your habits
eval "$(zoxide init --cmd cd zsh)"
