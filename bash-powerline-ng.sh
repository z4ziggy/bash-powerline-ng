#!/usr/bin/bash

# bash-powerline-ng (c) z4ziggy 2014-2026
# Minimalist, lightweight, usable and themable Powerline in pure Bash script.
# Easy enough to change and adapt to your liking: one source file, modestly commented.

#  ┏┓┏┓┏┳┓┳┏┓┳┓┏┓
#  ┃┃┃┃ ┃ ┃┃┃┃┃┗┓
#  ┗┛┣┛ ┻ ┻┗┛┛┗┗┛

# Set before sourcing, pass on the `source` cmdline, or set after (0=off, 1=on):
POWERLINE_SPACE=${POWERLINE_SPACE:-1}                   # "crumb space" between fields
POWERLINE_GIT=${POWERLINE_GIT:-1}                       # git parsing
POWERLINE_CRUMBS=${POWERLINE_CRUMBS:-1}                 # crumbs in path names
POWERLINE_HOST=${POWERLINE_HOST:-0}                     # hostname display
POWERLINE_VENV=${POWERLINE_VENV:-1}                     # python venv segment
POWERLINE_JOBS=${POWERLINE_JOBS:-1}                     # background jobs segment
POWERLINE_CMD_TIME=${POWERLINE_CMD_TIME:-1}             # command execution time segment
POWERLINE_CMD_TIME_THRESHOLD=${POWERLINE_CMD_TIME_THRESHOLD:-2}  # seconds; only show if >= this
POWERLINE_GIT_CACHE_TTL=${POWERLINE_GIT_CACHE_TTL:-3}   # seconds; cache git status (0=off)
POWERLINE_PATH_MAX_LEN=${POWERLINE_PATH_MAX_LEN:-0}     # truncate path to N segments (0=unlimited)
POWERLINE_HOST_FORMAT=${POWERLINE_HOST_FORMAT:-\\H}     # \h or \H for short or full
POWERLINE_THEME=${POWERLINE_THEME:-default}             # default theme
POWERLINE_COLORS=${POWERLINE_COLORS:-default}           # default color scheme

# list of themes and their symbols (separated by pipe '|') (spaces included):
# HOST | NETWORK | FOLDER | CRUMB | PART_START | PART_NEXT | PART_END
declare -A pl_themes=(
    [default]=" |🖧 | |  ||| "
      [arrow]=" |🖧 | |  ||| "
      [slant]="💻︎|🖧 | |  ||| "
       [diag]="💻︎|🖧 | |  ||| "
       [soft]=" |🖧 | | ⟩ |🭬|🭬|🭬"
      [round]=" |🖧 | |  ||| "
)
# list of color schemes and their colors (color names separated by space ' '):
# default success warn fail hostname folder_icon path crumbs git success_bg
declare -A pl_colors=(
      [default]="LightGrey    SpringGreen2   tan1           DarkRed       SteelBlue     DeepSkyBlue1    grey36          grey22          grey22          SpringGreen4"
    [solarized]="black        lime           black          red1          orange1       magenta3        violet          HotPink2        cyan3           DarkGreen"
         [nord]="DeepSkyBlue4 CadetBlue5     DeepSkyBlue4   MediumPurple3 LightSkyBlue3 MediumPurple3   LightSteelBlue3 SteelBlue2      SkyBlue2        DarkSlateGray"
        [ocean]="RoyalBlue4   DodgerGreen1   white          red3          DodgerBlue1   SkyBlue4        SlateGray3      SlateGray4      LightCyan4      DarkGreen"
       [forest]="sienna       yellow1        goldenrod1     firebrick3    chartreuse3   SpringGreen4    DarkOliveGreen3 DarkOliveGreen2 DarkOliveGreen4 DarkOliveGreen"
       [sunset]="white        white          black          red1          MediumOrchid4 white           PaleVioletRed3  white           sienna4         firebrick4"
   [catppuccin]="grey30       SpringGreen3   black          red1          LightSkyBlue2 grey30          LightPink1      grey30          LightSteelBlue1 DarkGreen"
      [blueish]="MidnightBlue MidnightBlue   black          red1          SlateGray4    MidnightBlue    DarkTurquoise   MidnightBlue    LightSteelBlue2 DarkSlateGray"
        [earth]="#A8CC8C      #A8CC8C        #E8A75D        #CC6666       #3E3A36       #D4C96B         #4A4540         #6B6560         #35322E         #2D3A2D"
      [rainbow]="white        white          white          #CC241D       #D65D0E       white           #D79921         white           #689D6A         #458588"
)

