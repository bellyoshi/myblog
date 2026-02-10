---
title: "Pas2JSで量子将棋を作る - Day41（Geminiで骨格、Cursorでコンパイルとユニットテスト）"
date: 2026-02-10T16:00:00+09:00
draft: false
featured_image: "/images/LazarusDay041.png"
description: "Lazarusチャレンジ41日目。全駒が量子状態の「量子将棋」をPas2JSで作成。骨格はGeminiに「続けて」「まとめて」と任せて作り、コンパイルが通らなかったためCursorにスイッチ。Cursorでpas2jsの型エラーを解消し、桂馬の飛び越え・グループ制限・経路遮断まで実装。今回初めてLazarusのコンソールでFPCUnitユニットテストを導入し、テスト作成はCursorに任せました。"
tags: ["Lazarus", "Pas2JS", "Web", "Pascal", "チャレンジ", "Day041", "量子将棋", "Gemini", "Cursor", "FPCUnit", "ユニットテスト", "pas2js"]
categories: ["技術"]
author: "ブログ管理者"
---

# Pas2JSで量子将棋を作る - Day41（Geminiで骨格、Cursorでコンパイルとユニットテスト）

Lazarusチャレンジ41日目です。**開始局面で王将を含む全駒が量子状態**の「量子将棋」を Pas2JS でブラウザ向けに作りました。設計と骨格は **Gemini** に「何でもいいから続けて」「まとめて全コード出して」と任せ、**コンパイルが通らなかった**ため **Cursor**（課金利用）に切り替えて完成させています。また、**ユニットテストを初めて導入**し、Lazarus のコンソール用 FPCUnit プロジェクトでロジックを検証。テストの作成も Cursor に任せました。この記事では、**人間が投げたプロンプト**に注目して、Gemini と Cursor の使い分けがどう効いたかをまとめます。

![量子将棋 画面](/images/LazarusDay041.png)

## ゲームのコンセプト

- **量子状態**: 各駒は「歩・香・桂・銀・金・角・飛・王」のいずれかである**可能性の重ね合わせ**で、動かすたびに「その手で矛盾する種類」が消え、観測（収束）していく
- **人間同士対局**: 盤面と駒台があり、駒の移動・取る・打つが可能
- **UI**: 可能性のある駒の文字を**重ねて表示**（複数種類なら薄く、1種類に確定すると濃く）
- **グループ制限**: 初期の「先手グループ」「後手グループ」ごとに駒種の枚数上限（角・飛・王は1、香・桂・金・銀は2、歩は9）。1枚確定しても、**上限に達したときだけ**他駒からその可能性を削除
- **経路遮断**: 飛・角・香は味方・敵を素通りしない。**桂馬だけ**飛び越え可（トンネル効果の防止）

## Gemini でやったこと

最初に **Gemini** で骨格を作りました。こちらは「**何でも言うことを聞いて続けて**」とお願いするスタイルで進めています。

### 出したプロンプトの流れ

1. **「pas2jsで量子将棋アプリを作りたい。開始局面では王将を含めてすべての駒が量子状態。まずは人間同士がプレイできる盤を作成。駒台なども忘れずに。」**

   **Geminiの回答（要約）:** DOMベース構築を推奨し、Board（9×9グリッド）・Cell（マス目）・Piece（量子状態の駒）・Stand（駒台）の構成を提示。データモデルとして `TQuantumPiece`（Owner, PossibleTypes, IsObserved, CurrentType）と盤面レンダリング用の `CreateBoard` のコード例を出した。MouseDown／MouseMove／MouseUp で選択・ゴースト・観測の流れを説明し、「まず駒を動かせる盤面を作る→次に移動で矛盾する可能性を排除する観測」という次のステップを二択で提案した。

2. **「まずは将棋のルールをおさらい。すべてのルール。」**

   **Geminiの回答（要約）:** ルールを「初期配置」「動き」「特殊ルール」「終局」の4つに分類。駒の動きを表形式（玉・飛・角・金・銀・桂・香・歩）で整理し、成り（龍・馬・成銀〜と金は金と同じ動き、強制成りの条件）、持ち駒と打ち駒のルール、禁じ手（二歩・打ち歩詰め・行き所のない駒・王手放置・千日手）を列挙。量子将棋への応用として、二歩の判定・成れるかの判定・王手の確率的判定に言及し、次に「盤面データ構造」か「駒の動きのロジック」のどちらを詰めるか選択させる形で返した。

