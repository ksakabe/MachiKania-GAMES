REM ===================================
REM oneko for KM-BASIC with touch panel
REM RP2350-LCD-2,ili9341
REM 2026-07-11

USEGRAPHIC

USECLASS STRDIM
USEVAR CX,CY,HI,WI,CWI,CHI,CI
USEVAR X0,Y0,X1,Y1
USEVAR SIZE,BMP,BUF
USEVAR CURB,CURWH:REM Cursor Data,width,height
USEVAR DX,DY,PX,PY
USEVAR DLY100,DLY500,DLY1000
USEVAR FLD,FLG,BIN
USEVAR DIR,BGC
USEVAR AWAKE,DOWN,DTOGI, DWLEFT
USEVAR DWRIGHT,JARE,KAKI, LEFT
USEVAR LTOGI, MATI,  RIGHT,RTOGI
USEVAR SLEEP,UP,  UPLEFT,UPRIGHT,UTOGI

REM Set charactor for display
REM FLD$="BSD":CI=1
REM FLD$="DOG":CI=0
FLD$="ONEKO":CI=3
REM FLD$="SAKURA":CI=2
REM FLD$="TOMOYO":CI=4
REM FLD$="TORA":CI=3
REM Set color palette
REM GPALETTE 7,255,255,0

REM Load touch panel class
REM USECLASS CST816D : REM for RP2350-LCD-2
REM T=NEW(CST816D)
USECLASS TSC2046 : REM for ili9341
T=NEW(TSC2046)

CLS

GOSUB INIT
GOSUB LOADDATA
GOSUB READCURSOR

DO
  REM 画面中央で寝て待機
  REM 画面のタッチを待つ
  DO
    GOSUB PLAY,22,500,500:REM Sleep

    IF T.POLLING() THEN
      X1=T.XPOS
      Y1=T.YPOS
      CX=X1:CY=Y1: REM カーソルの表示位置
      BREAK
    ENDIF
    DELAYMS 1
  LOOP
  
  REM -- カーソルの表示
  PUTBMP CX,CY,CURWH(CI,0),CURWH(CI,1),CURB(CI)
  REM -- Wakeup:AWAKE
  GOSUB PLAY,AWAKE,DLY500,DLY500

  REM -- かきかき
  FOR I=1 TO 5
    GOSUB PLAY,10,DLY100,DLY100
  NEXT
  
  REM タッチされた座標に向かって移動
  REM 現在位置とタッチ位置の関係から
  REM 描く猫を選択
  REM Decide moving direction
  DX=X1-X0
  DY=Y1-Y0

  IF DX=0 AND DY=0 THEN
    DIR=SLEEP
  ELSEIF ABS(DX)*4<=ABS(DY) AND DY<0 THEN
    DIR=UP
  ELSEIF ABS(DX)*4<=ABS(DY) AND DY>0 THEN
    DIR=DOWN
  ELSEIF ABS(DY)*4<=ABS(DX) AND DX<0 THEN
    DIR=LEFT
  ELSEIF ABS(DY)*4<=ABS(DX) AND DX>0 THEN
    DIR=RIGHT
  ELSEIF DX<0 AND DY<0 THEN
    DIR=UPLEFT
  ELSEIF DX>0 AND DY<0 THEN
    DIR=UPRIGHT
  ELSEIF DX>0 AND DY>0 THEN
    DIR=DWRIGHT
  ELSE
    DIR=DWLEFT
  ENDIF

  REM 移動量を判断し、移動
  IF ABS(DX)>ABS(DY) THEN
    M=ABS(DX)
  ELSE
    M=ABS(DY)
  ENDIF
  E=(M+15)/16
  IF E<1 THEN E=1

  FOR I=0 TO E
    X=X0+(X1-X0)*I/E
    Y=Y0+(Y1-Y0)*I/E
    GOSUB PLAY, DIR,DLY100,DLY100
  NEXT

  X0=X1:Y0=Y1
  X=X0:Y=Y0
  BOXFILL 0,0,WI-1,HI-1,BGC
  REM 移動完了後に待ち動作
  GOSUB PLAY,MATI,DLY100,DLY100: REM MATI
  BOXFILL 0,0,WI,HI,BGC
  REM 境界位置での動作
  IF FLG=1 THEN
    GOSUB PLAY,LTOGI,DLY100,DLY100: REM 左向きの研ぎ動作
  ELSEIF FLG=2 THEN
    GOSUB PLAY,DTOGI,DLY100,DLY100: REM 下向きの研ぎ動作
  ELSEIF FLG=3 THEN
    GOSUB PLAY,RTOGI,DLY100,DLY100: REM 右向きの研ぎ動作
  ELSEIF FLG=4 THEN
    GOSUB PLAY,UTOGI, DLY100,DLY100: REM 下向きの研ぎ動作
  ENDIF
