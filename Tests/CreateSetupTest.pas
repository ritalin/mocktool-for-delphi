unit CreateSetupTest;

interface
uses
  System.SysUtils,
  DUnitX.TestFramework,
  MockTarget, MockTools.Core.Types;

type

  [TestFixture]
  _Create_Setup_Roles = class(TObject)
  private
    procedure TestImpl(const proc: TProc<IMockSetup<TCounterObject>, IMockSessionRecorder>);
  public
    [Test] procedure _Setup_As_WillReturn;
    [Test] procedure _Setup_As_WillReturn_With_Args;
    [Test] procedure _Setup_As_WillExecute;
    [Test] procedure _Setup_As_WillRaise;
    [Test] procedure _Setup_As_WillReturn_With_Expect;
    [Test] procedure _Setup_As_WillExecute_With_Expect;
  end;

implementation

uses
  System.Rtti,
  MockTools.Core, MockTools.Mocks.CoreExpect,
  Should, Should.Constraint.CoreMatchers
;

{ _CreateSetup_Test }

procedure _Create_Setup_Roles.TestImpl(
  const proc: TProc<IMockSetup<TCounterObject>, IMockSessionRecorder>);
var
  proxy: IProxy<TCounterObject>;
  storage: IMockSessionRecorder;
  builder: IMockRoleBuilder<TCounterObject>;
begin
  proxy := TObjectRecordProxy<TCounterObject>.Create;
  storage := TMockSessionRecorder.Create;

  builder := TRoleInvokerBuilder<TCounterObject>.Create(proxy, storage);

  Its('Now Recording:before').Val(proxy.Proxifying).Should(BeTrue);

  Its('Roles:Length').Val(Length(builder.Roles)).Should(BeEqualTo(0));
  Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(0));

  proc(TMockSetup<TCounterObject>.Create(builder, false), storage);

  Its('Now Recording:after').Val(proxy.Proxifying).Should(not BeTrue);
end;

procedure _Create_Setup_Roles._Setup_As_WillReturn;
begin
  TestImpl(
    procedure (setup: IMockSetup<TCounterObject>; storage: IMockSessionRecorder)
    var
      when1: IWhenOrExpect<TCounterObject>;
      invoker: TMockAction;
      role: IMockRole;
      args: TArray<TValue>;
      val: TValue;
    begin
      when1 := setup.WillReturn(28);
      when1.When.CallCount;

      Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(1));

      invoker := storage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));
      Its('Invoker:roles[0]'    ).Val(TObject(invoker.Roles[0]).ClassType).Should(BeEqualTo(TMethodSetupRole));

      role := invoker.Roles[0];

      role.DoInvoke(invoker.Method, args, val);

      Its('Invoker:roles[0]:val').Val(val).Should(BeEqualTo(28));

      Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, args, val);

      Its('Invoker:roles[0]:val').Val(val).Should(BeEqualTo(28));

      Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Setup_Roles._Setup_As_WillReturn_With_Args;