3. **「UIは文字が重なった表示とする。」**

   **Geminiの回答（要約）:** CSS の absolute 配置と opacity で「複数可能性が共存」を表現する方針。未確定時は複数文字が半透明で重なり、観測が進むと不要な文字が消えて残りが濃くなり、確定時は1文字のみ不透明度100%とする。HTML は `cell` > `piece-container` > 駒種ごとの `span`、CSS は `opacity: 0.2` と `is-determined` で `opacity: 1.0`。Pascal 側では `TQuantumPiece.UpdateView` で各 span の表示／非表示と `opacity := 1.0/可能性数` を設定。駒台も「何か（量子駒）」として同様に扱い、打つときに二歩などで可能性が絞られると説明した。

4. **「計算ロジック」「進めます」「UI構築コード作成」「実装」「作る」「ロジックを作ります」**

   **Geminiの回答（要約）:** 「計算ロジック」で移動によるフィルタリング（CanMove で可能な種類だけ残す）、経路の飛び越し（桂馬以外はブロック）、取った駒は可能性を引き継いで駒台へ、駒の総数・二歩・行き所のない駒による矛盾の連鎖、王手・詰みの考え方と `CalculateNewPossibilities` のイメージを提示。「進めます」で CanMove の全駒分の Pascal コード（成り含む）、CheckPath、ResetToInitial、移動実行フロー（ベクトル計算→フィルタ→飛び越し→二歩→矛盾チェック→UI更新）を出した。「UI構築」で game-container／shogi-board／piece-container／quantum-char／piece-stand の CSS と `UpdateCellUI`・`CreateStandHTML`。「実装」で TGameController、HandleCellClick、MovePiece、CalculateNewPossibilities（走り駒は経路障害で除外）、取った駒は量子状態のまま駒台へ。「作る」で CapturePiece、DropPiece（行き所のない駒・二歩で可能性削除）、HasConfirmedPawnInColumn。「ロジックを作ります」で CheckKingFeasibility、IsKingInDanger、観測による勝敗、FinalizeTurn と次の「初期化でまとめる」提案まで、いずれもコード付きで段階的に出力した。

5. **「まとめる。全コードpasとhtml,cssの出力。」**

   **Geminiの回答（要約）:** これまでのロジックを1本にまとめ、index.html（game-container、stand-1/board/stand-0、#status、quantum_shogi.js）、style.css（body／game-container、shogi-board 9×9、cell、piece-container、quantum-char、piece-stand、#status）、quantum_shogi.pas（program、uses、TPieceType/TPieceSet、TQuantumPiece、TGame、InitBoard、CanMove、MovePiece、UpdateUI、HandleCellClick、メインで Board 生成とセルに onclick 付与）の全コードを提示。観測ロジック（MovePiece 内で newSet に絞り込み）、UI（opacity を 1/n）、イベント（匿名関数で座標渡し）のポイントを簡潔に述べ、続けて「王の確定演出や二歩の厳密判定を追加するか」と次の一手を聞いた。

6. **その後はコンパイルエラーをそのまま貼り付け**

   **Geminiの回答（要約）:** 各エラーに対して修正版コードを返した。Longint/Boolean 不一致では IfThen をやめ if 文で文字列代入に変更し Math ユニット追加。Expected "," では lambda をやめ dataset に x,y を入れ、クリック時に `StrToInt(target.dataset['x'])` で取る方式に変更。string exceeds end of line では日本語リテラルを変数に分け、TurnStr や PieceChar の代入を分割。TJSMouseEvent/TJSEvent では OnCellClick の引数を TJSEvent に統一し「コンパイラは onclick に TJSEvent を期待している」と説明したが、実際には pas2js が渡すのは TJSMouseEvent のため、同じ型不一致が繰り返し発生し、最後は「TJSEvent で受け取り関数内で TJSHTMLElement にキャストする」としつつ、それでもコンパイルエラーが解消されなかった。

つまり、**設計・骨格・ルール整理・コードの塊**は Gemini に任せると「続けて」「まとめて」の一言で進みますが、**pas2js の厳密な型（onclick のイベント型）** にはまり、コンパイルが完了しない状態が続きました。

## 人間のプロンプトに注目：Cursor にスイッチしてから

