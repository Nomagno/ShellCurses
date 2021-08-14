#!/bin/sh
#simple curses library to create windows on terminal
#
#author: Patrice Ferlet metal3d@copix.org
##license: new BSD
#
#create_buffer patch by Laurent Bachelier
#
#POSIX Compliance patch by Nomagno
#
#restriction to local variables and
#rename variables to ones which will not collide
#by Markus Mikkolainen
#
#support for bgcolors by Markus Mikkolainen
#
#support for delay loop function (instead of sleep
#enabling keyboard input) by Markus Mikkolainen

ECHO=/bin/echo

export captured_input=$(mktemp)

bsc_create_buffer(){
    # Try to use SHM, then $TMPDIR, then /tmp
    if [ -d "/dev/shm" ]; then
        BUFFER_DIR="/dev/shm"
    elif [ -n "$TMPDIR" ]; then
        BUFFER_DIR="$TMPDIR"
    else
        BUFFER_DIR="/tmp"
    fi

    _buffername=""
    [ "$1" != "" ] &&  _buffername=$1 || _buffername="bashsimplecurses"

    # Try to use mktemp before using the unsafe method
    if [ -x "$(which mktemp)" ]; then
        #mktemp --tmpdir=${BUFFER_DIR} ${_buffername}.XXXXXXXXXX
        mktemp
    else
        echo "$(mktemp)"
    fi
}

#Usefull variables
BSC_BUFFER=$(bsc_create_buffer)
BSC_STDERR=$(bsc_create_buffer stderr)

reset_layout() {
    BSC_COLLFT=0
    BSC_COLWIDTH=0
    BSC_COLWIDTH_MAX=0
    BSC_WLFT=0
    # Height are not dynamically updated
    # Only at window and endwin call
    # Height of the current window
    BSC_WNDHGT=0
    # Height of the bottom of the current window
    BSC_COLHGT=0
    # Heigh of the bottom of the current column
    BSC_COLBOT=0
    # Height of the maximum bottom ever
    BSC_COLHGT_MAX=0
    # Flags to code the lib user window placement request
    BSC_NEWWIN_TOP_REQ=0
    BSC_NEWWIN_RGT_REQ=0
}

clean_env(){
    rm -rf "$BSC_BUFFER"
    reset_colors
    tput cnorm
    tput cvvis
    setterm -cursor on
}
#call on SIGINT and SIGKILL
#it removes buffer before to stop
bsc_on_kill(){
    clean_env
    exit 15
}

BSC_SIGINT=0
bsc_flag_sigint()
{
    # Defer sigint processing because otherwise commands are pushed into BSC_BUFFER due to redirect in main_loop, which is deleted in clean_env ...
    # This does not seem to be problematic with SIGKILL
    # lets admit it this handling of SIGINT is tedious
    BSC_SIGINT=1
}
trap bsc_on_kill TERM
trap bsc_flag_sigint INT

#initialize terminal
bsc_term_init(){
    if [ "$BSC_MODE" = dashboard ]; then
        tput clear
    fi
    # tput civis
}


#change line
bsc__nl(){
    BSC_WNDHGT=$((BSC_WNDHGT+1))
    tput cud1
    tput cub "$(tput cols)"
    [ $BSC_WLFT -gt 0 ] && tput cuf $BSC_WLFT
    tput sc
}


move_up(){
    BSC_NEWWIN_TOP_REQ=1
}

col_right(){
    BSC_NEWWIN_RGT_REQ=1
}

#initialize chars to use
_TL="\033(0l\033(B"
_TR="\033(0k\033(B"
_BL="\033(0m\033(B"
_BR="\033(0j\033(B"
_SEPL="\033(0t\033(B"
_SEPR="\033(0u\033(B"
_VLINE="\033(0x\033(B"
_HLINE="\033(0q\033(B"
_DIAMOND="\033(00\033(B"
_BLOCK="\033(01\033(B"
_SPINNER='-'

