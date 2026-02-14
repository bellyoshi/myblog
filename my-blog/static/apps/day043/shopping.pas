program shopping;

uses
  browserconsole, web, sysutils, classes;

var
  ItemInput: TJSHTMLInputElement;
  AddBtn, ClearBtn: TJSHTMLButtonElement;
  ItemListUI: TJSHTMLElement;
  DataList: TStringList;

const
  STORAGE_KEY = 'pas2js_shopping_data';

// LocalStorageから読み込み
procedure LoadData;
var
  SavedData: String;
begin
  DataList.Clear;
  SavedData := window.localStorage.getItem(STORAGE_KEY);
  if (SavedData <> '') then
    DataList.CommaText := SavedData; // TStringListの便利機能
end;

// LocalStorageへ保存
procedure SaveData;
begin
  window.localStorage.setItem(STORAGE_KEY, DataList.CommaText);
end;

// UIの再描画
procedure RenderList;
var
  i: Integer;
  li: TJSHTMLElement;
begin
  ItemListUI.innerHTML := '';
  for i := 0 to DataList.Count - 1 do
  begin
    li := TJSHTMLElement(document.createElement('li'));
    li.innerHTML := Format('%s <span class="delete-item" data-index="%d">×</span>', [DataList[i], i]);
    ItemListUI.appendChild(li);
  end;
end;

// アイテム追加イベント
function AddItem(Event: TJSMouseEvent): boolean;
begin
  if ItemInput.value <> '' then
  begin
    DataList.Add(ItemInput.value);
    ItemInput.value := '';
    SaveData;
    RenderList;
  end;
  Result := False;
end;

// 削除・全削除イベント
function HandleListClick(Event: TJSMouseEvent): boolean;
var
  Idx: Integer;
begin
  if TJSHTMLElement(Event.target).className = 'delete-item' then
  begin
    Idx := StrToInt(TJSHTMLElement(Event.target).getAttribute('data-index'));
    DataList.Delete(Idx);
    SaveData;
    RenderList;
  end;
  Result := False;
end;

function ClearAll(Event: TJSMouseEvent): boolean;
begin
  if window.confirm('リストを空にしますか？') then
  begin
    DataList.Clear;
    SaveData;
    RenderList;
  end;
  Result := False;
end;

begin
  // 初期化
  DataList := TStringList.Create;
  ItemInput := TJSHTMLInputElement(document.getElementById('itemInput'));
  AddBtn := TJSHTMLButtonElement(document.getElementById('addBtn'));
  ClearBtn := TJSHTMLButtonElement(document.getElementById('clearBtn'));
  ItemListUI := TJSHTMLElement(document.getElementById('itemList'));

  // イベント登録
  AddBtn.onclick := @AddItem;
  ClearBtn.onclick := @ClearAll;
  ItemListUI.onclick := @HandleListClick;

  // 初期読み込み
  LoadData;
  RenderList;
end.
