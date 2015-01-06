program MockLibTest;

{$APPTYPE CONSOLE}
uses
  SysUtils,
  DUnitX.AutoDetect.Console,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestRunner,
  DUnitX.TestFramework,
  TestExceptionHandler.DUnitX,
  MockTools.Mocks in '..\Sources\MockTools.Mocks.pas',
  MockTools.Core in '..\Sources\MockTools.Core.pas',
  ObjectRecordingProxyTest in 'ObjectRecordingProxyTest.pas',
  MockTools.Core.Types in '..\Sources\MockTools.Core.Types.pas',
  CreateSetupTest in 'CreateSetupTest.pas',
  MockTarget in 'MockTarget.pas',
  CreateExpectRolesTest in 'CreateExpectRolesTest.pas',
  MockTools.Mocks.CoreExpect in '..\Sources\MockTools.Mocks.CoreExpect.pas',
  InterfaceRecordingProxyTest in 'InterfaceRecordingProxyTest.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
  try
    //Create the runner
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    //tell the runner how we will log things
    logger := TDUnitXConsoleLogger.Create(true);
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create;
    runner.AddLogger(logger);
    runner.AddLogger(nunitLogger);

//    TDUnitX.RegisterTestFixture(_RecordProxy_Test);
    TDUnitX.RegisterTestFixture(_InterfaceRecordingProxy_Test);
    TDUnitX.RegisterTestFixture(_Create_Setup_Roles);
//    TDUnitX.RegisterTestFixture(_Create_Expect_Roles);

    //Run tests
    results := runner.Execute;

    {$IFNDEF CI}
      //We don't want this happening when running under CI.
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