bsc_init_chars() {

    if [ "$LANG" != "" ]; then
        if [ $(printf "\xE2\x96\x88") = "\\xE2\\x96\\x88" ]; then
            _TL="+"
            _TR="+"
            _BL="+"
            _BR="+"
            _SEPL="+"
            _SEPR="+"
            _VLINE="|"
            _HLINE="-"
            _DIAMOND="*"
            _BLOCK="#"
        elif [ $(echo "$LANG" | grep -c UTF) = "1" ]; then
            _TL="\xE2\x94\x8C"
            _TR="\xE2\x94\x90"
            _BL="\xE2\x94\x94"
            _BR="\xE2\x94\x98"
            _SEPL="\xE2\x94\x9C"
            _SEPR="\xE2\x94\xA4"
            _VLINE="\xE2\x94\x82"
            _HLINE="\xE2\x94\x80"
            _DIAMOND="\xE2\x97\x86"
            _BLOCK="\xE2\x96\x88"
        fi
    fi
}

backtotoprow () {
    _travelback=""
    _travelback=$1

    # Testing if layout would require non destructive scrolling
    nbrows=$(tput lines)
    scrollback=$(( _travelback -nbrows ))
    if [ $scrollback -gt 0 ]; then
    #    tput rin $scrollback
    #    _travelback=$(( _travelback - scrollback ))
        echo "Warning: Current layout is exceeding terminal size. This will break window top alignment. Increase terminal height/reduce window content for proper rendering." >&2
    fi
    [ "$_travelback" -gt 0 ] && tput cuu "$_travelback"
}

#Append a window 
window() {
    _title=""
    _color=""
    _bgcolor=""
    _title=$1
    _color=$2
    _bgcolor=$4

    [ "$VERBOSE" -eq 2 ] && echo "Begin of window $_title" >&2

    # Manage new window position
    case "$BSC_NEWWIN_TOP_REQ$BSC_NEWWIN_RGT_REQ" in
        "00" )
        # Window is requested to be displayed under the previous one
        ;;
        "01" )
        # Window is requested to be displayed to the right of the last one

        BSC_WLFT=$(( BSC_WLFT + BSC_COLWIDTH ))
        [ $BSC_WLFT -gt 0 ] && tput cuf $(( BSC_WLFT + BSC_COLWIDTH ))
    backtotoprow $BSC_WNDHGT
        BSC_COLHGT=$(( BSC_COLHGT - BSC_WNDHGT))
        ;;
        "10" )
        # Window is requested to be displayed overwriting the ones above (??!??)
        # Instead, we reset the layout, enabling more possibilities
        tput cud $(( BSC_COLHGT_MAX - BSC_COLBOT ))
        reset_layout
        ;;
        "11" )
        # Window is requested to be displayed in a new column starting from top
    backtotoprow $BSC_COLHGT
        
        BSC_COLLFT=$(( BSC_COLLFT + BSC_COLWIDTH_MAX ))
        BSC_WLFT=$BSC_COLLFT

        BSC_COLHGT=0
        BSC_COLBOT=0
        BSC_COLWIDTH_MAX=0
        ;;
        * )
        echo "Unexpected window position requirement"
        clean_env
        exit 1
    esac

    # Reset window position mechanism for next window
    BSC_NEWWIN_TOP_REQ=0
    BSC_NEWWIN_RGT_REQ=0
    BSC_WNDHGT=0

    bsc_cols=$(tput cols)
    case $3  in
        "" )
            # No witdh given
        ;;
        *% )
            w=$(echo "$3" | sed 's/%//')
            bsc_cols=$((w*bsc_cols/100))
        ;;
        * )
            bsc_cols=$3
        ;;
    esac
    
    if [ "$bsc_cols" -lt 3 ]; then
        echo "Column width of window \"$_title\" is too narrow to render (sz=$bsc_cols)." >&2
        exit 1;
    fi

    BSC_COLWIDTH=$bsc_cols
    [ "$BSC_COLWIDTH" -gt $BSC_COLWIDTH_MAX ] && BSC_COLWIDTH_MAX=$BSC_COLWIDTH

    # Create an empty line for this window
    BSC_BLANKLINE=$(head -c "$BSC_COLWIDTH" /dev/zero | tr '\0' ' ')
    BSC_LINEBODY=${BSC_BLANKLINE}
    contentLen=${#BSC_LINEBODY}
    BSC_LINEBODY=$(echo "$BSC_LINEBODY" | sed "s/ /$_HLINE/g")

    _len=""
    _len=${#_title}

    if [ "$BSC_TITLECROP" -eq 1 ] && [ "$_len" -gt "$contentLen" ]; then
        _title="${_title:0:$contentLen}"
        _len=${#_title}
    fi

    bsc_left=$(( (bsc_cols - _len)/2 -1 ))

    # Init top left window corner
    tput cub "$(tput cols)"
    [ $BSC_WLFT -gt 0 ] && tput cuf $BSC_WLFT
    tput sc

    #draw upper line
    printf "$_TL$BSC_LINEBODY$_TR"

    #next line, draw title
    bsc__nl
    append "$_title" center "$_color" "$_bgcolor"

    #then draw bottom line for title
    addsep
}

reset_colors(){
    printf "\033[00m"
}
setcolor(){
    _color=""
    _color=$1
    case $_color in
        grey|gray)
            printf "\033[01;30m"
            ;;
        red)
            printf "\033[01;31m"
            ;;
        green)
            printf "\033[01;32m"
            ;;
        yellow)
            printf "\033[01;33m"
            ;;
        blue)
            printf "\033[01;34m"
            ;;
        magenta)
            printf "\033[01;35m"
            ;;
        cyan)
            printf "\033[01;36m"
            ;;
        white)
            printf "\033[01;37m"
            ;;
        *) #default should be 39 maybe?
            printf "\033[01;39m"
            ;;
    esac
}
setbgcolor(){
    _2bgcolor=""
    _2bgcolor=$1
    case $_2bgcolor in
        grey|gray)
            printf "\033[01;40m"
            ;;
        red)
            printf "\033[01;41m"
            ;;
        green)
            printf "\033[01;42m"
            ;;
        yellow)
            printf "\033[01;43m"
            ;;
        blue)
            printf "\033[01;44m"
            ;;
        magenta)
            printf "\033[01;45m"
            ;;
        cyan)
            printf "\033[01;46m"
            ;;
        white)
            printf "\033[01;47m"
            ;;
        black)
            printf "\033[01;49m"
            ;;
        *) #default should be 49
            printf "\033[01;49m"
            ;;
    esac

}

