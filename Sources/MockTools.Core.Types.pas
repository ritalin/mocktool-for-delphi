unit MockTools.Core.Types;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections
;

type
  IMockRole = interface;
  IMockSession = interface;

  IWhen<T> = interface
    function GetSubject: T;

    property When: T read GetSubject;
  end;

  IMockExpect = interface
    function CreateRole(const callerInfo: IMockSession): IMockRole;
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

  TMockAction = record
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
      const roles: TArray<IMockRole>): TMockAction; static;
  end;

  IMockRole = interface
    procedure DoInvoke(const methodName: TRttiMethod; var outResult: TValue);
    function Verify(invoker: TMockAction): TVerifyResult;
  end;

  IMockSession = interface
    ['{8E85E18C-881A-4A88-9332-AFD30592582A}']
    function GetActions: TArray<TMockAction>;
    function TryFindAction(const method: TRttiMethod; const args: TArray<TValue>; out outResult: TMockAction): boolean;
    function GetCallstacks: TList<TRttiMethod>;

    property Actions: TArray<TMockAction> read GetActions;
    property Callstacks: TList<TRttiMethod> read GetCallstacks;
  end;

  IMockSessionRecorder = interface(IMockSession)
    ['{C96895DC-9236-4A91-ABA6-4883D9B37A27}']
    procedure RecordAction(const invoker: TMockAction);
  end;

  IReadOnlyProxy<T> = interface
    function GetSubject: T;
    function TryGetSubject(const info: PTypeInfo; out outResult): boolean;

    property Subject: T read GetSubject;
  end;

  IRecordable = interface
    ['{2ADDEE2F-5A2A-46CF-9364-F9C158EBF0DB}']
    procedure BeginProxify(const callback: TInterceptBeforeNotify);
    procedure EndProxify;
    function IsProxifying: boolean;
  end;

  IProxy<T> = interface(IReadOnlyProxy<T>)
    ['{DA2C6DF9-BF35-4485-9E90-F4618A5FAA37}']
    procedure BeginProxify(const callback: TInterceptBeforeNotify);
    procedure EndProxify;
    function IsProxifying: boolean;
    function QueryProxy(const iid: TGuid; out outResult): HResult;

    property Proxifying: boolean read IsProxifying;
  end;

  IMockRoleBuilder<T> = interface(IReadOnlyProxy<T>)
    ['{07A0B665-346E-442A-AF8B-ABE502A90636}']
    procedure PushRole(const role: IMockRole);
    function Build(const method: TRttiMethod; const args: TArray<TValue>): TMockAction;
    function GetRoles: TArray<IMockRole>;
    function GetSession: IMockSession;

    property Roles: TArray<IMockRole> read GetRoles;
    property Session: IMockSession read GetSession;
  end;

implementation

{ TRoleInvoker }

class function TMockAction.Create(const method: TRttiMethod;
  const args: TArray<TValue>; const roles: TArray<IMockRole>): TMockAction;
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
