REM HANABI.BAS - Fireworks simulation for KM-BASIC
REM Any key stops the program.

USEVAR PHASE,ROCKET
USEVAR RY,RVX,RVY
USEVAR DLAY,LIFE
USEVAR COL,OLDX,OLDY
USEVAR NEWX,NEWY
USEVAR GW,GH,VX,VY

REM Spark data: position is stored at 8 times screen scale.
DIM X(31):DIM Y(31)
DIM VX(31):DIM VY(31)
DIM C(31)

USEGRAPHIC
GW=SYSTEM(22)
GH=SYSTEM(23)

GCLS

REM Bright firework colors.
GPALETTE 1,80,160,255
GPALETTE 2,255,70,40
GPALETTE 3,255,70,220
GPALETTE 4,80,255,100
GPALETTE 5,70,255,255
GPALETTE 6,255,220,40
GPALETTE 7,255,255,255

REM Dim colors used near the end of each spark's life.
GPALETTE 9,20,45,80
GPALETTE 10,90,20,10
GPALETTE 11,80,15,65
GPALETTE 12,15,75,25
GPALETTE 13,15,70,70
GPALETTE 14,85,60,10
GPALETTE 15,90,90,90

GOSUB LAUNCH

WHILE 1
 REM On a single page, start redrawing immediately after vertical sync.
 WAIT 2

 BOXFILL 0,12,GW-1,GH-1,8

 IF PHASE=0 THEN
  REM Draw and move the rising rocket.
  OLDX=ROCKET/8
  OLDY=RY/8
  ROCKET=ROCKET+RVX
  RY=RY+RVY
  RVY=RVY+(3*GH+112)/224
  NEWX=ROCKET/8
  NEWY=RY/8
  LINE OLDX,OLDY+8,NEWX,NEWY,6
  CIRCLEFILL NEWX,NEWY,2,7

  REM Burst close to the top of the flight.
  IF RVY>=-4 THEN GOSUB BURST

 ELSEIF PHASE=1 THEN
  REM Draw and update all sparks.
  FOR I=0 TO 31
   OLDX=X(I)/8
   OLDY=Y(I)/8
   X(I)=X(I)+VX(I)
   Y(I)=Y(I)+VY(I)
   VY(I)=VY(I)+(2*GH+112)/224
   NEWX=X(I)/8
   NEWY=Y(I)/8
   COL=C(I)
   IF LIFE<16 THEN COL=COL+8
   IF NEWX>=0 AND NEWX<GW AND NEWY>=0 AND NEWY<GH-8 THEN
    LINE OLDX,OLDY,NEWX,NEWY,COL
    IF LIFE>25 THEN PSET NEWX+1,NEWY,COL
   ENDIF
  NEXT
  LIFE=LIFE-1
  IF LIFE<=0 THEN PHASE=2:DLAY=18

 ELSE
  REM Short dark interval before the next launch.
  DLAY=DLAY-1
  IF DLAY<=0 THEN GOSUB LAUNCH
 ENDIF

 GPRINT 4,4,15,-1,"HANABI - PRESS ANY KEY TO END"

 REM On type PU, show the completed back page at vertical sync.
 IF INKEY() THEN BREAK
WEND

USEGRAPHIC 0
END

LABEL LAUNCH
 REM Select a launch point and an upward speed.
 ROCKET=(GW/8+RND()%(GW*3/4))*8
 RY=(GH-14)*8
 RVX=((RND()%9)-4)*GW/256
 RVY=(-68-(RND()%13))*GH/224
 PHASE=0
RETURN

LABEL BURST
 REM Turn the rocket into 32 independently moving sparks.
 FOR I=0 TO 31
  X(I)=ROCKET
  Y(I)=RY
  VX(I)=((RND()%81)-40)*GW/256
  VY(I)=((RND()%81)-40)*GH/224

  REM Avoid particles that hardly move.
  IF VX(I)>-8 AND VX(I)<8 THEN VX(I)=VX(I)*3
  IF VY(I)>-8 AND VY(I)<8 THEN VY(I)=VY(I)*3
  C(I)=1+RND()%7
 NEXT
 LIFE=48
 PHASE=1
RETURN