#append a separator, new line
addsep (){
    clean_line
    $ECHO -ne "$_SEPL$BSC_LINEBODY$_SEPR"
    bsc__nl
}

#clean the current line
clean_line(){
    #set default color
    reset_colors

    tput sc
    $ECHO -ne  "$BSC_BLANKLINE"
    #tput el
    tput rc
}

#add text on current window
append_file(){
    _filetoprint=""
    _filetoprint=$1
    shift
    append_command "cat $_filetoprint" "$@"
}
#
#   blinkenlights <text> <color> <color2> <incolor> <bgcolor> <light1> [light2...]
#
blinkenlights(){
    _2color=""
    _color2=""
    _2incolor=""
    _3bgcolor=""
    _2lights=""
    _2col=""
    _2text=""
    _2text=$1
    _2color=$2
    _color2=$3
    _2incolor=$4
    _3bgcolor=$5

    params0="$1"
    params1="$2"
    params2="$3"
    params3="$4"
    params4="$5"
    params5="$6"

    _2lights=""
    while [ -n "$params0" ];do
        _2col=$_2incolor
        [ "${params0}" = "1" ] && _2col=$_2color
        [ "${params0}" = "2" ] && _2col=$_color2
        _2lights="${_2lights} ${_DIAMOND} ${_2col} ${_3bgcolor}"
        unset "params0"
        
    done

    bsc__multiappend "left" "[" "$_2incolor" "$_3bgcolor" "$_2lights" "]${_2text}" "$_2incolor" "$_3bgcolor"
}

