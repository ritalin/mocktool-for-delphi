unit MockTools.ExceptionHandler.DUnitX;

interface

implementation

uses
  MockTools.Mocks, DUnitX.TestFramework
;

initialization

MockTools.Mocks.RegisterExceptionProc(
  procedure (message: string)
  begin
    raise DUnitX.TestFramework.ETestFailure.Create(message);
  end
);

end.