begin
  TestImpl(
    procedure (setup: IMockSetup<TCounterObject>; storage: IMockSessionRecorder)
    var
      invoker: TMockAction;
      role: IMockRole;
      args: TArray<TValue>;
      val: TValue;
    begin
      setup.WillReturn('qwerty').When.SomeFunc(1, 'a');

      Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(1));

      invoker := storage.Actions[0];
      begin
        Its('Invoker[0]:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('SomeFunc'));
        Its('Invoker[0]:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(2));
        Its('Invoker[0]:args[0]'     ).Val(invoker.Args[0]).Should(BeEqualTo(1));
        Its('Invoker[0]:args[0]'     ).Val(invoker.Args[1]).Should(BeEqualTo('a'));
        Its('Invoker[0]:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));
        Its('Invoker[0]:roles[0]'    ).Val(TObject(invoker.Roles[0]).ClassType).Should(BeEqualTo(TMethodSetupRole));

        role := invoker.Roles[0];

        role.DoInvoke(invoker.Method, args, val);

        Its('Invoker:roles[0]:val').Val(val).Should(BeEqualTo('qwerty'));

        Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

        role.DoInvoke(invoker.Method, args, val);

        Its('Invoker:roles[0]:val').Val(val).Should(BeEqualTo('qwerty'));

        Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      end;
    end
  );
end;

procedure _Create_Setup_Roles._Setup_As_WillReturn_With_Expect;
begin
  TestImpl(
    procedure (setup: IMockSetup<TCounterObject>; storage: IMockSessionRecorder)
    var
      when1: IWhenOrExpect<TCounterObject>;
      invoker: TMockAction;
      role1, role2: IMockRole;
      args: TArray<TValue>;
      val1, val2: TValue;
    begin
      when1 := setup.WillReturn(28);
      when1
        .Expect(Exactly(2))
        .When.CallCount;

      Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(1));

      invoker := storage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CallCount'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(2));
      Its('Invoker:roles[0]'    ).Val(TObject(invoker.Roles[0]).ClassType).Should(BeEqualTo(TMethodSetupRole));
      Its('Invoker:roles[1]'    ).Val(TObject(invoker.Roles[1]).ClassType).Should(BeEqualTo(TCountExpectRole));

      role1 := invoker.Roles[0];
      role2 := invoker.Roles[1];

      role1.DoInvoke(invoker.Method, args, val1);
      role2.DoInvoke(invoker.Method, args, val2);

      Its('Invoker:roles[0]:val').Val(val1).Should(BeEqualTo(28));

      Its('role[0]:Verify[0]:status').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      Its('role[1]:Verify[0]:status').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role1.DoInvoke(invoker.Method, args, val1);
      role2.DoInvoke(invoker.Method, args, val2);

      Its('Invoker:roles[0]:val').Val(val1).Should(BeEqualTo(28));

      Its('role[0]:Verify[1]:status').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      Its('role[1]:Verify[1]:status').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role1.DoInvoke(invoker.Method, args, val1);
      role2.DoInvoke(invoker.Method, args, val2);

      Its('Invoker:roles[0]:val').Val(val1).Should(BeEqualTo(28));

      Its('role[0]:Verify[2]:status').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      Its('role[1]:Verify[2]:status').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
    end
  );
end;

procedure _Create_Setup_Roles._Setup_As_WillExecute;
begin
  TestImpl(
    procedure (setup: IMockSetup<TCounterObject>; storage: IMockSessionRecorder)
    var
      count: integer;
      when1: IWhenOrExpect<TCounterObject>;
      invoker: TMockAction;
      role: IMockRole;
      args: TArray<TValue>;
      val: TValue;
    begin
      count := 0;

      Its('count').val(count).Should(BeEqualTo(0));

      when1 := setup.WillExecute(
        procedure (args: TArray<TValue>)
        begin
          count := count + 42;
        end
      );
      when1.When.CountUp;

      Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(1));

      invoker := storage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CountUp'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));
      Its('Invoker:roles[0]'    ).Val(TObject(invoker.Roles[0]).ClassType).Should(BeEqualTo(TMethodSetupRole));

      role := invoker.Roles[0];

      role.DoInvoke(invoker.Method, args, val);

      Its('Invoker:roles[0]:val').Val(val).Should(BeEqualTo(TValue.Empty));
      Its('count').val(count).Should(BeEqualTo(42));

      Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      role.DoInvoke(invoker.Method, args, val);

      Its('Invoker:roles[0]:val').Val(val).Should(BeEqualTo(TValue.Empty));
      Its('count').val(count).Should(BeEqualTo(84));

      Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Setup_Roles._Setup_As_WillExecute_With_Expect;
begin
  TestImpl(
    procedure (setup: IMockSetup<TCounterObject>; storage: IMockSessionRecorder)
    var
      count: integer;
      invoker: TMockAction;
      role1, role2: IMockRole;
      args: TArray<TValue>;
      val1, val2: TValue;
    begin
      count := 0;

      Its('count').val(count).Should(BeEqualTo(0));

      setup.WillExecute(
        procedure (args: TArray<TValue>)
        begin
          count := count + 42;
        end
      )
      .Expect(Exactly(3))
      .When.CountUp;

      Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(1));

      invoker := storage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CountUp'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(2));
      Its('Invoker:roles[0]'    ).Val(TObject(invoker.Roles[0]).ClassType).Should(BeEqualTo(TMethodSetupRole));
      Its('Invoker:roles[1]'    ).Val(TObject(invoker.Roles[1]).ClassType).Should(BeEqualTo(TCountExpectRole));

      role1 := invoker.Roles[0];
      role2 := invoker.Roles[1];

      role1.DoInvoke(invoker.Method, args, val1);
      role2.DoInvoke(invoker.Method, args, val2);

      Its('Invoker:roles[0]:val').Val(val1).Should(BeEqualTo(TValue.Empty));
      Its('count').val(count).Should(BeEqualTo(42));

      Its('role[0]:Verify[0]:status').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      Its('role[1]:Verify[0]:status').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role1.DoInvoke(invoker.Method, args, val1);
      role2.DoInvoke(invoker.Method, args, val2);

      Its('Invoker:roles[0]:val').Val(val1).Should(BeEqualTo(TValue.Empty));
      Its('count').val(count).Should(BeEqualTo(84));

      Its('role[0]:Verify[1]:status').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      Its('role[1]:Verify[1]:status').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

      role1.DoInvoke(invoker.Method, args, val1);
      role2.DoInvoke(invoker.Method, args, val2);

      Its('Invoker:roles[0]:val').Val(val1).Should(BeEqualTo(TValue.Empty));
      Its('count').val(count).Should(BeEqualTo(126));

      Its('role[0]:Verify[2]:status').Val(role1.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
      Its('role[1]:Verify[2]:status').Val(role2.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

procedure _Create_Setup_Roles._Setup_As_WillRaise;
begin
  TestImpl(
    procedure (setup: IMockSetup<TCounterObject>; storage: IMockSessionRecorder)
    var
      when1: IWhen<TCounterObject>;
      invoker: TMockAction;
      role: IMockRole;
      args: TArray<TValue>;
      val: TValue;
    begin
      when1 := setup.WillRaise(
        function: Exception
        begin
          Result := Exception.Create('Error Raised');
        end
      );
      when1.When.CountUp;

      Its('Actions:Length').Val(Length(storage.Actions)).Should(BeEqualTo(1));

      invoker := storage.Actions[0];

      Its('Invoker:name'        ).Val(invoker.Method.Name).Should(BeEqualTo('CountUp'));
      Its('Invoker:args:length' ).Val(Length(invoker.Args)).Should(BeEqualTo(0));
      Its('Invoker:roles:length').Val(Length(invoker.Roles)).Should(BeEqualTo(1));
      Its('Invoker:roles[0]'    ).Val(TObject(invoker.Roles[0]).ClassType).Should(BeEqualTo(TExceptionSetupRole));

      role := invoker.Roles[0];

      Its('Will raise').Call(
        procedure
        begin
          role.DoInvoke(invoker.Method, args, val);
        end
      )
      .Should(BeThrowenException(Exception, 'Error Raised'));

      Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

      Its('Will raise').Call(
        procedure
        begin
          role.DoInvoke(invoker.Method, args, val);
        end
      )
      .Should(BeThrowenException(Exception, 'Error Raised'));

      Its('Verify:status').Val(role.Verify(invoker).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
    end
  );
end;

initialization

end.
