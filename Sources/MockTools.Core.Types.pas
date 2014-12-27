unit MockTools.Core.Types;

interface

uses
  System.SysUtils, System.Rtti,
  MockTools.Mocks
;

type
  TVerifyResult = record
  public type
    TStatus = (Passed, Failed);
  private
    FStatus: TStatus;
    FReport: string;
  public
    property Status: TStatus read FStatus;
    property Report: string read FReport;
  public
    class function Create(const report: string): TVerifyResult; static;
  end;

  IMockRole = interface
    procedure DoInvoke(const methodName: TRttiMEthod; var outResult: TValue);
    function Verify: TVerifyResult;
  end;

  TMockInvoker = record
  private
    FMethod: TRttiMethod;
    FArgs: TArray<TValue>;
    FRoles: TArray<IMockRole>;
  public
    property Method: TRttiMethod read FMethod;
    property Args: TArray<TValue> read FArgs;
    property Roles: TArray<IMockRole> read FRoles;
  public
    class function Create(
      const method: TRttiMethod; const args: TArray<TValue>;
      const roles: TArray<IMockRole>): TMockInvoker; static;
  end;

  IActionStorage = interface
    procedure RecordInvoker(const invoker: TMockInvoker);
    function GetActions: TArray<TMockInvoker>;

    property Actions: TArray<TMockInvoker> read GetActions;
  end;

  IProxy<T> = interface
    function GetSubject: T;

    property Subject: T read GetSubject;
  end;

  IRecordProxy<T> = interface(IProxy<T>)
    procedure BeginRecord(const callback: TInterceptBeforeNotify);
    procedure EndRecord;
    function IsRecording: boolean;

    property Recording: boolean read IsRecording;
  end;

  IRoleInvokerBuilder<T> = interface(IProxy<T>)
    procedure PushRole(const role: IMockRole);
    function Build(const method: TRttiMethod; const args: TArray<TValue>): TMockInvoker;
    function GetRoles: TArray<IMockRole>;

    property Roles: TArray<IMockRole> read GetRoles;
  end;

implementation

{ TRoleInvoker }

class function TMockInvoker.Create(const method: TRttiMethod;
  const args: TArray<TValue>; const roles: TArray<IMockRole>): TMockInvoker;
begin
  Result.FMethod := method;
  Result.FArgs := args;
  Result.FRoles := roles;
end;

{ TVerifyResult }

class function TVerifyResult.Create(const report: string): TVerifyResult;
begin
  if report = '' then begin
    Result.FStatus := TStatus.Passed;
  end
  else begin
    Result.FStatus := TStatus.Failed;
  end;

  Result.FReport := report;
end;

end.
