#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:         .zshrc
# Created:      Tuesday, 20 January 2026 - 06:40 PM
# Modified:     Wednesday, 11 February 2026
# Author:       AhmdHosni (ahmdhosny@gmail.com)
# Link:         https://gist.github.com/noahbliss/4fec4f5fa2d2a2bc857cccc5d00b19b6
#               https://gitlab.com/kalilinux/packages/kali-defaults/-/blob/kali/master/etc/skel/.zshrc
# Description:  .zshrc file inspired by Kali-linux .zshrc with dual-mode prompt support:
#                 • GUI sessions  → Zinit plugin manager + Powerlevel10k theme
#                 • TTY sessions  → Kali's native configure_prompt() fallback
#--------------------------------------------------------------------------------
#
#  TABLE OF CONTENTS
#  ─────────────────
#   §1  Shell Options .................. Core setopt flags
#   §2  Word & Display Behavior ........ WORDCHARS, EOL mark
#   §3  Key Bindings ................... Emacs keymap + custom shortcuts
#   §4  Tab Completion System .......... compinit + zstyle rules
#   §5  Command History ................ HISTFILE, sizes, dedup options
#   §6  Time Format & Lesspipe ......... 'time' output format
#   §7  Prompt Configuration ........... The big section:
#       §7a  Chroot Detection
#       §7b  Color Support Detection
#       §7c  GUI Detection Helper (__has_gui)
#       §7d  Kali Fallback Prompt Function (configure_prompt)
#       §7e  Kali Config Variables
#       §7f  MODE BRANCH — Zinit+p10k (GUI) vs Kali prompt (TTY)
#   §8  Terminal Title & precmd Hook ... Window title + pre-prompt newline
#   §9  Color Support .................. ls, grep, diff, ip, man page colors
#   §10 Common Aliases ................. ll, la, l
#   §11 ZSH Plugins ................... Auto-suggestions, command-not-found
#
#--------------------------------------------------------------------------------


# .zshrc file with zinit for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples


# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then PATH="$HOME/.local/bin:$PATH"; fi



#================================================================================
#  SECTION 1: SHELL OPTIONS (setopt)
#--------------------------------------------------------------------------------
#  These options control the core behavior of the Zsh shell, such as how it
#  handles directory navigation, pattern matching, background jobs, and prompts.
#  Each 'setopt' enables a specific feature; 'unsetopt' or commenting out
#  disables it.
#================================================================================

setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt


#================================================================================
#  SECTION 2: WORD & DISPLAY BEHAVIOR
#--------------------------------------------------------------------------------
#  WORDCHARS defines which characters Zsh considers part of a "word" when using
#  keyboard shortcuts like Ctrl+W (delete word) or Ctrl+Left/Right (jump word).
#  Removing '/' from WORDCHARS means the shell treats path separators as word
#  boundaries, making it easier to navigate/edit filesystem paths.
#
#  PROMPT_EOL_MARK controls the character shown at the end of partial output
#  lines (lines not ending with a newline). Setting it to empty hides the
#  default '%' symbol that Zsh normally displays.
#================================================================================

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word
# hide EOL sign ('%')
PROMPT_EOL_MARK=""


#================================================================================
#  SECTION 3: KEY BINDINGS
#--------------------------------------------------------------------------------
#  These bindings map keyboard shortcuts to Zsh line-editor (ZLE) functions.
#  '-e' activates Emacs-style key bindings as the base keymap.
#  Each 'bindkey' maps a specific key sequence (identified by its terminal
#  escape code) to an editing action like moving the cursor, deleting text,
#  or navigating the command history buffer.
#================================================================================

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


#================================================================================
#  SECTION 4: TAB COMPLETION SYSTEM
#--------------------------------------------------------------------------------
#  Zsh's powerful completion system is initialized here with 'compinit'.
#  The 'zstyle' commands fine-tune its behavior:
#    - 'menu select'      : enables an interactive menu for multiple matches
#    - 'completer'        : defines the completion strategy (_expand then _complete)
#    - 'matcher-list'     : enables case-insensitive matching (a-z matches A-Z)
#    - 'rehash true'      : automatically finds new executables in $PATH
#    - 'use-compctl false': disables the legacy (pre-zstyle) completion system
#    - 'kill:*:command'   : customizes the process list shown for 'kill' completion
#  The dump file (~/.cache/zcompdump) caches completion data for faster startup.
#================================================================================

