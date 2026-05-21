#!/usr/bin/env bash
SCRIPT_PATH=${1:-$PWD/bash-powerline-ng.sh}
[[ -f $SCRIPT_PATH ]] || { echo "Error: $SCRIPT_PATH not found." >&2; exit 1; }
SCRIPT_PATH=$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/$(basename "$SCRIPT_PATH")
col=0 o_idx=0

RST=$'\e[0m' BOLD=$'\e[1m'
C_BORDER=$'\e[38;2;91;133;255m' C_TEXT=$'\e[38;2;225;235;255m' C_MUTED=$'\e[38;2;145;165;205m'
C_HI=$'\e[38;2;120;180;255m' C_PICK=$'\e[38;2;120;255;210m' C_SHADOW=$'\e[38;2;6;8;14m'
BG_APP=$'\e[48;2;31;35;45m' BG_BLACK=$'\e[48;2;0;0;0m' BG_PANEL=$'\e[48;2;18;30;56m'
BG_SEL=$'\e[48;2;57;85;160m' BG_SHADOW=$'\e[48;2;6;8;14m'

rep(){ printf -v "$1" '%*s' "$2" ''; printf -v "$1" %s "${!1// /$3}"; }

load_schema() {
    local name val desc i
    for i in themes colors; do mapfile -t "$i" < <(sed -n "/^declare -A pl_$i=(/,/^)/s/.*\\[\\([^]]*\\)\\].*/\\1/p" "$SCRIPT_PATH"); done
    while IFS='|' read -r name val desc; do
        val=${val//\\\\/\\}
        case $name in
            POWERLINE_THEME)  t_idx=0; for i in "${!themes[@]}"; do [[ ${themes[i]} == "$val" ]] && { t_idx=$i; break; }; done; default_t_idx=$t_idx ;;
            POWERLINE_COLORS) c_idx=0; for i in "${!colors[@]}"; do [[ ${colors[i]} == "$val" ]] && { c_idx=$i; break; }; done; default_c_idx=$c_idx ;;
            POWERLINE_CMD_TIME_THRESHOLD|POWERLINE_GIT_CACHE_TTL) ;;
            *) opt_names+=("$name"); opt_defs+=("$val"); opt_vals+=("$val"); opt_descs+=("$desc") ;;
        esac
    done < <(sed -n 's/^\(POWERLINE_[A-Z_]*\)=.*:-\([^}]*\)}[[:space:]]*#[[:space:]]*\(.*\)$/\1|\2|\3/p' "$SCRIPT_PATH")
}

cycle_opt() {
    local v=${opt_vals[$1]}
    case ${opt_names[$1]} in
        POWERLINE_PATH_MAX_LEN) case $v in 0) v=2;; 2) v=3;; 3) v=5;; *) v=0;; esac ;; POWERLINE_HOST_FORMAT) [[ $v == '\H' ]] && v='\h' || v='\H' ;; *) v=$((v ? 0 : 1)) ;;
    esac
    opt_vals[$1]=$v; preview_key=
}

calc_layout(){
    read -r LINES COLS < <(stty size 2>/dev/null) || { LINES=40 COLS=120; }
    if (( COLS < 94 )); then tx=2 tw=18 cw=20 cx=21 ox=42 pw=80; else tx=4 tw=20 cw=22 cx=26 ox=50 pw=86; fi
    ow=40 ly=5 px=$tx
    lh=$((LINES-15)); ((lh<10)) && lh=10; ((lh>14)) && lh=14
    py=$((ly+lh+2)); hy=$((py+7)); ((hy>=LINES)) && hy=$((LINES-1))
}

