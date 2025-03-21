#!/usr/bin/bash

# bash-powerline-ng (c) z4ziggy 2014-2024
# Minimalist, lightweight, usable and themable Powerline in pure Bash script.
#
# Code should be easy enough to change and adapt to your liking - it's one
# source file with less than 300 lines of code, modestly commented.

#  ┏┓┏┓┏┳┓┳┏┓┳┓┏┓
#  ┃┃┃┃ ┃ ┃┃┃┃┃┗┓
#  ┗┛┣┛ ┻ ┻┗┛┛┗┗┛
#
# To change functionality, either uncomment, change, or pass the var on the
# `source` command, or set it if/when needed.

#POWERLINE_GIT=${POWERLINE_GIT:-0}                      # disable git parsing
#POWERLINE_CRUMBS=${POWERLINE_CRUMBS:-0}                # disable crumbs in path names
#POWERLINE_HOST=${POWERLINE_HOST:-0}                    # disable hostname display
POWERLINE_HOST_FORMAT=${POWERLINE_HOST_FORMAT:-\\H}     # \h or \H for short or full

POWERLINE_THEME=${POWERLINE_THEME:-default}             # default theme
POWERLINE_COLORS=${POWERLINE_COLORS:-default}           # default color scheme

# list of themes and their symbols (separated by pipe '|') (spaces included).
# format = HOST | NETWORK | FOLDER | CRUMB | PART_START | PART_NEXT | PART_END
declare -A pl_themes=(
    [default]=" |🖧 | |  ||| "
      [arrow]=" |🖧 | |  ||| "
      [slant]="💻︎|🖧 | |  || | "
       [diag]="💻︎|🖧 | |  || | "
       [soft]=" |🖧 | | ⟩ |🭬|🭬|🭬"
      [round]=" |🖧 | |  ||| "
)

# list of color schemes and their colors (color names separated by space ' ')
# format =       default      successs       warn           fail          hostname      folder_icon     path            crumbs          git
declare -A pl_colors=(
      [default]="LightGrey    SpringGreen3   tan3           DarkRed       SteelBlue     DeepSkyBlue1    grey36          grey22          grey22         "
    [solarized]="black        lime           black          red1          orange1       magenta3        violet          HotPink2        cyan3          "
#     [dracula]="grey25       SeaGreen3      DarkOrange3    red3          DeepPink3     gold3           SeaGreen3       SkyBlue3        SlateBlue3     "
      [gruvbox]="yellow3      DarkOliveGreen gold4          red1          red4          gold1           SlateBlue3      SlateBlue1      cyan3          "
         [nord]="DeepSkyBlue4 CadetBlue3     DeepSkyBlue4   MediumPurple3 LightSkyBlue3 MediumPurple3   LightSteelBlue3 SteelBlue2      SkyBlue2       "
#     [monokai]="SlateBlue3   Chartreuse2    DarkGoldenrod3 red3          DarkRed       DarkSeaGreen3   DarkCyan        SlateBlue3      grey37         "
        [ocean]="RoyalBlue4   DodgerGreen1   chocolate4     red3          DodgerBlue1   SkyBlue4        SlateGray3      SlateGray4      LightCyan4     "
       [forest]="sienna       yellow1        goldenrod1     firebrick3    chartreuse3   SpringGreen4    DarkOliveGreen3 DarkOliveGreen2 DarkOliveGreen4"
       [sunset]="brown4       OrangeRed3     grey32         firebrick1    coral3        red3            goldenrod3      orange2         LightGoldenrod3"
)

# desc:   setup PS1 with fancy prompt
# output: a new PS1
powerline_set_ps1() {
    # uncomment if you wish to see a marker for modified git
    #pl_symbol_git_modified=*
    pl_symbol_git_branch=
    pl_symbol_git_push=⇡
    pl_symbol_git_pull=⇣

    pl_color_reset='\001\e[0m\002'
    pl_color_invert='\001\e[7m\002'

    pl_colors ${POWERLINE_COLORS}
    pl_theme ${POWERLINE_THEME}

    PROMPT_COMMAND="pl_ps1"
}

