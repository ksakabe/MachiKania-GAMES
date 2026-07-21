REM ============================================================
REM sl command ASCII version for KM-BASIC
REM
REM KM-BASIC port and modifications:
REM   Copyright 2026 Kazuhisa Sakabe
REM
REM Original sl program and ASCII locomotive artwork:
REM   Copyright 1993,1998,2014 Toyoda Masashi
REM   https://github.com/mtoyoda/sl
REM
REM This program is based on and modified from the original sl.
REM ============================================================

USECLASS STRDIM
USEVAR SCRW,SCRH,FRAME,PAT,ROW,DRAWX,DRAWY,START,LENGTH
USEVAR DBODY,DWHEEL,COAL,CBODY,CWHEEL,CCOAL
USEVAR LBODY,LWHEEL,LCOAL,LCAR
USEVAR MODE,FLY
USEVAR P1,P2,P3

DBODY=NEW(STRDIM,6)
DWHEEL=NEW(STRDIM,5,2)
COAL=NEW(STRDIM,10)

REM LOCOMOTIVE BODY (ROWS 0-6)
DBODY.SETSTR("      ====        ________                ___________ ",0)
DBODY.SETSTR("  _D _|  |_______/        \__I_I_____===__|_________| ",1)
DBODY.SETSTR("   |(_)---  |   H\________/ |   |        =|___ ___|   ",2)
DBODY.SETSTR("   /     |  |   H  |  |     |   |         ||_| |_||   ",3)
DBODY.SETSTR("  |      |  |   H  |__--------------------| [___] |   ",4)
DBODY.SETSTR("  | ________|___H__/__|_____/[][]~\_______|       |   ",5)
DBODY.SETSTR("  |/ |   |-----------I_____I [][] []  D   |=======|__ ",6)

REM SIX WHEEL FRAMES (ROWS 7-9)
DWHEEL.SETSTR("__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ ",0,0)
DWHEEL.SETSTR(" |/-=|___|=    ||    ||    ||    |_____/~\___/        ",0,1)
DWHEEL.SETSTR("  \_/      \O=====O=====O=====O_/      \_/            ",0,2)
DWHEEL.SETSTR("__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ ",1,0)
DWHEEL.SETSTR(" |/-=|___|=O=====O=====O=====O   |_____/~\___/        ",1,1)
DWHEEL.SETSTR("  \_/      \__/  \__/  \__/  \__/      \_/            ",1,2)
DWHEEL.SETSTR("__/ =| o |=-O=====O=====O=====O \ ____Y___________|__ ",2,0)
DWHEEL.SETSTR(" |/-=|___|=    ||    ||    ||    |_____/~\___/        ",2,1)
DWHEEL.SETSTR("  \_/      \__/  \__/  \__/  \__/      \_/            ",2,2)
DWHEEL.SETSTR("__/ =| o |=-~O=====O=====O=====O\ ____Y___________|__ ",3,0)
DWHEEL.SETSTR(" |/-=|___|=    ||    ||    ||    |_____/~\___/        ",3,1)
DWHEEL.SETSTR("  \_/      \__/  \__/  \__/  \__/      \_/            ",3,2)
DWHEEL.SETSTR("__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ ",4,0)
DWHEEL.SETSTR(" |/-=|___|=   O=====O=====O=====O|_____/~\___/        ",4,1)
DWHEEL.SETSTR("  \_/      \__/  \__/  \__/  \__/      \_/            ",4,2)
DWHEEL.SETSTR("__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ ",5,0)
DWHEEL.SETSTR(" |/-=|___|=    ||    ||    ||    |_____/~\___/        ",5,1)
DWHEEL.SETSTR("  \_/      \_O=====O=====O=====O/      \_/            ",5,2)

