#!/bin/bash

################################################################################
# Script Runner V14 - Final Production Version
#
# CHANGES FROM V13:
# 1. Sudo password persistent ALWAYS (not just --all mode) - cleaned up at end
# 2. Simpler final screen with "Press any key to reboot" instead of countdown
#
# FEATURES:
# - Auto-resume ONLY when RUN_ALL=true
# - Complete cleanup removes ALL traces
# - Persistent sudo password (encrypted, always saved, cleaned at end)
# - Persistent statistics across reboots
# - Manual reboot trigger at end (press any key)
################################################################################

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color
BOLD='\033[1m'

# State files
STATE_FILE="$HOME/.script_runner_state"
STATS_FILE="$HOME/.script_runner_stats"
LOG_FILE="$HOME/script_runner.log"
RESUME_TRIGGER="/tmp/.script_runner_resume_trigger"
PERSISTENT_INFO="$HOME/.script_runner_info"

RUN_ALL="false"

################################################################################
# SHARED LIBRARY
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_FOLDER="$SCRIPT_DIR/scripts"
LIB="$SCRIPTS_FOLDER/libs/lib_functions.sh"

if [ ! -f "$LIB" ]; then
    echo -e "${RED}${BOLD}✗ ERROR:${NC} ${RED}lib_functions.sh not found at: $LIB${NC}"
    exit 1
fi

source "$LIB"

################################################################################
# LOGGING
################################################################################

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}${BOLD}✓ SUCCESS:${NC} ${GREEN}$1${NC}"
    log_message "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}${BOLD}✗ ERROR:${NC} ${RED}$1${NC}"
    log_message "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}${BOLD}ℹ INFO:${NC} ${CYAN}$1${NC}"
    log_message "INFO: $1"
}

print_warning() {
    echo -e "${ORANGE}${BOLD}⚠ WARNING:${NC} ${ORANGE}$1${NC}"
    log_message "WARNING: $1"
}

print_section() {
    clear
    echo ""
    echo -e "${MAGENTA}${BOLD}##################################################${NC}"
    echo -e "${MAGENTA}${BOLD}  $1                                              ${NC}"
    echo -e "${MAGENTA}${BOLD}##################################################${NC}"
    echo ""
}

################################################################################
# PERSISTENT SUDO PASSWORD (ALWAYS - unconditional)
################################################################################

sudo() {
    echo "$SUDO_PASS" | command sudo -S "$@" 2>/dev/null
}

# Load sudo password from persistent file
load_sudo_password() {
    if [ -f "$PERSISTENT_INFO" ]; then
        local encoded_pass=$(grep "^SUDO_PASS_ENCODED=" "$PERSISTENT_INFO" 2>/dev/null | cut -d= -f2-)
        if [ -n "$encoded_pass" ]; then
            SUDO_PASS=$(echo "$encoded_pass" | base64 -d 2>/dev/null)
            if [ -n "$SUDO_PASS" ]; then
                export SUDO_PASS
                print_info "Sudo password restored"
                return 0
            fi
        fi
    fi
    return 1
}

# Save sudo password to persistent file (base64 encoded)
save_sudo_password() {
    if [ -n "$SUDO_PASS" ] && [ -f "$PERSISTENT_INFO" ]; then
        local encoded_pass=$(echo -n "$SUDO_PASS" | base64)
        sed -i '/^SUDO_PASS_ENCODED=/d' "$PERSISTENT_INFO" 2>/dev/null
        echo "SUDO_PASS_ENCODED=$encoded_pass" >>"$PERSISTENT_INFO"
        chmod 600 "$PERSISTENT_INFO"
    fi
}

# Initialize sudo password
if [ -z "$SUDO_PASS" ]; then
    if ! load_sudo_password; then
        echo -e "${YELLOW}${BOLD}Please enter your password:${NC}"
        read -rsp "Password: " SUDO_PASS
        echo ""
        if ! echo "$SUDO_PASS" | command sudo -S -k true 2>/dev/null; then
            echo -e "${RED}${BOLD}✗ Incorrect password. Exiting.${NC}"
            exit 1
        fi
        export SUDO_PASS
        echo -e "${GREEN}✓ Password accepted${NC}"
    fi
fi

################################################################################
# SECURE FILE MODIFICATION
################################################################################

secure_sudo_append() {
    local content="$1"
    local target_file="$2"
    local temp_file=$(mktemp)

    echo "$content" >"$temp_file"
    echo "$SUDO_PASS" | command sudo -S bash -c "cat '$temp_file' >> '$target_file'" 2>/dev/null
    local result=$?
    rm -f "$temp_file"

    return $result
}