# Nerd Font system icons keyed by $OSTYPE prefix
declare -A pl_os_icons=([darwin]=$'\uf179' [linux]=$'\uf17c')

powerline_set_ps1() {
    #pl_symbol_git_modified=*                            # uncomment to mark modified git
    pl_symbol_git_branch=
    pl_symbol_git_push=⇡
    pl_symbol_git_pull=⇣
    pl_color_reset='\001\e[0m\002'
    pl_color_invert='\001\e[7m\002'
    pl_set_colors ${POWERLINE_COLORS}
    pl_set_theme  ${POWERLINE_THEME}
    # DEBUG trap: track real commands (for error display) + grab start time (for cmd_time)
    trap '[[ $BASH_COMMAND != pl_ps1 ]] && pl_cmd_ran=1; [[ -z $pl_timer_start ]] && printf -v pl_timer_start "%(%s)T" -1' DEBUG
    PROMPT_COMMAND="pl_ps1"
}

pl_set_theme() {
    IFS='|' read -r pl_symbol_host pl_symbol_network pl_symbol_folder pl_symbol_crumb \
        pl_symbol_part_start pl_symbol_part_next pl_symbol_part_end <<< "${pl_themes[$1]}"
    # invert part_start if the theme reuses the same char as part_end
    [[ "$pl_symbol_part_end" =~ $pl_symbol_part_start ]] && pl_symbol_part_start=${pl_color_invert}${pl_symbol_part_start}${pl_color_reset}
    pl_crumb_symbol="${pl_color_crumb}${pl_symbol_crumb}${pl_color_default}"
    POWERLINE_THEME=$1
}

# rgb name -> "r;g;b" lookup map; populated once from showrgb; hex #RRGGBB also works.
declare -gA pl_rgb_map
pl_rgb_resolve() {
    REPLY=; [[ -z $1 ]] && return
    REPLY=${pl_rgb_map[$1]}
    if [[ -z $REPLY && $1 =~ ^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$ ]]; then
        REPLY="$((16#${BASH_REMATCH[1]}));$((16#${BASH_REMATCH[2]}));$((16#${BASH_REMATCH[3]}))"
        pl_rgb_map[$1]=$REPLY   # cache for next lookup
    fi
}

