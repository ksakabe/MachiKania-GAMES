# oneko for MachiKania

onekoをMachiKania上で再現したプログラムで、表示するキャラクターはonekoのキャラクターのビットマップデータとビットマスクを元にMachiKaniaのKM-BASICのPUTBMP命令で描画できる形式に変換したデータを使うようにしています。

プログラムはonekoのプログラムを移植したものではなく独自のものです。

# プログラムの構成

## BASICのプログラム

プログラムはタッチパネルを利用できるバージョンと利用できないバージョンの2つがあります。

- ONEKOTP.BAS：タッチパネルを利用できる機器向け
- ONEKORND.BAS：タッチパネルを利用できない機器向け

## キャラクタのビットマップデータファイル名保存ファイル

BASICのプログラムからビットマップデータを読み取るときに使用するファアイル名を記録したファイル`FILE.TXT`が必要です。

一行に一ファイルの形式です。

## ビットマップデータ作成Pythonスクリプト oneko_xbm2putbmp.py

オリジナルonekoのキャラクターおよびカーソルのビットマップおよびビットマスクデータを使ってKM-BASICで使用する形式に変換するPythonスクリプト`oneko_xbm2putbmp.py`をChatGPTに作ってもらいました。

[oneko](http://www.daidouji.com/oneko/)のファイルoneko-1.2.sakura.5.tar.gzを展開したディレクトリで実行すると各キャラクタ、カーソルのビットマップ、ビットマスクを読み取り変換したデータをBITMAPディレクトリ内に種類ごとにディレクトリを作成して保存されます。

| ディレクトリ名 | 保存内容                 |
|----------------|--------------------------|
| BSD            | BSDデーモン              |
| CURSOR         | 各キャラクタ向けカーソル |
| DOG            | 犬                       |
| ONEKO          | 猫                       |
| SAKURA         | 木之本桜                 |
| TOMOYO         | 大道寺知世               |
| TORA           | トラ猫                   |


# インストール

次のファイル、ディレクトリをダウンロードしマウントしたMachiKaniaのSDカードにコピーします。

- ONEKOTP.BASまたはONEKORND.BAS
- FILE.TXT
- 作成されたBITMAPディレクトリ

# 表示するキャラクタの選択

プログラムを実行して表示するキャラクターはBASICのプログラムの冒頭部で指定します。
初期状態では猫（ONEKO）が表示されるようになっています。その他のキャラクタはコメントとして置かれていますので表示したい行の先頭のREM文を削除します。

``` BASIC
REM Set charactor for display
REM FLD$="BSD":CI=1
REM FLD$="DOG":CI=0
FLD$="ONEKO":CI=3
REM FLD$="SAKURA":CI=2
REM FLD$="TOMOYO":CI=4
REM FLD$="TORA":CI=3
```

