REM ===================================
REM Minesweeper for MachiKania
REM 9x9のボード、地雷数10個
REM 修正版
REM ===================================

USEVAR MINE :REM 地雷の有無
USEVAR OPEN :REM 開閉状態
USEVAR FLAG :REM 旗の有無
USEVAR COUNT:REM 周囲の地雷数
USEVAR QX,QY:REM 0領域展開用キュー
USEVAR MNUM,MC:REM 地雷の数
USEVAR BW,BH:REM ボーロの幅と高さ
USEVAR MX,MY:REM 地雷の設定位置
USEVAR CS:REM セルの幅と高さ
USEVAR SPX,SPY:REM セルの選択位置
USEVAR GAMEEND:REM ゲーム終了フラグ
USEVAR FLAGNUM:REM 設置中の旗の数
USEVAR NX,NY:REM 一時的な座標
USEVAR DX,DY:REM 選択セル周辺の位置
USEVAR XT,YT,QH,QT

USEGRAPHIC
CLS

GOSUB INIT
GOSUB SETMINES
GOSUB CALCOUNTS

DO WHILE GAMEEND=0
  GOSUB DRAWBOARD
  GOSUB GETINPUT
  GOSUB UPDATE
  GOSUB CHECKGAME
LOOP

END

REM -----------------------------------
REM ゲームに必要なデータの準備
LABEL INIT
  MNUM=10:REM 地雷数
  BW=9:BH=9:REM ボードの幅と高さ

  REM 乱数のシード設定
  A=SYSTEM(101)
  S=VAL(STRFTIME$("%m%d%H%M%S"))
  POKE32 A,S

  CS=20 :REM ボードのセルは20x20ピクセル
  SPX=4:SPY=4:REM カーソルの初期位置
  GAMEEND=0
  FLAGNUM=0

  REM 配列宣言と初期化
  DIM OPEN(BW-1,BH-1)
  DIM FLAG(BW-1,BH-1)
  DIM MINE(BW-1,BH-1)
  DIM COUNT(BW-1,BH-1)
  DIM QX(BW*BH-1)
  DIM QY(BW*BH-1)

  FOR Y=0 TO BH-1
    FOR X=0 TO BW-1
      OPEN(X,Y)=0
      FLAG(X,Y)=0
      MINE(X,Y)=0
      COUNT(X,Y)=0
    NEXT
  NEXT
RETURN

REM -----------------------------------
REM 地雷の配置：乱数で決定
LABEL SETMINES
  MC=0
  DO WHILE MC<MNUM
    MX=RND() % BW
    MY=RND() % BH
    IF MINE(MX,MY)=0 THEN
      MINE(MX,MY)=1
      MC=MC+1
    ENDIF
  LOOP
RETURN

REM -----------------------------------
REM 各セルの周囲のセルの地雷数を計算
LABEL CALCOUNTS
VAR C
  FOR Y=0 TO BH-1
    FOR X=0 TO BW-1
      C=0
      FOR DY=-1 TO 1
        FOR DX=-1 TO 1
	  REM 対象のセル以外を対象にする
          IF (DX!=0) OR (DY!=0) THEN
            NX=X+DX
            NY=Y+DY
	    REM 検査対象はボードの範囲内のみ
            IF (NX>=0) AND (NX<BW) AND (NY>=0) AND (NY<BH) THEN
              IF MINE(NX,NY)=1 THEN C=C+1
            ENDIF
          ENDIF
        NEXT
      NEXT
      COUNT(X,Y)=C:REM 周辺の地雷数の保存
    NEXT
  NEXT
RETURN