# enable completion features
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


#================================================================================
#  SECTION 5: COMMAND HISTORY
#--------------------------------------------------------------------------------
#  Controls how Zsh records, stores, and retrieves previously executed commands.
#    - HISTFILE   : path to the file where history is persisted across sessions
#    - HISTSIZE   : max number of history entries kept in memory (current session)
#    - SAVEHIST   : max number of history entries saved to HISTFILE on exit
#    - hist_expire_dups_first : when HISTFILE is full, remove duplicates first
#    - hist_ignore_dups       : don't record consecutive duplicate commands
#    - hist_ignore_space      : commands prefixed with a space are NOT recorded
#                               (useful for sensitive commands)
#    - hist_verify            : when using '!' history expansion, show the
#                               expanded command for review before executing
#  The alias overrides the default 'history' command to show ALL entries
#  (starting from index 0) instead of only the last few.
#================================================================================

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


#================================================================================
#  SECTION 6: TIME FORMAT & LESSPIPE
#--------------------------------------------------------------------------------
#  TIMEFMT customizes the output of the 'time' built-in command, which measures
#  how long a command takes to execute. The format shows:
#    real = wall-clock time, user = CPU in user mode,
#    sys  = CPU in kernel mode, cpu  = CPU usage percentage.
#
#  lesspipe (commented out) would allow 'less' to preview non-text files such
#  as compressed archives, images, and PDFs by piping them through converters.
#================================================================================

TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

#================================================================================
#  §7  PROMPT CONFIGURATION — Dual-Mode (GUI / TTY)
#================================================================================
#
#  OVERVIEW / DECISION FLOW
#  ────────────────────────
#  This is the heart of the shell's visual identity. Two completely different
#  prompt engines are supported, selected automatically at shell startup:
#
#    ┌─────────────────────────────────────────────────────────┐
#    │  Is a GUI session active (X11 / Wayland)?              │
#    │  AND does /usr/share/zsh/zshExtras/zinit exist?        │
#    │                                                        │
#    │   YES (both true)         NO (either false)            │
#    │   ┌───────────────┐       ┌────────────────────────┐   │
#    │   │ ZINIT + P10K  │       │ KALI FALLBACK PROMPT   │   │
#    │   │ • Rich glyphs │       │ • Box-drawing chars    │   │
#    │   │ • Git status  │       │ • 3 styles: twoline /  │   │
#    │   │ • Async       │       │   oneline / backtrack  │   │
#    │   │ • Root config │       │ • Ctrl+P toggle        │   │
#    │   │ • Home config │       │ • Syntax highlighting  │   │
#    │   └───────────────┘       └────────────────────────┘   │
#    └─────────────────────────────────────────────────────────┘
#
#  WHY TWO MODES?
#  Powerlevel10k requires a Nerd Font with special glyphs to render correctly.
#  Bare TTY consoles (Ctrl+Alt+F1..F6) have a fixed framebuffer font that
#  cannot display these glyphs, resulting in broken/garbled prompts.
#  The Kali fallback uses only basic Unicode box-drawing characters (┌└─)
#  that render correctly in any terminal, including bare TTYs.
#
#  EXECUTION ORDER
#  ───────────────
#  §7a  Chroot detection ............ detect Debian chroot environment
#  §7b  Color support detection ..... check if terminal supports color
#  §7c  __has_gui() ................. helper function: is a GUI active?
#  §7d  configure_prompt() .......... Kali prompt function (DEFINED here,
#                                     CALLED only in TTY mode)
#  §7e  Kali config variables ....... PROMPT_ALTERNATIVE, NEWLINE_BEFORE_PROMPT
#  §7f  MODE BRANCH ................. Zinit+p10k (GUI) vs fallback (TTY)
#
#================================================================================