REM TENDER (ROWS 0-10)
COAL.SETSTR("                              ",0)
COAL.SETSTR("                              ",1)
COAL.SETSTR("    _________________         ",2)
COAL.SETSTR("   _|                \_____A  ",3)
COAL.SETSTR(" =|                        |  ",4)
COAL.SETSTR(" -|                        |  ",5)
COAL.SETSTR("__|________________________|_ ",6)
COAL.SETSTR("|__________________________|_ ",7)
COAL.SETSTR("   |_D__D__D_|  |_D__D__D_|   ",8)
COAL.SETSTR("    \_/   \_/    \_/   \_/    ",9)
COAL.SETSTR("                              ",10)

REM C51 BODY AND SIX WHEEL FRAMES
CBODY=NEW(STRDIM,6)
CWHEEL=NEW(STRDIM,5,3)
CCOAL=NEW(STRDIM,11)
CBODY.SETSTR("        ___                                            ",0)
CBODY.SETSTR("       _|_|_  _     __       __             ___________",1)
CBODY.SETSTR("    D__/   \_(_)___|  |__H__|  |_____I_Ii_()|_________|",2)
CBODY.SETSTR("     | `---'   |:: `--'  H  `--'         |  |___ ___|  ",3)
CBODY.SETSTR("    +|~~~~~~~~++::~~~~~~~H~~+=====+~~~~~~|~~||_| |_||  ",4)
CBODY.SETSTR("    ||        | ::       H  +=====+      |  |::  ...|  ",5)
CBODY.SETSTR("|    | _______|_::-----------------[][]-----|       |  ",6)
CWHEEL.SETSTR("| /~~ ||   |-----/~~~~\  /[I_____I][][] --|||_______|__",0,0)
CWHEEL.SETSTR("------'|oOo|=[]=-      ||      ||      |  ||=======_|__",0,1)
CWHEEL.SETSTR("/~\____|___|/~\_|  O=======O=======O   |__|+-/~\_|     ",0,2)
CWHEEL.SETSTR("\_/         \_/  \____/  \____/  \____/      \_/       ",0,3)
CWHEEL.SETSTR("| /~~ ||   |-----/~~~~\  /[I_____I][][] --|||_______|__",1,0)
CWHEEL.SETSTR("------'|oOo|=[]=- O=======O=======O    |  ||=======_|__",1,1)
CWHEEL.SETSTR("/~\____|___|/~\_|      ||      ||      |__|+-/~\_|     ",1,2)
CWHEEL.SETSTR("\_/         \_/  \____/  \____/  \____/      \_/       ",1,3)
CWHEEL.SETSTR("| /~~ ||   |-----/~~~~\  /[I_____I][][] --|||_______|__",2,0)
CWHEEL.SETSTR("------'|oOo|==[]=- O=======O=======O   |  ||=======_|__",2,1)
CWHEEL.SETSTR("/~\____|___|/~\_|      ||      ||      |__|+-/~\_|     ",2,2)
CWHEEL.SETSTR("\_/         \_/  \____/  \____/  \____/      \_/       ",2,3)
CWHEEL.SETSTR("| /~~ ||   |-----/~~~~\  /[I_____I][][] --|||_______|__",3,0)
CWHEEL.SETSTR("------'|oOo|===[]=- O=======O=======O  |  ||=======_|__",3,1)
CWHEEL.SETSTR("/~\____|___|/~\_|      ||      ||      |__|+-/~\_|     ",3,2)
CWHEEL.SETSTR("\_/         \_/  \____/  \____/  \____/      \_/       ",3,3)
CWHEEL.SETSTR("| /~~ ||   |-----/~~~~\  /[I_____I][][] --|||_______|__",4,0)
CWHEEL.SETSTR("------'|oOo|===[]=-    ||      ||      |  ||=======_|__",4,1)
CWHEEL.SETSTR("/~\____|___|/~\_|    O=======O=======O |__|+-/~\_|     ",4,2)
CWHEEL.SETSTR("\_/         \_/  \____/  \____/  \____/      \_/       ",4,3)
CWHEEL.SETSTR("| /~~ ||   |-----/~~~~\  /[I_____I][][] --|||_______|__",5,0)
CWHEEL.SETSTR("------'|oOo|==[]=-     ||      ||      |  ||=======_|__",5,1)
CWHEEL.SETSTR("/~\____|___|/~\_|   O=======O=======O  |__|+-/~\_|     ",5,2)
CWHEEL.SETSTR("\_/         \_/  \____/  \____/  \____/      \_/       ",5,3)

