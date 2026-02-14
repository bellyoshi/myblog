program project;

uses
  browserconsole, web, js, webaudio;

{ JavaScriptのAudioContextを叩くための関数 }
procedure PlayNote(NoteName: String); async;
var
  AudioCtx: TJSAudioContext;
  Oscillator: TJSOscillatorNode;
  GainNode: TJSGainNode;
  Freq: Double;
begin
  { 1. 音階名から周波数を決定 (Case文の活用) }
  case NoteName of
    'C4': Freq := 261.63;
    'D4': Freq := 293.66;
    'E4': Freq := 329.63;
    'F4': Freq := 349.23;
    'G4': Freq := 392.00;
    'A4': Freq := 440.00;
    'B4': Freq := 493.88;
  else
    Freq := 440.0;
  end;

  { 2. Web Audio APIの操作 }
  AudioCtx := TJSAudioContext.new;
  Oscillator := AudioCtx.createOscillator;
  GainNode := AudioCtx.createGain;

  Oscillator.type_ := 'sine'; // 正弦波（やわらかい音）
  Oscillator.frequency.value := Freq;

  // 音の終わりのプチプチ音を防ぐ（フェードアウト）
  GainNode.gain.setValueAtTime(0.5, AudioCtx.currentTime);
  GainNode.gain.exponentialRampToValueAtTime(0.001, AudioCtx.currentTime + 0.5);

  Oscillator.connect(GainNode);
  GainNode.connect(AudioCtx.destination);

  Oscillator.start;
  Oscillator.stop(AudioCtx.currentTime + 0.5);
end;

begin
  { コンパイラに PlayNote を残させるため参照（実行されない） }
  if false then PlayNote('C4');
  { JavaScript側から関数を呼べるようにエクスポート }
  asm
    window.pas = { PlayNote: $mod.PlayNote };
  end;
end.