**コンパイルがうまくいかない**ので **Cursor** に切り替えました。Cursor は課金して使っています。

### 出したプロンプトの流れ（要約）

1. **「pas2js .\quantum_shogi.pas -Tbrowser "-Jirtl.js" コマンドを実行しコンパイルを完了させる」**  
   → Cursor が 145 行付近を修正し、**onclick は TJSMouseEvent を期待する**ため、`OnCellClick` の引数を `TJSMouseEvent` に変更。さらに `CheckVictory` の実装不足を補い、前方宣言を追加。**ここでコンパイルが初めて完了**。

2. **「文字を大きくする。文字の色を黒にする。」**  
   → style.css のフォントサイズ・色を変更。

3. **「桂馬はねしても桂馬確定にならない。」**  
   → CanMove に桂馬の動き（L字）を追加し、銀・香の判定も修正。

4. **「持ち駒台の駒が重ならないようにする。」**  
   → 駒台の .cell に固定サイズと flex で折り返し。

5. **「文字をもう少し大きくして、升目の真ん中に表示されるようにする。」**  
   → .quantum-char のサイズと中央配置を調整。

6. **「矛盾移動ですの表示をする代わりに、移動範囲を表示し、そこしかクリックできないようにする。ただし、駒の選択を変えることはかのう。」**  
   → ValidMoves と ComputeValidMoves、移動可能マスのハイライト（.move-dest）、クリック受け付け条件の変更。

7. **「移動遷移後は移動範囲は色を元に戻す」**  
   → 選択解除時・移動後に ValidMoves をクリアし、move-dest を外す。

8. **「桂馬が増殖してしまう。初期条件… 初期先手グループと初期後手グループを用意し、駒の枚数に矛盾がないようにする。」**  
   → 初期駒を固定セットで配置。ここで一度「普通の将棋」になってしまう。

9. **「これでは普通の将棋になっている。」**  
   → 量子状態に戻しつつ、**種類ごとの枚数上限**（WouldExceedTypeCount）と、収束時のチェックを導入。

10. **「先手の角が２枚出現する。… グループAの中で角は一枚しかない。グループBの中で角は一枚しかない。」**  
    → **初期グループ（A/B）** を導入し、取られてもグループは不変。**グループごと**に角1・飛1・王1などで制限。

11. **「グループAで例えば飛車確定したときに、他の駒のグループAのなかの飛車の可能性は消える処理はあるか。UIが更新されているか」**  
    → `RemovePossibilityFromGroup` を追加し、確定時に同グループの他駒からその駒種の可能性を削除。UI は既存の UpdateUI で更新。

12. **「香車確定の時の動き、… すでに確定した香車が消えてしまう。香車、桂馬はグループ内で２枚。歩兵はグループ内で９枚。」**  
    → 「**その種類の確定数がグループ上限に達したときだけ**」他駒から可能性を削除するよう変更。香・桂・金・銀は2枚、歩は9枚。

13. **「香・桂・金・銀（グループ内2枚）… これのテストを作成。」**  
    → 画面上のテストボタンと RunGroupTwoPieceTest を追加。

14. **「fpcunitproject1からテストを実行できるようにし、c:\Lazarus\lazbuildでビルドし実行。実行したものを考察。さらにテストが必要なら追加していく」**  
    → **quantum_shogi_logic.pas** にロジックを切り出し、**FPCUnit** の testcase1 でテストを実装。初回は「確定済みの駒からも香を削除してしまう」バグで1件失敗し、**確定済み（Possibilities = [pt]）は除外**するよう修正。全7テスト通過、考察を TEST_考察.md に記載。

15. **「quantum_shogi.pasでquantum_shogi_logicを使用するようになっているか。重複コードは整理」**  
    → TGame を TGameLogic の子クラスにし、型・InitBoard・枚数制限・RemovePossibilityFromGroup などをユニットに集約。pas2js ビルドと FPCUnit の両方で確認。

16. **「トンネル効果？している。テストを作成し、駒が敵、味方の駒を素通りしないことを確かめる。桂馬のみ飛び越えてよい。」**  
    → **IsPathClear** / **IsMovePathBlocked** を追加。飛・角・香は経路に駒があればブロック、桂馬は飛び越え可。経路遮断のテストを追加し、全13テスト通過。

