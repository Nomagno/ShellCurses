#!/bin/sh

. $(dirname $0)/shell_curses.sh

Cross=" X       X \n   X   X   \n     X     \n   X   X   \n X       X \n\n\n\n\n"
Circle="   0O O0   \n 0       0 \n0         0\n0         0\n0         0\n 0       0\n   0O O0   \n\n\n"
Empty= "------------\n|          |\n|          |\n|          |\n|          |\n------------\n\n\n\n"

compose1=""
compose2=""
compose3=""

twotimes=0 

tictactoe() {

  if [ "$1" = "1" ]; then
    compose1="C-X-C"
  fi
  if [ "$1" = "2" ]; then
    compose2="X-C-X"
  fi  
  if [ "$1" = "3" ]; then
    compose3="X-X-C"
  fi
}

tictactoe1() {

  tictactoe "1"
  var1=${compose1%[\-][A-Z][\-][A-Z]}
  varm=${compose1#[A-Z][\-]}
  var2=${varm%[\-][A-Z]}
  var3=${compose1#*[A-Z][\-][A-Z][\-]}
  

      if [ "$var1" = "C" ]; then
      printf "$Circle"
      elif [ "$var1" = "X" ]; then
      printf "$Cross"
      elif [ "$var1" = "E" ]; then
      printf "$Empty"
      fi
      
      if [ "$var2" = "C" ]; then
      printf "$Circle"
      elif [ "$var2" = "X" ]; then
      printf "$Cross"
      elif [ "$var2" = "E" ]; then
      printf "$Empty"
      fi

      if [ "$var3" = "C" ]; then
      printf "$Circle"
      elif [ "$var3" = "X" ]; then
      printf "$Cross"
      elif [ "$var3" = "E" ]; then
      printf "$Empty"
      fi
}

tictactoe2() {

  tictactoe "2"
  var12=${compose2%[\-][A-Z][\-][A-Z]}
  varm2=${compose2#[A-Z][\-]}
  var22=${varm2%[\-][A-Z]}
  var32=${compose2#*[A-Z][\-][A-Z][\-]}
  
      if [ "$var12" = "C" ]; then
      printf "$Circle"
      elif [ "$var12" = "X" ]; then
      printf "$Cross"
      elif [ "$var12" = "E" ]; then
      printf "$Empty"
      fi
      
      if [ "$var22" = "C" ]; then
      printf "$Circle"
      elif [ "$var22" = "X" ]; then
      printf "$Cross"
      elif [ "$var22" = "E" ]; then
      printf "$Empty"
      fi

      if [ "$var32" = "C" ]; then
      printf "$Circle"
      elif [ "$var32" = "X" ]; then
      printf "$Cross"
      elif [ "$var32" = "E" ]; then
      printf "$Empty"
      fi
  
}

tictactoe3() {

  tictactoe "3"
  var13=${compose3%[\-][A-Z][\-][A-Z]}
  varm3=${compose3#[A-Z][\-]}
  var23=${varm3%[\-][A-Z]}
  var33=${compose3#*[A-Z][\-][A-Z][\-]}
  
      if [ "$var13" = "C" ]; then
      printf "$Circle"
      elif [ "$var13" = "X" ]; then
      printf "$Cross"
      elif [ "$var13" = "E" ]; then
      printf "$Empty"
      fi
      
      if [ "$var23" = "C" ]; then
      printf "$Circle"
      elif [ "$var23" = "X" ]; then
      printf "$Cross"
      elif [ "$var23" = "E" ]; then
      printf "$Empty"
      fi

      if [ "$var33" = "C" ]; then
      printf "$Circle"
      elif [ "$var33" = "X" ]; then
      printf "$Cross"
      elif [ "$var33" = "E" ]; then
      printf "$Empty"
      fi
  
}


main() {
    window "TicTacToe" "grey" "100%"
    append "SCORE"
    endwin
    
    window "column1" "green" "33%"
    append "$(tictactoe1)"
    endwin

    col_right


    
    window "column2" "red" "33%"
    append "$(tictactoe2)"
    endwin

    col_right

    

    window "column3" "blue" "33%"
    append "$(tictactoe3)"
    endwin

    move_up

    window "TicTacClock" "grey" "100%"
    append "$(date +%H:%M:%S)"
    endwin



  }

captured_input_new=$(cat $captured_input)
  
main_loop


