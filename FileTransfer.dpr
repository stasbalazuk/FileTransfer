program FileTransfer;

uses
  Forms,
  Windows,
  d_Trans in 'd_Trans.pas' {d_Form};

{$R *.res}

var
 MutexHandle : THandle;
const
 MutexName = 'CopyFileSTS';
begin
  MutexHandle := OpenMutex(MUTEX_ALL_ACCESS, false, MutexName);
  if MutexHandle <> 0 then begin
   CloseHandle(MutexHandle);
   //MessageBox(0,'Проверка связи ...','Внимание!', 0);
   //halt;
  end;
  // Mutex
  MutexHandle := CreateMutex(nil, false, MutexName);
  Application.Initialize;
  Application.CreateForm(Td_Form, d_Form);
  Application.ShowMainForm:=False;
  Application.Run;
  CloseHandle(MutexHandle);
end.
