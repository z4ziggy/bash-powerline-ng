#!/usr/bin/bash

# bash-powerline-ng (c) z4ziggy 2014-2024
# Minimalist, lightweight, usable and themable Powerline in pure Bash script.
#
# Source should be easy enough to change and adapt to your liking - it's one
# file with less than 300 lines of code, modestly commented.

#  ┏┓┏┓┏┳┓┳┏┓┳┓┏┓
#  ┃┃┃┃ ┃ ┃┃┃┃┃┗┓
#  ┗┛┣┛ ┻ ┻┗┛┛┗┗┛

## To disable functionality, either uncomment, or pass the var on the `source`
## command, or export it if/when needed.
#POWERLINE_GIT=${POWERLINE_GIT:-0}                      # disable git parsing
#POWERLINE_CRUMBS=${POWERLINE_CRUMBS:-0}                # disable crumbs in path names
#POWERLINE_HOST=${POWERLINE_HOST:-0}                    # disable hostname display

## Settings can be overridden from user env or here
POWERLINE_THEME=${POWERLINE_THEME:-default}             # default theme
POWERLINE_COLORS=${POWERLINE_COLORS:-default}           # default color scheme

# list of themes and their symbols (separated by pipe '|') (spaces included).
# format = HOST | NETWORK | FOLDER | CRUMB | PART_START | PART_NEXT | PART_END
declare -A __powerline_themes=(
    [default]=" |🖧 | |  ||| "
      [arrow]=" |🖧 | |  ||| "
      [slant]="💻︎|🖧 | | | | |  "
       [diag]="💻︎|🖧 | | | | |  "
       [soft]=" |🖧 | | ⟩ |🭬|🭬|🭬"
      [round]=" |🖧 | |  | || "
)

# list of color schemes and their colors (color names separated by space ' ')
# format =       default      successs       warn           fail          hostname      folder_icon     path            crumbs          git
declare -A __powerline_colors=(
      [default]="LightGrey    SpringGreen3   tan3           DarkRed       SteelBlue     DeepSkyBlue1    grey36          grey22          grey22         "
    [solarized]="black        lime           black          red1          orange1       magenta3        violet          HotPink2        cyan3          "
#      [dracula]="grey25       SeaGreen3      DarkOrange3    red3          DeepPink3     gold3           SeaGreen3       SkyBlue3        SlateBlue3    "
      [gruvbox]="yellow3      DarkOliveGreen gold4          red1          red4          gold1           SlateBlue3      SlateBlue1      cyan3          "
         [nord]="DeepSkyBlue4 CadetBlue3     DeepSkyBlue4   MediumPurple3 LightSkyBlue3 MediumPurple3   LightSteelBlue3 SteelBlue2      SkyBlue2       "
#      [monokai]="SlateBlue3   Chartreuse2    DarkGoldenrod3 red3          DarkRed       DarkSeaGreen3   DarkCyan        SlateBlue3      grey37        "
        [ocean]="RoyalBlue4   DodgerGreen1   chocolate4     red3          DodgerBlue1   SkyBlue4        SlateGray3      SlateGray4      LightCyan4     "
       [forest]="sienna       yellow1        goldenrod1     firebrick3    chartreuse3   SpringGreen4    DarkOliveGreen3 DarkOliveGreen2 DarkOliveGreen4"
       [sunset]="brown4       OrangeRed3     grey32         firebrick1    coral3        red3            goldenrod3      orange2         LightGoldenrod3"
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

    pl_colors ${POWERLINE_COLORS}
    pl_theme ${POWERLINE_THEME}

    PROMPT_COMMAND="ps1"
}

# desc:   setup symbol variables from selected theme
# input:  $1 = string containing theme symbols separated by pipe '|'
#              (eg, " |🖧 |  | | | ")
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

    crumb_symbol="${color_crumb}${symbol_crumb}${color_default}"
    POWERLINE_THEME=$1
}

