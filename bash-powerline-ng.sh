#!/usr/bin/bash

## To disable functionality, either uncomment, or pass the var on the `source`
## command, or export it if/when needed.
#POWERLINE_GIT=${POWERLINE_GIT:-0}                       # disable git parsing
#POWERLINE_CRUMBS=${POWERLINE_CRUMBS:-0}                 # disable crumbs in path names
POWERLINE_HOST=${POWERLINE_HOST:-0}                      # disable hostname display

## Settings can be overidden from user env or here
PL_THEME=${PL_THEME:-default}       # default theme
PL_COLORS=${PL_COLORS:-default}     # default color scheme

# list of themes and their symbols (separated by pipe '|') (spaces included).
# format = HOST | NETWORK | FOLDER | CRUMB | PART_START | PART_NEXT | PART_END
declare -A __powerline_themes=(
    [default]=" |🖧 | |||| "
      [arrow]=" |🖧 | |||| "
      [slant]="💻︎|🖧 | | | | |  "
       [diag]="💻︎|🖧 | | | | |  "
       [soft]=" |🖧 | |⟩|🭬|🭬|🭬"
      [round]=" |🖧 | || || "
)

# list of colors (color names separated by space ' ')
# format =       default      successs       warn           fail          hostname      folder_icon     path            crumbs          git             path:r
declare -A __powerline_colors=(
      [default]="LightGrey    SpringGreen3   tan3           DarkRed       SteelBlue     DeepSkyBlue1    grey36          grey22          grey22          DarkRed"
    [solarized]="black        lime           black          red1          orange1       magenta3        violet          HotPink2        cyan3           grey37"
#      [dracula]="grey25       SeaGreen3      DarkOrange3    red3          DeepPink3     gold3           SeaGreen3       SkyBlue3        SlateBlue3      DarkRed"
      [gruvbox]="yellow3      DarkOliveGreen gold4          red1          red4          gold1           SlateBlue3      SlateBlue1      cyan3           DarkRed"
         [nord]="DeepSkyBlue4 CadetBlue3     DeepSkyBlue4   MediumPurple3 LightSkyBlue3 MediumPurple3   LightSteelBlue3 SteelBlue2      SkyBlue2        DarkRed"
#      [monokai]="SlateBlue3   Chartreuse2    DarkGoldenrod3 red3          DarkRed       DarkSeaGreen3   DarkCyan        SlateBlue3      grey37          DarkRed"
        [ocean]="RoyalBlue4   DodgerGreen1   chocolate4     red3          DodgerBlue1   SkyBlue4        SlateGray3      SlateGray4      LightCyan4      DarkRed"
       [forest]="sienna       yellow1        goldenrod1     firebrick3    chartreuse3   SpringGreen4    DarkOliveGreen3 DarkOliveGreen2 DarkOliveGreen4 DarkRed"
       [sunset]="brown4       OrangeRed3     grey32         firebrick1    coral3        red3            goldenrod3      orange2         LightGoldenrod3 DarkRed"
)

# desc:   setup PS1 with fancy prompt
# output: a new PS1
__powerline() {
    # uncomment if you wish to see a marker for modified git
    #symbol_git_modified=*
    symbol_git_branch=
    symbol_git_push=⇡
    symbol_git_pull=⇣

    color_reset='\001\e[0m\002'
    color_invert='\001\e[7m\002'

    host_name=$(hostname)

    pl_colors ${PL_COLORS}
    pl_theme ${PL_THEME}

    PROMPT_COMMAND="ps1"
}

# desc:   retrieve rgb color (by name) from showrgb and set terminal color
# input:  $1 = color name (eg, "blue") (case sensative)
# output: escape code with corresponding rgb values
pl_rgb() {
    (set $(showrgb|grep $'\t'"${1}$"||echo 0); echo -en "\001\e[38;2;$1;$2;$3m\002")
}

# desc:   retrieve rgb color (by name) from showrgb and set terminal bg color
# input:  $1 = bg color name (eg, "DarkGrey") (case sensative)
# output: escape code with corresponding rgb values
pl_rgb_bg() {
    (set $(showrgb|grep $'\t'"${1}$"||echo 0); echo -en "\001\e[48;2;$1;$2;$3m\002")
}

# desc:   setup symbol variables from selected theme
# input:  $1 = string containing theme symbols separated by pipe '|'
#              (eg, " |🖧 | | | | ")
# output: symbol_ variables propagated
pl_theme() {
    IFS='|' read -r       \
        symbol_host       \
        symbol_network    \
        symbol_folder     \
        symbol_crumb      \
        symbol_part_start \
        symbol_part_next  \
        symbol_part_end   \
        <<< "${__powerline_themes[$1]}"

    system_symbol=${symbol_host}
    # detect SSH connection (TODO: detect nfs mount)
    if [[ ! -z ${SSH_CONNECTION} ]]; then  # [[ `who am i` =~ \([0-9\.]+\)$ ]]
        system_symbol=${symbol_network}
    fi

    # invert color for symbol_part_start if needed
    if [[ "$symbol_part_end" =~ "$symbol_part_start" ]]; then
        symbol_part_start=${color_invert}${symbol_part_start}${color_reset}
    fi
    PL_THEME=$1
}

