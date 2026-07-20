REM ================================================
REM 8 Puzzle for MachiKania / KM-BASIC
REM
REM Controls
REM   UP/DOWN/LEFT/RIGHT : Slide a tile in that direction
REM   START              : Make a new puzzle
REM
REM The board is shuffled by legal moves only, so every
REM generated puzzle is guaranteed to be solvable.
REM ================================================

USEGRAPHIC
USEVAR WI,HI,SZ,OX,OY,MSGX
USEVAR EMPTY,KEY,OLD,NPOS,ROW,COL
USEVAR TMP,MOVES,SOLVED

REM Nine elements: 1..8 are tiles, 0 is the empty square.
DIM B(8)

REM Calm blue-gray color scheme.
REM   0  : background
REM   1  : tile face
REM   9  : highlight
REM   10 : shade and drop shadow
REM   7  : tile number and text
GPALETTE 0,24,28,32
GPALETTE 1,72,92,104
GPALETTE 9,124,144,154
GPALETTE 10,38,50,58
GPALETTE 7,232,228,216

REM Obtain the actual display size so this works on different displays.
WI=SYSTEM(22):HI=SYSTEM(23)

REM Reserve 96 dots for margins, the gap, and the 80-dot-wide message area.
REM Divide the remaining width among the three columns.
SZ=(WI-96)/3

REM Keep the large-screen tile size at a maximum of 64 dots.
IF SZ>64 THEN SZ=64

REM Also reduce the tile size when the display height is insufficient.
IF SZ*3>HI-8 THEN SZ=(HI-8)/3

REM Center the puzzle and message area.  At narrow widths OX becomes 4.
OX=(WI-SZ*3-88)/2
IF OX<4 THEN OX=4
OY=HI/2-SZ*3/2
MSGX=OX+SZ*3+8

GOSUB INIT

DO
  GOSUB DRAW

  REM Wait for a button press.  A small delay prevents rapid repeats.
  DO
    KEY=KEYS()
    WAIT 1
  LOOP WHILE KEY=0

  IF KEY AND 16 THEN
    GOSUB INIT
  ELSE
    GOSUB MOVE
  ENDIF

  REM One press makes at most one move.
  WHILE KEYS()!=0:WAIT 1:WEND

  GOSUB CHECK
  IF SOLVED THEN
    GOSUB DRAW
    GPRINT MSGX,OY+96,9,-1,"CLEARED!"
    WHILE KEYS(16)=0:WAIT 1:WEND
    WHILE KEYS()!=0:WAIT 1:WEND
    GOSUB INIT
  ENDIF
LOOP

LABEL INIT
  REM Set random seed value
  A=SYSTEM(101)
  S=VAL(STRFTIME$("%m%d%H%M%S"))
  POKE32 A,S
  
  REM Start with the solved layout.
  FOR I=0 TO 7
    B(I)=I+1
  NEXT
  B(8)=0
  EMPTY=8
  MOVES=0

  REM Make 120 legal random moves.  Do not immediately undo the last move.
  OLD=-1
  FOR I=1 TO 120
    DO
      REM D is a random direction: 0=UP, 1=DOWN, 2=LEFT, 3=RIGHT.
      D=RND()%4
      NPOS=-1
      IF D=0 THEN NPOS=EMPTY-3
      IF D=1 THEN NPOS=EMPTY+3
      IF D=2 THEN NPOS=EMPTY-1
      IF D=3 THEN NPOS=EMPTY+1
      GOSUB CANMOVE
    LOOP WHILE NPOS=OLD OR N=0
    OLD=EMPTY
    GOSUB SWAP
  NEXT

  REM Very rarely the shuffle can return to the solved state.
  GOSUB CHECK
  IF SOLVED THEN GOTO INIT
RETURN

LABEL MOVE
  REM Select the tile that moves in the pressed direction.
  REM For example, RIGHT moves the tile left of the empty square to the right.
  NPOS=-1
  IF KEY AND 1 THEN NPOS=EMPTY+3
  IF KEY AND 2 THEN NPOS=EMPTY-3
  IF KEY AND 4 THEN NPOS=EMPTY+1
  IF KEY AND 8 THEN NPOS=EMPTY-1
  GOSUB CANMOVE
  IF N THEN
    GOSUB SWAP
    MOVES=MOVES+1
  ENDIF
RETURN

LABEL CANMOVE
  REM N becomes 1 only if NPOS is a neighbouring square in the board.
  N=0
  IF NPOS<0 OR NPOS>8 THEN RETURN
  IF ABS(NPOS-EMPTY)=3 THEN N=1
  IF ABS(NPOS-EMPTY)=1 AND NPOS/3=EMPTY/3 THEN N=1
RETURN

LABEL SWAP
  TMP=B(EMPTY)
  B(EMPTY)=B(NPOS)
  B(NPOS)=TMP
  EMPTY=NPOS
RETURN

LABEL CHECK
  SOLVED=1
  FOR I=0 TO 7
    IF B(I)!=I+1 THEN SOLVED=0
  NEXT
  IF B(8)!=0 THEN SOLVED=0
RETURN

LABEL DRAW
  GCLS

  REM Display all information to the right of the puzzle.
  GPRINT MSGX,OY,7,-1,"8 PUZZLE"
  REM Limit the counter text to 10 characters so it stays in the message area.
  IF MOVES<10000 THEN
    GPRINT MSGX,OY+24,9,-1,"MOVE:"+DEC$(MOVES)
  ELSE
    GPRINT MSGX,OY+24,9,-1,"MOVE:9999+"
  ENDIF
  GPRINT MSGX,OY+48,7,-1,"ARROW:MOVE"
  GPRINT MSGX,OY+64,7,-1,"START:NEW"

  FOR I=0 TO 8
    ROW=I/3
    COL=I%3
    IF B(I)!=0 THEN
      REM Draw every tile with the same color.
      X=OX+COL*SZ
      Y=OY+ROW*SZ

      REM Drop shadow.
      BOXFILL X+6,Y+6,X+SZ-2,Y+SZ-2,10

      REM Tile face.
      BOXFILL X+2,Y+2,X+SZ-6,Y+SZ-6,1

      REM Bright top and left edges.
      LINE X+2,Y+2,X+SZ-6,Y+2,9
      LINE X+2,Y+2,X+2,Y+SZ-6,9
      LINE X+3,Y+3,X+SZ-7,Y+3,9
      LINE X+3,Y+3,X+3,Y+SZ-7,9

      REM Dark bottom and right edges.
      LINE X+3,Y+SZ-6,X+SZ-6,Y+SZ-6,10
      LINE X+SZ-6,Y+3,X+SZ-6,Y+SZ-6,10
      LINE X+4,Y+SZ-7,X+SZ-7,Y+SZ-7,10
      LINE X+SZ-7,Y+4,X+SZ-7,Y+SZ-7,10

      REM Draw the tile number at its center.
      GPRINT X+SZ/2-4,Y+SZ/2-4,7,-1,CHR$(48+B(I))
    ENDIF
  NEXT
RETURN