################################################################################
# PERSISTENT STATISTICS TRACKING
################################################################################

init_stats() {
    if [ ! -f "$STATS_FILE" ]; then
        cat >"$STATS_FILE" <<EOF
SUCCESSFUL=0
FAILED=0
SKIPPED=0
EOF
        chmod 600 "$STATS_FILE"
    fi
}

load_stats() {
    if [ -f "$STATS_FILE" ]; then
        source "$STATS_FILE"
    else
        SUCCESSFUL=0
        FAILED=0
        SKIPPED=0
    fi
}

update_stats() {
    local stat_name=$1
    load_stats

    case "$stat_name" in
    successful) SUCCESSFUL=$((SUCCESSFUL + 1)) ;;
    failed) FAILED=$((FAILED + 1)) ;;
    skipped) SKIPPED=$((SKIPPED + 1)) ;;
    esac

    cat >"$STATS_FILE" <<EOF
SUCCESSFUL=$SUCCESSFUL
FAILED=$FAILED
SKIPPED=$SKIPPED
EOF
    chmod 600 "$STATS_FILE"
}

################################################################################
# AUTO-RESUME SYSTEM (ONLY FOR RUN_ALL=true)
################################################################################

create_persistent_info() {
    cat >"$PERSISTENT_INFO" <<EOF
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$SCRIPT_DIR
USER=$USER
RUN_ALL=$RUN_ALL
EOF
    chmod 600 "$PERSISTENT_INFO"

    # ALWAYS save sudo password (unconditional - not just for RUN_ALL=true)
    save_sudo_password
}

create_resume_trigger() {
    create_persistent_info

    cat >"$RESUME_TRIGGER" <<EOF
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$SCRIPT_DIR
USER=$USER
RUN_ALL=$RUN_ALL
EOF
    chmod 600 "$RESUME_TRIGGER"
    print_success "Resume trigger created"
}

remove_resume_trigger() {
    [ -f "$RESUME_TRIGGER" ] && rm -f "$RESUME_TRIGGER"
    [ -f "$PERSISTENT_INFO" ] && rm -f "$PERSISTENT_INFO"
}

setup_autoresume() {
    local script_path="$(readlink -f "$0")"
    local profile_hook="$HOME/.script_runner_profile_hook"

    if [ ! -f "$STATE_FILE" ]; then
        return
    fi

    # ONLY setup auto-resume if RUN_ALL=true
    if [ "$RUN_ALL" != "true" ]; then
        # Still save sudo password even in interactive mode
        create_persistent_info
        print_info "Interactive mode: Auto-resume disabled (use --resume manually)"
        return
    fi

    print_info "Setting up auto-resume (--all mode only)..."

    create_resume_trigger

    cat >"$profile_hook" <<'PROFILE_EOF'
# Script Runner Auto-Resume Hook (--all mode only)
#
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color
BOLD='\033[1m'

STATE_FILE="$HOME/.script_runner_state"
PERSISTENT_INFO="$HOME/.script_runner_info"
RESUME_TRIGGER="/tmp/.script_runner_resume_trigger"

# Safety checks
if [ ! -f "$STATE_FILE" ]; then return 0; fi
if ! tty >/dev/null 2>&1; then return 0; fi
if [ -n "$DISPLAY" ] && [ -z "$TERM" ]; then return 0; fi
if [ "$USER" = "gdm" ] || [ "$USER" = "Debian-gdm" ]; then return 0; fi
if [ -n "$TMUX" ]; then return 0; fi
if [ -n "$SCRIPT_RUNNER_RESUME_SHOWN" ]; then return 0; fi

# Recreate trigger if missing
if [ ! -f "$RESUME_TRIGGER" ] && [ -f "$PERSISTENT_INFO" ]; then
    cp "$PERSISTENT_INFO" "$RESUME_TRIGGER"
    chmod 600 "$RESUME_TRIGGER"
fi

if [ ! -f "$RESUME_TRIGGER" ]; then return 0; fi

# Check RUN_ALL flag
source "$RESUME_TRIGGER" 2>/dev/null || return 0

if [ "$RUN_ALL" != "true" ]; then return 0; fi

export SCRIPT_RUNNER_RESUME_SHOWN=1

echo ""
echo -e "\033[1;33m╔════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;33m║  Script Runner: Auto-Resuming (--all mode)             ║\033[0m"
echo -e "\033[1;33m╚════════════════════════════════════════════════════════╝\033[0m"
echo ""

for i in {5..1}; do
            echo -ne "\r${CYAN} Resuming in $i seconds... (Ctrl+C to cancel)${NC}   "
            sleep 1
        done
        echo ""

#echo -e "\033[1;36mResuming in 3 seconds...\033[0m"
#echo ""

sleep 3
exec "$SCRIPT_PATH" --resume
PROFILE_EOF
    chmod 600 "$profile_hook"

    local user_zshrc="$HOME/.config/zsh/.zshrc"
    if [ -f "$user_zshrc" ]; then
        if ! grep -q "script_runner_profile_hook" "$user_zshrc" 2>/dev/null; then
            echo "" >>"$user_zshrc"
            echo "# Script Runner Auto-Resume Hook (--all mode only)" >>"$user_zshrc"
            echo "[ -f \"$profile_hook\" ] && source \"$profile_hook\"" >>"$user_zshrc"
            print_info "Added hook to .zshrc"
        fi
    fi

    local global_zshenv="/etc/zsh/zshenv"
    if [ -f "$global_zshenv" ] || [ -d "/etc/zsh" ]; then
        echo "$SUDO_PASS" | command sudo -S touch "$global_zshenv" 2>/dev/null

        if ! echo "$SUDO_PASS" | command sudo -S grep -q "script_runner_profile_hook" "$global_zshenv" 2>/dev/null; then
            local hook_content=$'\n# Script Runner Auto-Resume Hook (--all mode only)\n'"[ -f \"$profile_hook\" ] && source \"$profile_hook\""
            secure_sudo_append "$hook_content" "$global_zshenv"
            print_info "Added hook to /etc/zsh/zshenv"
        fi
    fi

    print_success "Auto-resume enabled (--all mode only)"
}