REM C51 TENDER IS SHIFTED DOWN ONE ROW FROM THE LOCOMOTIVE.
CCOAL.SETSTR("                              ",0)
CCOAL.SETSTR("                              ",1)
CCOAL.SETSTR("                              ",2)
CCOAL.SETSTR("    _________________         ",3)
CCOAL.SETSTR("   _|                \_____A  ",4)
CCOAL.SETSTR(" =|                        |  ",5)
CCOAL.SETSTR(" -|                        |  ",6)
CCOAL.SETSTR("__|________________________|_ ",7)
CCOAL.SETSTR("|__________________________|_ ",8)
CCOAL.SETSTR("   |_D__D__D_|  |_D__D__D_|   ",9)
CCOAL.SETSTR("    \_/   \_/    \_/   \_/    ",10)
CCOAL.SETSTR("                              ",11)

REM LONG SL LOGO TRAIN
LBODY=NEW(STRDIM,3)
LWHEEL=NEW(STRDIM,5,1)
LCOAL=NEW(STRDIM,5)
LCAR=NEW(STRDIM,5)
LBODY.SETSTR("     ++      +------ ",0)
LBODY.SETSTR("     ||      |+-+ |  ",1)
LBODY.SETSTR("   /---------|| | |  ",2)
LBODY.SETSTR("  + ========  +-+ |  ",3)
LWHEEL.SETSTR(" _|--O========O~\-+  ",0,0)
LWHEEL.SETSTR("//// \_/      \_/    ",0,1)
LWHEEL.SETSTR(" _|--/O========O\-+  ",1,0)
LWHEEL.SETSTR("//// \_/      \_/    ",1,1)
LWHEEL.SETSTR(" _|--/~O========O-+  ",2,0)
LWHEEL.SETSTR("//// \_/      \_/    ",2,1)
LWHEEL.SETSTR(" _|--/~\------/~\-+  ",3,0)
LWHEEL.SETSTR("//// \_O========O    ",3,1)
LWHEEL.SETSTR(" _|--/~\------/~\-+  ",4,0)
LWHEEL.SETSTR("//// \O========O/    ",4,1)
LWHEEL.SETSTR(" _|--/~\------/~\-+  ",5,0)
LWHEEL.SETSTR("//// O========O_/    ",5,1)
LCOAL.SETSTR("____                 ",0)
LCOAL.SETSTR("|   \@@@@@@@@@@@     ",1)
LCOAL.SETSTR("|    \@@@@@@@@@@@@@_ ",2)
LCOAL.SETSTR("|                  | ",3)
LCOAL.SETSTR("|__________________| ",4)
LCOAL.SETSTR("   (O)       (O)     ",5)
LCAR.SETSTR("____________________ ",0)
LCAR.SETSTR("|  ___ ___ ___ ___ | ",1)
LCAR.SETSTR("|  |_| |_| |_| |_| | ",2)
LCAR.SETSTR("|__________________| ",3)
LCAR.SETSTR("|__________________| ",4)
LCAR.SETSTR("   (O)        (O)    ",5)

SCRW=SYSTEM(20)
SCRH=SYSTEM(21)
FRAME=0
MODE=0
FLY=0
COLOR 7
CLS

