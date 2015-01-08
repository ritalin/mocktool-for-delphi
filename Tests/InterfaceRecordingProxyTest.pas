unit InterfaceRecordingProxyTest;

interface
uses
  SysUtils, Classes, Rtti,
  DUnitX.TestFramework;

type

  [TestFixture]
  _InterfaceRecordingProxy_Test = class(TObject) 
  public
    [Test] procedure _Has_Rtti;
    [Test] procedure _Create_Proxy;
    [Test] procedure _Create_Proxy_extends_other_intf;
    [Test] procedure _Create_Builder;
  end;

implementation

uses
  MockTools.Core.Types, MockTools.Core, MockTools.Mocks.CoreExpect,
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
  proxy: IProxy<ICounter>;
  log: TStrings;
begin
  log := TStringList.Create;
  try
    proxy := TInterfaceRecordProxy<ICounter>.Create(ICounter, TypeInfo(ICounter), []);

    Its('Now Proxifying:before').Val(proxy.Proxifying).Should(not BeTrue);

    proxy.BeginProxify(ProxyRecordingHook(log));
    begin
      Its('Now Proxifying').Val(proxy.Proxifying).Should(BeTrue);
      Its('log:length:before').Val(log.Count).Should(BeEqualTo(0));

      proxy.Subject.CountUp;
      proxy.Subject.CountUp;
      proxy.Subject.CallCount;

      Its('log:length:after').Val(log.Count).Should(BeEqualTo(3));
      Its('log[0]').Val(log[0]).Should(BeEqualTo('CountUp'));
      Its('log[1]').Val(log[1]).Should(BeEqualTo('CountUp'));
      Its('log[2]').Val(log[2]).Should(BeEqualTo('CallCount'));
    end;
    proxy.EndProxify;

    Its('Now Proxifying:after').Val(proxy.Proxifying).Should(not BeTrue);
  finally
    log.Free;
  end;
end;

procedure _InterfaceRecordingProxy_Test._Create_Proxy_extends_other_intf;
var
  proxy: IProxy<ICounter>;
  log: TStrings;
  showing: IShowing;
begin
  log := TStringList.Create;
  try
    proxy := TInterfaceRecordProxy<ICounter>.Create(ICounter, TypeInfo(ICounter), [IShowing]);

    Its('Now Proxifying:before').Val(proxy.Proxifying).Should(not BeTrue);

    proxy.BeginProxify(ProxyRecordingHook(log));
    begin
      Its('Now Proxifying').Val(proxy.Proxifying).Should(BeTrue);
      Its('log:length:before').Val(log.Count).Should(BeEqualTo(0));

      proxy.Subject.CountUp;
      proxy.Subject.CountUp;
      proxy.Subject.CallCount;

      Its('Switch interface').Val(Supports(proxy.Subject, IShowing, showing)).Should(BeTrue);

      showing.ToString;
      showing.ToString;

      Its('log:length:after').Val(log.Count).Should(BeEqualTo(5));
      Its('log[0]').Val(log[0]).Should(BeEqualTo('CountUp'));
      Its('log[1]').Val(log[1]).Should(BeEqualTo('CountUp'));
      Its('log[2]').Val(log[2]).Should(BeEqualTo('CallCount'));
      Its('log[3]').Val(log[3]).Should(BeEqualTo('ToString'));
      Its('log[4]').Val(log[4]).Should(BeEqualTo('ToString'));
    end;
    proxy.EndProxify;

    Its('Now Proxifying:after').Val(proxy.Proxifying).Should(not BeTrue);
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
  proxy: IProxy<ICounter>;
  storage: IMockSessionRecorder;
  builder: IMockRoleBuilder<ICounter>;
  setup: IMockSetup<ICounter>;
  invoker: TMockAction;
  role1, role2: IMockRole;
  val: TValue;
begin
  proxy := TInterfaceRecordProxy<ICounter>.Create(ICounter, TypeInfo(ICounter), []);
  storage := TMockSessionRecorder.Create;

  Its('Now Proxifying:before').Val(proxy.Proxifying).Should(not BeTrue);

  builder := TRoleInvokerBuilder<ICounter>.Create(
    proxy, storage
  );

  Its('Now Proxifying').Val(proxy.Proxifying).Should(BeTrue);

  Its('Actions:length:before').Val(Length(storage.Actions)).Should(BeEqualTo(0));

  setup := TMockSetup<ICounter>.Create(builder, false);
  setup
    .WillReturn(108)
    .Expect(Exactly(2))
    .When.CallCount
  ;

  Its('Now Proxifying:after').Val(proxy.Proxifying).Should(not BeTrue);

  Its('Actions:length:after').Val(Length(storage.Actions)).Should(BeEqualTo(1));

  invoker := storage.Actions[0];

  Its('Actions[0]:name').Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
  Its('Actions[0]:args:length').Val(Length(invoker.Args)).Should(BeEqualTo(1));  // the receiver is counted
  Its('Actions[0]:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(2));

  role1 := invoker.Roles[0];

  Its('Actions[0]:role[0]:verify[0]').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  role1.DoInvoke(invoker.Method, val);

  Its('Actions[0]:role[0]:result[1]').val(val).Should(BeEqualTo(108));
  Its('Actions[0]:role[0]:verify[1]').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  role1.DoInvoke(invoker.Method, val);

  Its('Actions[0]:role[0]:result[2]').val(val).Should(BeEqualTo(108));
  Its('Actions[0]:role[0]:verify[2]').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  role2 := invoker.Roles[1];

  Its('Actions[0]:role[1]:verify[0]').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  role2.DoInvoke(invoker.Method, val);

  Its('Actions[0]:role[1]:verify[1]').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  role2.DoInvoke(invoker.Method, val);

  Its('Actions[0]:role[1]:verify[2]').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
end;

initialization

end.
