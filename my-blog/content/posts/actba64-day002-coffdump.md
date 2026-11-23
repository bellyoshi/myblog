---
title: "リンカーの試作の試作：coffdump を作る - Day2"
date: 2026-07-24T12:00:00+09:00
draft: true
description: "ActiveBasicでActiveBasicを作るプロジェクトDay2。リンカーの第一歩として、COFF（.obj）を読み込んで中身を表示する coffdump を作った。COFFヘッダー、セクションヘッダー、リロケーション、シンボルテーブルと文字列テーブルの読み方を整理する。"
tags: ["Actba64", "ActiveBasic", "リンカ", "COFF", "coffdump", "NASM", "Cursor", "Day002"]
categories: ["技術"]
author: "ブログ管理者"
---

# リンカーの試作の試作：coffdump を作る - Day2

記事は２日目だが、実際にはactba64開発、１日目の午後の話だ。セミの鳴き声がうるさい。

まずは COFF を表示するプログラム **coffdump** を作る。
コンパイラーをつくるのに、字句解析でもなく、構文解析でもなく、PE（実行形式）の出力でもなく **coffdump** をつくるのには訳がある。
それは、おいおいわかってくるので、まずはCOFFとはなにかを把握しておこう。

## COFF ファイルとは

Common Object File Format（COFF）は、**プログラムをコンパイル（アセンブル）した直後に生成される**オブジェクトファイル（`.o` や `.obj`）の標準的なバイナリフォーマットだ。Windows の COFF は Unix のものを少し変えて使われている。ちなみに現在のLinux では ELF が使われているが初期のLinuxはCOFFもサポートしていたようだ。

PE ファイル（=`.exe`つまり、われわれの最終生成目標）と違って、COFF はそのままでは実行できない。だが PE ファイルを作るための部品となる。

### COFF ファイルの中身

COFF ファイルの中には、ただの機械語ではなく、リンカが結合しやすいように以下のような情報が整理して入っている。

```text
┌─────────────────────────────────────────┐
│ 1. COFF ヘッダー                        │
│    (ターゲットCPU、セクション数、作成日時など)│
├─────────────────────────────────────────┤
│ 2. セクションヘッダー                   │
│    (各セクションのサイズや位置の情報)   │
├─────────────────────────────────────────┤
│ 3. セクションデータ                     │
│    ・.text セクション (実際のx86マシン語)│
│    ・.data セクション (初期化済み変数)  │
│    ・.bss  セクション (未初期化変数)    │
├─────────────────────────────────────────┤
│ 4. リロケーション情報 (Relocations)     │
│    (後でアドレスを書き換えるべき場所の目印)│
├─────────────────────────────────────────┤
│ 5. シンボルテーブル (Symbol Table)      │
│    (関数名や変数名と、その位置の対応表)  │
└─────────────────────────────────────────┘
```

### なぜリロケーションとシンボルが必要なのか

コンパイルした時点（`.obj` の段階）では、**その関数や変数が最終的な `.exe` のメモリ上のどこに配置されるかがまだ決まっていない。**

例えば `call _ExitProcess@4` という命令を書いたとき、

1. **アセンブラ**は `ExitProcess` がどこにあるか知らないので、仮の値（`00 00 00 00`）を書いておき、「ここを後で書き換えてね」という目印（**リロケーション情報**）を COFF 内に残す。
2. **リンカ**が複数の `.obj` や `.lib`（DLL の接続情報）を集めたとき、初めて `ExitProcess` の実際のアドレスが決まる。
3. **リンカ**は COFF のリロケーション情報を頼りに、仮の値を本物のアドレスで上書きする。

### COFF と PE の関係

実は Windows の実行ファイルである **PE フォーマット（Portable Executable / `.exe` や `.dll`）は、COFF 形式をベースに拡張されたもの**だ。専門的には **PE/COFF** と呼ばれたりする。

| フォーマット | 拡張子 | 役割 | 特徴 |
|---|---|---|---|
| **COFF** | `.obj` / `.o` | 結合前のパーツ | アドレス未確定、リロケーション情報あり |
| **PE (PE/COFF)** | `.exe` / `.dll` | 完成品 | Windows がそのままメモリに載せて実行できる |

- **COFF**：パーツ同士を繋ぐための「つなぎ目情報（シンボルやリロケーション）」がメイン。
- **PE**：Windows のローダーが読み込んですぐ実行できるように、DOS ヘッダーやデータディレクトリなどを頭に追加したもの。

## なぜ coffdump から始めるのか

coffdump はコンパイラ群には含まれないが、最初に作るものとしては適している。

