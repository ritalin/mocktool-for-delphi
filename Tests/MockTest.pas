unit MockTest;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  _Mock_Test = class(TObject)
  public
    [Test] procedure _Create_Object_Mock;
    [Test] procedure _Create_Interface_Mock;
    [Test] procedure _Create_Interface_Mock_Multi_Intf;
  end;

implementation

uses
  MockTools.Mocks, MockTools.Core.Types, MockTools.Mocks.CoreExpect,
  MockTarget,
  Should, Should.Constraint.CoreMatchers
;

{ _Mock_Test }

procedure _Mock_Test._Create_Object_Mock;
var
  mock: TMock<TCounterObject>;
begin
  mock := TMock.Create<TCounterObject>;
  mock
    .Setup.WillReturn(108)
    .Expect(Exactly(3))
    .When.CallCount
  ;

  Its('mock.verify[0]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(108));

  Its('mock.verify[1]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('count[2]').Val(mock.Instance.CallCount).Should(BeEqualTo(108));

  Its('mock.verify[2]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('count[3]').Val(mock.Instance.CallCount).Should(BeEqualTo(108));

  Its('mock.verify[3]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  Its('count[4]').Val(mock.Instance.CallCount).Should(BeEqualTo(108));

  Its('mock.verify[4]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));
end;

procedure _Mock_Test._Create_Interface_Mock;
var
  mock: TMock<ICounter>;
begin
  mock := TMock.Implements<ICounter>;
  mock
    .Setup.WillReturn(64)
    .Expect(AtLeast(2))
    .When.CallCount
  ;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(64));

  Its('mock.verify[1]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('count[2]').Val(mock.Instance.CallCount).Should(BeEqualTo(64));

  Its('mock.verify[2]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  Its('count[3]').Val(mock.Instance.CallCount).Should(BeEqualTo(64));

  Its('mock.verify[3]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
end;

procedure _Mock_Test._Create_Interface_Mock_Multi_Intf;
var
  mock: TMock<ICounter>;
begin
  mock := TMock.Implements<ICounter>([IShowing]);

  mock.Setup.WillReturn(4096).Expect(Once).When.CallCount;

  mock.Setup<IShowing>.WillReturn('FizzBazz').When.ToString;

  Its('mock.verify[0]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(4096));

  Its('mock.verify[1]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('content[1]').Val(mock.Instance<IShowing>.ToString).Should(BeEqualTo('FizzBazz'));

  Its('mock.verify[2]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  Its('content[2]').Val(mock.Instance<IShowing>.ToString).Should(BeEqualTo('FizzBazz'));

  Its('mock.verify[3]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
end;

initialization

end.