ここまでが、**人間が「何をしてほしいか」を短いプロンプトで伝え、Cursor がコンパイル通過・挙動修正・テスト追加・リファクタまで一気にやった**流れです。

## 今回初めてのユニットテスト（Lazarus コンソール + FPCUnit）

- **Lazarus のコンソール用 FPCUnit プロジェクト**（fpcunitproject1）から、量子将棋の**ロジックだけ**をテストする形にしました。
- ロジックは **quantum_shogi_logic.pas** に分離し、**quantum_shogi.pas** は UI と進行（DOM・イベント・手番）のみを担当。
- **テストの作成は Cursor に任せました。** 香・桂・金・銀の「2枚目確定で他駒から可能性削除」「1枚目は触らない」、グループ間の影響なし、確定済み駒は触らない、経路遮断（飛・角・香はブロック、桂馬は飛び越え可）など、計13本のテストが追加されています。
- ビルド・実行は次のとおりです。

```batch
cd day041_QuantumShogi
c:\Lazarus\lazbuild fpcunitproject1.lpi
fpcunitproject1.exe
```

- 実行結果の考察（初回失敗とその修正）は、プロジェクト内の **TEST_考察.md** にまとまっています。

## 作成したアプリの機能（抜粋）

- **量子状態の表示**: 各マス・駒台で、可能性のある駒の文字を重ねて表示。確定すると1文字が濃く表示。
- **移動・取る・打つ**: 移動可能マスを緑で表示し、そのマスと駒の選択変更だけクリック可能。駒台から打つときは空マスのみ有効。
- **グループ制限**: 初期グループ A/B ごとに角1・飛1・王1・金2・銀2・桂2・香2・歩9。収束時に上限を超える手は不可。上限に達したときだけ他駒からその可能性を削除。
- **経路遮断**: 飛・角・香は経路上に駒があると進めない。桂馬のみ飛び越え可。
- **勝利判定**: 王の可能性が自軍に1つもなくなった側の負け。

## コンパイル方法（Pas2JS）

```bash
pas2js quantum_shogi.pas -Tbrowser -Jirtl.js
```

`index.html` から生成された `quantum_shogi.js` を読み込み、必要に応じて `rtl.run()` でプログラムを開始します。

### index.html

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>Quantum Shogi - pas2js</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="game-container">
        <div id="stand-1" class="piece-stand gote"></div>
        
        <div id="board" class="shogi-board"></div>
        
        <div id="stand-0" class="piece-stand sente"></div>
    </div>
    <div id="status">手番: 先手</div>

    <script src="quantum_shogi.js"></script>
    <script>rtl.run();</script>
</body>
</html>
```

## ダウンロード

**アプリをブラウザで開く**: [量子将棋を開く](/apps/day041/)

作成したアプリ（HTML / CSS / Pascal ソース・quantum_shogi_logic ユニット・FPCUnit テスト・コンパイル済み JS）は以下のリンクからダウンロードできます。

[day041_QuantumShogi.zip](/downloads/day041_QuantumShogi.zip)

## まとめ：プロンプトの違いと役割分担

- **Gemini**: 「〜を作りたい」「ルールおさらい」「UIは文字重ね」「計算ロジック」「進めます」「まとめて全コード」といった**大きな指示**で、設計とコードの塊を一気に書かせるのに向いていました。一方で、**pas2js の厳密なイベント型**（TJSMouseEvent / TJSEvent）では同じエラーを何度貼っても解消せず、コンパイル完了には至りませんでした。
- **Cursor**: 「コンパイルを完了させて」で型と実装を直して**コンパイル通過**。「文字大きく」「桂馬確定」「駒台重ならない」「移動範囲表示」「グループ制限」「香車2枚目」「テスト作成」「fpcunit で実行」「トンネル効果のテスト」「logic を使うようにして重複整理」など、**具体的な仕様と修正**を短いプロンプトで渡すと、コード変更・テスト追加・考察メモまで一気にやってくれました。
- **ユニットテスト**は今回が初めて。Lazarus のコンソールで FPCUnit を動かし、**テストの作成は Cursor に任せた**ことで、グループ内枚数・経路遮断・確定済み駒を触らないなど、ロジックの安心材料が増えています。

「骨格は Gemini、通す・仕上げ・テストは Cursor」という使い分けが、今回の開発の流れでした。

---

*Lazarusチャレンジ Day 41/100*