REM -----------------------------------
REM ボードの描画
LABEL DRAWBOARD
VAR N
  FOR Y=0 TO BH-1
    FOR X=0 TO BW-1
      IF OPEN(X,Y)=0 THEN
        PUTBMP X*CS,Y*CS,CS,CS,CELL_CLOSED
        IF FLAG(X,Y)=1 THEN
          REM 旗付きマス。文字位置と色は機種に合わせて調整可能
          GPRINT X*CS+7,Y*CS+6,1,2,"F"
        ENDIF
      ELSEIF MINE(X,Y)=1 THEN
        PUTBMP X*CS,Y*CS,CS,CS,CELL_MINE :REM 地雷の表示
      ELSE
        PUTBMP X*CS,Y*CS,CS,CS,CELL_SAFE :REM 空のセル
	REM 周囲の地雷数の表示
        N=COUNT(X,Y)
        IF N>0 THEN
          REM 数字の位置・色は使用機種に合わせて調整可能
          GPRINT X*CS+7,Y*CS+6,1,7,DEC$(N)
        ENDIF
      ENDIF
    NEXT
  NEXT

  REM 選択位置は画像を上書きせず、枠線で表示する
  LINE SPX*CS,SPY*CS,SPX*CS+CS-1,SPY*CS,     2
  LINE              ,SPX*CS+CS-1,SPY*CS+CS-1,2
  LINE              ,SPX*CS,     SPY*CS+CS-1,2
  LINE              ,SPX*CS,     SPY*CS,     2

  REM 残り地雷数の目安を表示
  GPRINT 0,BH*CS+2,1,7,"MINE:"+DEC$(MNUM-FLAGNUM)
RETURN

REM -----------------------------------
REM ボタンおよびキー入力
LABEL GETINPUT
  WHILE KEYS()!=0:WAIT 1:WEND
  WHILE KEYS()=0:WAIT 1:WEND
  K=KEYS()
  WHILE KEYS()!=0:WAIT 1:WEND
RETURN

REM -----------------------------------
REM キー入力に伴う状態更新
REM セルの位置計算
LABEL UPDATE
  IF K=1 THEN
    SPY=SPY-1
  ELSEIF K=2 THEN
    SPY=SPY+1
  ELSEIF K=4 THEN
    SPX=SPX-1
  ELSEIF K=8 THEN
    SPX=SPX+1
  ELSEIF K=16 THEN
    GOSUB TOGGLEFLAG :REM フラグ処理へ
  ELSEIF K=32 THEN
    GOSUB OPENCELL :REM セルを開く
  ENDIF

  REM セル位置をボードの範囲内に
  IF SPX<0   THEN SPX=0
  IF SPX>=BW THEN SPX=BW-1
  IF SPY<0   THEN SPY=0
  IF SPY>=BH THEN SPY=BH-1
RETURN

REM -----------------------------------
REM 選択中のセルの旗の設置・解除
REM KEYS()のビット値16を旗操作に使用
LABEL TOGGLEFLAG
  REM 開封済みのマスには旗を置けない
  IF OPEN(SPX,SPY)=1 THEN RETURN
  REM 旗のないセルでの処理
  IF FLAG(SPX,SPY)=0 THEN
    REM 地雷数を超えて旗を置かない場合は次の判定を有効にする
    IF FLAGNUM>=MNUM THEN RETURN
    FLAG(SPX,SPY)=1
    FLAGNUM=FLAGNUM+1
  ELSE
    FLAG(SPX,SPY)=0
    FLAGNUM=FLAGNUM-1
  ENDIF
RETURN

REM -----------------------------------
REM 選択中のセルを開く
LABEL OPENCELL
  REM 旗がある、あるいは開いている場合は何もしない
  IF FLAG(SPX,SPY)=1 THEN RETURN
  IF OPEN(SPX,SPY)=1 THEN RETURN
  REM 地雷がある場合、地雷等の表示、ゲームオーバ
  IF MINE(SPX,SPY)=1 THEN
    OPEN(SPX,SPY)=1
    GOSUB SHOWMINES
    GOSUB DRAWBOARD
    GOSUB GAMEOVER
    RETURN
  ENDIF
  REM 近辺地雷数がある場合、ない場合
  IF COUNT(SPX,SPY)>0 THEN
    OPEN(SPX,SPY)=1
  ELSE
    GOSUB OPENZERO,SPX,SPY
  ENDIF
RETURN