アセンブラの出力が COFF になり、リンカにはその COFF ファイルを入力する。**COFF を制すればアセンブラもリンカーも理解できる**のだ。

coffdump はリンカー（ablinker）の試作の試作というわけだ。機能は、COFF 形式のファイルを読み込み、人間が分かりやすい形でコンソールに表示すること。coffdump ができれば、それがそのままリンカの読み込み部分になる。

リンカーが行う仕事は、大きく分けて 4 つのステップがある。

```text
[ .obj ファイル ]
       │
       ▼
 1. COFFの解析              (マシン語データやリロケーション情報の読み込み)
       │
       ▼
 2. メモリレイアウトの決定  (各セクションを .exe 上のどこに置くか計算)
       │
       ▼
 3. リロケーション（補正）  (仮アドレスを決定した実アドレスで上書き)
       │
       ▼
 4. PEヘッダーの付加と出力  (Windows用ヘッダーをつけて .exe として保存)
```

このうち **1. COFF の解析** の部分だけを、まずは作成する。

使い方のイメージはこうだ。

```text
> coffdump.exe sample.obj
（見やすい形に表示）
```

## 準備：sample.obj を作る

`prototype1` フォルダを作り、ActiveBasic のプロジェクトエディタを開いて `coffdump.pj` プロジェクトを作成した。

まだアセンブラができていないので、読み込ませる COFF ファイル（`.obj`）は外部ツールの NASM を使って作る。Day1 の sample.asm を再掲する。

**sample.asm**

```nasm
global _main
extern _ExitProcess@4

section .text
_main:
    push 0                  ; 終了コード 0 (正常終了)
    call _ExitProcess@4     ; Windowsを正常終了するAPI
```

```powershell
nasm -f win32 sample.asm -o sample.obj
```

これで obj ファイルが用意できた。あとは `coffdump.exe sample.obj` で中身が表示されるように、`coffdump.pj` を編集していく。

## 実装に必要なデータ構造

COFF（`.obj`）は先頭に構造体（ヘッダー）がくっついたバイナリファイルだ。ActiveBasic の `Type` 構文で定義して、ファイルから読み込む。

### ① COFF ヘッダー（.obj の先頭）

```vb
' COFF File Header (20 バイト)
Type COFF_HEADER
    Machine              As Word   ' CPUの種類 (x86なら 0x014C)
    NumberOfSections     As Word   ' セクション数 (.text や .data の数)
    TimeDateStamp        As DWord  ' タイムスタンプ
    PointerToSymbolTable As DWord  ' シンボルテーブルの位置
    NumberOfSymbols      As DWord  ' シンボルの数
    SizeOfOptionalHeader As Word   ' オプションヘッダーのサイズ (OBJでは通常 0)
    Characteristics      As Word   ' フラグ
End Type
```

### ② セクションヘッダー（.text などの情報）

```vb
' Section Header (40 バイト)
Type SECTION_HEADER
    Name(7)              As Byte   ' セクション名 (例: ".text\0\0\0")
    VirtualSize          As DWord  ' メモリ上のサイズ
    VirtualAddress       As DWord  ' メモリ上の配置アドレス (RVA)
    SizeOfRawData        As DWord  ' ファイル上のサイズ
    PointerToRawData     As DWord  ' ファイル上の位置
    PointerToRelocations As DWord  ' リロケーション情報へのポインタ ★重要
    PointerToLinenumbers As DWord  ' デバッグ用行番号ポインタ
    NumberOfRelocations  As Word   ' リロケーションの数 ★重要
    NumberOfLinenumbers  As Word   ' 行番号の数
    Characteristics      As DWord  ' 実行/読み/書き 権限フラグ
End Type
```

リロケーション（`COFF_RELOCATION`）とシンボル（`COFF_SYMBOL`）の定義は Day1 で紹介したとおりだ。

これらを abp ファイルに用意し、Cursor にすべてを託した。

**プロンプト**

> Coffdumpを作成

しばらくコーヒーを淹れて、飲みながら待つ。

## coffdump のアルゴリズム

出来上がった coffdump のアルゴリズムは、3 つの重要な部分に分けることができる。

### 1. COFF ヘッダーの解析（ファイルの「目次」の読み取り）

プログラムはファイル先頭から `SIZEOF_COFF_HEADER`（20 バイト）分をメモリコピーし、構造体 `COFF_HEADER` に割り当てる。

