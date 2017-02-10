unit testgcmmain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Layouts, FMX.Memo, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  gcmnotification;

type
  TForm8 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    gcmn: TGCMNotification;
    procedure OnNotification(Sender: TObject; ANotification: TGCMNotificationMessage);
  end;

const
  YOUR_GCM_SENDERID = '1234567890';
  YOUR_API_ID = 'abc1234567890';

var
  Form8: TForm8;

implementation

{$R *.fmx}

procedure TForm8.Button1Click(Sender: TObject);
begin
  gcmn.SenderID := YOUR_GCM_SENDERID;
  if gcmn.DoRegister then
    Memo1.Lines.Add('Successfully registered with GCM.');
end;

procedure TForm8.Button2Click(Sender: TObject);
const
  sendUrl = 'https://android.googleapis.com/gcm/send';
var
  Params: TStringList;
  AuthHeader: STring;
  idHTTP: TIDHTTP;
  SSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  idHTTP := TIDHTTP.Create(nil);
  try
    SslIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    idHTTP.IOHandler := SSLIOHandler;
    idHTTP.HTTPOptions := [];
    Params := TStringList.Create;
    try
      Params.Add('registration_id='+ gcmn.RegistrationID);
      Params.Values['data.message'] := 'test: ' + FormatDateTime('yy-mm-dd hh:nn:ss', Now);
      idHTTP.Request.Host := sendUrl;
      AuthHeader := 'Authorization: key=' + YOUR_API_ID;
      idHTTP.Request.CustomHeaders.Add(AuthHeader);
      IdHTTP.Request.ContentType := 'application/x-www-form-urlencoded;charset=UTF-8';
      Memo1.Lines.Add('Send result: ' + idHTTP.Post(sendUrl, Params));
    finally
      Params.Free;
    end;
  finally
    FreeAndNil(idHTTP);
  end;
end;

procedure TForm8.FormCreate(Sender: TObject);
begin
   gcmn := TGCMNotification.Create(self);
   gcmn.OnReceiveGCMNotification := OnNotification;
end;

procedure TForm8.FormDestroy(Sender: TObject);
begin
  FreeAndNil(gcmn);
end;

procedure TForm8.OnNotification(Sender: TObject;  ANotification: TGCMNotificationMessage);
begin
  Memo1.Lines.Add('Received: ' + ANotification.Body);
end;

end.