REM DOWN=D51, RIGHT=C51, LEFT=LONG, UP=FLY CURRENT TRAIN.
FOR DRAWX=SCRW-1 TO -87 STEP -1
  K=INKEY()
  IF K=$26 THEN FLY=1
  IF K=$27 THEN MODE=1:FLY=0
  IF K=$28 THEN MODE=0:FLY=0
  IF K=$25 THEN MODE=2:FLY=0

  CLS
  PAT=(87+DRAWX)%6
  IF PAT<0 THEN PAT=PAT+6

  IF MODE=0 THEN
    REM D51
    DRAWY=SCRH/2-5
    IF FLY THEN DRAWY=DRAWX/7+SCRH-SCRW/7-10
    FOR ROW=0 TO 10
      IF ROW<7 THEN GOSUB PUTSTR,DRAWY+ROW,DRAWX,DBODY.GETSTR$(ROW)
      IF ROW>=7 AND ROW<10 THEN GOSUB PUTSTR,DRAWY+ROW,DRAWX,DWHEEL.GETSTR$(PAT,ROW-7)
      GOSUB PUTSTR,DRAWY+ROW,DRAWX+53,COAL.GETSTR$(ROW)
    NEXT
    F=7

  ELSEIF MODE=1 THEN
    REM C51
    DRAWY=SCRH/2-5
    IF FLY THEN DRAWY=DRAWX/7+SCRH-SCRW/7-11
    FOR ROW=0 TO 11
      IF ROW<7 THEN GOSUB PUTSTR,DRAWY+ROW,DRAWX,CBODY.GETSTR$(ROW)
      IF ROW>=7 AND ROW<11 THEN GOSUB PUTSTR,DRAWY+ROW,DRAWX,CWHEEL.GETSTR$(PAT,ROW-7)
      GOSUB PUTSTR,DRAWY+ROW,DRAWX+55,CCOAL.GETSTR$(ROW)
    NEXT
    F=7

  ELSE
    REM LONG LOGO TRAIN
    DRAWY=SCRH/2-3
    P1=0:P2=0:P3=0
    IF FLY THEN
      DRAWY=DRAWX/6+SCRH-SCRW/6-6
      P1=2:P2=4:P3=6
    ENDIF
    FOR ROW=0 TO 6
      IF ROW<4 THEN GOSUB PUTSTR,DRAWY+ROW,DRAWX,LBODY.GETSTR$(ROW)
      IF ROW>=4 AND ROW<6 THEN GOSUB PUTSTR,DRAWY+ROW,DRAWX,LWHEEL.GETSTR$(PAT,ROW-4)
      IF ROW<6 THEN
        GOSUB PUTSTR,DRAWY+ROW+P1,DRAWX+21,LCOAL.GETSTR$(ROW)
        GOSUB PUTSTR,DRAWY+ROW+P2,DRAWX+42,LCAR.GETSTR$(ROW)
        GOSUB PUTSTR,DRAWY+ROW+P3,DRAWX+63,LCAR.GETSTR$(ROW)
      ENDIF
    NEXT
    F=4
  ENDIF

  REM THREE RISING PUFFS, PHASED FOUR FRAMES APART.
  FOR I=0 TO 2
    P=(FRAME+I*4)%16
    X=DRAWX+F+P/2
    Y=DRAWY-1-P/4
    IF P<4 THEN
      S$="(@@@)"
    ELSEIF P<8 THEN
      S$="(@)"
    ELSEIF P<12 THEN
      S$="O"
    ELSE
      S$="o"
    ENDIF
    GOSUB PUTSTR,Y,X,S$
  NEXT

  WAIT 2
  FRAME=FRAME+1
NEXT

CLS
CURSOR 0,SCRH-1
END

REM PRINT A STRING WITH LEFT/RIGHT/TOP/BOTTOM CLIPPING.
LABEL PUTSTR
  VAR DRAWY,DRAWX,START,LENGTH,A$
  DRAWY=ARGS(1)
  DRAWX=ARGS(2)
  A$=ARGS$(3)
  IF DRAWY<0 OR DRAWY>=SCRH THEN RETURN
  START=0
  IF DRAWX<0 THEN START=-DRAWX:DRAWX=0
  IF START>=LEN(A$) OR DRAWX>=SCRW THEN RETURN
  LENGTH=LEN(A$)-START
  IF LENGTH>SCRW-DRAWX THEN LENGTH=SCRW-DRAWX
  CURSOR DRAWX,DRAWY
  PRINT A$(START,LENGTH);
RETURN