# desc:   setup colors from selected color scheme
# input:  $1 = string containing list of colors separated by space ' '
#              (eg. "color1 color2 color3")
# output: color_ variables propagated
pl_colors() {
    read -a colors <<< ${__powerline_colors[$1]}

         color_default=$(pl_rgb    ${colors[0]})
         color_success=$(pl_rgb    ${colors[1]})
         color_warning=$(pl_rgb    ${colors[2]})
         color_failure=$(pl_rgb    ${colors[3]})
       color_bg_result=$(pl_rgb_bg ${colors[3]})
            color_host=$(pl_rgb    ${colors[4]})
         color_bg_host=$(pl_rgb_bg ${colors[4]})
            color_icon=$(pl_rgb    ${colors[5]})
         color_bg_icon=$(pl_rgb_bg ${colors[5]})
           color_crumb=$(pl_rgb    ${colors[7]})
             color_git=$(pl_rgb    ${colors[8]})
          color_bg_git=$(pl_rgb_bg ${colors[8]})

    # setup colors according to user or root
    if [[ ${EUID} -ne 0 ]]; then
         color_bg_path=$(pl_rgb_bg ${colors[6]})
            color_path=$(pl_rgb    ${colors[6]})
    else
         color_bg_path=$(pl_rgb_bg ${colors[9]})
            color_path=$(pl_rgb    ${colors[9]})
    fi

    unset colors
    PL_COLORS=$1
}

# desc:   populate git_info if git info found
# output: git_info variable propagated
__git_info() {
    # check if git functionality is disabled
    [[ ${POWERLINE_GIT} = 0 ]] && return

    # check for .git directory in parent dirs (it's faster than running git)
    local dir=$PWD
    while [[ -n "$dir" ]]; do
        [[ -d $dir/.git ]] && break
        dir="${dir%/*}"
    done
    [[ ! -n $dir ]] && [[ ! -d /.git ]] && return

    # check if 'git' command exists
    #command git 2>/dev/null || return # git not found

    # force git output in English to make our work easier
    local git_eng="env LANG=C git"

    # get current branch name
    local ref=$(${git_eng} symbolic-ref --short HEAD 2>/dev/null)

    if [[ -n "${ref}" ]]; then
        # prepend branch symbol
        ref="${symbol_git_branch} ${ref}"
    else
        # get tag name or short unique hash
        ref=$(${git_eng} describe --tags --always 2>/dev/null)
    fi

    [[ -n "${ref}" ]] || return  # not a git repo

    local marks

    # scan first two lines of output from `git status`
    while IFS= read -r line; do
        if [[ ${line} =~ ^## ]]; then # header line
            [[ ${line} =~ ahead\ ([0-9]+) ]] && \
                marks+=" ${symbol_git_push}$(echo ${BASH_REMATCH[1]} | \
                    sed 'y/0123456789/₀₁₂₃₄₅₆₇₈₉/')"
            [[ ${line} =~ behind\ ([0-9]+) ]] && \
                marks+=" ${symbol_git_pull}$(echo ${BASH_REMATCH[1]} | \
                    sed 'y/0123456789/⁰¹²³⁴⁵⁶⁷⁸⁹/')"
        else
            # branch is modified if output contains lines after header
            marks="${symbol_git_modified}${marks}"
            ref="${color_warning}${ref}"
            break
        fi
    # loop while reading git result (note the space between the two <)
    done < <(${git_eng} status --porcelain --branch -uno 2>/dev/null)
    [[ -z ${marks} ]] || ref="${color_warning}${ref}"

    # print the git branch segment without a trailing newline
    printf " ${color_success}${ref}${marks}"
}

ps1() {
    # remeber last command result
    local last_cmd_result=${?##0}

    # Get git info
    local git_info=$(__git_info)

    local crumb=${color_crumb}${symbol_crumb}${color_default}

    local wd folder_prefix
    # Check if PWD is writable and set color accordingly
    if [[ -w ${PWD} ]]; then
        folder_prefix=${color_icon}${symbol_folder}
    else
        folder_prefix=${color_failure}${symbol_folder}
    fi

    # Parse path
    if [[ "${PWD}" == ${HOME}* ]]; then
        # replace occurrences of $HOME in $PWD with ~
        wd="${PWD/${HOME}/\~}"
        # make crumbs from path if needed
        [[ ${POWERLINE_CRUMBS} = 0 ]] || wd="${wd//\// ${crumb} }"
    else
        wd="${PWD}"
        if [[ "${PWD}" != "/" ]]; then
            # make crumbs from path if needed
            [[ ${POWERLINE_CRUMBS} = 0 ]] || wd="/${PWD//\// ${crumb} }"
        fi
    fi

    # Add system info if exists
    if [[ ${POWERLINE_HOST} = 0 ]]; then
        # Add local/remote symbol
        PS1="${color_path}${symbol_part_start}${color_bg_path} ${folder_prefix}"
    else
        PS1="${color_host}${symbol_part_start}${color_bg_host} ${color_default}"\
"${system_symbol} ${host_name} ${color_bg_path}"
        PS1+="${color_host}${symbol_part_next}${color_bg_path} ${folder_prefix}"
    fi

    # Add Wordking directory
    PS1+="${color_default} ${wd} ${color_reset}${color_path}"

    # Expand git info if we have any
    PS1+="${git_info:+${color_bg_git}${symbol_part_next}${git_info} "\
"${color_reset}${color_git}}"

    # Expand last command result (FIXME: show only once)
    PS1+="${last_cmd_result:+${color_bg_result}${symbol_part_next} "\
"${color_default}${last_cmd_result} ${color_reset}${color_failure}}"

    # Finalize PS1
    PS1+="${symbol_part_end}${color_reset}"
}

# exit if there is no interactive terminal (commit by @prof7bit)
tty -s || exit

__powerline
unset __powerline
