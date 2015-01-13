unit MockTest;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  _Mock_Test = class(TObject)
  public
    [Test] procedure _Create_Object_Mock;
    [Test] procedure _Create_Object_Mock_unarranged;
    [Test] procedure _Create_Interface_Mock;
    [Test] procedure _Create_Interface_Mock_Multi_Intf;
    [Test] procedure _Create_NestedInterface_Mock;
    [Test] procedure _Create_NestedInterface_Mock_with_dependency;
    [Test] procedure _Create_Method_Expection_only;
  end;

implementation

uses
  SysUtils,
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

type
  TAbstractTarget = class
  public
    function Text: string;
    function Value: integer; virtual; abstract;
  end;

{ TAbstractTarget }

function TAbstractTarget.Text: string;
begin
  Result := 'xyz';
end;

procedure _Mock_Test._Create_Object_Mock_unarranged;
var
  mock: TMock<TAbstractTarget>;
begin
  mock := TMock.Create<TAbstractTarget>;

  Its('Text').Val(mock.Instance.Text).Should(BeEqualTo('xyz'));
  Its('Value').Call(
    procedure
    begin
      mock.Instance.Value;
    end
  )
  .Should(BeThrowenException(EAbstractError));
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

procedure _Mock_Test._Create_Method_Expection_only;
var
  mock: TMock<ICounter>;
begin
  mock := TMock.Implements<ICounter>;
  mock.Expect(Once).When.CountUp;

  Its('mock.verify[0]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  mock.Instance.CountUp;

  Its('mock.verify[1]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  mock.Instance.CountUp;

  Its('mock.verify[2]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  mock := TMock.Implements<ICounter>([IShowing]);
  mock.Expect<IShowing>(Once).When.ToString;

  Its('mock.verify[0]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  mock.Instance<IShowing>.ToString;

  Its('mock.verify[1]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));

  mock.Instance<IShowing>.ToString;

  Its('mock.verify[2]').Val(mock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
end;

type
  {$M+}
  INestedInterfaceMaster = interface
    ['{4D81F82A-EC44-40D3-901B-CC22CFE0C642}']
    function GetCounter: ICounter;
  end;
  {$M-}

procedure _Mock_Test._Create_NestedInterface_Mock;
var
  masterMock: TMock<INestedInterfaceMaster>;
  slaveMock: TMock<ICounter>;
  counter: ICounter;
begin
  slaveMock := TMock.Implements<ICounter>;
  slaveMock.Setup.WillReturn(108).When.CallCount;

  masterMock := TMock.Implements<INestedInterfaceMaster>;
  masterMock.Setup.WillReturn(slaveMock).When.GetCounter;

  Its('masterMock.verify[0]').Val(masterMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));
  Its('slaveMock.verify[0]').Val(slaveMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  counter := masterMock.Instance.GetCounter;

  Its('masterMock.verify[1]').Val(masterMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
  Its('slaveMock.verify[1]').Val(slaveMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('counter').Val(masterMock.Instance.GetCounter.CallCount).Should(BeEqualTo(108));

  Its('masterMock.verify[2]').Val(masterMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
  Its('slaveMock.verify[2]').Val(slaveMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
end;

procedure _Mock_Test._Create_NestedInterface_Mock_with_dependency;
var
  masterMock: TMock<INestedInterfaceMaster>;
  slaveMock: TMock<ICounter>;
  counter: ICounter;
begin
  slaveMock := TMock.Implements<ICounter>;
  slaveMock.Setup.WillReturn(108).When.CallCount;

  masterMock := TMock.Implements<INestedInterfaceMaster>;
  masterMock.Setup.WillReturn(slaveMock).When.GetCounter;

  masterMock.DependsOn<ICounter>(slaveMock);

  Its('mock.verify[0]').Val(masterMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  counter := masterMock.Instance.GetCounter;

  Its('mock.verify[1]').Val(masterMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Failed.AsTValue));

  Its('counter').Val(masterMock.Instance.GetCounter.CallCount).Should(BeEqualTo(108));

  Its('mock.verify[2]').Val(masterMock.VerifyAll(true).Status).Should(BeEqualTo(TVerifyResult.TStatus.Passed.AsTValue));
end;

initialization

end.