# --- §7a. Chroot Detection ---
# Detects if you are inside a Debian chroot environment and stores the chroot
# name so it can be displayed in the prompt (e.g., "(mychroot)─").
# The variable is referenced inside PROMPT strings in both GUI and TTY modes.

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# --- §7b. Color Support Detection ---
# First checks if the terminal type ($TERM) is known to support color.
# Then, if force_color_prompt is enabled, uses 'tput' to verify that the
# terminal can actually render ANSI colors (Ecma-48 / ISO/IEC-6429).
# Result: color_prompt is set to 'yes' or left empty.
# This variable is used in §7f (TTY branch) to decide between colored
# and plain prompts.

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt


# Force color prompt:
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


# --- 7c. Prompt theme function ---
# --- §7c. GUI Detection Helper ---
# A small helper function that returns true (exit 0) if a graphical desktop
# session is currently active. It checks three indicators, any one is enough:
#   1. $DISPLAY is set         → an X11 server is running
#   2. $WAYLAND_DISPLAY is set → a Wayland compositor is running
#   3. X11 socket files exist  → X11 is running but env vars may not be inherited
#   4. Wayland socket files    → same fallback for Wayland
# The double-underscore prefix (__) is a naming convention that signals this
# is an internal/private helper — not meant to be called by the user directly.

