unit CreateExpectRolesTest;

interface

uses
  DUnitX.TestFramework,
  MockTarget
;

type

  [TestFixture]
  _Create_Expect_Roles = class(TObject)
  public
    [Test] procedure _Create_Exactly;
  end;

implementation

uses
  System.SysUtils, System.Rtti,
  Should, Should.Constraint.CoreMatchers,
  MockTools.Mocks, MockTools.Core, MockTools.Core.Types
;

{ _Create_Expect_Roles }

procedure _Create_Expect_Roles._Create_Exactly;
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

initialization

end.