REM -----------------------------------
REM 周囲地雷数0の領域をキュー方式で展開
LABEL OPENZERO
  XT=ARGS(1)
  YT=ARGS(2)

  QH=0
  QT=0
  QX(QT)=XT
  QY(QT)=YT
  QT=QT+1
  OPEN(XT,YT)=1

  DO WHILE QH<QT
    XT=QX(QH)
    YT=QY(QH)
    QH=QH+1

    REM 0のマスからだけ周囲へ展開する
    IF COUNT(XT,YT)=0 THEN
      FOR B=-1 TO 1
        FOR A=-1 TO 1
          IF (A!=0) OR (B!=0) THEN
            NX=XT+A
            NY=YT+B

            IF (NX>=0) AND (NX<BW) AND (NY>=0) AND (NY<BH) THEN
              IF OPEN(NX,NY)=0 THEN
                IF FLAG(NX,NY)=0 THEN
                  IF MINE(NX,NY)=0 THEN
                    OPEN(NX,NY)=1
                    QX(QT)=NX
                    QY(QT)=NY
                    QT=QT+1
                  ENDIF
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        NEXT
      NEXT
    ENDIF
  LOOP
RETURN

REM -----------------------------------
REM 地雷以外をすべて開いたか確認
LABEL CHECKGAME
USEVAR OC
VAR OC
  IF GAMEEND=1 THEN RETURN

  OC=0
  FOR Y=0 TO BH-1
    FOR X=0 TO BW-1
      IF OPEN(X,Y)=1 THEN OC=OC+1
    NEXT
  NEXT

  IF OC=BW*BH-MNUM THEN
    GOSUB SHOWMINES
    GOSUB DRAWBOARD
    GOSUB GAMECLEAR
  ENDIF
RETURN

REM -----------------------------------
REM 全地雷を表示状態にする
LABEL SHOWMINES
  FOR Y=0 TO BH-1
    FOR X=0 TO BW-1
      IF MINE(X,Y)=1 THEN OPEN(X,Y)=1
    NEXT
  NEXT
RETURN

REM -----------------------------------
LABEL GAMEOVER
  GAMEEND=1
  GPRINT 0,SYSTEM(23)-8,2,7,"GAME OVER"
  WHILE KEYS()!=0:WAIT 1:WEND
  WHILE KEYS()=0:WAIT 1:WEND
RETURN

REM -----------------------------------
LABEL GAMECLEAR
  GAMEEND=1
  GPRINT 0,SYSTEM(23)-8,1,6,"GAME CLEAR"
  WHILE KEYS()!=0:WAIT 1:WEND
  WHILE KEYS()=0:WAIT 1:WEND
RETURN

REM -----------------------------------
REM セルの描画データ
LABEL CELL_SELECT
CDATA 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,10,10,
      2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,10,10,
      2,2,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,10,10,10,
      2,2,8,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
      10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
      10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10

LABEL CELL_CLOSED
CDATA 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,1,1,
      15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,1,1,
      15,15,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1,1,1,
      15,15,8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

LABEL CELL_MINE
CDATA 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,15,
      1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,1,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,1,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,1,8,1,1,1,1,1,8,1,8,8,8,8,7,15,
      1,0,8,8,8,8,1,1,1,1,1,1,1,8,8,8,8,8,7,15,
      1,0,8,8,8,1,1,15,1,1,1,1,1,1,8,8,8,8,7,15,
      1,0,8,8,8,1,1,1,1,1,1,1,1,1,8,8,8,8,7,15,
      1,0,8,1,1,1,1,1,1,1,1,1,1,1,1,1,8,8,7,15,
      1,0,8,8,8,1,1,1,1,1,1,1,1,1,8,8,8,8,7,15,
      1,0,8,8,8,1,1,1,1,1,1,1,1,1,8,8,8,8,7,15,
      1,0,8,8,8,8,1,1,1,1,1,1,1,8,8,8,8,8,7,15,
      1,0,8,8,8,1,8,1,1,1,1,1,8,1,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,1,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,1,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,15,
      1,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

LABEL CELL_SAFE
CDATA 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,15,
      1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7,15,
      1,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,15,
      1,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
