unit CreateExpectRolesTest;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  MockTarget, MockTools.Mocks, MockTools.Core.Types
;

type

  [TestFixture]
  _Create_Expect_Roles = class(TObject)
  private
    procedure TestImpl<T: class>(
      const proc: TProc<IWhenOrExpect<T>, IActionStorage>);
  public
    [Test] procedure _Create_Exactly;
    [Test] procedure _Create_Once;
    [Test] procedure _Create_Never;
    [Test] procedure _Create_At_Least;
    [Test] procedure _Create_At_Least_Once;
    [Test] procedure _Create_At_Most;
    [Test] procedure _Create_Between;

    [Test] procedure _Create_BeforeOnce_NoCall;
    [Test] procedure _Create_BeforeOnce_NoCall_2;
    [Test] procedure _Create_BeforeOnce_OverCalled;
    [Test] procedure _Create_BeforeOnce_OverCalled_2;
    [Test] procedure _Create_BeforeOnce_Valid;

    [Test] procedure _Create_Before_NoCall;
    [Test] procedure _Create_Before_NoCall_2;
    [Test] procedure _Create_Before_OverCalled;
    [Test] procedure _Create_Before_OverCalled_2;
    [Test] procedure _Create_Before_Valid;

    [Test] procedure _Create_AfterOnce_NoCall;
    [Test] procedure _Create_AfterOnce_NoCall_2;
    [Test] procedure _Create_AfterOnce_OverCalled;
    [Test] procedure _Create_AfterOnce_OverCalled_2;
    [Test] procedure _Create_AfterOnce_Valid;

    [Test] procedure _Create_After_NoCall;
    [Test] procedure _Create_After_NoCall_2;
    [Test] procedure _Create_After_OverCalled;
    [Test] procedure _Create_After_OverCalled_2;
    [Test] procedure _Create_After_Valid;
  end;

implementation

uses
  System.Rtti,
  MockTools.Mocks.CoreExpect, MockTools.Core,
  Should, Should.Constraint.CoreMatchers
;

{ _Create_Expect_Roles }

procedure _Create_Expect_Roles.TestImpl<T>(
  const proc: TProc<IWhenOrExpect<T>, IActionStorage>);
var
  proxy: IRecordProxy<T>;
  strage: IActionStorage;
  builder: IRoleInvokerBuilder<T>;
  expect: IWhenOrExpect<T>;
begin
  proxy := TObjectRecordProxy<T>.Create;
  strage := TActionStorage.Create;

  builder := TRoleInvokerBuilder<T>.Create(proxy, strage);
  expect := TWhen<T>.Create(builder);

  Its('Now Recording').Val(proxy.Recording).Should(BeTrue);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(0));
  Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(0));

  proc(expect, strage);

  Its('Now Recording').Val(proxy.Recording).Should(not BeTrue);
end;

procedure _Create_Expect_Roles._Create_Exactly;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Exactly(2))
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Once;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Once)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Never;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Never)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_At_Least;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AtLeast(2))
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_At_Least_Once;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AtLeastOnce)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_At_Most;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AtMost(2))
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Between;
begin
  Self.TestImpl<TCounterObject>(
    procedure (mock: IWhenOrExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Between(1, 3))
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[4]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

type
  TCallFlowObject = class
  public
    procedure SetupOnce; virtual;
    procedure Setup; virtual;
    procedure Execute; virtual;
    procedure TearDown; virtual;
    procedure TearDownOnce; virtual;
  end;

{ TCallFlowObject }

procedure TCallFlowObject.Execute;
begin

end;

procedure TCallFlowObject.Setup;
begin

end;

procedure TCallFlowObject.SetupOnce;
begin

end;

procedure TCallFlowObject.TearDown;
begin

end;

procedure TCallFlowObject.TearDownOnce;
begin

end;

function FindMethodByName(const name: string): TRttiMethod;
var
  ctx: TRttiContext;
begin
  ctx := TRttiContext.Create;
  try
    Result := ctx.GetType(TCallFlowObject).GetMethod(name);
  finally
    ctx.Free;
  end;
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_NoCall;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(BeforeOnce('SetupOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_NoCall_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(BeforeOnce('SetupOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_Valid;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(BeforeOnce('SetupOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_OverCalled;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(BeforeOnce('SetupOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_OverCalled_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(BeforeOnce('SetupOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Before_NoCall;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Before('Setup'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Before_NoCall_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Before('Setup'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Before_Valid;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Before('Setup'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Before_OverCalled;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Before('Setup'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Before_OverCalled_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(Before('Setup'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_AfterOnce_NoCall;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AfterOnce('TearDownOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_AfterOnce_NoCall_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AfterOnce('TearDownOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_AfterOnce_OverCalled;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AfterOnce('TearDownOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));
      strage.Callstacks.Add(FindMethodByName('TearDown'));

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_AfterOnce_OverCalled_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AfterOnce('TearDownOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));
      strage.Callstacks.Add(FindMethodByName('TearDown'));

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));
      strage.Callstacks.Add(FindMethodByName('TearDown'));

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_AfterOnce_Valid;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(AfterOnce('TearDownOnce'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetUpOnce'));
      strage.Callstacks.Add(FindMethodByName('SetUp'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_After_NoCall;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(After('TearDown'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_After_NoCall_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(After('TearDown'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_After_OverCalled;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(After('TearDown'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_After_OverCalled_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(After('TearDown'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('TearDown'));

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      strage.Callstacks.Add(FindMethodByName('TearDown'));

      Its('Roles[0]:verify[3]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_After_Valid;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (mock: IWhenOrExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      mock
      .Expect(After('TearDown'))
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Setup'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('TearDown'));
      strage.Callstacks.Add(FindMethodByName('TearDownOnce'));

      Its('Roles[0]:verify[2]:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

initialization

end.
