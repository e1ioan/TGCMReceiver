unit gcmnotification;

interface
{$IFDEF ANDROID}
uses
  System.SysUtils,
  System.Classes,
  FMX.Helpers.Android,
  Androidapi.JNI.PlayServices,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNIBridge,
  Androidapi.JNI.JavaTypes;

type
  TGCMNotificationMessageKind = (nmMESSAGE_TYPE_MESSAGE, nmMESSAGE_TYPE_DELETED, nmMESSAGE_TYPE_SEND_ERROR);

  { Discription of notification for Notification Center }
  TGCMNotificationMessage = class (TPersistent)
  private
    FKind: TGCMNotificationMessageKind;
    FSender: string;
    FWhat: integer;
    FBody: string;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    { Unique identificator for determenation notification in Notification list }
    property Kind: TGCMNotificationMessageKind read FKind write FKind;
    property Sender: string read FSender write FSender;
    property What: integer read FWhat write FWhat;
    property Body: string read FBody write FBody;
    constructor Create;
  end;

  TOnReceiveGCMNotification = procedure (Sender: TObject; ANotification: TGCMNotificationMessage) of object;

  TGCMNotification = class(TComponent)
  strict private
    { Private declarations }
    FRegistrationID: string;
    FSenderID: string;
    FOnReceiveGCMNotification: TOnReceiveGCMNotification;
    FReceiver: JBroadcastReceiver;
    FAlreadyRegistered: boolean;
    function CheckPlayServicesSupport: boolean;
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function DoRegister: boolean;
    function GetGCMInstance: JGoogleCloudMessaging;
  published
    { Published declarations }
    property SenderID: string read FSenderID write FSenderID;
    property RegistrationID: string read FRegistrationID write FRegistrationID;
    property OnReceiveGCMNotification: TOnReceiveGCMNotification read FOnReceiveGCMNotification write FOnReceiveGCMNotification;
  end;

{$ENDIF}
implementation
{$IFDEF ANDROID}
uses
  uGCMReceiver;


{ TGCMNotification }
function TGCMNotification.CheckPlayServicesSupport: boolean;
var
  resultCode: integer;
begin
  resultCode := TJGooglePlayServicesUtil.JavaClass.isGooglePlayServicesAvailable(SharedActivity);
  result := (resultCode = TJConnectionResult.JavaClass.SUCCESS);
end;

constructor TGCMNotification.Create(AOwner: TComponent);
var
  Filter: JIntentFilter;
begin
  inherited;
  Filter := TJIntentFilter.Create;
  FReceiver := TJGCMReceiver.Create(Self);
  SharedActivity.registerReceiver(FReceiver, Filter);
  FAlreadyRegistered := false;
end;

destructor TGCMNotification.Destroy;
begin
  SharedActivity.unregisterReceiver(FReceiver);
  FReceiver := nil;
  inherited;
end;

function TGCMNotification.DoRegister: boolean;
var
  p: TJavaObjectArray<JString>;
  gcm: JGoogleCloudMessaging;
begin
  if FAlreadyRegistered then
    result := true
  else
  begin
    if CheckPlayServicesSupport then
    begin
      gcm := GetGCMInstance;
      p := TJavaObjectArray<JString>.Create(1);
      p.Items[0] := StringToJString(FSenderID);
      FRegistrationID := JStringToString(gcm.register(p));
      FAlreadyRegistered := (FRegistrationID <> '');
      result := FAlreadyRegistered;
    end
    else
      result := false;
  end;
end;

function TGCMNotification.GetGCMInstance: JGoogleCloudMessaging;
begin
  result := TJGoogleCloudMessaging.JavaClass.getInstance(SharedActivity.getApplicationContext);
end;

{ TGCMNotificationMessage }

procedure TGCMNotificationMessage.AssignTo(Dest: TPersistent);
var
  DestNotification: TGCMNotificationMessage;
begin
  if Dest is TGCMNotificationMessage then
  begin
    DestNotification := Dest as TGCMNotificationMessage;
    DestNotification.Kind := Kind;
    DestNotification.What := What;
    DestNotification.Sender := Sender;
    DestNotification.Body := Body;
  end
  else
    inherited AssignTo(Dest);
end;

constructor TGCMNotificationMessage.Create;
begin
  Body := '';
end;
{$ENDIF}
end.
