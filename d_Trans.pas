unit d_Trans;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,
  DateUtils, IniFiles, Gauges, Menus, XPMan, ImgList, CoolTrayIcon,
  ComCtrls;

type
  Td_Form = class(TForm)
    Panel1: TPanel;
    d_Memo_Info: TMemo;
    d_Shape_Led: TShape;
    Shape1: TShape;
    d_Lbl_Info: TLabel;
    Panel2: TPanel;
    Gauge1: TGauge;
    Bevel1: TBevel;
    Label1: TLabel;
    d_Lbl_Info1: TLabel;
    d_Shape_Led1: TShape;
    Shape2: TShape;
    d_Lbl_Info2: TLabel;
    d_Shape_Led2: TShape;
    Shape3: TShape;
    d_BitBtn_Pusk: TBitBtn;
    d_BitBtn_Ok: TBitBtn;
    grp1: TGroupBox;
    login1: TLabeledEdit;
    Password1: TLabeledEdit;
    chk1: TCheckBox;
    tmr1: TTimer;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    tmr2: TTimer;
    chk2: TCheckBox;
    TrayIcon1: TCoolTrayIcon;
    ImageList2: TImageList;
    pm1: TPopupMenu;
    N1: TMenuItem;
    Server1: TLabeledEdit;
    N2: TMenuItem;
    procedure OnCreate(Sender: TObject);
    procedure d_BitBtn_PuskClick(Sender: TObject);
    procedure d_BitBtn_OkClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure tmr2Timer(Sender: TObject);
    procedure grp1DblClick(Sender: TObject);
    procedure StatusFile;
    procedure BlockUn;
    procedure chk2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrayIcon1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure chk1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
  private
    { Private declarations }
    function LedSwich: boolean;
    function LedSwich1: boolean;
    function LedSwich2: boolean;
    function CopyFile(sOldFile, sNewFile: string): boolean;
    function ProgressMax: longint;
    procedure WMQueryEndSession(var Message: TMessage); message WM_QUERYENDSESSION;
  public
    { Public declarations }
  end;

type
   TRConfigIniKhD = record
      sMask: string;
      sMask1: string;
      sLogFileName: string;
      sPathLogLocal: string;
      sPathLogServer: string;
      sPathNetServer: string;
      sPathRab: string;
      sPathBackupServer: string;
      sPathBackupLocal: string;
      sLogin: string;
      sPassword: string;
      sServer: string;
      dPreDate: TDate;
      dLastDate: TDate;
      iCountMoon: integer;
    end;

var
   d_Form: Td_Form;
   recConfigIni: TRConfigIniKhD;
   bFlConnect: boolean;
   iCount: Longint = 0;
   iCntMn: longint = 0;
   sLogFileName: string;
   mMask,mMask1: string;
   iniF1: string;
   iniF2: string;
   tic: integer;
   Attrib: Boolean;
   FileHandle: Integer;
   FileName,vr: string;

implementation

{$R *.dfm}
{$R UAC.RES}

//Правильный выход с программы при перезагрузке Винды
procedure Td_Form.WMQueryEndSession(var Message: TMessage);
begin
  Message.Result := 1;
  Application.Terminate;
end;

procedure CreateFormInRightBottomCorner;
var
 r : TRect;
begin
 SystemParametersInfo(SPI_GETWORKAREA, 0, Addr(r), 0);
 d_Form.Left := r.Right-d_Form.Width;
 d_Form.Top := r.Bottom-d_Form.Height;
end;

//Защита от отладчика
function DebuggerPresent:boolean;
type
  TDebugProc = function:boolean; stdcall;
var
   Kernel32:HMODULE;
   DebugProc:TDebugProc;
begin
   Result:=false;
   Kernel32:=GetModuleHandle('kernel32.dll');
   if kernel32 <> 0 then
    begin
      @DebugProc:=GetProcAddress(kernel32, 'IsDebuggerPresent');
      if Assigned(DebugProc) then
         Result:=DebugProc;
    end;                                  
end;

//Узнать свою версию
function GetFileVersion(FileName: string; var VerInfo : TVSFixedFileInfo): boolean;
var
  InfoSize, puLen: DWORD;
  Pt, InfoPtr: Pointer;