################################################################################
# COMPLETE CLEANUP
################################################################################

cleanup_autoresume() {
    local profile_hook="$HOME/.script_runner_profile_hook"

    print_info "Cleaning up auto-resume system..."

    [ -f "$profile_hook" ] && rm -f "$profile_hook"

    if [ -f "$HOME/.config/zsh/.zshrc" ]; then
        sed -i '/# Script Runner Auto-Resume Hook/,+1d' "$HOME/.config/zsh/.zshrc" 2>/dev/null
    fi

    if [ -f "/etc/zsh/zshenv" ]; then
        echo "$SUDO_PASS" | command sudo -S sed -i '/# Script Runner Auto-Resume Hook/,+1d' "/etc/zsh/zshenv" 2>/dev/null
    fi

    if [ -f "$HOME/.zprofile" ]; then
        if grep -q "script_runner_profile_hook" "$HOME/.zprofile" 2>/dev/null; then
            sed -i '/# Script Runner Auto-Resume Hook/,+1d' "$HOME/.zprofile" 2>/dev/null

            if [ ! -s "$HOME/.zprofile" ] || ! grep -q '[^[:space:]]' "$HOME/.zprofile" 2>/dev/null; then
                rm -f "$HOME/.zprofile"
            fi
        fi
    fi

    if [ -f "$HOME/.config/zsh/.zprofile" ]; then
        if grep -q "script_runner_profile_hook" "$HOME/.config/zsh/.zprofile" 2>/dev/null; then
            sed -i '/# Script Runner Auto-Resume Hook/,+1d' "$HOME/.config/zsh/.zprofile" 2>/dev/null

            if [ ! -s "$HOME/.config/zsh/.zprofile" ] || ! grep -q '[^[:space:]]' "$HOME/.config/zsh/.zprofile" 2>/dev/null; then
                rm -f "$HOME/.config/zsh/.zprofile"
            fi
        fi
    fi

    [ -f "$STATE_FILE" ] && rm -f "$STATE_FILE"
    [ -f "$STATS_FILE" ] && rm -f "$STATS_FILE"
    [ -f "$RESUME_TRIGGER" ] && rm -f "$RESUME_TRIGGER"

    # Remove persistent info (including encrypted sudo password)
    if [ -f "$PERSISTENT_INFO" ]; then
        rm -f "$PERSISTENT_INFO"
        print_info "Removed persistent info (sudo password erased)"
    fi

    print_success "Auto-resume cleanup complete"
}

################################################################################
# STATE MANAGEMENT
################################################################################

save_state() {
    local current_index=$1
    echo "$current_index" >"$STATE_FILE"
    echo "$RUN_ALL" >>"$STATE_FILE"
    log_message "State saved: index=$current_index, run_all=$RUN_ALL"
}

load_state() {
    if [ -f "$STATE_FILE" ]; then
        head -n 1 "$STATE_FILE"
    else
        echo "0"
    fi
}

load_run_all() {
    if [ -f "$STATE_FILE" ]; then
        sed -n '2p' "$STATE_FILE"
    else
        echo "false"
    fi
}

