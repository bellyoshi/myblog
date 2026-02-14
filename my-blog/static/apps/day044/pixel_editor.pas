program pixel_editor;

uses
  JS, Web, SysUtils, Math;

type
  TColorArr = array[0..15, 0..15] of string; // CSSの色文字列(#RRGGBB)で管理

var
  Grid: TColorArr;
  Canvas: TJSHTMLCanvasElement;
  Ctx: TJSCanvasRenderingContext2D;
  Picker: TJSHTMLInputElement;
  
const
  GRID_SIZE = 16;
  CELL_SIZE = 20; // 320 / 16

{ --- レンダリング --- }
procedure Render;
var
  x, y: Integer;
begin
  for y := 0 to GRID_SIZE - 1 do
    for x := 0 to GRID_SIZE - 1 do
    begin
      Ctx.fillStyle := Grid[x, y];
      Ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE);
      
      // グリッド線
      Ctx.strokeStyle := '#444444';
      Ctx.strokeRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE);
    end;
end;

{ --- 保存機能 (LocalStorage) --- }
procedure AutoSave;
begin
  window.localStorage.setItem('pixel_data', TJSJSON.stringify(Grid));
end;

{ --- クリックイベント --- }
function OnCanvasClick(Event: TJSMouseEvent): boolean;
var
  ix, iy: Integer;
begin
  ix := Floor(Event.OffsetX / CELL_SIZE);
  iy := Floor(Event.OffsetY / CELL_SIZE);

  if (ix in [0..15]) and (iy in [0..15]) then
  begin
    Grid[ix, iy] := Picker.value; // カラーピッカーの色を代入
    Render;
    AutoSave;
  end;
  Result := True;
end;

{ --- ダウンロード機能 --- }
function OnDownload(Event: TJSMouseEvent): boolean;
var
  Link: TJSHTMLAnchorElement;
begin
  Link := TJSHTMLAnchorElement(document.createElement('a'));
  Link.download := 'pixel-art.png';
  Link.href := Canvas.toDataURL('image/png');
  Link.click;
  Result := True;
end;

{ --- クリア機能 --- }
function OnClear(Event: TJSMouseEvent): boolean;
var
  x, y: Integer;
begin
  for x := 0 to 15 do
    for y := 0 to 15 do Grid[x, y] := '#000000';
  Render;
  AutoSave;
  Result := True;
end;

{ --- 初期化 --- }
procedure Init;
var
  Data: String;
  x, y: Integer;
begin
  Canvas := TJSHTMLCanvasElement(document.getElementById('editor'));
  Ctx := TJSCanvasRenderingContext2D(Canvas.getContext('2d'));
  Picker := TJSHTMLInputElement(document.getElementById('picker'));
  
  // イベント登録
  Canvas.onclick := @OnCanvasClick;
  TJSHTMLButtonElement(document.getElementById('btnDownload')).onclick := @OnDownload;
  TJSHTMLButtonElement(document.getElementById('btnClear')).onclick := @OnClear;
  
  // LocalStorageから復元
  Data := window.localStorage.getItem('pixel_data');
  if (Data <> '') then
    Grid := TColorArr(TJSJSON.parse(Data))
  else
  begin
    // 初期はすべて黒
    for x := 0 to 15 do
      for y := 0 to 15 do Grid[x, y] := '#000000';
  end;

  Render;
end;

begin
  Init;
end.