begin
  InfoSize := GetFileVersionInfoSize( PChar(FileName), puLen );
  FillChar(VerInfo, SizeOf(TVSFixedFileInfo), 0);
  if InfoSize > 0 then
  begin
    GetMem(Pt,InfoSize);
    GetFileVersionInfo( PChar(FileName), 0, InfoSize, Pt);
    VerQueryValue(Pt,'\',InfoPtr,puLen);
    Move(InfoPtr^, VerInfo, sizeof(TVSFixedFileInfo) );
    FreeMem(Pt);
    Result := True;
  end
  else
    Result := False;
end;

function ShowVersion(FileName:string):string;
var
  VerInfo : TVSFixedFileInfo;
begin
  if GetFileVersion(FileName, VerInfo) then
    Result:=Format('%u.%u.%u.%u',[HiWord(VerInfo.dwProductVersionMS), LoWord(VerInfo.dwProductVersionMS),
      HiWord(VerInfo.dwProductVersionLS), LoWord(VerInfo.dwProductVersionLS)])
  else
    Result:='------';
end;

procedure RestartP;
var
  FullProgPath: PChar;
begin
  FullProgPath := PChar(Application.ExeName);
  WinExec(FullProgPath, SW_SHOW); // Or better use the CreateProcess function
  Application.Terminate; // or: Close; 
end;

// запись в реестра
function RegWriteStr(RootKey: HKEY; Key, Name, Value: string): Boolean;
var
  Handle: HKEY;
  Res: LongInt;
begin
  Result := False;
  Res := RegCreateKeyEx(RootKey, PChar(Key), 0, nil, REG_OPTION_NON_VOLATILE,
    KEY_ALL_ACCESS, nil, Handle, nil);
  if Res <> ERROR_SUCCESS then
    Exit;
  Res := RegSetValueEx(Handle, PChar(Name), 0, REG_SZ, PChar(Value),
    Length(Value) + 1);
  Result := Res = ERROR_SUCCESS;
  RegCloseKey(Handle);
end;

function SplitStr(s: string): string;
begin
   Result:= s;
   if s = '' then Exit;
   if s[Length(s)]<>'\' then Result:= s+'\';
end;{SplitStr}

function StrTime: string;
begin
   Result:= TimeToStr(GetTime) +'  ';
end;{StrTime}

function Td_Form.LedSwich: boolean;
begin
   if DirectoryExists(recConfigIni.sPathLogLocal)
   then begin
         d_Lbl_Info.Font.Color:= clGreen;
         d_Lbl_Info.Caption:= 'Связь с сервером АРМВЗ - ОК';
         bFlConnect:= True;
         d_Shape_Led.Brush.Color:= clLime;
         d_Shape_Led.Pen.Color:= clGreen;
         Result:= True;
        end
   else begin
         d_Lbl_Info.Font.Color:= clRed;
         d_Lbl_Info.Caption:= 'Нет связи с сервером АРМВЗ';
         bFlConnect:= False;
         d_Shape_Led.Brush.Color:= clRed;
         d_Shape_Led.Pen.Color:= clMaroon;
         Result:= False;
        end;
end;{LedSwich}

function Td_Form.LedSwich1: boolean;
begin
   if DirectoryExists(recConfigIni.sPathNetServer)
   then begin
         d_Lbl_Info1.Font.Color:= clGreen;
         d_Lbl_Info1.Caption:= 'Связь с сервером Харьков - ОК';
         bFlConnect:= True;
         d_Shape_Led1.Brush.Color:= clLime;
         d_Shape_Led1.Pen.Color:= clGreen;
         Result:= True;
        end
   else begin
         d_Lbl_Info1.Font.Color:= clRed;
         d_Lbl_Info1.Caption:= 'Нет связи с сервером Харьков';
         bFlConnect:= False;
         d_Shape_Led1.Brush.Color:= clRed;
         d_Shape_Led1.Pen.Color:= clMaroon;
         Result:= False;
        end;
end;{LedSwich}

function Td_Form.LedSwich2: boolean;
begin
   if DirectoryExists(recConfigIni.sPathBackupServer)
   then begin
         d_Lbl_Info2.Font.Color:= clGreen;
         d_Lbl_Info2.Caption:= 'Связь с сервером ЦПЗ - ОК';
         bFlConnect:= True;
         d_Shape_Led2.Brush.Color:= clLime;
         d_Shape_Led2.Pen.Color:= clGreen;
         Result:= True;
        end
   else begin
         d_Lbl_Info2.Font.Color:= clRed;
         d_Lbl_Info2.Caption:= 'Нет связи с сервером ЦПЗ';
         bFlConnect:= False;
         d_Shape_Led2.Brush.Color:= clRed;
         d_Shape_Led2.Pen.Color:= clMaroon;
         Result:= False;
        end;
end;{LedSwich}

function LogDat: string;
var
   sDat: string;
begin
   sDat:= DateToStr(Date);
   Result:= 'Log_'+ sDat[1]+sDat[2]+'-'+sDat[4]+sDat[5]+'-'+sDat[9]+sDat[10];
end;{LogDat}

//Подключение к серверу Подключение сет диска ConnectNetDrive('Y:','\\xp\c$','Vi','');
function ConnectNetDrive(DriveName,Machine,User,Pass:string):variant;
var
  NRW: TNetResource;
  v: variant;
begin
with NRW do
begin
dwType := RESOURCETYPE_ANY;
lpLocalName := pchar(DriveName); // подключаемся к диску с этой буквой
lpRemoteName := pchar(machine);
// Необходимо заполнить. В случае пустой строки
// используется значение lpRemoteName.
lpProvider := '';
end;
v:=WNetAddConnection2(NRW, pchar(pass), pchar(user),CONNECT_UPDATE_PROFILE);
//****** CASE ******
case v of
  ERROR_ACCESS_DENIED	:result:='ERROR_ACCESS_DENIED';
  ERROR_ALREADY_ASSIGNED:result:='ERROR_ALREADY_ASSIGNED';
  ERROR_BAD_DEV_TYPE	:result:='ERROR_BAD_DEV_TYPE';
  ERROR_BAD_DEVICE      :result:='ERROR_BAD_DEVICE';
  ERROR_BAD_NET_NAME	:result:='ERROR_BAD_NET_NAME';
  ERROR_BAD_PROFILE	:result:='ERROR_BAD_PROFILE';
  ERROR_BUSY            :result:='ERROR_BUSY';
  ERROR_CANCELLED       :result:='ERROR_CANCELLED';
  ERROR_CANNOT_OPEN_PROFILE:result:='ERROR_CANNOT_OPEN_PROFILE';
  ERROR_DEVICE_ALREADY_REMEMBERED:result:='ERROR_DEVICE_ALREADY_REMEMBERED';
  ERROR_EXTENDED_ERROR		:result:='ERROR_EXTENDED_ERROR';
  ERROR_INVALID_PASSWORD	:result:='ERROR_INVALID_PASSWORD';
  ERROR_NO_NET_OR_BAD_PATH	:result:='ERROR_NO_NET_OR_BAD_PATH';
  ERROR_NO_NETWORK	:result:='ERROR_NO_NETWORK';
else begin
   result:='';//machine+' ('+DriveName+')';
   d_Form.d_Memo_Info.Lines.Add(StrTime + machine+' ('+DriveName+')'+' - OK');
end;
end;
//****** END CASE ******
end;

//ПОСЧИТАТЬ КОЛИЧЕСТВО ФАЙЛОВ В ПАПКЕ//
function CountFiles(const ADirectory: String): Integer;
var
   Rec : TSearchRec;
   sts : Integer ;
begin
   Result := 0;
   sts := FindFirst(ADirectory + '\*.*', faAnyFile, Rec);
   if sts = 0 then
     begin
       repeat
         if ((Rec.Attr and faDirectory) <> faDirectory) then
            Inc(Result)
            else if (Rec.Name <> '.') and (Rec.Name <> '..') then
            Result := Result + CountFiles(ADirectory + '\'+ Rec.Name);
       until FindNext(Rec) <> 0;
       SysUtils.FindClose(Rec);
     end;
end;

procedure Td_Form.BlockUn;
var
  f:TFileStream;// Переменная для работы с файлами
  s:byte;
begin
iniF1:=ExtractFilePath(ParamStr(0))+'FileTransfer.ini';
iniF2:=ExtractFilePath(ParamStr(0))+'Transfer.ini';
if FileExists(iniF1) then begin
// открываем файл для чтения и записи
f:=TFileStream.Create(iniF1,fmOpenReadWrite);
// переходим в начало файла
f.Seek($00000000,soFromBeginning);
// читаем текущее значение
f.Read(s,sizeof(s));
// если файл доступен, то блокируем его
if s=$4D then
   begin
   s:=$00;// зануляем значение по адресу $00000000
f.Seek($00000000,soFromBeginning);
f.Write(s,sizeof(s));// записали новое значение
d_Memo_Info.Lines.Add(StrTime + 'Status: Block');
end
// если файл заблокирован, то разблокируем его
else
if s=$00 then
   begin
   s:=$4D;
   f.Seek($00000000,soFromBeginning);
   f.Write(s,sizeof(s));
   d_Memo_Info.Lines.Add(StrTime + 'Status: Unblock');
   end;
f.Free;
end;
if FileExists(iniF2) then begin
// открываем файл для чтения и записи
f:=TFileStream.Create(iniF2,fmOpenReadWrite);
// переходим в начало файла
f.Seek($00000000,soFromBeginning);
// читаем текущее значение
f.Read(s,sizeof(s));
// если файл доступен, то блокируем его
if s=$4D then
   begin
   s:=$00;// зануляем значение по адресу $00000000
f.Seek($00000000,soFromBeginning);
f.Write(s,sizeof(s));// записали новое значение
d_Memo_Info.Lines.Add(StrTime + 'Status: Block');
end
// если файл заблокирован, то разблокируем его
else
if s=$00 then
   begin
   s:=$4D;
   f.Seek($00000000,soFromBeginning);
   f.Write(s,sizeof(s));
   d_Memo_Info.Lines.Add(StrTime + 'Status: Unblock');
   end;
f.Free;
end;
end;

procedure Td_Form.StatusFile;
var
  f:TFileStream;// Переменная для работы с файлами
  s:byte;
begin
   iniF1:=ExtractFilePath(ParamStr(0))+'FileTransfer.ini';
   iniF2:=ExtractFilePath(ParamStr(0))+'Transfer.ini';
  if FileExists(iniF1) then begin
   // открываем файл для чтения и записи
   f:=TFileStream.Create(iniF1,fmOpenReadWrite);
   // переходим в начало файла
   f.Seek($00000000,soFromBeginning);
   // читаем текущее значение
   f.Read(s,sizeof(s));
   if s=$4D then d_Memo_Info.Lines.Add(StrTime + 'Status: Unblock');
   if s=$00 then d_Memo_Info.Lines.Add(StrTime + 'Status: Block');
   // закрываем файл
   f.Free;
  end;
  if FileExists(iniF2) then begin
   // открываем файл для чтения и записи
   f:=TFileStream.Create(iniF2,fmOpenReadWrite);
   // переходим в начало файла
   f.Seek($00000000,soFromBeginning);
   // читаем текущее значение
   f.Read(s,sizeof(s));
   if s=$4D then begin
      d_Memo_Info.Lines.Add(StrTime + 'Status: Unblock');
      BlockUn;
   end;
   if s=$00 then d_Memo_Info.Lines.Add(StrTime + 'Status: Block');
   // закрываем файл
   f.Free;
  end;
end;

procedure ConnectServ;
var
  Ini: TIniFile;
begin
   iniF1:=ExtractFilePath(ParamStr(0))+'FileTransfer.ini';
   iniF2:=ExtractFilePath(ParamStr(0))+'Transfer.ini';
   d_Form.d_BitBtn_Pusk.Tag:=10;
   d_Form.d_BitBtn_Pusk.Enabled:=False;
   d_Form.d_BitBtn_Ok.Enabled:=False;
   if FileExists(iniF1) or FileExists(iniF2) then begin
   if FileExists(iniF1) then begin
   Ini:= TIniFile.Create(iniF1);
   try
    recConfigIni.sLogFileName:= LogDat;
    recConfigIni.sMask:= Ini.ReadString('ToKhD','Mask','');
    recConfigIni.sMask1:= Ini.ReadString('ToCPZ','Mask1','');    
    recConfigIni.sPathLogLocal:= SplitStr(Ini.ReadString('LocalDIR','LocalDIR',''));
    if not DirectoryExists(recConfigIni.sPathLogLocal) then CreateDir(recConfigIni.sPathLogLocal);
    recConfigIni.sPathLogServer:= SplitStr(Ini.ReadString('LocalDIR','LocalDIRBackup',''));
    if not DirectoryExists(recConfigIni.sPathLogServer) then CreateDir(recConfigIni.sPathLogServer);
    recConfigIni.sPathNetServer:= SplitStr(Ini.ReadString('ToKhD','DestDIR',''));
    if not DirectoryExists(recConfigIni.sPathNetServer) then CreateDir(recConfigIni.sPathNetServer);
    recConfigIni.sPathRab:= SplitStr(Ini.ReadString('ToKhD','DestDIRBackup',''));
    if not DirectoryExists(recConfigIni.sPathRab) then CreateDir(recConfigIni.sPathRab);
    recConfigIni.sPathBackupServer:= SplitStr(Ini.ReadString('ToCPZ','DestDIR',''));
    if not DirectoryExists(recConfigIni.sPathBackupServer) then CreateDir(recConfigIni.sPathBackupServer);
    recConfigIni.sPathBackupLocal:= SplitStr(Ini.ReadString('ToCPZ','DestDIRBackup',''));
    if not DirectoryExists(recConfigIni.sPathBackupLocal) then CreateDir(recConfigIni.sPathBackupLocal);
    recConfigIni.sLogin:=SplitStr(Ini.ReadString('Login','Login',''));
    recConfigIni.sPassword:=SplitStr(Ini.ReadString('Password','Password',''));
    recConfigIni.sServer:=SplitStr(Ini.ReadString('Server','Server',''));
    if recConfigIni.sLogin <> '' then
    d_Form.login1.Text:=Ini.ReadString('Login','Login','');
    if recConfigIni.sPassword <> '' then
    d_Form.Password1.Text:=Ini.ReadString('Password','Password','');
    if recConfigIni.sServer <> '' then
    d_Form.Server1.Text:=Ini.ReadString('Server','Server','');
    mMask:=recConfigIni.sMask;
    mMask1:=recConfigIni.sMask1;
   finally
      Ini.Free;
   end;
   end;
   d_Form.Label1.Caption:=inttostr(CountFiles(recConfigIni.sPathLogLocal));
   if FileExists(iniF2) then begin
   Ini:= TIniFile.Create(iniF2);
   try
    recConfigIni.sMask:= Ini.ReadString('ToKhD','Mask','');
    recConfigIni.sMask1:= Ini.ReadString('ToCPZ','Mask1','');
    recConfigIni.sLogFileName:= LogDat;
    recConfigIni.sPathLogLocal:= SplitStr(Ini.ReadString('LocalDIR','LocalDIR',''));
    if not DirectoryExists(recConfigIni.sPathLogLocal) then CreateDir(recConfigIni.sPathLogLocal);
    recConfigIni.sPathLogServer:= SplitStr(Ini.ReadString('LocalDIR','LocalDIRBackup',''));
    if not DirectoryExists(recConfigIni.sPathLogServer) then CreateDir(recConfigIni.sPathLogServer);
    recConfigIni.sPathNetServer:= SplitStr(Ini.ReadString('ToKhD','DestDIR',''));
    if not DirectoryExists(recConfigIni.sPathNetServer) then CreateDir(recConfigIni.sPathNetServer);
    recConfigIni.sPathRab:= SplitStr(Ini.ReadString('ToKhD','DestDIRBackup',''));
    if not DirectoryExists(recConfigIni.sPathRab) then CreateDir(recConfigIni.sPathRab);
    recConfigIni.sPathBackupServer:= SplitStr(Ini.ReadString('ToCPZ','DestDIR',''));
    if not DirectoryExists(recConfigIni.sPathBackupServer) then CreateDir(recConfigIni.sPathBackupServer);
    recConfigIni.sPathBackupLocal:= SplitStr(Ini.ReadString('ToCPZ','DestDIRBackup',''));
    if not DirectoryExists(recConfigIni.sPathBackupLocal) then CreateDir(recConfigIni.sPathBackupLocal);
    recConfigIni.sLogin:=SplitStr(Ini.ReadString('Login','Login',''));
    recConfigIni.sPassword:=SplitStr(Ini.ReadString('Password','Password',''));
    recConfigIni.sServer:=SplitStr(Ini.ReadString('Server','Server',''));
    if recConfigIni.sLogin <> '' then
    d_Form.login1.Text:=Ini.ReadString('Login','Login','');
    if recConfigIni.sPassword <> '' then
    d_Form.Password1.Text:=Ini.ReadString('Password','Password','');
    if recConfigIni.sServer <> '' then
    d_Form.Server1.Text:=Ini.ReadString('Server','Server','');
    recConfigIni.dPreDate:= Now;
    recConfigIni.dLastDate:= Now;
    recConfigIni.iCountMoon:= MonthOfTheYear(Now);
    mMask:=recConfigIni.sMask;
    mMask1:=recConfigIni.sMask1;
   finally
      Ini.Free;
   end;
   end;
   end else begin
   FileClose(FileHandle);
   iniF1:=ExtractFilePath(ParamStr(0))+'FileTransfer.ini';
    if not FileExists(iniF1) then begin
     Ini := TIniFile.Create(iniF1);
    try
     Ini.WriteString('LogFile','FileName',LogDat);
     Ini.WriteString('LocalDIR','LocalDIR',recConfigIni.sPathLogLocal);
     Ini.WriteString('LocalDIR','LocalDIRBackup',recConfigIni.sPathLogServer);
     Ini.WriteString('ToKhD','Mask',recConfigIni.sMask);
     Ini.WriteString('ToKhD','DestDIR',recConfigIni.sPathNetServer);
     Ini.WriteString('ToKhD','DestDIRBackup',recConfigIni.sPathRab);
     Ini.WriteString('ToCPZ','Mask1',recConfigIni.sMask1);
     Ini.WriteString('ToCPZ','DestDIR',recConfigIni.sPathBackupServer);
     Ini.WriteString('ToCPZ','DestDIRBackup',recConfigIni.sPathBackupLocal);
     Ini.WriteString('Login','Login',d_Form.login1.Text);
     Ini.WriteString('Password','Password',d_Form.Password1.Text);
     Ini.WriteString('Server','Server',d_Form.Server1.Text);
     Ini.WriteString('Date','PreDate',DateToStr(Now));
     Ini.WriteString('Date','LastDate',DateToStr(Now));
     Ini.WriteString('Date','CountMoon',IntToStr(MonthOfTheYear(Now)));
    finally
     Ini.Free;
    end;
    end;
   end;
   d_Form.d_Memo_Info.Lines.Add('Старт программы '+ DateToStr(Date)+' в '+ TimeToStr(GetTime));
   d_Form.d_Memo_Info.Lines.Add(StrTime+d_Form.Caption);
   d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Проверка связи с серверами ...');
   d_Form.d_Memo_Info.Lines.Add(StrTime+ '==============================');
   iCount:= 0;
   if d_Form.LedSwich
   then begin
        bFlConnect:= True;
          if not DirectoryExists(recConfigIni.sPathLogServer) then begin
             if not ForceDirectories(recConfigIni.sPathLogServer) then
             begin
               raise Exception.Create('Невозможно создать каталог '+ recConfigIni.sPathLogServer);
               d_Form.d_Memo_Info.Lines.Add(StrTime+ recConfigIni.sPathLogServer);
               bFlConnect:= False;
             end;
          end else begin
               d_Form.d_BitBtn_Pusk.Tag:=0;
               d_Form.chk1.Enabled:=True;
               d_Form.chk2.Enabled:=True;
               d_Form.d_BitBtn_Pusk.Enabled:=True;
               d_Form.d_BitBtn_Ok.Enabled:=True;
            if d_Form.LedSwich then
               d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Связь с сервером АРМВЗ - ОК');
               Application.ProcessMessages;
          end;
   end
   else begin
        d_Form.d_BitBtn_Pusk.Tag:=10;
        d_Form.chk1.Enabled:=False;
        d_Form.chk2.Enabled:=False;
        d_Form.d_BitBtn_Pusk.Enabled:=False;
        d_Form.d_BitBtn_Ok.Enabled:=False;
        bFlConnect:= False;
        d_Form.Label1.Caption:= '0';
        d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Нет связи с сервером АРМВЗ: '+recConfigIni.sPathLogServer);
        Application.ProcessMessages;
   end;
   if d_Form.LedSwich1
   then begin
        bFlConnect:= True;
          if not DirectoryExists(recConfigIni.sPathNetServer) then begin
             if not ForceDirectories(recConfigIni.sPathNetServer) then
             begin
               raise Exception.Create('Невозможно создать каталог '+ recConfigIni.sPathNetServer);
               d_Form.d_Memo_Info.Lines.Add(StrTime+ recConfigIni.sPathNetServer);
               bFlConnect:= False;
             end;
          end else begin
               d_Form.d_BitBtn_Pusk.Tag:=0;
               d_Form.chk1.Enabled:=True;
               d_Form.chk2.Enabled:=True;
               d_Form.d_BitBtn_Pusk.Enabled:=True;
               d_Form.d_BitBtn_Ok.Enabled:=True;
            if d_Form.LedSwich1 then
               d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Связь с сервером Харьков - ОК');
               Application.ProcessMessages;
          end;
   end
   else begin
        d_Form.d_BitBtn_Pusk.Tag:=10;
        d_Form.chk1.Enabled:=False;
        d_Form.chk2.Enabled:=False;
        d_Form.d_BitBtn_Pusk.Enabled:=False;
        d_Form.d_BitBtn_Ok.Enabled:=False;
        bFlConnect:= False;
        d_Form.Label1.Caption:= '0';
        d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Нет связи с сервером Харьков: '+recConfigIni.sPathNetServer);
        Application.ProcessMessages;
   end;
   if d_Form.LedSwich2
   then begin
        bFlConnect:= True;
          if not DirectoryExists(recConfigIni.sPathBackupServer) then begin
             if not ForceDirectories(recConfigIni.sPathBackupServer) then
             begin
               raise Exception.Create('Невозможно создать каталог '+ recConfigIni.sPathBackupServer);
               d_Form.d_Memo_Info.Lines.Add(StrTime+ recConfigIni.sPathBackupServer);
               bFlConnect:= False;
             end;
          end else begin
               d_Form.d_BitBtn_Pusk.Tag:=0;
               d_Form.chk1.Enabled:=True;
               d_Form.chk2.Enabled:=True;
               d_Form.d_BitBtn_Pusk.Enabled:=True;
               d_Form.d_BitBtn_Ok.Enabled:=True;
            if d_Form.LedSwich2 then     
               d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Связь с сервером ЦПЗ - ОК');
               Application.ProcessMessages;
          end;
   end
   else begin
        d_Form.d_BitBtn_Pusk.Tag:=10;
        d_Form.chk1.Enabled:=False;
        d_Form.chk2.Enabled:=False;
        d_Form.d_BitBtn_Pusk.Enabled:=False;
        d_Form.d_BitBtn_Ok.Enabled:=False;
        bFlConnect:= False;
        d_Form.Label1.Caption:= '0';
        d_Form.d_Memo_Info.Lines.Add(StrTime+ 'Нет связи с сервером ЦПЗ: '+recConfigIni.sPathBackupServer);
        Application.ProcessMessages;
   end;
   d_Form.d_Memo_Info.Lines.Add(StrTime+ '==============================');
   ///////////////////////////
   d_Form.StatusFile;
   iniF1:=ExtractFilePath(ParamStr(0))+'FileTransfer.ini';
   iniF2:=ExtractFilePath(ParamStr(0))+'Transfer.ini';
   if FileExists(iniF1) then begin
      FileName := iniF1;
      FileHandle := FileOpen(FileName, fmShareExclusive);
      d_Form.d_Memo_Info.Lines.Add(StrTime + 'Файл '+ExtractFileName(iniF1)+' заблокирован');
   end;
   if FileExists(iniF2) then begin
      FileName := iniF2;
      FileHandle := FileOpen(FileName, fmShareExclusive);
      d_Form.d_Memo_Info.Lines.Add(StrTime + 'Файл '+ExtractFileName(iniF2)+' заблокирован');
   end;
   ///////////////////////////
   if d_Form.LedSwich and d_Form.LedSwich1 and d_Form.LedSwich2 then d_Form.tmr2.Enabled:=True;
   Exit;
end;

procedure Td_Form.OnCreate(Sender: TObject);
begin
  tic:=2;
  Label1.Caption:= '0';
  d_Form.chk1.Enabled:=False;
  d_Form.chk2.Enabled:=False;
  d_Form.d_BitBtn_Pusk.Enabled:=False;
  d_Form.d_BitBtn_Ok.Enabled:=False;
  vr:=ShowVersion(Application.ExeName);
  d_Form.Caption:='FileTransfer '+vr;
  //=====Защита от отладчика===========
  //if DebuggerPresent then Application.Terminate;
  TrayIcon1.IconVisible := not TrayIcon1.IconVisible;
  TrayIcon1.ShowBalloonHint(PChar('Внимание'),PChar('Ожидайте ...'+#13#10+'Идет подключение к серверу ...'),bitInfo,20);
  Application.ProcessMessages;
  ConnectServ;
  TrayIcon1.HideBalloonHint;  
  //RegWriteStr(HKEY_CURRENT_USER,'Software\\Microsoft\\Windows\\CurrentVersion\\Run','CopyFileSTS',ParamStr(0));
  tmr1.Enabled:=True;
end;{Td_Form.OnCreate}

function Td_Form.CopyFile(sOldFile, sNewFile: string): boolean;
var
  NewFile: TFileStream;
  OldFile: TFileStream;
begin
    Result:= True;
    try
      OldFile := TFileStream.Create(sOldFile, fmOpenRead or fmShareDenyWrite);
      NewFile := TFileStream.Create(sNewFile, fmCreate {or fmShareDenyRead});
      try
         if NewFile.CopyFrom(OldFile, OldFile.Size)<> OldFile.Size
         then Result:= False;
      except
           Result:= False;
      end;
    finally
       FreeAndNil(OldFile);
       FreeAndNil(NewFile)
    end;
end;{CopyFile}

function Td_Form.ProgressMax: longint;
var
   i: longint;
   SR: TSearchRec;
   sFName: TFileName;
begin
   i:=0;
   with recConfigIni do
   try
     if FindFirst(SplitStr(sPathNetServer)+ sMask, faAnyFile, SR)<>0
     then Result:= 0
     else begin
             repeat
                Application.ProcessMessages;
                if LedSwich
                then begin
                        sFName:= SR.Name;
                        Inc(i);
                        bFlConnect:= True
                     end
                else begin
                        bFlConnect:= False;
                        d_Memo_Info.Lines.Add(StrTime + 'Остановлено пользователем');
                end;
             until ((FindNext(SR)<>0) or not bFlConnect);
             if not bFlConnect then d_Memo_Info.Lines.Add(StrTime + 'Остановлено пользователем');
             Result:= i;
          end;
   finally
       FindClose(sr);
   end;
end;

procedure Td_Form.d_BitBtn_PuskClick(Sender: TObject);
var
   SR: TSearchRec;
   i: Integer;
   attrs: Integer;
   StrL : TStringList;
begin
   if d_BitBtn_Pusk.Tag = 10 then Exit;
   Label1.Caption:= '0';
   Gauge1.MaxValue:= ProgressMax;
   Gauge1.MinValue:= 0;
   Gauge1.Progress:= 0;
   bFlConnect:= True;
   StrL := TStringList.Create;
   StrL.Delimiter := ',';
   StrL.DelimitedText := recConfigIni.sMask;
   Gauge1.MaxValue:=CountFiles(recConfigIni.sPathLogLocal);
   //MC,DC,IM
   for i := 0 to StrL.Count-1 do begin
   mMask:=StrL.Strings[i];
   with recConfigIni do
   try
   if FindFirst(SplitStr(recConfigIni.sPathLogLocal)+ mMask+'*.*', faAnyFile-faDirectory, SR)=0 then begin
     if LedSwich and LedSwich1 and LedSwich2 then
     if FileExists(recConfigIni.sPathLogLocal+SR.Name) then begin
       repeat
        d_Memo_Info.Lines.Add(StrTime+'Копирование файла ... '+SR.Name+' Size: '+IntToStr(SR.Size)+' byte');
       if Attrib then begin  // Attribut Files
        d_Memo_Info.Lines.Add(StrTime+'Проверка атрибута файла '+SR.Name+' - Начата');
        attrs := FileGetAttr(recConfigIni.sPathLogLocal+SR.Name);
        if attrs and faReadOnly > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл только для чтения')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не только для чтения');
        if attrs and faHidden > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл скрытый')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не скрытый');
        if attrs and faSysFile > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл системный')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не системный');
        if attrs and faVolumeID > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл является идентификатором объема')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не является идентификатором объема');
        if attrs and faDirectory > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл является каталогом')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не является каталогом');
        if attrs and faArchive > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл архивный')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не архивный');
        if attrs and faSymLink > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл является ярлыком')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не является ярлыком');
        d_Memo_Info.Lines.Add(StrTime+'Проверка атрибута файла '+SR.Name+' - Закончена');
       end;
        Application.ProcessMessages;
        if FileExists(recConfigIni.sPathLogLocal+SR.Name) then
           if (CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathLogServer+SR.Name) and
               CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathNetServer+SR.Name) and
               CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathRab+SR.Name))
           then begin
                    if (FileExists(recConfigIni.sPathLogServer+SR.Name) and FileExists(recConfigIni.sPathNetServer+SR.Name)) then
                       if (DeleteFile(recConfigIni.sPathLogLocal+SR.Name) and LedSwich and LedSwich1 and LedSwich2)
                       then begin
                                Inc(iCount);
                                Gauge1.Progress:=iCount;
                                Label1.Caption:= IntToStr(iCount);
                                d_Memo_Info.Lines.Add(StrTime + SR.Name + ' - Ok');
                       end else begin
                                bFlConnect:= False;
                                d_Memo_Info.Lines.Add(StrTime + 'Нет связи с сервером!! ');
                       end
           end else d_Memo_Info.Lines.Add(StrTime + recConfigIni.sPathLogLocal+SR.Name + '  Error Copy');
       until ((FindNext(SR)<>0) or not bFlConnect);
             if not bFlConnect then d_Memo_Info.Lines.Add(StrTime + 'Остановлено пользователем');
             FindClose(sr);
             d_Memo_Info.Lines.Add(StrTime + 'Копирование файлов завершено');
             d_Memo_Info.Lines.Add(StrTime + 'Всего скопировано '+ IntToStr(iCount)+' файлов');
             d_Memo_Info.Lines.Add('========================================');
             Gauge1.Progress:=100;
             iCount:= 0;
     end else begin
        d_Memo_Info.Lines.Add(StrTime+'Нет файлов '+mMask+' для копирования!');
     end;
   end;
   except
      d_Memo_Info.Lines.Add(StrTime +'Ошибка копирования!');
   end;
   end;
   StrL.Free;
   StrL := TStringList.Create;
   StrL.Delimiter := ',';
   StrL.DelimitedText := recConfigIni.sMask1;
   //6,d6,1,5,f1,f7,F11,SP,nrsmd,MLife,SKUNIV
   for i := 0 to StrL.Count-1 do begin
   mMask1:=StrL.Strings[i];
   with recConfigIni do
   try
   if FindFirst(SplitStr(recConfigIni.sPathLogLocal)+ mMask1+'*.*', faAnyFile-faDirectory, SR)=0 then begin
     if LedSwich and LedSwich1 and LedSwich2 then
     if FileExists(recConfigIni.sPathLogLocal+SR.Name) then begin
       repeat
        d_Memo_Info.Lines.Add(StrTime+'Копирование файла ... '+SR.Name+' Size: '+IntToStr(SR.Size)+' byte');
       if Attrib then begin  // Attribut Files
        d_Memo_Info.Lines.Add(StrTime+'Проверка атрибута файла '+SR.Name+' - Начата');
        attrs := FileGetAttr(recConfigIni.sPathLogLocal+SR.Name);
        if attrs and faReadOnly > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл только для чтения')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не только для чтения');
        if attrs and faHidden > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл скрытый')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не скрытый');
        if attrs and faSysFile > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл системный')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не системный');
        if attrs and faVolumeID > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл является идентификатором объема')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не является идентификатором объема');
        if attrs and faDirectory > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл является каталогом')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не является каталогом');
        if attrs and faArchive > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл архивный')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не архивный');
        if attrs and faSymLink > 0 then d_Memo_Info.Lines.Add(StrTime + 'Файл является ярлыком')
        else d_Memo_Info.Lines.Add(StrTime + 'Файл не является ярлыком');
        d_Memo_Info.Lines.Add(StrTime+'Проверка атрибута файла '+SR.Name+' - Закончена');
       end;
        Application.ProcessMessages;
        if FileExists(recConfigIni.sPathLogLocal+SR.Name) then
           if (CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathLogServer+SR.Name) and
               //CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathNetServer+SR.Name) and
               //CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathRab+SR.Name) and
               CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathBackupServer+SR.Name) and
               CopyFile(recConfigIni.sPathLogLocal+SR.Name, recConfigIni.sPathBackupLocal+SR.Name))
           then begin
                    if (FileExists(recConfigIni.sPathBackupLocal+SR.Name) and FileExists(recConfigIni.sPathBackupServer+SR.Name)) then
                       if (DeleteFile(recConfigIni.sPathLogLocal+SR.Name) and LedSwich and LedSwich1 and LedSwich2)
                       then begin
                                Inc(iCount);
                                Gauge1.Progress:=iCount;
                                Label1.Caption:= IntToStr(iCount);
                                d_Memo_Info.Lines.Add(StrTime + SR.Name + ' - Ok');
                       end else begin
                                bFlConnect:= False;
                                d_Memo_Info.Lines.Add(StrTime + 'Нет связи с сервером!! ');
                       end
           end else d_Memo_Info.Lines.Add(StrTime + recConfigIni.sPathLogLocal+SR.Name + '  Error Copy');
       until ((FindNext(SR)<>0) or not bFlConnect);
             if not bFlConnect then d_Memo_Info.Lines.Add(StrTime + 'Остановлено пользователем');
             FindClose(sr);
             d_Memo_Info.Lines.Add(StrTime + 'Копирование файлов завершено');
             d_Memo_Info.Lines.Add(StrTime + 'Всего скопировано '+ IntToStr(iCount)+' файлов');
             d_Memo_Info.Lines.Add('========================================');
             Gauge1.Progress:=100;
             iCount:= 0;
     end else begin
        d_Memo_Info.Lines.Add(StrTime+'Нет файлов '+mMask1+' для копирования!');
     end;
   end;
   except
      d_Memo_Info.Lines.Add(StrTime +'Ошибка копирования!');
   end;
   end;
   StrL.Free;
   if not DirectoryExists(ExtractFilePath(ParamStr(0))+'Logs') then CreateDir(ExtractFilePath(ParamStr(0))+'Logs');
   if DirectoryExists(ExtractFilePath(ParamStr(0))+'Logs') then d_Memo_Info.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'Logs\'+LogDat+'.log');
