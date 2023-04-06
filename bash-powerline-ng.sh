#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

__powerline() {
    # if there is no interactive terminal we don't need a fancy prompt, 
    # commit by @prof7bit
    tty -s || return

    # Colors
    FG_BLACK='\[\033[0;30m\]'
    FG_GREEN='\[\033[0;32m\]'
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
    SYMBOL_CAT=🐈
    SYMBOL_DOG=🐕

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
    SYMBOL_NET_PATH=${SYMBOL_NET_PATH:-🖧 }
    SYMBOL_HOME_PATH=${SYMBOL_HOME_PATH:-🏠}
    SYMBOL_ROOT_PATH=${SYMBOL_ROOT_PATH:-🖴 }
    SYMBOL_PART_NEXT=${SYMBOL_PART_NEXT:-🭬} # 
    SYMBOL_PATH_NEXT=${SYMBOL_PATH_NEXT:-⟩} # ❭〉 ⟩
    SYMBOL_ERROR=${SYMBOL_ERROR:-💥}

    # detect SSH connection (TODO: detect nfs mount)
    #if [[ ! -z $SSH_CONNECTION ]]; then
    if [[ `who am i` =~ \([0-9\.]+\)$ ]]; then
        SYMBOL_HOME_PATH=$SYMBOL_NET_PATH
        SYMBOL_ROOT_PATH=$SYMBOL_NET_PATH
    fi

    # celebrate international cat & dog days
    local DATE=`date +%m%d`
    [ "$DATE" -eq "0826" ] && SYMBOL_HOME_PATH=$SYMBOL_DOG
    [ "$DATE" -eq "0808" ] && SYMBOL_HOME_PATH=$SYMBOL_CAT

    __git_info() {
        [[ $POWERLINE_GIT = 0 ]] && return # disabled
        #hash git 2>/dev/null || return # git not found
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
        [[ -z $marks ]] || ref="$FG_YELLOW$ref"

        # print the git branch segment without a trailing newline
        printf " $ref$marks"
    }

    ps1() {
        local RESULT=${?##0}

        local PATH_FG=${FG_LIGHTWHITE}
        local PATH_BG=${BG_GREY}
        local USER_FG=${FG_BLUE}
        local PART_FG=${FG_GREY}

        # Check if PWD is writable and set color accordingly
        if [ ! -w $PWD ]; then
            PATH_FG=${FG_DARKRED}
            USER_FG=${FG_DARKRED}
        fi

        # Check for root
        if [[ $EUID -eq 0 ]]; then
            USER_FG=${FG_LIGHTWITE}
            PATH_BG=${BG_RED}
            PART_FG=${FG_RED}
        fi

        # Parse path
        local WD
        if [[ -z $SSH_CONNECTION ]] && [[ "$PWD" == ${HOME}* ]]; then
            WD=${PWD/$HOME/${USER_FG}${SYMBOL_HOME_PATH}}
            WD=${WD//\// ${FG_DARKGREY}${SYMBOL_PATH_NEXT}${PATH_FG} }
        else
            [[ "$PWD" != "/" ]] && WD=${PWD//\// ${FG_DARKGREY}${SYMBOL_PATH_NEXT}${PATH_FG} }
            WD=${USER_FG}${SYMBOL_ROOT_PATH}${WD}
        fi

        # Get git info
        local GIT_INFO=$(__git_info)

        # Add working directory & symbol (net/home/root)
        PS1="${PATH_FG}${PATH_BG} ${WD} ${COLOR_RESET}${PART_FG}"
        # Expand git info
        PS1+="${GIT_INFO:+${BG_DARKGREY}${SYMBOL_PART_NEXT}${COLOR_RESET}${FG_GREEN}${BG_DARKGREY}${GIT_INFO} ${COLOR_RESET}${FG_DARKGREY}}"
        # Expand exit code of the previous command
        PS1+="${RESULT:+${BG_DARKRED}${SYMBOL_PART_NEXT}${FG_LIGHTWHITE}${RESULT} ${COLOR_RESET}${FG_DARKRED}}"
        # Finalize PS1
        PS1+="${SYMBOL_PART_NEXT}${COLOR_RESET}"
    }

    PROMPT_COMMAND="ps1" #${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

__powerline
unset __powerline