LOOP

END

REM === Play oneko ====================
LABEL PLAY
  USEVAR D1,D2,Z2
  VAR Z,D1,D2
  Z=ARGS(1) : REM image #
  D1=ARGS(2): REM delay1
  D2=ARGS(3): REM delay2
  
  Z2=Z+1

  IF Z=AWAKE OR Z=JARE THEN Z2=Z

  PUTBMP X,Y,W,H,BUF(Z)
  PX=X:PY=Y
  DELAYMS D1
  BOXFILL PX,PY,PX+W-1,PY+H-1,BGC

  PUTBMP X,Y,W,H,BUF(Z2)
  PX=X:PY=Y
  DELAYMS D2
  BOXFILL PX,PY,PX+W-1,PY+H-1,BGC
RETURN

REM ===================================
LABEL INIT
REM 画面の幅と高さ、中央座標
  WI=SYSTEM(22):HI=SYSTEM(23)
  X0=WI/2-16:Y0=HI/2-16
  PX=X0:PY=Y0
  BGC=8
REM 乱数のシード値設定
  A=SYSTEM(101)
  S=VAL(STRFTIME$("%m%d%H%M%S"))
  POKE32 A,S

  X=PX:Y=PY

  REM 動作の番号を変数に保存
  AWAKE=0  :DOWN=1 :DTOGI=3  :DWLEFT=5
  DWRIGHT=7:JARE=9 :KAKI=10  :LEFT=12
  LTOGI=14 :MATI=16:RIGHT=18 :RTOGI=20
  SLEEP=22 :UP=24  :UPLEFT=26:UPRIGHT=28
  UTOGI=30

  REM 表示遅延時間設定
  DLY100=100:DLY500=500:DLY1000=1000
RETURN

REM ===================================
REM ビットマップデータの読み取りと保存
LABEL LOADDATA
VAR T
  REM ビットマップデータの読み取りと保存
  REM ビットマップデータファイル名は
  REM FILE.TXTに保存してある
  BIN=NEW(STRDIM,31)
  REM 改行コードのチェック
  FOPEN "FILE.TXT","r"
  T$=FINPUT$()
  FCLOSE

  L=1 : REM Only LF
  IF LEN(T$)>=2 THEN
    IF ASC(T$(-2))=$0D THEN L=2 : REM CR LF
  ENDIF

  REM ファイル名の読み取りと保存
  FOPEN "FILE.TXT","r"
  FOR I=0 TO 31
    IF FEOF() THEN
      PRINT "FILE.TXT LINE ERROR"
      PRINT "EXPECTED 32 LINES"
      PRINT "ACTUAL=";I
      FCLOSE
      END
    ENDIF
    
    T$=FINPUT$()

    REM 改行コードを除去
    IF LEN(T$)>=L THEN
      T$=T$(0,LEN(T$)-L):REM Remove LF or CRLF
    ENDIF

    IF LEN(T$)=0 THEN
      PRINT "EMPTY FILE NAME LINE=";I+1
      FCLOSE
      END
    ENDIF

    BIN.SETSTR(T$,I)
  NEXT
  FCLOSE
  
  REM ビットマップデータ用配列の定義
  REM 32×32で決め打ち
  W=32:H=32
  SIZE=W*H
  N=(SIZE+3)/4
  DIM BMP(N-1)
  DIM BUF(31,N-1)

  REM フォルダ名を付加して各キャラクターデータを配列に保存
  FOR I=0 TO 31
    GOSUB READBIN,"BITMAP/"+FLD$+"/"+BIN.GETSTR$(I)+".BIN"
    FOR J=0 TO N-1
      BUF(I,J)=BMP(J)
    NEXT
  NEXT