end;{Td_Form.d_BitBtn_PuskClick}

procedure Td_Form.d_BitBtn_OkClick(Sender: TObject);
begin
   bFlConnect:= False;
end;

procedure Td_Form.tmr1Timer(Sender: TObject);
begin
   tic:=tic-1;
   Label1.Caption:=IntToStr(tic);
if tic <= 0 then begin
   tic:=1;
   tmr2.Enabled:=True;
end;
end;

procedure Td_Form.tmr2Timer(Sender: TObject);
begin
if TimeToStr(Time) = '14:10:10' then begin
   tmr2.Enabled:=False;
   d_Form.d_BitBtn_Pusk.Click;
end;
if TimeToStr(Time) = '16:10:10' then begin
   tmr2.Enabled:=False;
   d_Form.d_BitBtn_Pusk.Click;
end;
   tmr2.Enabled:=True;
   Close;
end;

procedure Td_Form.grp1DblClick(Sender: TObject);
begin
  chk1.Enabled:=True;
  chk2.Enabled:=True;
end;

procedure Td_Form.chk2Click(Sender: TObject);
var
   Ini: TIniFile;
begin
    FileClose(FileHandle);
    iniF1:=ExtractFilePath(ParamStr(0))+'FileTransfer.ini';
  if FileExists(iniF1) then begin
    Ini := TIniFile.Create(iniF1);
   try
    Ini.WriteString('LogFile','FileName',recConfigIni.sLogFileName);
    Ini.WriteString('LocalDIR','LocalDIR',recConfigIni.sPathLogLocal);
    Ini.WriteString('LocalDIR','LocalDIRBackup',recConfigIni.sPathLogServer);
    Ini.WriteString('ToKhD','Mask',recConfigIni.sMask);
    Ini.WriteString('ToKhD','DestDIR',recConfigIni.sPathNetServer);
    Ini.WriteString('ToKhD','DestDIRBackup',recConfigIni.sPathRab);
    Ini.WriteString('ToCPZ','Mask1',recConfigIni.sMask1);
    Ini.WriteString('ToCPZ','DestDIR',recConfigIni.sPathBackupServer);
    Ini.WriteString('ToCPZ','DestDIRBackup',recConfigIni.sPathBackupLocal);
    Ini.WriteString('Login','Login',d_Form.login1.Text);
    Ini.WriteString('Password','Password',d_Form.Password1.Text);
    Ini.WriteString('Server','Server',d_Form.Server1.Text);
    Ini.WriteString('Date','PreDate',DateToStr(Now));
    Ini.WriteString('Date','LastDate',DateToStr(Now));
    Ini.WriteString('Date','CountMoon',IntToStr(MonthOfTheYear(Now)));
   finally
      Ini.Free;
   end;
  end;
  if chk2.Checked then RestartP;