# $1=out var, $2=38(fg)|48(bg), $3=color name or #RRGGBB
pl_mkcolor()    { pl_rgb_resolve "$3"; declare -g $1="\001\e[$2;2;${REPLY}m\002"; }
pl_rgb()        { pl_mkcolor "$1" 38 "$2"; }
pl_rgb_bg()     { pl_mkcolor "$1" 48 "$2"; }
pl_color_pair() { pl_rgb "pl_color_$1" "$2"; pl_rgb_bg "pl_color_bg_$1" "$2"; }
pl_set_colors() {
    if [[ ${#pl_rgb_map[@]} -eq 0 ]] && command -v showrgb &>/dev/null; then
        local r g b color_name extra
        while read -r r g b color_name extra; do
            color_name+=${extra:+ ${extra}}
            pl_rgb_map["${color_name}"]="$r;$g;$b"
        done < <(showrgb)
    fi
    local colors
    read -a colors <<< "${pl_colors[$1]}"
    pl_rgb        pl_color_default      ${colors[0]}
    pl_rgb        pl_color_success      ${colors[1]}
    pl_rgb        pl_color_success_dark ${colors[9]}
    pl_rgb_bg     pl_color_bg_success   ${colors[9]}
    pl_color_pair warning               ${colors[2]}
    pl_color_pair failure               ${colors[3]}
    pl_color_pair host                  ${colors[4]}
    pl_color_pair icon                  ${colors[5]}
    pl_color_pair path                  ${colors[6]}
    pl_color_pair git                   ${colors[8]}
    pl_rgb        pl_color_crumb        ${colors[7]}
    pl_crumb_symbol="${pl_color_crumb}${pl_symbol_crumb}${pl_color_default}"
    pl_host_cache_key=   # invalidate host_info cache
    pl_git_cache_dir=    # invalidate git_info cache
    POWERLINE_COLORS=$1
}

pl_conv() { local -n out=$1; local i; for ((i=0; i<${#2}; i++)); do out+="${3:${2:$i:1}:1}"; done; }
pl_git_info() {
    local -n git=$1
    # cached .git walk per PWD; -e (not -d) so submodules/worktrees work
    if [[ $PWD != $pl_git_dir_pwd ]]; then
        pl_git_dir_pwd=$PWD pl_git_dir=$PWD
        while [[ -n $pl_git_dir && ! -e $pl_git_dir/.git ]]; do
            pl_git_dir=${pl_git_dir%/*}
        done
    fi
    [[ -z $pl_git_dir && ! -e /.git ]] && return
    # cache: reuse result if same repo and within TTL (EPOCHREALTIME for precision)
    local ttl=${POWERLINE_GIT_CACHE_TTL:-3}
    if (( ttl > 0 )) && [[ $pl_git_dir == $pl_git_cache_dir ]]; then
        local age=${EPOCHREALTIME%.*}; (( age - ${pl_git_cache_time:-0} < ttl )) && { git=$pl_git_cache; return; }
    fi
    # single git call: parse branch + ahead/behind + dirty from status --branch
    local git_eng="env LANG=C git --no-optional-locks"
    local ref marks line dirty=
    while IFS= read -r line; do
        if [[ ${line} =~ ^## ]]; then
            ref=${line#\#\# }; ref=${ref%%...*}; ref=${ref%% \[*}
            [[ $ref == *"no branch"* ]] && ref=$(${git_eng} rev-parse --short HEAD 2>/dev/null)
            [[ ${line} =~ ahead\ ([0-9]+)  ]] && marks+=" ${pl_symbol_git_push}" && pl_conv marks ${BASH_REMATCH[1]} "₀₁₂₃₄₅₆₇₈₉"
            [[ ${line} =~ behind\ ([0-9]+) ]] && marks+=" ${pl_symbol_git_pull}" && pl_conv marks ${BASH_REMATCH[1]} "⁰¹²³⁴⁵⁶⁷⁸⁹"
        else
            dirty=1; marks="${pl_symbol_git_modified}${marks}"
            break
        fi
    done < <(${git_eng} status --porcelain --branch -uno 2>/dev/null)
    [[ -z $ref ]] && return
    ref="${pl_symbol_git_branch} ${ref}"
    [[ -n $dirty ]] && ref="${pl_color_warning}${ref}"
    git="${pl_color_success}${ref}${marks}"
    pl_git_cache=$git pl_git_cache_dir=$pl_git_dir pl_git_cache_time=${EPOCHREALTIME%.*}
}

pl_host_info() {
    local -n start=$1 info=$2
    local next_fg=${3:-$pl_color_path} next_bg=${4:-$pl_color_bg_path}
    # cached host_info; rebuilt only when any input changes
    local key="${POWERLINE_THEME}:${POWERLINE_COLORS}:${POWERLINE_SPACE-0}:${SSH_CONNECTION}:${POWERLINE_HOST_FORMAT}:${next_fg}:${next_bg}"
    if [[ $key != $pl_host_cache_key ]]; then
        # pick system icon: SSH > OS match > theme default
        local sys=${pl_symbol_host} k
        for k in "${!pl_os_icons[@]}"; do
            [[ $OSTYPE == $k* ]] && { sys=${pl_os_icons[$k]}; break; }
        done
        [[ -n ${SSH_CONNECTION} ]] && sys=${pl_symbol_network}
        # root uses failure colors for the host segment
        local bg=${pl_color_bg_host} fg=${pl_color_host}
        (( EUID == 0 )) && { bg=${pl_color_bg_failure}; fg=${pl_color_failure}; }
        pl_host_cache_start=${fg}
        pl_host_cache_info="${bg} ${pl_color_default}${sys} ${POWERLINE_HOST_FORMAT} ${pl_space_on:+${pl_color_reset}${fg}${pl_symbol_part_next}${next_fg}${pl_color_invert}${pl_symbol_part_next}${pl_color_reset}}${pl_space_off:+${next_bg}${fg}${pl_symbol_part_next}}"
        pl_host_cache_key=$key
    fi
    start=$pl_host_cache_start
    info=$pl_host_cache_info
}

# truncate path to POWERLINE_PATH_MAX_LEN segments, insert crumbs, add folder icon
pl_path_info() {
    local -n out=$1
    local wd=${PWD/#${HOME}/\~} folder_color=${pl_color_icon}
    [[ -w $PWD ]] || folder_color=${pl_color_failure}
    if (( POWERLINE_PATH_MAX_LEN >= 2 )); then
        local IFS=/ max=${POWERLINE_PATH_MAX_LEN}
        local -a parts=($wd)
        (( ${#parts[@]} <= max )) || wd="${parts[0]}/…/${parts[*]: -max+1}"
    fi
    if [[ ${POWERLINE_CRUMBS} != 0 && ${#wd} != 1 ]]; then
        wd=${wd//\//${pl_crumb_symbol}}
        [[ ${wd:0:1} == "~" ]] || wd=/$wd
    fi
    out="${folder_color}${pl_symbol_folder}${pl_color_default} ${wd}"
}

pl_venv_info() {
    local -n out=$1; out=
    local env=${VIRTUAL_ENV:-${CONDA_DEFAULT_ENV}}
    [[ ${POWERLINE_VENV} = 0 || -z $env ]] || out=${env##*/}
}

# choose the first visible segment: path by default, venv when active
pl_first_seg_info() {
    local -n bg=$1 fg=$2 content=$3 content_fg=$4
    bg=$pl_color_bg_path
    fg=$pl_color_path
    content=$5
    content_fg=$pl_color_default
    [[ -n $6 ]] || return
    bg=$pl_color_bg_warning
    fg=$pl_color_warning
    content=$6
    content_fg=$pl_color_path
}

pl_jobs_info() {
    local -n out=$1; out=0
    [[ ${POWERLINE_JOBS} = 0 ]] || while read -r _; do ((out++)); done < <(jobs -rp 2>/dev/null)
    (( out )) || out=
}

pl_cmd_time_info() {
    local -n out=$1; out=
    [[ -z $pl_timer_start ]] && return
    local now elapsed
    printf -v now '%(%s)T' -1
    elapsed=$(( now - pl_timer_start ))
    (( elapsed >= ${POWERLINE_CMD_TIME_THRESHOLD:-2} )) && out="${elapsed}s"
    pl_timer_start=
}

# $1=bg escape, $2=fg escape, $3=content, $4=content fg (optional)
pl_seg() {
    PS1+="${pl_space_on:+${pl_symbol_part_next}${2}${pl_color_invert}${pl_symbol_part_next}${pl_color_reset}}${1}${pl_space_off:+${pl_symbol_part_next}}${4:-$pl_color_default} ${3} ${pl_color_reset}${2}"
}

pl_ps1() {
    local last_cmd_result=$? first_content host_info git_info venv jobs_count cmd_time path_seg
    local pl_space=${POWERLINE_SPACE-0}
    local pl_space_off=${pl_space//[!0]/}
    local pl_space_on=${pl_space//0/}
    local first_seg_fg=$pl_color_path start_color first_seg_bg=$pl_color_bg_path first_content_fg=$pl_color_default

    [[ -n $pl_cmd_ran ]] && last_cmd_result=${last_cmd_result##0} || last_cmd_result=
    pl_cmd_ran=
    pl_path_info path_seg
    pl_venv_info venv
    pl_jobs_info jobs_count
    pl_cmd_time_info cmd_time
    pl_first_seg_info first_seg_bg first_seg_fg first_content first_content_fg "$path_seg" "$venv"
    start_color=$first_seg_fg
    [[ ${POWERLINE_HOST} = 0 ]] || pl_host_info start_color host_info "$first_seg_fg" "$first_seg_bg"
    [[ ${POWERLINE_GIT}  = 0 ]] || pl_git_info git_info
    PS1="${start_color}${pl_symbol_part_start}${host_info}${first_seg_bg} ${first_content_fg}${first_content} ${pl_color_reset}${first_seg_fg}"
    [[ -n $venv              ]] && pl_seg "$pl_color_bg_path"    "$pl_color_path"          "$path_seg"
    [[ -n $git_info          ]] && pl_seg "$pl_color_bg_git"     "$pl_color_git"           "$git_info"
    [[ -n $jobs_count        ]] && pl_seg "$pl_color_bg_host"    "$pl_color_host"          $'\uf013  '"$jobs_count"
    [[ -n $cmd_time          ]] && pl_seg "$pl_color_bg_success" "$pl_color_success_dark"  $'\uf017  '"$cmd_time"
    [[ -n $last_cmd_result   ]] && pl_seg "$pl_color_bg_failure" "$pl_color_failure"       "$last_cmd_result"
    PS1+="${pl_symbol_part_end}${pl_color_reset}"
}

# bail out in non-interactive shells (works whether sourced or executed)
tty -s || return 2>/dev/null || exit
powerline_set_ps1
unset powerline_set_ps1