clear_state() {
    cleanup_autoresume
}

################################################################################
# USER INTERACTION
################################################################################

ask_install() {
    local script_name=$1
    echo -e "${CYAN}${BOLD}Do you want to run: ${YELLOW}$script_name${CYAN}?${NC}"
    echo -e "${CYAN}[y]es | [n]o | [a]uto run all | [q]uit | [c]lean quit${NC}"
    read -r response
    case "$response" in
    [yY]*) return 0 ;;
    [aA]*)
        RUN_ALL="true"
        print_info "Switched to auto-run mode"
        return 0
        ;;
    [cC]*) return 3 ;;
    [qQ]*) return 2 ;;
    *) return 1 ;;
    esac
}

################################################################################
# SCRIPT EXECUTION
################################################################################

execute_script() {
    local script_path=$1
    local run_as_root=$2
    local current_num=$3
    local total_num=$4
    local script_name=$(basename "$script_path")

    print_section "Executing: $script_name ($current_num/$total_num)"

    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi

    [ ! -x "$script_path" ] && chmod +x "$script_path"

    local start_time=$(date +%s)

    if [ "$run_as_root" = "true" ]; then
        print_info "Running as ROOT..."
        if sudo bash "$script_path"; then
            local duration=$(($(date +%s) - start_time))
            print_success "$script_name completed (${duration}s)"
            return 0
        else
            print_error "$script_name failed"
            return 1
        fi
    else
        print_info "Running as USER..."
        if bash "$script_path"; then
            local duration=$(($(date +%s) - start_time))
            print_success "$script_name completed (${duration}s)"
            return 0
        else
            print_error "$script_name failed"
            return 1
        fi
    fi
}

check_reboot() {
    [ -f /var/run/reboot-required ]
}

################################################################################
# REBOOT PROMPT
################################################################################

prompt_reboot() {
    print_warning "A reboot may be required!"

    print_info "Ensuring auto-resume hooks are in place..."
    setup_autoresume

    if [ "$RUN_ALL" = "true" ]; then
        print_info "AUTO MODE: Rebooting in 10 seconds..."
        print_info "Script will automatically resume after reboot"

        for i in {10..1}; do
            echo -ne "\r${YELLOW}${BOLD}Rebooting in $i seconds... (Ctrl+C to cancel)${NC}   "
            sleep 1
        done
        echo ""

        print_info "Rebooting now..."
        sudo reboot
    else
        echo ""
        echo -e "${YELLOW}${BOLD}Reboot now? [y/n]${NC}"
        read -r response

        if [[ "$response" =~ ^[yY]$ ]]; then
            print_info "Rebooting in 5 seconds..."
            print_warning "After reboot, run: $0 --resume"

            for i in {5..1}; do
                echo -ne "\r${YELLOW}${BOLD}Rebooting in $i seconds...${NC}   "
                sleep 1
            done
            echo ""

            print_info "Rebooting now..."
            sudo reboot
        else
            print_warning "Reboot skipped"
            print_info "When ready, run: $0 --resume"
        fi
    fi
}

################################################################################
# SCRIPT LOADING
################################################################################