box(){
    local x=$1 y=$2 w=$3 h=$4 t=$5 i hb tb sb iw=$(($3-2))
    rep hb $iw '─'; rep tb $((iw-3-${#t})) '─'; rep sb "$3" '▀'
    for ((i=1;i<h-1;i++)); do
        printf '\e[%s;%sH%s%s│%*s│%s %s' "$((y+i))" "$x" "$BG_PANEL" "$C_BORDER" "$iw" '' "$BG_SHADOW" "$RST$BG_APP"
    done
    printf '\e[%s;%sH%s%s╭─ %s%s %s%s╮%s\e[%s;%sH%s%s╰%s╯%s %s\e[%s;%sH%s%s%s%s' "$y" "$x" "$BG_PANEL" "$C_BORDER" "$C_HI$BOLD" "$t" "$C_BORDER" "$tb" "$RST$BG_APP" "$((y+h-1))" "$x" "$BG_PANEL" "$C_BORDER" "$hb" "$BG_SHADOW" "$RST$BG_APP" "$((y+h))" "$((x+1))" "$BG_APP" "$C_SHADOW" "$sb" "$RST$BG_APP"
}

draw_list(){
    local ci=$1 x=$2 w=$3 cur=$4; shift 4
    local items=("$@") vis=$((lh-4)) start=0 i row ry bg fg tw mark
    (( cur >= vis )) && start=$((cur-vis+1))
    for ((i=0; i<vis && start+i<${#items[@]}; i++)); do
        row=$((start+i)); ry=$((ly+2+i))
        bg=$BG_PANEL fg=$C_TEXT tw=$((w-2)) mark=
        (( row == cur )) && { fg=$C_PICK$BOLD; tw=$((w-4)); (( col == ci )) && bg=$BG_SEL fg=$C_TEXT$BOLD; mark="$bg$C_PICK$BOLD✓ "; }
        printf '\e[%s;%sH%s%s%-*.*s%s%s' "$ry" "$((x+1))" "$bg" "$fg" "$tw" "$tw" " ${items[row]}" "$mark" "$RST$BG_PANEL"
    done
}

draw_options(){
    local i row ry vis=$((lh-5)) start=0 name v shown bg nfg vfg
    (( o_idx >= vis )) && start=$((o_idx-vis+1))
    for ((i=0; i<vis && start+i<${#opt_names[@]}; i++)); do
        row=$((start+i)); ry=$((ly+2+i))
        name=${opt_names[row]}; v=${opt_vals[row]}
        case $name in POWERLINE_PATH_MAX_LEN|POWERLINE_HOST_FORMAT) shown=$v ;; *) ((v)) && shown=ON || shown=OFF ;; esac
        bg=$BG_PANEL nfg=$C_TEXT vfg=$C_MUTED
        (( row == o_idx )) && { nfg=$C_PICK$BOLD vfg=$C_PICK$BOLD; (( col == 2 )) && bg=$BG_SEL nfg=$C_TEXT$BOLD; }
        printf '\e[%s;%sH%s%s%-*.*s%s%5s %s' "$ry" "$((ox+1))" "$bg" "$nfg" "$((ow-8))" "$((ow-10))" " $name" "$vfg" "$shown" "$RST$BG_PANEL"
    done
    printf '\e[%s;%sH%s%s%-*.*s%s' "$((ly+lh-2))" "$((ox+1))" "$BG_PANEL" "$C_MUTED" "$((ow-2))" "$((ow-2))" " ${opt_descs[$o_idx]}" "$RST$BG_PANEL"
}

preview_setup(){
    preview_dir=$(mktemp -d)
    preview_src=$(sed '/^# bail out in non-interactive shells/,$d' "$SCRIPT_PATH")
    preview_proj=$preview_dir/home/demo/project
    mkdir -p "$preview_proj"
    { git -C "$preview_proj" -c init.defaultBranch=main init -q; git -C "$preview_proj" -c user.name=demo -c user.email=demo@example.invalid commit -qm init --allow-empty; } >/dev/null 2>&1
}

build_preview() {
    local i preview p1= p2=
    cd "$preview_proj" || exit 1
    export HOME=$preview_dir/home POWERLINE_THEME=${themes[t_idx]} POWERLINE_COLORS=${colors[c_idx]}
    for i in "${!opt_names[@]}"; do export "${opt_names[i]}=${opt_vals[i]}"; done
    { eval "$preview_src"; powerline_set_ps1; } >/dev/null 2>&1
    [[ ${POWERLINE_VENV_SHOW:-0}     != 0 ]] && export VIRTUAL_ENV=/opt/demo-venv
    [[ ${POWERLINE_JOBS_SHOW:-0}     != 0 ]] && { sleep 30 & p1=$!; sleep 30 & p2=$!; }
    [[ ${POWERLINE_CMD_TIME_SHOW:-0} != 0 ]] && pl_timer_start=$((EPOCHSECONDS-5))
    pl_cmd_ran=1; pl_ps1 2>/dev/null
    [[ -n $p1 ]] && kill "$p1" "$p2" 2>/dev/null
    preview=${PS1@P}
    printf %s "${preview//[$'\001\002']/}"
}

draw_preview(){
    local key=$t_idx:$c_idx:${opt_vals[*]} pv
    [[ $key != "$preview_key" ]] && { preview_val=$(build_preview); preview_key=$key; }
    pv=${preview_val//$'\e[0m'/$'\e[0m'$BG_PANEL}
    pv=${pv//$'\e[m'/$'\e[m'$BG_PANEL}
    printf '\e[%s;%sH%s%*s\e[%s;%sH\e[?7l%s%b%s\e[?7h' "$((py+2))" "$((px+1))" "$BG_PANEL" "$((pw-2))" '' "$((py+2))" "$((px+2))" "$BG_PANEL" "$pv" "$RST$BG_PANEL"
}

redraw(){ draw_list 0 "$tx" "$tw" "$t_idx" "${themes[@]}"; draw_list 1 "$cx" "$cw" "$c_idx" "${colors[@]}"; draw_options; draw_preview; }

full_redraw(){
    calc_layout
    printf '\e[?25l%s\e[2J\e[H\e[2;1H%s\e[K   %sbash-powerline-ng configure%s\e[3;1H%s\e[K   %sNative Bash TUI - arrows move, Enter/Space changes selected option, q quits%s\e[%s;1H%s\e[K   %s←/→ column   ↑/↓ move   Enter/Space change   r reset   q quit%s' "$RST$BG_APP" "$BG_BLACK" "$C_TEXT$BOLD" "$RST$BG_APP" "$BG_BLACK" "$C_MUTED" "$RST$BG_APP" "$hy" "$BG_BLACK" "$C_MUTED" "$RST$BG_APP"
    box "$tx" "$ly" "$tw" "$lh" Theme
    box "$cx" "$ly" "$cw" "$lh" Colors
    box "$ox" "$ly" "$ow" "$lh" Options
    box "$px" "$py" "$pw" 5 "Live Preview"
    redraw
}

move_cur(){
    local arrs=(themes colors opt_names) idxs=(t_idx c_idx o_idx) n
    local -n a=${arrs[col]} i=${idxs[col]}; n=${#a[@]}
    ((n)) && i=$(( (i + n + $1) % n )); (( col != 2 )) && preview_key=
}

cleanup(){
    printf '\e[?25h\e[?7h\e[0m\e]110\a\e]111\a'; rm -rf "$preview_dir" 2>/dev/null; stty "${tty_state:-sane}" 2>/dev/null || stty sane
}

load_schema; preview_setup; trap full_redraw WINCH; trap cleanup EXIT INT TERM
tty_state=$(stty -g); stty -echo -icanon time 0 min 1; printf '\e]10;#e1ebff\a\e]11;#1f232d\a'
full_redraw

while IFS= read -rsn1 key; do
    [[ $key == $'\e' ]] && { IFS= read -rsn2 -t 0.08 esc || break; [[ $esc == [\[O]? ]] || continue; key=$'\e'$esc; }
    case $key in
        q|Q) break ;;
        r|R) t_idx=$default_t_idx c_idx=$default_c_idx o_idx=0; opt_vals=("${opt_defs[@]}"); preview_key=; full_redraw; continue ;;
        ''|' '|$'\r'|$'\n') (( col == 2 )) && cycle_opt "$o_idx" ;;
        $'\e[A'|$'\eOA') move_cur -1 ;;
        $'\e[B'|$'\eOB') move_cur  1 ;;
        $'\e[C'|$'\eOC') (( col = (col+1) % 3 )) ;;
        $'\e[D'|$'\eOD') (( col = (col+2) % 3 )) ;;
        *) continue ;;
    esac
    redraw
done

trap - EXIT INT TERM; cleanup

cmd=$(
    (( t_idx != default_t_idx )) && printf 'POWERLINE_THEME=%q '  "${themes[t_idx]}"
    (( c_idx != default_c_idx )) && printf 'POWERLINE_COLORS=%q ' "${colors[c_idx]}"
    for i in "${!opt_names[@]}"; do [[ ${opt_vals[i]} != "${opt_defs[i]}" ]] && printf '%s=%q ' "${opt_names[i]}" "${opt_vals[i]}"; done
    printf 'source %q' "$SCRIPT_PATH"
)

printf '\e[%s;1H\e[0m\e[J\n%s%s%s\n%s\n\n\e[?25h' $((hy+1)) "$C_HI$BOLD" "Add this to your ~/.bashrc:" "$RST" "$cmd"
