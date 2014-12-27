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
    procedure TestImpl(
      const proc: TProc<IMockExpect<TCounterObject>, IActionStorage>);
  public
    [Test] procedure _Create_Exactly;
    [Test] procedure _Create_Once;
    [Test] procedure _Create_Never;
    [Test] procedure _Create_At_Least;
    [Test] procedure _Create_At_Least_Once;
    [Test] procedure _Create_At_Most;
    [Test] procedure _Create_Between;
  end;

implementation

uses
  System.Rtti,
  Should, Should.Constraint.CoreMatchers,
  MockTools.Core
;

{ _Create_Expect_Roles }

procedure _Create_Expect_Roles.TestImpl(
  const proc: TProc<IMockExpect<TCounterObject>, IActionStorage>);
var
  proxy: IRecordProxy<TCounterObject>;
  strage: IActionStorage;
  builder: IRoleInvokerBuilder<TCounterObject>;
  expect: IMockExpect<TCounterObject>;
begin
  proxy := TObjectRecordProxy<TCounterObject>.Create;
  strage := TActionStorage.Create;

  builder := TRoleInvokerBuilder<TCounterObject>.Create(proxy, strage);
  expect := TExpect<TCounterObject>.Create(builder);

  Its('Now Recording').Val(proxy.Recording).Should(BeTrue);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(0));
  Its('Actions:Length').Val(Length(strage.Actions)).Should(BeEqualTo(0));

  proc(expect, strage);

  Its('Now Recording').Val(proxy.Recording).Should(not BeTrue);
end;

procedure _Create_Expect_Roles._Create_Exactly;
begin
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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
  Self.TestImpl(
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

      Its('Invoker:roles[0]'    ).Val(invoker.Roles[0]).Should(BeEqualTo(TValue.From<IMockRole>(role)));
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

initialization

end.