# desc:   setup colors from selected color scheme
# input:  $1 = string containing list of colors separated by space ' '
#              (eg. "color1 color2 color3")
# output: color_ variables propagated
pl_colors() {

    declare -A rgb
    __rgb()    { echo -en "\001\e[38;2;${rgb[$1]}m\002"; }
    __rgb_bg() { echo -en "\001\e[48;2;${rgb[$1]}m\002"; }

    # fill rgb array with colors from showrgb
    while read -r r g b color_name extra; do
        color_name+=${extra:+ ${extra}}
        rgb["${color_name}"]="$r;$g;$b"
    done < <(showrgb)

    # read powerline color theme
    read -a colors <<< ${__powerline_colors[$1]}

       color_default=$(__rgb    ${colors[0]})
       color_success=$(__rgb    ${colors[1]})
       color_warning=$(__rgb    ${colors[2]})
       color_failure=$(__rgb    ${colors[3]})
    color_bg_failure=$(__rgb_bg ${colors[3]})
          color_host=$(__rgb    ${colors[4]})
       color_bg_host=$(__rgb_bg ${colors[4]})
          color_icon=$(__rgb    ${colors[5]})
       color_bg_icon=$(__rgb_bg ${colors[5]})
       color_bg_path=$(__rgb_bg ${colors[6]})
          color_path=$(__rgb    ${colors[6]})
         color_crumb=$(__rgb    ${colors[7]})
           color_git=$(__rgb    ${colors[8]})
        color_bg_git=$(__rgb_bg ${colors[8]})

    unset colors rgb
    crumb_symbol="${color_crumb}${symbol_crumb}${color_default}"
    POWERLINE_COLORS=$1
}

# desc:   populate git_info if git info found
# output: git_info variable propagated
__git_info() {
    # check if git functionality is disabled
    [[ ${POWERLINE_GIT} = 0 ]] && return

    # check for .git directory in parent dirs (it's faster than running git)
    local dir=$PWD
    while [[ -n "$dir" && ! -d $dir/.git ]]; do
        dir="${dir%/*}"
    done
    [[ -z $dir && ! -d /.git ]] && return

    # check if 'git' command exists
    #command git 2>/dev/null || return # git not found

    # force git output in English to make our work easier
    local git_eng="env LANG=C git"

    # get current branch name
    local ref=$(${git_eng} symbolic-ref --short HEAD 2>/dev/null)

    if [[ ! -n "${ref}" ]]; then
        # get tag name or short unique hash
        ref=$(${git_eng} describe --tags --always 2>/dev/null)
    fi

    [[ -n "${ref}" ]] || return  # not a git repo

    # prepend branch symbol
    ref="${symbol_git_branch} ${ref}"

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
    # remember last command result (make it blank if zero)
    local last_cmd_result=${?##0}

    # Get git info
    local git_info=$(__git_info)

    local folder_color=${color_icon}
    # Check if PWD is writable and set folder color accordingly
    [[ -w ${PWD} ]] || folder_color="${color_failure}"

    # Parse path
    local wd="$(dirs)"
    # make crumbs from path if needed
    if [[ ! ${POWERLINE_CRUMBS} = 0 ]]; then
        [[ "${wd}" != "/"              ]] && wd="${wd//\//${crumb_symbol}}"
        [[ "${wd}" == ${crumb_symbol}* ]] && wd="/${wd}"
    fi

    local host_info start_color=${color_path}
    # setup host_info if needed
    if [[ ! ${POWERLINE_HOST} = 0 ]]; then
        start_color=${color_host}
        # set host_info with part_start & system symbols + hostname + part_next
        host_info="${color_bg_host} ${color_default}${system_symbol} \h "\
"${color_bg_path}${color_host}${symbol_part_next}"
    fi

    #  ┏┓┏┓┓
    #  ┃┃┗┓┃ Finally we are ready to start assembly our prompt
    #  ┣┛┗┛┻

    # Add part_start symbol and host_info if any
    PS1="${start_color}${symbol_part_start}${host_info}"

    # Add folder symbol + Working directory
    PS1+="${color_bg_path} ${folder_color}${symbol_folder}${color_default} "\
"${wd} ${color_reset}${color_path}"

    # Expand git info if we have any
    PS1+="${git_info:+${color_bg_git}${symbol_part_next}${git_info} "\
"${color_reset}${color_git}}"

    # Expand last command result (FIXME: show only once)
    PS1+="${last_cmd_result:+${color_bg_failure}${symbol_part_next} "\
"${color_default}${last_cmd_result} ${color_reset}${color_failure}}"

    # Finalize PS1
    PS1+="${symbol_part_end}${color_reset}"
}

# exit if there is no interactive terminal (commit by @prof7bit)
tty -s || exit

__powerline
unset __powerline
