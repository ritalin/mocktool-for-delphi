unit InterfaceRecordingProxyTest;

interface
uses
  Classes, Rtti,
  DUnitX.TestFramework;

type

  [TestFixture]
  _InterfaceRecordingProxy_Test = class(TObject) 
  public
    [Test] procedure _Has_Rtti;
    [Test] procedure _Create_Proxy;
    [Test] procedure _Create_Builder;
  end;

implementation

uses
  MockTools.Core.Types, MockTools.Core,
  MockTarget,
  Should, Should.Constraint.CoreMatchers
;

function ProxyRecordingHook(log: TStrings): TInterceptBeforeNotify;
begin
  Result :=
    procedure (Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
      out Result: TValue)
    begin
      log.Add(Method.Name);
    end
  ;
end;

{ _InterfaceRecordingProxy_Test }

procedure _InterfaceRecordingProxy_Test._Create_Proxy;
var
  proxy: IRecordProxy<ICounter>;
  obj: ICounter;
  count: integer;
  log: TStrings;
begin
  log := TStringList.Create;
  try
    proxy := TInterfaceRecordProxy<ICounter>.Create(ICounter);
    proxy.BeginRecord(ProxyRecordingHook(log));
    begin
      Its('log:length:before').Val(log.Count).Should(BeEqualTo(0));

      proxy.Subject.CountUp;
      proxy.Subject.CountUp;
      proxy.Subject.CallCount;

      Its('log:length:after').Val(log.Count).Should(BeEqualTo(3));
      Its('log[0]').Val(log[0]).Should(BeEqualTo('CountUp'));
      Its('log[1]').Val(log[1]).Should(BeEqualTo('CountUp'));
      Its('log[2]').Val(log[2]).Should(BeEqualTo('CallCount'));
    end;
    proxy.EndRecord;
  finally
    log.Free;
  end;
end;

procedure _InterfaceRecordingProxy_Test._Has_Rtti;
begin
  Its('INoRttiIntf').Val(HasRtti(TypeInfo(INoRttiIntf))).Should(not BeTrue);
  Its('ICounter').Val(HasRtti(TypeInfo(ICounter))).Should(BeTrue);
end;

procedure _InterfaceRecordingProxy_Test._Create_Builder;
var
  proxy: IRecordProxy<ICounter>;
begin

end;

initialization

end.