```text
[ファイル先頭 buf]
 ├─ 0x00: Machine (2 Bytes)              -> 0x014C なら i386 (32bit)
 ├─ 0x02: NumberOfSections (2 Bytes)     -> セクションの総数
 ├─ 0x04: TimeDateStamp (4 Bytes)        -> 作成日時
 ├─ 0x08: PointerToSymbolTable (4 Bytes) -> シンボルテーブルのファイル内オフセット ★重要
 ├─ 0x0C: NumberOfSymbols (4 Bytes)      -> シンボルの総数 ★重要
 ├─ 0x10: SizeOfOptionalHeader (2 Bytes) -> オプショナルヘッダーのサイズ（OBJでは通常0）
 └─ 0x12: Characteristics (2 Bytes)      -> フラグ情報
```

ポイントは 2 つ。

- **オフセット計算の起点を作る**：セクションヘッダーがどこから始まるかを決めるため、`sectOff = SIZEOF_COFF_HEADER + hdr.SizeOfOptionalHeader` を計算する。OBJ ファイルでは通常オプショナルヘッダーは 0 バイトだが、規格に忠実に加算して先頭位置を確定させている。
- **シンボル位置の確保**：後続の処理で使う `hdr.PointerToSymbolTable`（ファイル先頭からのバイト数）と `hdr.NumberOfSymbols` をここで保持する。

### 2. セクションヘッダーとリロケーションの解析（データ・コードの区画整理）

#### (1) セクションヘッダーのループ解析

各セクションヘッダーのサイズは `SIZEOF_SECTION_HEADER`（40 バイト）固定だ。

```text
[配列要素のオフセット計算]
off = sectOff + (i * SIZEOF_SECTION_HEADER)
```

1. **境界チェック（安全対策）**：`off + SIZEOF_SECTION_HEADER > fsiz` で、壊れたファイルなどによる領域外アクセス（アクセス違反）を防いでいる。
2. **構造体の読み出し**：`memcpy` で 40 バイト分を `SECTION_HEADER` 構造体に読み込む。
    - `Name`：8 バイトのセクション名（`.text`、`.data`、`.rdata` など）。
    - `SizeOfRawData` / `PointerToRawData`：実際にコードやデータが格納されているファイル内の位置とサイズ。
    - `PointerToRelocations` / `NumberOfRelocations`：このセクションに紐づく再配置情報の位置と件数。

#### (2) リロケーション（再配置情報）の展開

コンパイル時点では、関数や変数の最終的なアドレスが決まっていない。リンカに対して「ここを後で書き換えてね」と指示する情報がリロケーションだ。

```text
[セクション i のリロケーション配列]
off = sect.PointerToRelocations + (j * SIZEOF_COFF_RELOCATION)
```

1. **配列の走査**：`sect.NumberOfRelocations` 回だけループを回し、リロケーション構造体（`SIZEOF_COFF_RELOCATION` = 10 バイト）を順に取得する。
2. **情報の抽出**：
    - **`VirtualAddress`（4 Bytes）**：セクション内での書き換え対象のオフセット（何バイト目か）。
    - **`SymbolTableIndex`（4 Bytes）**：参照先が「シンボルテーブルの何番目の要素か」。
    - **`RelType`（2 Bytes）**：書き換えの方式。
        - `IMAGE_REL_I386_DIR32`：アドレスをそのまま絶対値（32bit）で書き込む。
        - `IMAGE_REL_I386_REL32`：呼び出し元からの相対距離（相対ジャンプ / CALL など）で書き込む。

### 3. シンボルテーブルと文字列テーブルの解析（名前解決）

COFF 形式で最も複雑で、工夫が凝らされているのが**名前（Symbol Name）の解釈**だ。

#### (1) 文字列テーブル（String Table）の位置特定

COFF 形式では、ファイルサイズを減らすために「短い名前」と「長い名前」で管理方法を変えている。シンボルテーブル全体（1 個あたり 18 バイト × `nSym` 個）の**すぐ直後**に「文字列テーブル」が置かれている。

```text
[バイナリ構造]
[COFF Header] ... [Sections] ... [Symbol 0][Symbol 1]...[Symbol N-1] [String Table]
                                 ▲                                   ▲
                     PointerToSymbolTable                     strTab (Pointer)
```

コードでは次のようにして `strTab`（文字列テーブルの先頭アドレス）を割り出している。

```vb
off = hdr.PointerToSymbolTable + nSym * SIZEOF_COFF_SYMBOL
memcpy(VarPtr(strTabSize), VarPtr(buf[off]), 4) ' 先頭4バイトに文字列テーブル全体のサイズが入っている
strTab = VarPtr(buf[off])
```

#### (2) `SymbolName$` 関数の名前復元

シンボル構造体（18 バイト）の先頭 8 バイト（`Name` フィールド）の使われ方は 2 パターンある。