end;

procedure Td_Form.FormActivate(Sender: TObject);
begin
  //=====Защита от отладчика===========
  ////if DebuggerPresent then Application.Terminate;
  CreateFormInRightBottomCorner;
  TrayIcon1.IconList := ImageList2;
  TrayIcon1.CycleInterval := 400;
  TrayIcon1.CycleIcons := True;
end;

procedure Td_Form.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  if not CanClose then
  begin
    tmr1.Enabled:=True;
    TrayIcon1.HideMainForm;
    TrayIcon1.IconVisible := True;
  end;
end;

procedure Td_Form.TrayIcon1Click(Sender: TObject);
begin
  Application.ProcessMessages;
  tmr1.Enabled:=False;
  tmr2.Enabled:=False;
  if bFlConnect then d_Form.Show;
end;

procedure Td_Form.FormDestroy(Sender: TObject);
begin
   TrayIcon1.HideMainForm;
   TrayIcon1.IconVisible := False;
end;

procedure Td_Form.N1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure Td_Form.chk1Click(Sender: TObject);
begin
 if chk1.Checked then begin
 if (d_Form.Password1.Text = '') or (d_Form.login1.Text = '')or (d_Form.Server1.Text = '') then Exit;
    ConnectNetDrive('S:',d_Form.Server1.Text,d_Form.login1.Text,d_Form.Password1.Text);
    chk1.Enabled:=false;
    login1.Enabled:=false;
    Password1.Enabled:=false;
    Server1.Enabled:=false;
 end;
end;

procedure Td_Form.N2Click(Sender: TObject);
begin
  d_Form.d_BitBtn_Pusk.Click;
end;

end.
