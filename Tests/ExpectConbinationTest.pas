unit ExpectConbinationTest;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  _Expect_Conbination_Test = class(TObject) 
  public
    [Test] procedure _Not_Expection;
  end;

implementation

uses
  MockTools.Mocks, MockTools.Mocks.CoreExpect,
  MockTarget,
  Should, Should.Constraint.CoreMatchers
;

{ _Expect_Conbination_Test }

procedure _Expect_Conbination_Test._Not_Expection;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>;
  mock
    .Setup.WillReturn(1024)
    .Expect(not Once)
    .When.CallCount
  ;

  mock.VerifyAll; // passed

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(1024));

  Its('mock.verify[1]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  Its('count[2]').Val(mock.Instance.CallCount).Should(BeEqualTo(1024));

  mock.VerifyAll; // passed

  Its('count[3]').Val(mock.Instance.CallCount).Should(BeEqualTo(1024));

  mock.VerifyAll; // passed
end;

initialization
  TDUnitX.RegisterTestFixture(_Expect_Conbination_Test);
end.
