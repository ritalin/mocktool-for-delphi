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
    end
  );
end;

procedure _Create_Expect_Roles._Create_Once;
begin

end;

initialization

end.