__has_gui() {
    [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]] \
        || ls /tmp/.X11-unix/X* >/dev/null 2>&1 \
        || ls /run/user/*/wayland-* >/dev/null 2>&1
}

# --- §7d. Kali Fallback Prompt Function ---
# Defined GLOBALLY so it is always available (e.g., for toggle_oneline_prompt),
# but only CALLED in the TTY/fallback branch (§7f else-block).
#
# Provides three prompt styles controlled by the PROMPT_ALTERNATIVE variable:
#
#   twoline (default):
#     ┌──(user㉿host)-[~/current/path]
#     └─$
#     The signature Kali two-line prompt with box-drawing characters.
#     Uses green for regular users, blue/red for root.
#
#   oneline:
#     user@host:~/current/path$
#     A compact single-line prompt. Toggled via Ctrl+P.
#
#   backtrack:
#     user@host:~/current/path$
#     Similar to oneline but with a red username for visual emphasis.
#
# All styles include debian_chroot and Python virtualenv indicators when active.
# The %(6~.%-1~/…/%4~.%5~) notation truncates long paths: if the path has 6+
# components, it shows the first component, "…", and the last 4 components.


# configure prompt 
configure_prompt() {
    prompt_symbol=㉿
    # Skull emoji for root terminal
    #[ "$EUID" -eq 0 ] && prompt_symbol=💀
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.cyan)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{green}$)%b%F{reset} '
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




# --- §7e. Kali Config Variables (DO NOT modify the delimiter comments) ---
# These variables are read/written by Kali's configuration tools (kali-tweaks).
# The START/STOP delimiters are markers that those tools search for — moving
# or modifying them will break automatic configuration updates.
#   PROMPT_ALTERNATIVE   : selects the active prompt style (twoline/oneline/backtrack)
#   NEWLINE_BEFORE_PROMPT: prints a blank line before each prompt for readability

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES


# --- §7f. MODE BRANCH — Zinit + Powerlevel10k (GUI) vs Kali Prompt (TTY) ---
#
# This is the central decision point. Both conditions must be true for GUI mode:
#   1. __has_gui()  → a graphical session (X11 or Wayland) is active
#   2. The Zinit installation directory exists on disk
#
# If either condition fails, we fall through to the TTY/fallback branch which
# uses the Kali-native configure_prompt() with optional syntax highlighting.

if __has_gui && [[ -d /usr/share/zsh/zshExtras/zinit ]]; then
    #────────────────────────────────────────────────────────────────────────
    #  GUI MODE — Zinit Plugin Manager + Powerlevel10k Theme
    #────────────────────────────────────────────────────────────────────────
    #  Zinit is a fast, flexible Zsh plugin manager. Here it is configured
    #  to use a shared system-wide installation under /usr/share/zsh/zshExtras
    #  rather than the default ~/.local/share/zinit, so all users on the
    #  system share the same plugin binaries (saves disk and update effort).
    #────────────────────────────────────────────────────────────────────────

    # Override Zinit paths to point to the shared system installation.
    # ZINIT_HOME    : path to the zinit.git repository itself
    # ZINIT[]       : associative array controlling where Zinit stores plugins,
    #                 snippets, and completions
    export ZINIT_HOME="/usr/share/zsh/zshExtras/zinit/zinit.git"
    typeset -gA ZINIT
    ZINIT[HOME_DIR]="/usr/share/zsh/zshExtras/zinit"
    ZINIT[PLUGINS_DIR]="/usr/share/zsh/zshExtras/zinit/plugins"
    ZINIT[SNIPPETS_DIR]="/usr/share/zsh/zshExtras/zinit/snippets"
    ZINIT[COMPLETIONS_DIR]="/usr/share/zsh/zshExtras/zinit/completions"

    # Auto-install: if the Zinit repo directory doesn't exist yet, clone it.
    # This makes first-time setup fully automatic — just open a terminal.
    if [[ ! -d "$ZINIT_HOME" ]]; then
        print -P "%F{33}▓▒░ %F{220}Installing Shared Zinit Manager...%f"
        mkdir -p "$(dirname $ZINIT_HOME)"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi

    # Source Zinit to make the 'zinit' command available
    source "${ZINIT_HOME}/zinit.zsh"

    # --- Zinit Plugins (uncomment to enable) ---
    # Each 'zinit light' loads a plugin in "turbo" mode (fast, no reporting).
    # fast-syntax-highlighting : real-time command colorization (replaces §7f's zsh-syntax-highlighting)
    # zsh-completions          : additional completion definitions for hundreds of tools
    # zsh-autosuggestions      : fish-like greyed-out suggestions from history
    # fzf-tab                  : replaces Zsh's completion menu with fzf (fuzzy finder)
    # zsh-vi-mode              : vim-style keybindings (replaces the Emacs keymap from §3)
    # zinit light zdharma-continuum/fast-syntax-highlighting
    # zinit light zsh-users/zsh-completions
    # zinit light zsh-users/zsh-autosuggestions
    # zinit light Aloxaf/fzf-tab
    # zinit light jeffreytse/zsh-vi-mode

    # --- Oh-My-Zsh Snippets ---
    # 'zinit snippet OMZP::' loads individual Oh-My-Zsh plugins without the
    # full OMZ framework overhead. Only the git plugin is active by default.
    zinit snippet OMZP::git
    # zinit snippet OMZP::sudo
    # zinit snippet OMZP::tmuxinator
    # zinit snippet OMZP::docker
    # zinit snippet OMZP::command-not-found

    # --- Powerlevel10k Theme ---
    # depth=1 : shallow git clone (faster install, less disk)
    # nocd    : don't change directory during load (avoids side effects)
    # p10k is configured via separate config files loaded below.
    zinit ice depth=1 nocd
    zinit light romkatv/powerlevel10k

    # --- p10k Config: Root vs Regular User ---
    # Different p10k configuration files allow distinct visual styles:
    #   • Root  (.p10k-root.zsh) : typically shows a more prominent/warning style
    #   • Home  (.p10k-home.zsh) : the standard user prompt style
    # These files are generated by running 'p10k configure' and then renamed/moved.
    # The root branch also:
    #   • Prints a red WARNING banner as a visual reminder of elevated privileges
    #   • Aliases rm/cp/mv with '-i' (interactive) to require confirmation before
    #     overwriting or deleting files — a safety net against accidental destruction
    if [[ $UID -eq 0 ]]; then
        [[ -f "$XDG_CONFIG_HOME/zsh/.p10k-root.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/.p10k-root.zsh"
        print -P "%F{1}                   WARNING: ROOT PRIVILEGES ACTIVE%f"
        alias rm='rm -i' cp='cp -i' mv='mv -i'
    else
        [[ -f "$XDG_CONFIG_HOME/zsh/.p10k-home.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/.p10k-home.zsh"
    fi

else
    #────────────────────────────────────────────────────────────────────────
    #  TTY / NO-ZINIT MODE — Kali-Native Fallback Prompt
    #────────────────────────────────────────────────────────────────────────
    #  This branch activates when either:
    #    • No GUI session is detected (bare TTY console, e.g., Ctrl+Alt+F1)
    #    • The Zinit installation directory is missing
    #  It uses the Kali-native configure_prompt() defined in §7d, along with
    #  zsh-syntax-highlighting for command colorization.
    #────────────────────────────────────────────────────────────────────────

    if [ "$color_prompt" = yes ]; then
        # Disable Python's default "(venv)" indicator — the prompt handles it
        VIRTUAL_ENV_DISABLE_PROMPT=1

        # Activate the Kali prompt (reads PROMPT_ALTERNATIVE from §7e)
        configure_prompt

        # --- Zsh Syntax Highlighting (TTY-mode colorization) ---
        # In GUI mode, Zinit plugins handle syntax highlighting instead.
        # This block loads the system-installed zsh-syntax-highlighting and
        # applies a comprehensive custom color theme for different token types.
        if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
            . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

            # --- Token type colors ---
            ZSH_HIGHLIGHT_STYLES[default]=none
            ZSH_HIGHLIGHT_STYLES[unknown-token]=underline
            ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
            ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
            ZSH_HIGHLIGHT_STYLES[global-alias]=fg=green,bold
            ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
            ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
            ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline

            # --- Path colors ---
            ZSH_HIGHLIGHT_STYLES[path]=bold
            ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
            ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=

            # --- Globbing & history expansion colors ---
            ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
            ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold

            # --- Substitution colors ---
            ZSH_HIGHLIGHT_STYLES[command-substitution]=none
            ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
            ZSH_HIGHLIGHT_STYLES[process-substitution]=none
            ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold

            # --- Option colors (single-dash and double-dash flags) ---
            ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
            ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green

            # --- Quoting & argument colors ---
            ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
            ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
            ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
            ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
            ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
            ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
            ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
            ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
            ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold

            # --- Miscellaneous token colors ---
            ZSH_HIGHLIGHT_STYLES[assign]=none
            ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
            ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
            ZSH_HIGHLIGHT_STYLES[named-fd]=none
            ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
            ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan

            # --- Bracket matching colors (nested bracket depth) ---
            ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
            ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
            ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
            ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
            ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
            ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
            ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
        fi
    else
        # No color support — use a minimal uncolored prompt
        PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
    fi
    unset color_prompt force_color_prompt

    # --- Prompt Toggle Widget (Ctrl+P) — TTY mode only ---
    # Registers a ZLE (Zsh Line Editor) widget that toggles between 'twoline'
    # and 'oneline' prompt styles on the fly by pressing Ctrl+P.
    # This only makes sense in TTY mode — in GUI mode, Powerlevel10k manages
    # the prompt entirely and toggling would conflict with it.
    toggle_oneline_prompt(){
        if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
            PROMPT_ALTERNATIVE=twoline
        else
            PROMPT_ALTERNATIVE=oneline
        fi
        configure_prompt
        zle reset-prompt
    }
    zle -N toggle_oneline_prompt
    bindkey ^P toggle_oneline_prompt
fi


#================================================================================
#  §8  TERMINAL TITLE & precmd HOOK
#--------------------------------------------------------------------------------
#  Sets the terminal window/tab title to "user@host: ~/current/path" for
#  supported terminal emulators (xterm, rxvt, alacritty, gnome-terminal, etc.).
#  Unsupported terminals (bare TTY, screen, etc.) are silently skipped.
#
#  The precmd() function is a special Zsh hook that runs BEFORE each prompt
#  is displayed. It:
#    1. Updates the terminal title with the latest working directory.
#    2. Prints a blank line before the prompt (for visual breathing room),
#       but skips the blank line on the very first prompt of the session
#       so there's no awkward gap at the top of a fresh terminal.
#
#  NOTE: This runs in BOTH GUI and TTY modes. In GUI mode, Powerlevel10k
#  adds its own precmd hooks via Zsh's add-zsh-hook mechanism — they coexist
#  without conflict because Zsh supports multiple precmd functions.
#================================================================================

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
*)
    ;;
esac

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
}


#================================================================================
#  §9  COLOR SUPPORT — ls, grep, diff, ip, less, man pages
#--------------------------------------------------------------------------------
#  If 'dircolors' is available, this block enables colorized output for many
#  common commands via aliases and environment variables:
#    - LS_COLORS       : colorizes 'ls' output by file type/extension
#    - grep/fgrep/egrep: highlights matching patterns in color
#    - diff            : colorized file comparison output
#    - ip              : colorized network interface information
#    - LESS_TERMCAP_*  : adds color to man pages viewed in 'less'
#        mb = blink, md = bold, me = reset bold/blink
#        so = standout (reverse video), se = end standout
#        us = underline, ue = end underline
#    - Completion colors are also tied to LS_COLORS so tab-completion menus
#      show file types in matching colors.
#
#  This block runs in BOTH GUI and TTY modes — colorized ls/grep/man output
#  is useful regardless of which prompt engine is active.
#================================================================================

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

#================================================================================
#  §10 ALIASES AND COOL FUNCTIONS 
#--------------------------------------------------------------------------------
#  Shorthand aliases for frequently used 'ls' variations:
#    ll = long listing format (detailed file info: permissions, owner, size, date)
#    la = list all files including hidden ones (except . and ..)
#    l  = compact multi-column listing with file type indicators (/ for dirs, etc.)
#================================================================================
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

alias c='clear'
alias q='exit'
alias ..='cd ..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Alias for neovim
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

# Alias for lsd
if [[ -x "$(command -v lsd)" ]]; then
    alias ls='lsd -F --group-dirs first'
    alias ll='lsd --all --header --long --group-dirs first'
    alias tree='lsd --tree'
fi

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
# COOL FUNCTIONS:
#####################

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

#================================================================================
#  §11  ZSH PLUGINS — Auto-suggestions & Command-Not-Found
#--------------------------------------------------------------------------------
#  These system-installed plugins are loaded in BOTH GUI and TTY modes.
#  In GUI mode, if you uncomment the equivalent Zinit plugins (§7f), those
#  will take priority — but having these as fallbacks does no harm.
#
#  §11a. ZSH-AUTOSUGGESTIONS
#        Suggests commands as you type based on your command history, shown in
#        a dimmed gray color (#999). Press the right arrow key to accept a
#        suggestion. Install the package: apt install zsh-autosuggestions
#
#  §11b. COMMAND-NOT-FOUND
#        When you type a command that doesn't exist, this handler queries the
#        package database and suggests which package provides it
#        (e.g., "apt install <package>").
#        Install the package: apt install command-not-found
#================================================================================

# --- §11a. Auto-suggestions based on history ---
##############################################
# enable auto-suggestions based on the history
# ############################################

if [ -f /usr/share/zsh/zshExtras/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh/zshExtras/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi


# --- $11b. Command-not-found handler ---
#######################################
# enable command-not-found if installed
# #####################################

if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi




######################
# $12. More Custom settings 
######################

 # importing aliases file
 if [ -f /usr/share/zsh/zshExtras/aliases/aliases.zsh ]; then . /usr/share/zsh/zshExtras/aliases/aliases.zsh; fi

# removing text copy/paste highlights
zle_highlight+=(paste:none)


####################
# Shell integrations
####################

# If yazi terminal file explorer is installed 
# y shell wrapper that provides the ability to change the current working directory when exiting yazi.
if [[ -x "$(command -v yazi)" ]]; then
    function y() {
        local tmp="$(mktemp -t "yazi-cwd.xxxxxx")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$pwd" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }

fi


# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Zoxide config for zsh plugins 
eval "$(zoxide init --cmd cd zsh)"