#
#   vumeter <text> <width> <value> <max> [color] [color2] [inactivecolor] [bgcolor]
#
vumeter(){
    _done=""
    _todo=""
    _over=""
    _2len=""
    _max=""

    _green=""
    _red=""
    _rest=""

    _3incolor=""
    _3okcolor=""
    _3overcolor=""
    _text=$1
    _2len=$2
    _value=$3
    _max=$4
    _2len=$(( _2len - 2 ))
    _3incolor=$7
    _3okcolor=$5
    _3overcolor=$6
    [ "$_3incolor" = "" ] && _3incolor="grey"
    [ "$_3okcolor" = "" ] && _3okcolor="green"
    [ "$_3overcolor" = "" ] && _3overcolor="red"

    done=$(( _value * _2len / _max  + 1 ))
    todo=$(( _2len - done - 1))

    [ "$(( _2len * 2 / 3 ))" -lt "$done" ] && {
        _over=$(( done - ( _2len * 2 /3 )))
        _done=$(( _2len * 2 / 3 ))
    }
    _green=""
    _red=""
    _rest=""

    for i in $(seq 1 $(($_done)));do
        _green="${_green}|"
    done
    for i in $(seq 0 $(($_over)));do
        _red="${_red}|"
    done
    _red=${_red}
    for i in $(seq 0 $(($_todo)));do
        _rest="${_rest}."
    done
    [ "$_red" = ""  ] && bsc__multiappend "left" "[" $_3incolor "black" "${_green}" $_3okcolor "black" "${_rest}]${_text}" $_3incolor "black"
    [ "$_red" != ""  ] && bsc__multiappend "left" "[" $_3incolor "black" "${_green}" $_3okcolor "black" "${_red}" $_3overcolor "black" "${_rest}]${_text}" $_3incolor "black"
}
#
#
#
#   progressbar <length> <progress> <max> [color] [bgcolor]
#
progressbar(){
    _done=""
    _todo=""
    _3len=""
    _5progress=""
    _5max=""
    _bar=""
    _modulo=""
    _3len=$1
    _5progress=$2
    _5max=$3
 
    _done=$(( _5progress * _3len / _5max ))
    _todo=$(( _3len - _done - 1 ))
    _modulo=$(( $(date +%s) % 4 ))

    bar="[";

    if [ "$_done" -lt "$_3len" ]; then
        bar="${_bar}${_SPINNER}"
    fi

    bar="${_bar}]"
    bsc__append "$_bar" "left" "$4" "$5"
}
append(){
    tmp8=$(mktemp)
    printf "%s\n"  "$1" | fold -w $((BSC_COLWIDTH-2)) -s > $tmp8
    while read -r line; do
        bsc__append "$line" "$2" "$3" "$4"
    done < $tmp8
}
#
#   append a single line of text consisting of multiple
#   segments
#   bsc__multiappend <centering> (<text> <color> <bgcolor>)+
#
bsc__multiappend(){
    _4len=""
    _7text=""
    declare -a params
    params0="$1"
    params1="$2"
    params2="$3"
    _text=""
    unset "params0"
    while [ -n "$params" ];do
        _text="${_7text}${params0}"
        unset "params0"
        unset "params1"
        unset "params2"
    done
    clean_line
    tput sc
     echo -ne "$_VLINE"
    _4len=""
    tmp9=$(mktemp)
    $ECHO -n "$1" > "$tmp9"
    _4len=$(wc -c < $tmp9)
    bsc_left=$( BSC_COLWIDTH - _4len/2 - 1 )

    [ "${params0}" = "left" ] && bsc_left=0
    unset "params0"
    params0="$1"
    params1="$2"
    params2="$3"
    [ $bsc_left -gt 0 ] && tput cuf $bsc_left
    while [ -n "${params0}" ];do
        setcolor "${params1}"
        setbgcolor "${params2}"
         "$params0"
        reset_colors
        unset "params0"
        unset "params1"
        unset "params2"
    done
    tput rc
    tput cuf $((BSC_COLWIDTH-1))
    printf "$_VLINE"
    bsc__nl
}
#
#   bsc__append <text> [centering] [color] [bgcolor]
#
bsc__append(){
    clean_line
    tput sc
    printf  "$_VLINE"
    _5len=""
    tmp10=$(mktemp)
    printf "$1" > "$tmp10"
    _5len=$(wc -c < $tmp10)
    bsc_left=$(( (BSC_COLWIDTH - _5len)/2 - 1 ))

    [ "$2" = "left" ] && bsc_left=0

    [ $bsc_left -gt 0 ] && tput cuf $bsc_left
    setcolor "$3"
    setbgcolor "$4"
    printf "$1"
    reset_colors
    tput rc
    tput cuf $((BSC_COLWIDTH-1))
    printf "$_VLINE"
    bsc__nl
}

