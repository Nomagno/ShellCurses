#!/bin/sh
#simple curses library to create windows on terminal
#
#ShellCurses patch by Nomagno
#
#original author: Patrice Ferlet metal3d@copix.org
#
#create_buffer patch by Laurent Bachelier
#support for bgcolors by Markus Mikkolainen
#
##license: new BSD
#


version() {
  printf 'Version 1.0\n'
}
usage() {

  printf 'USAGE AFTER SOURCING\nwindow TITLE COLOR [WIDTH] | create a window with title, color and width
append TEXT [CENTERING] [COLOR] [BGCOLOR] | append text to the window
addsep | add separator
main_loop | initialization\n
Please see the included tictactoe example for more information and auxiliary commands.\n'
}

if [ "$1" = "-v"  ] || [ "$1" = "--version"  ]; then
  version
  exit
elif [ "$1" = "-h"  ] || [ "$1" = "--help"  ]; then
  usage
  exit
fi

VERBOSE=0
BSC_MODE="dashboard"

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
    echo "$(mktemp)"
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


bsc_init_chars() {
            _TL="+"
            _TR="+"
            _BL="+"
            _BR="+"
            _SEPL="+"
            _SEPR="+"
            _VLINE="|"
            _HLINE="-"
            SPINNER='-'
            _DIAMOND="*"
            _BLOCK="#"
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

    bsc_cols=$(expr $(tput cols) - 3)
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
    printf "%s" "$BSC_LINEBODY"
    bsc__nl
}

#clean the current line
clean_line(){
    #set default color
    reset_colors

    tput sc
    printf "$BSC_BLANKLINE"
    #tput el
    tput rc
}

append(){
    tmp8=$(mktemp)
    printf "%s\n"  "$1" | fold -w $((BSC_COLWIDTH-2)) -s > $tmp8
    while read -r line; do
        bsc__append "$line" "$2" "$3" "$4"
    done < $tmp8
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



#main loop called
main_loop (){

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

        bash -ic '{ read line; echo "$line" > $captured_input; kill 0; kill 0; } | { sleep 0.3; kill 0; }' 3>&1 2>/dev/null

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
