unit MockTools.ExceptionHandler.DUnit;

interface

implementation

uses
  MockTools.Mocks, TestFramework
;

initialization

MockTools.Mocks.RegisterExceptionProc(
  procedure (message: string)
  begin
    raise TestFramework.TTestFailure.Create(message);
  end
);

end.