```text
【パターンA: 短い名前（8バイト以下）】
Name(0..7) : [ 'm' ][ 'a' ][ 'i' ][ 'n' ][ \0 ][   ][   ][   ]
 -> 先頭4バイトは 0 ではない。そのまま 8 バイト以内の文字列として扱う。

【パターンB: 長い名前（9バイト以上）】
Name(0..3) : [ 0x00 ][ 0x00 ][ 0x00 ][ 0x00 ]  -> 先頭4バイト（Zeroes）が「0」
Name(4..7) : [    Offset (4 Bytes)    ]         -> 文字列テーブル内へのオフセット値
```

`SymbolName$` は、この判定を次のように行っている。

```vb
memcpy(VarPtr(zeroes), VarPtr(sym->Name(0)), 4)
If zeroes = 0 Then
    ' パターンB: 先頭4バイトが0なら、後半4バイトをオフセットとして文字列テーブルから取得
    memcpy(VarPtr(offset), VarPtr(sym->Name(4)), 4)
    SymbolName$ = MakeStr(VarPtr(strTab[offset]))
Else
    ' パターンA: そのまま8バイト固定長の文字列を取り出す
    SymbolName$ = ShortName$(VarPtr(sym->Name(0)))
End If
```

sample.obj の `_ExitProcess@4` は 14 文字あるので、パターン B で文字列テーブルに入っている。

#### (3) 補助シンボル（Auxiliary Symbols）のスキップ

COFF のシンボルテーブルには、関数定義の追加情報（関数サイズや行番号など）を持つ「補助シンボル（Aux Symbol）」が入ることがある。

- 補助シンボルも通常シンボルと同じ **18 バイト**で、通常シンボルの直後に並ぶ。
- 通常シンボルの `NumberOfAuxSymbols` フィールド（1 バイト）に「後ろに続く補助シンボルの個数」が記録されている。

プログラムでは、これを `auxLeft` カウンタで次のようにスキップしている。

```vb
If auxLeft > 0 Then
    ' 前のシンボルが「補助シンボルあり」と指示していた場合
    Print "[" + Str$(i) + "] <aux>"
    auxLeft = auxLeft - 1  ' 残り個数を減らす
Else
    ' 通常のシンボル解析を実施
    ...
    auxLeft = sym.NumberOfAuxSymbols ' 次の要素のために補助シンボル数をセット
End If
```

これで構造が崩れることなく、インデックス `i`（0 から `nSym - 1`）とバイナリデータを同期させたまま解析を終えられる。

## ビルドと実行

完成したら、ActiveBasic で `coffdump.pj` を開き、リリースコンパイルする。ActiveBasic は GUI でコンパイルするので、ここは手作業だ。

coffdump.exe ができたら、ターミナルで obj を見てみる。

```powershell
.\coffdump.exe .\sample.obj
```

**実行結果**

```text
File: .\sample.obj
Size: 132 bytes

=== COFF Header ===
Machine              : 0x014C (i386)
NumberOfSections     : 1
TimeDateStamp        : 0x00000000
PointerToSymbolTable : 0x0000004D
NumberOfSymbols      : 2
SizeOfOptionalHeader : 0
Characteristics      : 0x0000

=== Sections (1) ===
--- Section #1 : .text ---
  VirtualSize          : 0x00000000
  VirtualAddress       : 0x00000000
  SizeOfRawData        : 0x00000007
  PointerToRawData     : 0x0000003C
  PointerToRelocations : 0x00000043
  NumberOfRelocations  : 1
  Characteristics      : 0x60500020
  Relocations:
    [0] VA=0x00000003  Sym=1  Type=20 (REL32)

=== Symbols (2) ===
StringTable size: 19
[0] _main  Value=0x00000000  Section=1  Type=0x0000  Class=2 (EXTERNAL)  Aux=0
[1] _ExitProcess@4  Value=0x00000000  Section=0  Type=0x0000  Class=2 (EXTERNAL)  Aux=0
```

sample.asm と見比べると、ちゃんと読めているのが分かる。

- `.text` は 7 バイト。`push 0`（`6A 00`）の 2 バイトと `call`（`E8 xx xx xx xx`）の 5 バイトだ。
- リロケーションは `VA=0x00000003` に 1 つ。`call` の opcode `E8` の次、つまりオフセット 3 からの 4 バイトが「後で書き換える場所」で、参照先はシンボル 1 の `_ExitProcess@4`、方式は相対（REL32）。
- `_ExitProcess@4` は `Section=0`、つまりこの obj の中には定義がない（外部シンボル）。これをリンカが解決することになる。
- 文字列テーブルのサイズ 19 は、サイズ欄の 4 バイト + `_ExitProcess@4\0` の 15 バイトだ。

## まとめ
COFF は exeの部品。
CoffDumpは リンカー、アセンブラの試作。


