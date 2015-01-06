unit MockTools.Core.Types;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections
;

type
  IMockRole = interface;
  ICallerInfo = interface;

  IWhen<T> = interface
    function GetSubject: T;

    property When: T read GetSubject;
  end;

  IMockExpect = interface
    function CreateRole(const callerInfo: ICallerInfo): IMockRole;
  end;

  IWhenOrExpect<T> = interface(IWhen<T>)
    function Expect(const expect: IMockExpect): IWhen<T>;
  end;

  IMockSetup<T> = interface
    function WillReturn(value: TValue): IWhenOrExpect<T>; overload;
    function WillExecute(const proc: TProc): IWhenOrExpect<T>; overload;
    function WillExecute(const fn: TFunc<TValue>): IWhenOrExpect<T>; overload;
    function WillRaise(const provider: TFunc<Exception>): IWhen<T>; overload;
  end;

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

  IMockRole = interface
    procedure DoInvoke(const methodName: TRttiMethod; var outResult: TValue);
    function Verify(invoker: TMockInvoker): TVerifyResult;
  end;

  ICallerInfo = interface
    ['{8E85E18C-881A-4A88-9332-AFD30592582A}']
    function GetCallstacks: TList<TRttiMethod>;
  end;

  IActionStorage = interface(ICallerInfo)
    ['{C96895DC-9236-4A91-ABA6-4883D9B37A27}']
    procedure RecordInvoker(const invoker: TMockInvoker);
    function GetActions: TArray<TMockInvoker>;
    function GetCallstacks: TList<TRttiMethod>;

    property Actions: TArray<TMockInvoker> read GetActions;
    property Callstacks: TList<TRttiMethod> read GetCallstacks;
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
    ['{07A0B665-346E-442A-AF8B-ABE502A90636}']
    procedure PushRole(const role: IMockRole);
    function Build(const method: TRttiMethod; const args: TArray<TValue>): TMockInvoker;
    function GetRoles: TArray<IMockRole>;
    function GetCallerInfo: ICallerInfo;

    property Roles: TArray<IMockRole> read GetRoles;
    property CallerInfo: ICallerInfo read GetCallerInfo;
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
