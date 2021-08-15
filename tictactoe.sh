#!/bin/sh
. ./shell_curses.sh
Cross=" X       X \\n   X   X   \\n     X     \\n   X   X   \\n X       X \\n\\n\\n\\n\\n"
Circle="   0O O0   \\n 0       0 \\n0         0\\n0         0\\n0         0\\n 0       0\\n   0O O0   \\n\\n\\n"
Empty="____________\\n|          |\\n|          |\\n|          |\\n|          |\\n____________\\n\\n\\n\\n"

score1=0
score2=0

compose1=""
compose2=""
compose3="" 


p1=""
p2=""
c1="E"
c2="E"
c3="E"
c4="E"
c5="E"
c6="E"
c7="E"
c8="E"
c9="E"

pc1="$Empty"
pc2="$Empty"
pc3="$Empty"
pc4="$Empty"
pc5="$Empty"
pc6="$Empty"
pc7="$Empty"
pc8="$Empty"
pc9="$Empty"

board_reset() {
  c1="E"
  c2="E"
  c3="E"
  c4="E"
  c5="E"
  c6="E"
  c7="E"
  c8="E"
  c9="E"
  
  pc1="$Empty"
  pc2="$Empty"
  pc3="$Empty"
  pc4="$Empty"
  pc5="$Empty"
  pc6="$Empty"
  pc7="$Empty"
  pc8="$Empty"
  pc9="$Empty"


}


tictactoe() {

  processed_input=$(cat "$captured_input")
  p1=${processed_input#[q]}
  p2=${processed_input#[w]}

  if [ "$p1" = "1" ] && [ "$c1" != "C" ]; then
    c1="X"
    pc1="$Cross"
  elif [ "$p1" = "2" ] && [ "$c2" != "C" ]; then
    c2="X"
    pc2="$Cross"
  elif [ "$p1" = "3" ] && [ "$c3" != "C" ]; then
    c3="X"
    pc3="$Cross"
  elif [ "$p1" = "4" ] && [ "$c4" != "C" ]; then
    c4="X"
    pc4="$Cross"
  elif [ "$p1" = "5" ] && [ "$c5" != "C" ]; then
    c5="X"
    pc5="$Cross"
  elif [ "$p1" = "6" ]  && [ "$c6" != "C" ]; then
    c6="X"
    pc6="$Cross"
  elif [ "$p1" = "7" ] && [ "$c7" != "C" ]; then
    c7="X"
    pc7="$Cross"
  elif [ "$p1" = "8" ] && [ "$c8" != "C" ]; then
    c8="X"
    pc8="$Cross"
  elif [ "$p1" = "9" ]  && [ "$c9" != "C" ]; then
    c9="X" 
    pc9="$Cross" 
  fi


  if [ "$p2" = "1" ] && [ "$c1" != "X" ]; then
    c1="C"
    pc1="$Circle"
  elif [ "$p2" = "2" ] && [ "$c2" != "X" ]; then
    c2="C"
    pc2="$Circle"
  elif [ "$p2" = "3" ] && [ "$c3" != "X" ]; then
    c3="C"
    pc3="$Circle"
  elif [ "$p2" = "4" ] && [ "$c4" != "X" ]; then
    c4="C"
    pc4="$Circle"
  elif [ "$p2" = "5" ] && [ "$c5" != "X" ]; then
    c5="C"
    pc5="$Circle"
  elif [ "$p2" = "6" ] && [ "$c6" != "X" ]; then
    c6="C"
    pc6="$Circle"
  elif [ "$p2" = "7" ] && [ "$c7" != "X" ]; then
    c7="C"
    pc7="$Circle"
  elif [ "$p2" = "8" ] && [ "$c8" != "X" ]; then
    c8="C"
    pc8="$Circle"
  elif [ "$p2" = "9" ] && [ "$c9" != "X" ]; then
    c9="C" 
    pc9="$Circle"
  fi

  if [ "$c1" = "$c2"  ] && [ "$c2" = "$c3" ]; then
    if [ "$c1" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c1" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi
  elif [ "$c4" = "$c5"  ] && [ "$c5" = "$c6" ]; then
    if [ "$c4" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c4" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi
  elif [ "$c7" = "$c8"  ] && [ "$c8" = "$c9" ]; then
    if [ "$c7" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c7" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi


  elif [ "$c1" = "$c4"  ] && [ "$c4" = "$c7" ]; then
    if [ "$c1" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c1" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi
  elif [ "$c2" = "$c5"  ] && [ "$c5" = "$c8" ]; then
    if [ "$c2" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c2" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi
  elif [ "$c3" = "$c6"  ] && [ "$c6" = "$c9" ]; then
      if [ "$c3" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c3" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi


  elif [ "$c1" = "$c5"  ] && [ "$c5" = "$c9" ]; then
    if [ "$c1" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c1" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi
  elif [ "$c7" = "$c5"  ] && [ "$c5" = "$c3" ]; then
    if [ "$c7" = "X" ]; then
      board_reset
      score1=$(( score2 + 1 ))
    elif [ "$c7" = "C" ]; then
      board_reset
      score2=$(( score2 + 1 ))
    fi
  fi

  echo > "$captured_input"
  p1=""
  p2=""

}

main() {



    tictactoe
    window "TicTacToe" "grey" "100%"
    append "$(printf "How to play: P1 - q | P2 - w \n"; printf "PN - the player letter and the cell number, e.g q5\n"; printf "SCORE: CROSS - $score1 ||| CIRCLE - $score2 \n")"
    endwin
    
    window "column1" "green" "33%"
    append "$(printf "${pc1}"; printf "${pc4}"; printf "${pc7}")"
    endwin

    col_right

    window "column2" "red" "33%"
    append "$(printf "${pc2}"; printf "${pc5}"; printf "${pc8}")"
    endwin

    col_right
    
    window "column3" "blue" "33%"
    append "$(printf "${pc3}"; printf "${pc6}"; printf "${pc9}")"
    endwin

    move_up

    window "TicTacClock" "grey" "100%"
    append "$(date +%H:%M:%S)"
    endwin

  }

main_loop
