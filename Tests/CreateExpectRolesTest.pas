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
      const proc: TProc<IMockExpect<T>, IActionStorage>);
  public
    [Test] procedure _Create_Exactly;
    [Test] procedure _Create_Once;
    [Test] procedure _Create_Never;
    [Test] procedure _Create_At_Least;
    [Test] procedure _Create_At_Least_Once;
    [Test] procedure _Create_At_Most;
    [Test] procedure _Create_Between;
    [Test] procedure _Create_BeforeOnce_NoCall;
    [Test] procedure _Create_BeforeOnce_Valid;
    [Test] procedure _Create_BeforeOnce_OverCalled;
    [Test] procedure _Create_BeforeOnce_OverCalled_2;
  end;

implementation

uses
  System.Rtti,
  Should, Should.Constraint.CoreMatchers,
  MockTools.Core
;

{ _Create_Expect_Roles }

procedure _Create_Expect_Roles.TestImpl<T>(
  const proc: TProc<IMockExpect<T>, IActionStorage>);
var
  proxy: IRecordProxy<T>;
  strage: IActionStorage;
  builder: IRoleInvokerBuilder<T>;
  expect: IMockExpect<T>;
begin
  proxy := TObjectRecordProxy<T>.Create;
  strage := TActionStorage.Create;

  builder := TRoleInvokerBuilder<T>.Create(proxy, strage);
  expect := TExpect<T>.Create(builder);

  Its('Now Recording').Val(proxy.Recording).Should(BeTrue);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(0));
  Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(0));

  proc(expect, strage);

  Its('Now Recording').Val(proxy.Recording).Should(not BeTrue);
end;

procedure _Create_Expect_Roles._Create_Exactly;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.Exactly(2)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Once;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.Once
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Never;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.Never
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_At_Least;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.AtLeast(2)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_At_Least_Once;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.AtLeastOnce
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_At_Most;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.AtMost(2)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_Between;
begin
  Self.TestImpl<TCounterObject>(
    procedure (expect: IMockExpect<TCounterObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.Between(1, 3)
      .When.CallCount;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[2]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[3]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[4]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
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
    procedure (expect: IMockExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.BeforeOnce('SetupOnce')
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_Valid;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (expect: IMockExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.BeforeOnce('SetupOnce')
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_OverCalled;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (expect: IMockExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.BeforeOnce('SetupOnce')
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Expect_Roles._Create_BeforeOnce_OverCalled_2;
begin
  Self.TestImpl<TCallFlowObject>(
    procedure (expect: IMockExpect<TCallFlowObject>; strage: IActionStorage)
    var
      role: IMockRole;
      invoker: TMockInvoker;
      val: TValue;
    begin
      expect.BeforeOnce('SetupOnce')
      .When.Execute;

      Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(1));

      invoker := strage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('Execute'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));

      role := invoker.Roles[0];

      Its('Roles[0]:verify[0]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      strage.Callstacks.Add(FindMethodByName('SetupOnce'));
      strage.Callstacks.Add(FindMethodByName('Execute'));

      role.DoInvoke(invoker.Method, val);

      Its('Roles[0]:verify[1]:status').Val(role.Verify.Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

initialization

end.