# desc:   setup symbol variables from selected theme
# input:  $1 = string containing theme symbols separated by pipe '|'
#              (eg, " |🖧 |  | | | ")
# output: pl_symbol_ variables propagated
pl_theme() {
    IFS='|' read -r          \
        pl_symbol_host       \
        pl_symbol_network    \
        pl_symbol_folder     \
        pl_symbol_crumb      \
        pl_symbol_part_start \
        pl_symbol_part_next  \
        pl_symbol_part_end   \
        <<< "${pl_themes[$1]}"

    pl_system_symbol=${pl_symbol_host}
    # detect SSH connection (TODO: detect nfs mount)
    if [[ ! -z ${SSH_CONNECTION} ]]; then  # [[ `who am i` =~ \([0-9\.]+\)$ ]]
        pl_system_symbol=${pl_symbol_network}
    fi

    # invert color for pl_symbol_part_start if needed
    if [[ "$pl_symbol_part_end" =~ $pl_symbol_part_start ]]; then
        pl_symbol_part_start=${pl_color_invert}${pl_symbol_part_start}${pl_color_reset}
    fi

    pl_crumb_symbol="${pl_color_crumb}${pl_symbol_crumb}${pl_color_default}"
    POWERLINE_THEME=$1
}

# desc:   setup colors from selected color scheme
# input:  $1 = string containing list of colors separated by space ' '
#              (eg. "color1 color2 color3")
# output: pl_color_ variables propagated
pl_colors() {
    declare -A rgb
    pl_rgb()    { declare -g $1="\001\e[38;2;${rgb[$2]}m\002"; }
    pl_rgb_bg() { declare -g $1="\001\e[48;2;${rgb[$2]}m\002"; }

    # fill rgb array with colors from showrgb
    while read -r r g b color_name extra; do
        color_name+=${extra:+ ${extra}}
        rgb["${color_name}"]="$r;$g;$b"
    done < <(showrgb)

    # read powerline color theme
    read -a colors <<< ${pl_colors[$1]}

    pl_rgb    pl_color_default    ${colors[0]}
    pl_rgb    pl_color_success    ${colors[1]}
    pl_rgb    pl_color_warning    ${colors[2]}
    pl_rgb    pl_color_failure    ${colors[3]}
    pl_rgb_bg pl_color_bg_failure ${colors[3]}
    pl_rgb    pl_color_host       ${colors[4]}
    pl_rgb_bg pl_color_bg_host    ${colors[4]}
    pl_rgb    pl_color_icon       ${colors[5]}
    pl_rgb_bg pl_color_bg_icon    ${colors[5]}
    pl_rgb_bg pl_color_bg_path    ${colors[6]}
    pl_rgb    pl_color_path       ${colors[6]}
    pl_rgb    pl_color_crumb      ${colors[7]}
    pl_rgb    pl_color_git        ${colors[8]}
    pl_rgb_bg pl_color_bg_git     ${colors[8]}

    unset colors rgb
    pl_crumb_symbol="${pl_color_crumb}${pl_symbol_crumb}${pl_color_default}"
    POWERLINE_COLORS=$1
}