load_scripts() {
    local scripts_array=()

    if [ ! -d "$SCRIPTS_FOLDER" ]; then
        echo -e "${RED}✗ ERROR: Scripts folder not found${NC}" >&2
        exit 1
    fi

    local config_file="$SCRIPTS_FOLDER/scripts.conf"

    if [ -f "$config_file" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            IFS='|' read -r script_name run_as_root description <<<"$line"
            [[ "$script_name" != /* ]] && script_name="$SCRIPTS_FOLDER/$script_name"
            scripts_array+=("$script_name|$run_as_root|$description")
        done <"$config_file"
    else
        while IFS= read -r script_file; do
            local script_path="$script_file"
            local script_name=$(basename "$script_file" .sh)
            local description=$(echo "$script_name" | sed 's/_/ /g; s/\b\(.\)/\u\1/g')
            scripts_array+=("$script_path|false|$description")
        done < <(find "$SCRIPTS_FOLDER" -maxdepth 1 -name "*.sh" -type f | sort)
    fi

    printf '%s\n' "${scripts_array[@]}"
}

print_info "Detecting scripts in: $SCRIPTS_FOLDER"
mapfile -t SCRIPTS < <(load_scripts)

if [ ${#SCRIPTS[@]} -eq 0 ]; then
    print_error "No scripts found"
    exit 1
fi

print_success "Loaded ${#SCRIPTS[@]} script(s)"

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    ensure_tmux || return 1
    if [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
        exec tmux new-session -s "runScript" -- "$0" "$@"
    fi

    print_section "Script Runner V14"
    print_info "Log: $LOG_FILE"
    echo ""

    init_stats

    local start_index=0
    if [ "$1" = "--resume" ]; then
        start_index=$(load_state)
        RUN_ALL=$(load_run_all)

        # Always try to load sudo password (not just in --all mode)
        load_sudo_password

        [ "$RUN_ALL" = "true" ] && print_info "Resuming in auto-run mode" || print_info "Resuming in interactive mode"
        print_info "Resuming from script index: $start_index"
    fi

    setup_autoresume

    local total_scripts=${#SCRIPTS[@]}

    for i in $(seq $start_index $((total_scripts - 1))); do
        IFS='|' read -r script_path run_as_root description <<<"${SCRIPTS[$i]}"

        if [ ! -f "$script_path" ]; then
            print_error "Script not found: $script_path"
            update_stats failed
            continue
        fi

        echo ""
        print_info "[$((i + 1))/$total_scripts] $description"
        print_info "Script: $script_path"
        print_info "Privilege: $([ "$run_as_root" = "true" ] && echo "ROOT" || echo "USER")"
        echo ""

        if [ "$RUN_ALL" = "true" ]; then
            print_info "Auto-running: $description"
            local choice=0
        else
            ask_install "$description"
            local choice=$?
        fi

        if [ $choice -eq 3 ]; then
            print_warning "Clean quit requested"
            clear_state
            print_success "Cleanup complete"
            exit 0
        elif [ $choice -eq 2 ]; then
            print_warning "Quit - state saved"
            save_state $i
            print_info "To resume: $0 --resume"
            exit 0
        elif [ $choice -eq 1 ]; then
            print_warning "Skipped"
            update_stats skipped
            continue
        fi

        save_state $i

        if execute_script "$script_path" "$run_as_root" "$((i + 1))" "$total_scripts"; then
            update_stats successful

            if check_reboot; then
                save_state $((i + 1))
                prompt_reboot
            fi
        else
            update_stats failed

            if [ "$RUN_ALL" = "true" ]; then
                print_warning "Continuing..."
            else
                echo ""
                echo -e "${RED}${BOLD}Continue? [y/n]${NC}"
                read -r response
                [[ ! "$response" =~ ^[yY]$ ]] && {
                    save_state $((i + 1))
                    exit 1
                }
            fi
        fi
    done

    # ========================================================================
    # FINAL SUMMARY - Old Simple Format
    # ========================================================================

    load_stats

    print_section "Installation Complete"
    echo -e "${GREEN}${BOLD}Successful:${NC} $SUCCESSFUL"
    echo -e "${YELLOW}${BOLD}Skipped:${NC} $SKIPPED"
    echo -e "${RED}${BOLD}Failed:${NC} $FAILED"
    echo ""
    print_success "All done! Check the log file for details: $LOG_FILE"
    echo ""

    # ========================================================================
    # CLEANUP
    # ========================================================================

    print_info "Cleaning up auto-resume system..."
    cleanup_autoresume

    # ========================================================================
    # FINAL REBOOT - Press Any Key
    # ========================================================================

    echo ""
    #read -n 1 -s -r -p "One Last Reboot required, Press any key to reboot..."
    read -n 1 -s -r -p "$(echo -e "${YELLOW}${BOLD}One Last Reboot required, Press any key to reboot...${NC}")"
    echo ""
    echo ""
    for i in {5..1}; do
        echo -ne "\r${YELLOW}${BOLD}Rebooting in $i seconds... (Ctrl+C to cancel)${NC}   "
        sleep 1
    done
    echo ""

    print_info "Rebooting now..."
    sudo reboot
}

################################################################################
# ENTRY POINT
################################################################################

case "$1" in
--resume) main --resume ;;
--all)
    RUN_ALL="true"
    main
    ;;
--reset)
    clear_state
    print_success "State cleared"
    ;;
--help)
    cat <<EOF
${BOLD}Script Runner V14${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    ${GREEN}(no args)${NC}  Interactive mode
    ${GREEN}--all${NC}      Auto-run all scripts
    ${GREEN}--resume${NC}   Resume from saved state
    ${GREEN}--reset${NC}    Clear state and cleanup
    ${GREEN}--help${NC}     Show this help

${BOLD}FEATURES:${NC}
  • Auto-resume only in --all mode
  • Complete cleanup
  • Persistent sudo (always, cleaned at end)
  • Persistent statistics
  • Press any key to reboot at end
EOF
    ;;
*) main ;;
esac