RETURN

REM ===========================
REM キャラクターのビットマップデータファイルの読み取り
LABEL READBIN
USEVAR FW,FH
VAR F,R

  F$=ARGS$(1)
  FOPEN F$,"r"
  REM 先頭4バイトから幅と高さを読み込む
  REM ファイルはリトルエンディアン形式
  FW=FGETC()
  FW=FW OR (FGETC()<<8)

  FH=FGETC()
  FH=FH OR (FGETC()<<8)

  REM キャラクターデータは32×32に限定
  IF FW!=32 OR FH!=32 THEN
    PRINT "INVALID IMAGE SIZE ";F$
    PRINT "WIDTH=";FW;" HEIGHT=";FH
    FCLOSE
    END
  ENDIF

  REM 必要な画素数
  SIZE=W*H
  REM Store data to array
  R=FGET(BMP,SIZE)
  IF R!=SIZE THEN
    PRINT "READ ERROR ";F$
    FCLOSE
    END
  ENDIF

  FCLOSE
RETURN

REM ===================================
REM カーソルのビットマップデータ読み取り保存
LABEL READCURSOR
USEVAR CUR,READN,MAXCUR
  REM カーソルファイル名保存
  CUR=NEW(STRDIM,4)
  CUR.SETSTR("BONE.BIN",0)
  CUR.SETSTR("BSD.BIN",1)
  CUR.SETSTR("CARD.BIN",2)
  CUR.SETSTR("MOUSE.BIN",3)
  CUR.SETSTR("PETAL.BIN",4)
  REM Store cursor image
  MAXCUR=204
  DIM CURB(4,(MAXCUR+3)/4-1)
  DIM CURWH(4,1)

  FOR I=0 TO 4
  REM ファイルを開く
    FOPEN "BITMAP/"+"CURSOR/"+CUR.GETSTR$(I),"r"

    REM 幅を32ビット・リトルエンディアンで読み込む
    CWI=FGETC()
    CWI=CWI OR (FGETC()<<8)

    REM 高さを32ビット・リトルエンディアンで読み込む
    CHI=FGETC()
    CHI=CHI OR (FGETC()<<8)
    REM 各カーソルビットマップの幅と大きさを保存
    CURWH(I,0)=CWI
    CURWH(I,1)=CHI
    REM 画像データのバイト数
    SIZE=CWI*CHI
    IF SIZE>MAXCUR THEN
      PRINT "CURSOR TOO LARGS"
      PRINT CUR.GETSTR$(I)
      PRINT "SIZE=";SIZE;" MAX=";MAXCUR
      FCLOSE
      END
    ENDIF

    REM KM-BASICの整数配列は1要素4バイト
    REM 必要な要素数を切り上げて確保する
    N=(SIZE+3)/4
    DIM P(N-1)

    REM 画像データを配列に読み込む
    READN=FGET(P,SIZE)

    REM データ読み込み失敗時に表示
    IF READN!=SIZE THEN
      PRINT "FILE READ ERROR"
      PRINT "EXPECTED=";SIZE
      PRINT "ACTUAL=";READN
      FCLOSE
      END
    ENDIF
  
    REM 保存領域をゼロクリア
    FOR J=0 TO (MAXCUR+3)/4-1
      CURB(I,J)=0
    NEXT
    REM 読み込んだデータを保存用配列にコピー
    FOR J=0 TO N-1
      CURB(I,J)=P(J)
    NEXT

    FCLOSE
  NEXT
RETURN
