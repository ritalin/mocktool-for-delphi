unit ObjectRecordingProxyTest;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  _RecordProxy_Test = class(TObject)
  public
    [Test] procedure _Create_Object_Record_Proxy;
    [Test] procedure _Create_Builder;
    [Test] procedure _Create_Expect;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo,
  MockTools.Mocks, MockTools.Core.Types, MockTools.Core,
  MockTarget,
  Should, Should.Constraint.CoreMatchers
;

procedure ProxyFook(Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
      out Result: TValue);
begin
  DoInvoke := false;
end;

{ _RecordProxy_Test }

procedure _RecordProxy_Test._Create_Object_Record_Proxy;
var
  proxy: IRecordProxy<TCounterObject>;
  obj: TCounterObject;
  count: integer;
begin
  proxy := TObjectRecordProxy<TCounterObject>.Create;
  proxy.BeginRecord(ProxyFook);
  begin
    proxy.Subject.CountUp;
  end;

  proxy := TObjectRecordProxy<TCounterObject>.Create;
  proxy.BeginRecord(ProxyFook);
  begin
    obj := proxy.Subject;
    try
      count := obj.CallCount;
    finally
      obj.Free;
    end;
  end;

  obj := TCounterObject.Create;
  try
    obj.CountUp;
    obj.CountUp;
    obj.CountUp;

    count := obj.CallCount;
  finally
    obj.Free;
  end;
end;

type
  TDummyRole = class(TInterfacedObject, IMockRole)
    procedure DoInvoke(var outResult: TValue);
    function Verify: TVerifyResult;
  end;

{ TDummyRole }

procedure TDummyRole.DoInvoke(var outResult: TValue);
begin

end;

procedure _RecordProxy_Test._Create_Builder;
var
  proxy: IRecordProxy<TCounterObject>;
  builder: IRoleInvokerBuilder<TCounterObject>;
  role1, role2: IMockRole;
  invoker: TMockInvoker;

  ctx: TRttiContext;
  t: TRttiType;
begin
  proxy := TObjectRecordProxy<TCounterObject>.Create;

  Its('Now Recording').Val(proxy.Recording).Should(not BeTrue);

  builder := TRoleInvokerBuilder<TCounterObject>.Create(
    proxy, TActionStorage.Create
  );

  // ロールの追加を行わせたくないため、レコーディングフックを差し替える
  proxy.BeginRecord(ProxyFook);

  Its('Now Recording').Val(proxy.Recording).Should(BeTrue);

  role1 := TDummyRole.Create;
  role2 := TDummyRole.Create;

  builder.PushRole(role1);
  builder.PushRole(role2);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(2));
  Its('Roles[0]').Val(builder.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role1)));
  Its('Roles[1]').Val(builder.Roles[1]).Should(BeEqualTo(TValue.From<IMockRole>(role2)));

  ctx := TRttiContext.Create;
  try
    t := ctx.GetType(System.TypeInfo(TCounterObject));

    invoker := builder.Build(t.GetMethod('SomeFunc'), TArray<TValue>.Create(42, 'Answer'));

    Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('SomeFunc'));
    Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(2));
    Its('Invoker:args[0]'     ).Val(invoker.Args[0]).Should(BeEqualTo(42));
    Its('Invoker:args[1]'     ).Val(invoker.Args[1]).Should(BeEqualTo('Answer'));
    Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(2));
    Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role1)));
    Its('Invoker:roles[1]'    ).Val(invoker.Roles[1]).Should(BeEqualTo(TValue.From<IMockRole>(role2)));
  finally
    ctx.Free;
  end;
end;

procedure _RecordProxy_Test._Create_Expect;
var
  proxy: IRecordProxy<TCounterObject>;
  strage: IActionStorage;
  builder: IRoleInvokerBuilder<TCounterObject>;
  expect: IExpect<TCounterObject>;
  when: IWhen<TCounterObject>;

  role: IMockRole;
  invoker: TMockInvoker;
begin
  proxy := TObjectRecordProxy<TCounterObject>.Create;
  strage := TActionStorage.Create;

  builder := TRoleInvokerBuilder<TCounterObject>.Create(proxy, strage);
  expect := TExpect<TCounterObject>.Create(builder);

  Its('Now Recording').Val(proxy.Recording).Should(BeTrue);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(0));
  Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(0));

  when := expect.Exactly(2);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(1));
  Its('Roles[0]').Val(TObject(builder.Roles[0]).ClassType).Should(BeEqualTo(TExpectRole));

  role := builder.Roles[0];

  when.When.CallCount;

  Its('Now Recording').Val(proxy.Recording).Should(not BeTrue);
  Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

  invoker := strage.Actions[0];

  Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
  Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
  Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));
  Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
end;

function TDummyRole.Verify: TVerifyResult;
begin
  Result := System.Default(TVerifyResult);
end;

end.
