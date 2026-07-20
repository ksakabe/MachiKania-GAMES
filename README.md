# 8パズル on MachiKania

MachiKaniaのKM-BASICで動作する8パズルです。ランダムに並んでいる1〜8の数字のマスを左上から順に並べるゲームです。

画面のサイズに応じてパズルのマス目を描画するようになっています。

MachiKania type P ver 1.7.0で動作を確認しました。

# 導入方法

ファイルEIGHTPUZ.BASをダウンロードし、SDカードにコピーします。

# 設定

マス目の移動はボード上の上下左右ボタンで操作しますが`MACHIKAP.INI`で下記を設定することでUSBキーボードからもカーソルキー、`S`キー、`F`キーで操作可能になります。

``` INI
EMULATEBUTTONUP=38
EMULATEBUTTONDOWN=40
EMULATEBUTTONLEFT=37
EMULATEBUTTONRIGHT=39
EMULATEBUTTONSTART=83
EMULATEBUTTONFIRE=70
```

# 操作方法

- UP、DOWN、LEFT、RIGHTボタンまたはキーボードのカーソルで空白コマに隣接しているコマを上下左右に移動します
- `START`ボタンまたは`S`キーで新しい問題を作ります
