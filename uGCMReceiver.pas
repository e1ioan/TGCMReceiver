unit uGCMReceiver;

interface
{$IFDEF ANDROID}
uses
  FMX.Types,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  gcmnotification;

type
  JGCMReceiverClass = interface(JBroadcastReceiverClass)
  ['{9D967671-9CD8-483A-98C8-161071CE7B64}']
    {Methods}
  end;

  [JavaSignature('com/ioan/delphi/GCMReceiver')]
  JGCMReceiver = interface(JBroadcastReceiver)
  ['{4B30D537-5221-4451-893D-7916ED11CE1F}']
    {Methods}
  end;


  TJGCMReceiver = class(TJavaGenericImport<JGCMReceiverClass, JGCMReceiver>)
  private
    FOwningComponent: TGCMNotification;
  protected
    constructor _Create(AOwner: TGCMNotification);
  public
    class function Create(AOwner: TGCMNotification): JGCMReceiver;
    procedure OnReceive(Context: JContext; ReceivedIntent: JIntent);
  end;
{$ENDIF}
implementation
{$IFDEF ANDROID}
uses
  System.Classes,
  System.SysUtils,
  FMX.Helpers.Android,
  Androidapi.NativeActivity,
  Androidapi.JNI,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os,
  Androidapi.JNI.PlayServices;

{$REGION 'JNI setup code and callback'}
var
  GCMReceiver: TJGCMReceiver;
  ARNContext: JContext;
  ARNReceivedIntent: JIntent;

procedure GCMReceiverOnReceiveThreadSwitcher;
begin
  Log.d('+gcmReceiverOnReceiveThreadSwitcher');
  Log.d('Thread: Main: %.8x, Current: %.8x, Java:%.8d (%2:.8x)',
    [MainThreadID, TThread.CurrentThread.ThreadID,
    TJThread.JavaClass.CurrentThread.getId]);
  GCMReceiver.OnReceive(ARNContext,ARNReceivedIntent );
  Log.d('-gcmReceiverOnReceiveThreadSwitcher');
end;

//This is called from the Java activity's onReceiveNative() method
procedure GCMReceiverOnReceiveNative(PEnv: PJNIEnv; This: JNIObject; JNIContext, JNIReceivedIntent: JNIObject); cdecl;
begin
  Log.d('+gcmReceiverOnReceiveNative');
  Log.d('Thread: Main: %.8x, Current: %.8x, Java:%.8d (%2:.8x)',
    [MainThreadID, TThread.CurrentThread.ThreadID,
    TJThread.JavaClass.CurrentThread.getId]);
  ARNContext := TJContext.Wrap(JNIContext);
  ARNReceivedIntent := TJIntent.Wrap(JNIReceivedIntent);
  Log.d('Calling Synchronize');
  TThread.Synchronize(nil, GCMReceiverOnReceiveThreadSwitcher);
  Log.d('Synchronize is over');
  Log.d('-gcmReceiverOnReceiveNative');
end;

procedure RegisterDelphiNativeMethods;
var
  PEnv: PJNIEnv;
  ReceiverClass: JNIClass;
  NativeMethod: JNINativeMethod;
begin
  Log.d('Starting the GCMReceiver JNI stuff');

  PEnv := TJNIResolver.GetJNIEnv;

  Log.d('Registering interop methods');

  NativeMethod.Name := 'gcmReceiverOnReceiveNative';
  NativeMethod.Signature := '(Landroid/content/Context;Landroid/content/Intent;)V';
  NativeMethod.FnPtr := @GCMReceiverOnReceiveNative;

  ReceiverClass := TJNIResolver.GetJavaClassID('com.ioan.delphi.GCMReceiver');

  PEnv^.RegisterNatives(PEnv, ReceiverClass, @NativeMethod, 1);

  PEnv^.DeleteLocalRef(PEnv, ReceiverClass);
end;
{$ENDREGION}

{ TActivityReceiver }

constructor TJGCMReceiver._Create(AOwner: TGCMNotification);
begin
  inherited;
  FOwningComponent := AOwner;
  Log.d('TJGCMReceiver._Create constructor');
end;

class function TJGCMReceiver.Create(AOwner: TGCMNotification): JGCMReceiver;
begin
  Log.d('TJGCMReceiver.Create class function');
  Result := inherited Create;
  GCMReceiver := TJGCMReceiver._Create(AOwner);
end;

procedure TJGCMReceiver.OnReceive(Context: JContext;  ReceivedIntent: JIntent);
var
  extras: JBundle;
  gcm: JGoogleCloudMessaging;
  messageType: JString;
  noti: TGCMNotificationMessage;
begin
  if Assigned(FOwningComponent.OnReceiveGCMNotification) then
  begin
    noti := TGCMNotificationMessage.Create;
    try
      Log.d('Received a message!');
      extras := ReceivedIntent.getExtras();
      gcm := FOwningComponent.GetGCMInstance;
      // The getMessageType() intent parameter must be the intent you received
      // in your BroadcastReceiver.
      messageType := gcm.getMessageType(ReceivedIntent);
      if not extras.isEmpty() then
      begin
          {*
           * Filter messages based on message type. Since it is likely that GCM will be
           * extended in the future with new message types, just ignore any message types you're
           * not interested in, or that you don't recognize.
           *}
          if TJGoogleCloudMessaging.JavaClass.MESSAGE_TYPE_SEND_ERROR.equals(messageType) then
          begin
            // It's an error.
            noti.Kind := TGCMNotificationMessageKind.nmMESSAGE_TYPE_SEND_ERROR;
            FOwningComponent.OnReceiveGCMNotification(Self, noti);
          end
          else
          if TJGoogleCloudMessaging.JavaClass.MESSAGE_TYPE_DELETED.equals(messageType) then
          begin
            // Deleted messages on the server.
            noti.Kind := TGCMNotificationMessageKind.nmMESSAGE_TYPE_DELETED;
            FOwningComponent.OnReceiveGCMNotification(Self, noti);
          end
          else
          if TJGoogleCloudMessaging.JavaClass.MESSAGE_TYPE_MESSAGE.equals(messageType) then
          begin
            // It's a regular GCM message, do some work.
            noti.Kind := TGCMNotificationMessageKind.nmMESSAGE_TYPE_MESSAGE;
            noti.Sender := JStringToString(extras.getString(StringToJString('sender')));
            noti.What := StrToIntDef(JStringToString(extras.getString(StringToJString('what'))), 0);
            noti.Body := JStringToString(extras.getString(StringToJString('message')));
            FOwningComponent.OnReceiveGCMNotification(Self, noti);
          end;
      end;
    finally
      noti.Free;
    end;
  end;
end;

initialization
  RegisterDelphiNativeMethods
{$ENDIF}
end.