#add separated values on current window
append_tabbed(){
    [ $2 = "" ] && echo "append_tabbed: Second argument needed" >&2 && exit 1
    [ "$3" != "" ] && delim=$3 || delim=":"
    clean_line

    printf "$_VLINE"
    _6len=""
    tmp11=$(mktemp)
    printf "$1" > "$tmp9"
    _6len=$(wc -c < $tmp11)
    cell_wdt=$((BSC_COLWIDTH/$2))

    setcolor "$4"
    setbgcolor "$5"
    tput sc

    _i=""
    for _i in $(seq 0 $(($2))); do
        tput rc
        cell_offset=$((cell_wdt*_i))
        [ $cell_offset -gt 0 ] && tput cuf $cell_offset
        $ECHO -n "$(echo -n "$1" | cut -f$((i+1)) -d"$delim" | cut -c 1-$((cell_wdt-3)))"
    done

    tput rc
    reset_colors
    tput cuf $((BSC_COLWIDTH-2))
    printf "$_VLINE"
    bsc__nl
}

#append a command output
append_command(){
    tmp20=$(mktemp)
    $1 2>&1 | fold -w $((BSC_COLWIDTH-2)) -s > $tmp20
    while read -r line; do
        bsc__append "$line" left "$2" "$3"
    done < $tmp20
    }

#close the window display
endwin(){
    # Plot bottom line
    printf "$_BL$BSC_LINEBODY$_BR"
    bsc__nl

    BSC_COLHGT=$(( BSC_COLHGT + BSC_WNDHGT ))

    if [ $BSC_COLHGT -gt $BSC_COLBOT ]; then
        BSC_COLBOT=$BSC_COLHGT
    fi

    if [ $BSC_COLBOT -gt $BSC_COLHGT_MAX ]; then
        BSC_COLHGT_MAX=$BSC_COLBOT
    fi
    [ "$VERBOSE" -eq 2 ] && echo "End of window $_title" >&2
}

usage() {
    script_name=$(basename "$0")
    printf "See BashSimpleCurses for usage\n"
}

parse_args (){
    BSC_MODE=dashboard
    VERBOSE=1
    BSC_TITLECROP=0
    time=1
    while [ $# -gt 0 ]; do
        # shellcheck disable=SC2034
        case "$1" in
        -c | --crop )        BSC_TITLECROP=1; shift 1 ;;
        -h | --help )        usage; exit 0 ;;
        -q | --quiet )       VERBOSE=0; shift 1 ;;
        -s | --scroll )      BSC_MODE=scroll; shift 1 ;;
        -t | --time )        time=$2; shift 2 ;;
        -V | --verbose )     VERBOSE=2; shift 1 ;;
        -- ) return 0 ;;
        * ) echo "Option $1 does not exist"; exit 1;;
        esac
    done
}



#main loop called
main_loop (){
    parse_args "$@"

    bsc_term_init
    bsc_init_chars

    if [ "$BSC_MODE" = dashboard ]; then
        trap "tput clear" WINCH
    fi

    while true; do
        reset_layout
        echo "" > "$BSC_BUFFER"
        rm -f "$BSC_STDERR"

        if [ "$BSC_MODE" = dashboard ]; then
            tput clear >> "$BSC_BUFFER"
            tput cup 0 0 >> "$BSC_BUFFER"
        fi

        main >> "$BSC_BUFFER" 2>"$BSC_STDERR"

        # Go under the higest column, from under the last displayed window
        tput cud $(( BSC_COLHGT_MAX - BSC_COLBOT )) >> "$BSC_BUFFER"
        tput cub "$(tput cols)" >> "$BSC_BUFFER"

        sigint_check

        # Display the buffer
        cat "$BSC_BUFFER"
    
        [ $VERBOSE -gt 0 ] && [ -f "$BSC_STDERR" ] && cat "$BSC_STDERR" && rm "$BSC_STDERR"

        bash -ic '{ read line; echo $line > $captured_input; kill 0; kill 0; } | { sleep 0.3; kill 0; }' 3>&1 2>/dev/null

        retval=$?
        if [ $retval -eq 255 ]; then
                clean_env
                exit "$retval"
        fi


        sigint_check
    done
}
# Calls to this function are placed so as to avoid stdout mangling
sigint_check (){
    if [ $BSC_SIGINT -eq 1 ]; then
        clean_env
        [ -f "$BSC_STDERR" ] && cat "$BSC_STDERR" && rm "$BSC_STDERR"
        # https://mywiki.wooledge.org/SignalTrap
        trap - INT
        kill -s INT "$$"
    fi
}
