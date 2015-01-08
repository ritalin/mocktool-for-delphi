unit ExpectConbinationTest;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  _Expect_Conbination_Test = class(TObject) 
  public
    [Test] procedure _Not_Expection;
    [Test] procedure _And_Expection;
    [Test] procedure _And_Expection_Failed;
    [Test] procedure _And_Expection_Failed_2;
    [Test] procedure _Or_Expection;
    [Test] procedure _Or_Expection_2;
    [Test] procedure _Or_Expection_3;
    [Test] procedure _Or_Expection_Failed;
  end;

implementation

uses
  MockTools.Mocks, MockTools.Mocks.CoreExpect,
  MockTarget,
  Should, Should.Constraint.CoreMatchers
;

{ _Expect_Conbination_Test }

procedure _Expect_Conbination_Test._And_Expection;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>;
  mock
    .Setup.WillReturn(256)
    .Expect(BeforeOnce('CountUp') and Once)
    .When.CallCount
  ;
  mock
    .Stub.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
  ;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  mock.Instance.CountUp;

  Its('mock.verify[1]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  Its('count[2]').Val(mock.Instance.CallCount).Should(BeEqualTo(256));

  mock.VerifyAll; // passed

  Its('count[3]').Val(mock.Instance.CallCount).Should(BeEqualTo(256));

  Its('mock.verify[3]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));
end;

procedure _Expect_Conbination_Test._And_Expection_Failed_2;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>;
  mock
    .Setup.WillReturn(256)
    .Expect(BeforeOnce('CountUp') and Once)
    .When.CallCount
  ;
  mock
    .Setup.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
  ;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  mock.Instance.CountUp;
  mock.Instance.CountUp;

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(256));

  Its('mock.verify[1]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));
end;

procedure _Expect_Conbination_Test._And_Expection_Failed;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>;
  mock
    .Setup.WillReturn(256)
    .Expect(BeforeOnce('CountUp') and Once)
    .When.CallCount
  ;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(256));

  Its('mock.verify[1]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));
end;

procedure _Expect_Conbination_Test._Or_Expection;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>([IShowing]);
  mock
    .Setup.WillReturn(999)
    .Expect(BeforeOnce('CountUp') or AfterOnce('ToString'))
    .When.CallCount
  ;
  mock
    .Setup.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
  ;
  mock.Stub<IShowing>.WillReturn('FizzBazz').When.ToString;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  mock.Instance.CountUp;
  Its('count[2]').Val(mock.Instance.CallCount).Should(BeEqualTo(999));

  mock.VerifyAll; // passed
end;

procedure _Expect_Conbination_Test._Or_Expection_2;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>([IShowing]);
  mock
    .Setup.WillReturn(999)
    .Expect(BeforeOnce('CountUp') or AfterOnce('ToString'))
    .When.CallCount
  ;
  mock
    .Setup.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
  ;
  mock.Setup<IShowing>.WillReturn('FizzBazz').When.ToString;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  mock.Instance.CountUp;
  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(999));
  mock.Instance<IShowing>.ToString;

  mock.VerifyAll; // passed
end;

procedure _Expect_Conbination_Test._Or_Expection_3;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>([IShowing]);
  mock
    .Setup.WillReturn(999)
    .Expect(BeforeOnce('CountUp') or AfterOnce('ToString'))
    .When.CallCount
  ;
  mock
    .Stub.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
  ;
  mock.Setup<IShowing>.WillReturn('FizzBazz').When.ToString;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  Its('count[1]').Val(mock.Instance.CallCount).Should(BeEqualTo(999));
  mock.Instance<IShowing>.ToString;

  mock.VerifyAll; // passed
end;

procedure _Expect_Conbination_Test._Or_Expection_Failed;
var
  mock: TMock<Icounter>;
begin
  mock := TMock.Implements<Icounter>([IShowing]);
  mock
    .Setup.WillReturn(999)
    .Expect(BeforeOnce('CountUp') or AfterOnce('ToString'))
    .When.CallCount
  ;
  mock
    .Setup.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
  ;
  mock.Setup<IShowing>.WillReturn('FizzBazz').When.ToString;

  Its('mock.verify[0]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  mock.Instance.CountUp;
  mock.Instance.CountUp;

  Its('mock.verify[1]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  Its('count[2]').Val(mock.Instance.CallCount).Should(BeEqualTo(999));

  Its('mock.verify[2]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));

  mock.Instance<IShowing>.ToString;

  mock.VerifyAll; // passed

  mock.Instance<IShowing>.ToString;

  Its('mock.verify[3]').Call(
    procedure
    begin
      mock.VerifyAll;
    end
  )
  .Should(BeThrowenException(ETestFailure));
end;

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
  mock
    .Stub.WillExecute(
      procedure
      begin
      end
    )
    .When.CountUp
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