# desc:   populate git_info if git info found
# output: git_info variable propagated
pl_git_info() {
    # clear git_info
    unset $1
    # check for .git directory in parent dirs (it's faster than running git)
    local git_dir=$PWD
    while [[ -n "$git_dir" && ! -d $git_dir/.git ]]; do
        git_dir="${git_dir%/*}"
    done
    [[ -z $git_dir && ! -d /.git ]] && return

    # check if 'git' command exists
    #command git 2>/dev/null || return # git not found

    # force git output in English to make our work easier
    local git_eng="env LANG=C git"

    # get current branch name
    local ref=$(${git_eng} symbolic-ref --short -q HEAD 2>/dev/null)
    [[ -n "${ref}" ]] || ref=$(${git_eng} rev-parse --short HEAD)

    # get tag name or short unique hash
    #[[ -n "${ref}" ]] || ref=$(${git_eng} describe --tags --always 2>/dev/null)
    [[ -n "${ref}" ]] || return  # not a git repo

    # prepend branch symbol
    ref="${pl_symbol_git_branch} ${ref}"

    # convert each digit from input ($2) using list ($3) and add to ($1)
    pl_conv() { for ((i=0; i<${#2}; i++)); do export ${1}+="${3:${2:$i:1}:1}"; done; }

    local marks
    # scan first two lines of output from `git status`
    while IFS= read -r line; do
        if [[ ${line} =~ ^## ]]; then # header line
            [[ ${line} =~ ahead\ ([0-9]+) ]]     && \
                marks+=" ${pl_symbol_git_push}"  && \
                pl_conv marks ${BASH_REMATCH[1]} "₀₁₂₃₄₅₆₇₈₉"
            [[ ${line} =~ behind\ ([0-9]+) ]]    && \
                marks+=" ${pl_symbol_git_pull}"  && \
                pl_conv marks ${BASH_REMATCH[1]} "⁰¹²³⁴⁵⁶⁷⁸⁹"
        else
            # branch is modified if output contains lines after header
            marks="${pl_symbol_git_modified}${marks}"
            ref="${pl_color_warning}${ref}"
            break
        fi
    # loop while reading git result (note the space between the two <)
    done < <(${git_eng} status --porcelain --branch -uno 2>/dev/null)
    [[ -n ${marks} ]] && ref="${pl_color_warning}${ref}"

    # add git branch segment
    declare -g $1="${pl_color_success}${ref}${marks}"
}

pl_host_info() {
    export $1=${pl_color_host}
    # set host_info with part_start & system symbols + hostname + part_next
    export $2="${pl_color_bg_host} ${pl_color_default}${pl_system_symbol} "\
"${POWERLINE_HOST_FORMAT} ${pl_color_bg_path}${pl_color_host}${pl_symbol_part_next}"
}

pl_crumbs() {
    local path=${!1}
    [[ ${#path}   -eq   1 ]] && return

    export $1="${!1//\//${pl_crumb_symbol}}"
    [[ "${!1:0:1}" == "~" ]] || export $1="/${!1}"
}

pl_ps1() {
    # remember last command result (make it blank if zero)
    local last_cmd_result=${?##0}
    local host_info start_color=${pl_color_path}
    local folder_color=${pl_color_icon}
    # format working directory to ~ (its faster than `dirs`)
    local wd="${PWD/#${HOME}/\~}"

    # Check if PWD is writable and set folder color accordingly
    [[ -w ${PWD} ]] || folder_color="${pl_color_failure}"

    # make crumbs from path if needed
    [[ ${POWERLINE_CRUMBS} = 0 ]] || pl_crumbs wd
    # setup host_info if needed
    [[ ${POWERLINE_HOST}   = 0 ]] || pl_host_info start_color host_info
    # setup git info if needed
    [[ ${POWERLINE_GIT}    = 0 ]] || pl_git_info git_info

    #  ┏┓┏┓┓
    #  ┃┃┗┓┃ Finally we are ready to start assembly our prompt
    #  ┣┛┗┛┻

    # Add part_start symbol and host_info if any
    PS1="${start_color}${pl_symbol_part_start}${host_info}"

    # Add folder symbol + Working directory
    PS1+="${pl_color_bg_path} ${folder_color}${pl_symbol_folder}${pl_color_default} "\
"${wd} ${pl_color_reset}${pl_color_path}"

    # Expand git info if we have any
    PS1+="${git_info:+${pl_color_bg_git}${pl_symbol_part_next} ${git_info} "\
"${pl_color_reset}${pl_color_git}}"

    # Expand last command result (FIXME: show only once)
    PS1+="${last_cmd_result:+${pl_color_bg_failure}${pl_symbol_part_next} "\
"${pl_color_default}${last_cmd_result} ${pl_color_reset}${pl_color_failure}}"

    # Finalize PS1
    PS1+="${pl_symbol_part_end}${pl_color_reset}"

    # cleanup
    unset git_info
}

# exit if there is no interactive terminal (commit by @prof7bit)
tty -s || exit

powerline_set_ps1
unset powerline_set_ps1
