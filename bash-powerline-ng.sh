#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

__powerline() {
    # if there is no interactive terminal we don't need a fancy prompt, 
    # commit by @prof7bit
    tty -s || return

    # Colors
    FG_YELLOW='\[\033[33m\]'
    FG_RED='\[\033[0;31m\]'
    FG_DARKRED='\[\e[38;5;52m\]'
    FG_LIGHTWHITE="\[\e[38;5;250m\]"
    FG_GREY="\[\e[38;5;240m\]"
    FG_WHITE="\[\e[38;5;15m\]"
    FG_BLUE="\[\e[38;5;31m\]"
    FG_DARKGREY="\[\e[38;5;237m\]"

    BG_RED='\[\033[41m\]'
    BG_DARKRED='\[\e[48;5;52m\]'
    BG_GREY="\[\e[48;5;240m\]"
    BG_BLUE="\[\e[48;5;31m\]"
    BG_DARKGREY="\[\e[48;5;237m\]"

    BOLD='\[\033[1m\]'

    COLOR_RESET='\[\033[m\]'
    COLOR_CWD=${COLOR_CWD:-'\[\033[0;34m\]'} # blue
    COLOR_GIT=${COLOR_GIT:-'\[\033[0;36m\]'} # cyan
    COLOR_SUCCESS=${COLOR_SUCCESS:-'\[\033[0;32m\]'} # green
    COLOR_FAILURE=${COLOR_FAILURE:-'\[\033[0;31m\]'} # red

    # Symbols
    if [[ $TERM == linux ]]; then
        SYMBOL_GIT_BRANCH=${SYMBOL_GIT_BRANCH:-+}
        SYMBOL_GIT_MODIFIED=${SYMBOL_GIT_MODIFIED:-*}
        SYMBOL_GIT_PUSH=${SYMBOL_GIT_PUSH:-^}
        SYMBOL_GIT_PULL=${SYMBOL_GIT_PULL:-\\}
        SYMBOL_HOME_PATH=${SYMBOL_HOME_PATH:- \~}
        SYMBOL_ROOT_PATH=${SYMBOL_ROOT_PATH:- /}
        SYMBOL_PART_NEXT=${SYMBOL_PART_NEXT:->}
        SYMBOL_PATH_NEXT=${SYMBOL_PATH_NEXT:->}
    fi
    SYMBOL_GIT_BRANCH=${SYMBOL_GIT_BRANCH:-}
    SYMBOL_GIT_MODIFIED=${SYMBOL_GIT_MODIFIED:-*}
    SYMBOL_GIT_PUSH=${SYMBOL_GIT_PUSH:-⇡}
    SYMBOL_GIT_PULL=${SYMBOL_GIT_PULL:-⇣}
    SYMBOL_HOME_PATH=${SYMBOL_HOME_PATH:-🏠} # 🐈🐕★
    SYMBOL_ROOT_PATH=${SYMBOL_ROOT_PATH:-🖴 }
    SYMBOL_PART_NEXT=${SYMBOL_PART_NEXT:-🭬}
    SYMBOL_PATH_NEXT=${SYMBOL_PATH_NEXT:-⟩}
    SYMBOL_ERROR=${SYMBOL_ERROR:-💥}

#    if [[ -z "$PS_SYMBOL" ]]; then
#      case "$(uname)" in
#          Darwin)   PS_SYMBOL='';;
#          Linux)    PS_SYMBOL='$';; 🐧
#          *)        PS_SYMBOL='%';; 🗗
#      esac
#    fi

    __git_info() {
        [[ $POWERLINE_GIT = 0 ]] && return # disabled
        #hash git 2>/dev/null || return # git not found
        #[ -d .git ] || return
        local git_eng="env LANG=C git"   # force git output in English to make our work easier

        # get current branch name
        local ref=$($git_eng symbolic-ref --short HEAD 2>/dev/null)

        if [[ -n "$ref" ]]; then
            # prepend branch symbol
            ref="$SYMBOL_GIT_BRANCH $ref"
        else
            # get tag name or short unique hash
            ref=$($git_eng describe --tags --always 2>/dev/null)
        fi

        [[ -n "$ref" ]] || return  # not a git repo

        local marks

        # scan first two lines of output from `git status`
        while IFS= read -r line; do
            if [[ $line =~ ^## ]]; then # header line
                [[ $line =~ ahead\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PUSH${BASH_REMATCH[1]}"
                [[ $line =~ behind\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PULL${BASH_REMATCH[1]}"
            else # branch is modified if output contains more lines after the header line
                #marks="$SYMBOL_GIT_MODIFIED$marks"
                ref="$FG_YELLOW$ref"
                break
            fi
        done < <($git_eng status --porcelain --branch -uno 2>/dev/null)  # note the space between the two <
        [ -z $marks ] || ref="$FG_YELLOW$ref"

        # print the git branch segment without a trailing newline
        printf " $ref$marks"
    }

    ps1() {
        local RESULT=${?##0}

        # Check for root
        if [[ $EUID -eq 0 ]]; then
                PS1="${BOLD}${FG_WHITE}${BG_RED} \u ${FG_RED}"
        else
                PS1="${BOLD}${FG_WHITE}${BG_BLUE} \u ${FG_BLUE}"
        fi

        # Get git info
        local GIT_INFO=$(__git_info)
        PS1+="${GIT_INFO:+${BG_DARKGREY}${SYMBOL_PART_NEXT}${COLOR_RESET}${FG_LIGHTWHITE}${BG_DARKGREY}${GIT_INFO} ${FG_DARKGREY}}"
        PS1+="${BG_GREY}${SYMBOL_PART_NEXT}${COLOR_RESET}"

        # Check if PWD is writable and set color accordingly
        local PATH_COLOR=${FG_LIGHTWHITE}
        [ -w $PWD ] || PATH_COLOR=${FG_DARKRED}

        # Parse path
        local WD
        if [[ "$PWD" == ${HOME}* ]]; then
            WD=${PWD/$HOME/${SYMBOL_HOME_PATH}$BOLD}
            WD=${WD//\// ${FG_DARKGREY}${SYMBOL_PATH_NEXT}${PATH_COLOR} }
        else
            WD=${PWD//\// ${FG_DARKGREY}${SYMBOL_PATH_NEXT}${PATH_COLOR} }
            WD=${SYMBOL_ROOT_PATH}$BOLD${WD}
        fi
        PS1+="${PATH_COLOR}${BG_GREY}${WD} ${COLOR_RESET}${FG_GREY}"

        # Expand exit code of the previous command and display different
        # colors in the prompt accordingly.
        PS1+="${RESULT:+${BG_DARKRED}${SYMBOL_PART_NEXT}${FG_WHITE}${RESULT} ${COLOR_RESET}${FG_DARKRED}}"

        # Finalize PS1
        PS1+="${SYMBOL_PART_NEXT}${COLOR_RESET}"
    }

    PROMPT_COMMAND="ps1" #${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

__powerline
unset __powerline
