unit MockTools.Core.Types;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections
;

type
  IMockRole = interface;
  IMockSession = interface;
  IMockExpect = interface;

  TMockExpectWrapper = record
  private
    FExpect: IMockExpect;
  public
    class operator LogicalNot(expect: TMockExpectWrapper): TMockExpectWrapper;
    class operator LogicalAnd(lhs, rhs: TMockExpectWrapper): TMockExpectWrapper;
    class operator LogicalOr(lhs, rhs: TMockExpectWrapper): TMockExpectWrapper;
  public
    function CreateRole(const callerInfo: IMockSession): IMockRole;
  public
    class function Create(const expect: IMockExpect): TMockExpectWrapper; static;
  end;

  IWhen<T> = interface
    function GetSubject: T;

    property When: T read GetSubject;
  end;

  IMockExpect = interface
    function CreateRole(const callerInfo: IMockSession): IMockRole;
  end;

  IWhenOrExpect<T> = interface(IWhen<T>)
    function Expect(const expect: TMockExpectWrapper): IWhen<T>;
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
    TOption = (None, Negate);
  private var
    FReportPrivider: TFunc<TOption, string>;
    FStatus: TStatus;
    FOption: TOption;
  private
    function GetReportText: string;
    function GetStatus: TStatus;
  public
    property Status: TStatus read GetStatus;
    property Report: string read GetReportText;
  public
    class function Create(const provider: TFunc<TOption, string>; const status: TStatus; const opt: TOption): TVerifyResult; overload; static;
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

  TNotExpect = class(TInterfacedObject, IMockExpect)
  private type
    TMockRole = class(TInterfacedObject, IMockRole)
    private
      FParentRole: IMockRole;
    protected
      procedure DoInvoke(const methodName: TRttiMethod; var outResult: TValue);
      function Verify(invoker: TMockAction): TVerifyResult;
    public
      constructor Create(const role: IMockRole);
    end;
  private
    FParentExpect: IMockExpect;
  protected
    { IMockExpect }
    function CreateRole(const callerInfo: IMockSession): IMockRole;
  public
    constructor Create(const expect: IMockExpect);
  end;

  TAndExpect = class(TInterfacedObject, IMockExpect)
  private type
    TMockRole = class(TInterfacedObject, IMockRole)
    private
      FLeftRole: IMockRole;
      FRightRole: IMockRole;
    protected
      procedure DoInvoke(const methodName: TRttiMethod; var outResult: TValue);
      function Verify(invoker: TMockAction): TVerifyResult;
    public
      constructor Create(const lhs, rhs: IMockRole);
    end;
  private
    FLeftExpect: IMockExpect;
    FRightExpect: IMockExpect;
  protected
    { IMockExpect }
    function CreateRole(const callerInfo: IMockSession): IMockRole;
  public
    constructor Create(const lhs, rhs: IMockExpect);
  end;

  TOrExpect = class(TInterfacedObject, IMockExpect)
  private type
    TMockRole = class(TInterfacedObject, IMockRole)
    private
      FLeftRole: IMockRole;
      FRightRole: IMockRole;
    protected
      procedure DoInvoke(const methodName: TRttiMethod; var outResult: TValue);
      function Verify(invoker: TMockAction): TVerifyResult;
    public
      constructor Create(const lhs, rhs: IMockRole);
    end;
  private
    FLeftExpect: IMockExpect;
    FRightExpect: IMockExpect;
  protected
    { IMockExpect }
    function CreateRole(const callerInfo: IMockSession): IMockRole;
  public
    constructor Create(const lhs, rhs: IMockExpect);
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

class function TVerifyResult.Create(const provider: TFunc<TOption, string>;
  const status: TStatus; const opt: TOption): TVerifyResult;
begin
  Assert(Assigned(provider));

  Result.FReportPrivider := provider;
  Result.FStatus := status;
  Result.FOption := opt;
end;

function TVerifyResult.GetReportText: string;
begin
  Result := FReportPrivider(FOption);
end;

function TVerifyResult.GetStatus: TStatus;
begin
  if (FStatus = TStatus.Failed) xor (FOption = TOption.Negate) then begin
    Result := TStatus.Failed;
  end
  else begin
    Result := TStatus.Passed;
  end;
end;

{ TExpectWrapper }

class function TMockExpectWrapper.Create(const expect: IMockExpect): TMockExpectWrapper;
begin
  Assert(Assigned(expect));
  Result.FExpect := expect;
end;

function TMockExpectWrapper.CreateRole(const callerInfo: IMockSession): IMockRole;
begin
  Result := FExpect.CreateRole(callerInfo);
end;

class operator TMockExpectWrapper.LogicalNot(
  expect: TMockExpectWrapper): TMockExpectWrapper;
begin
  Result := TMockExpectWrapper.Create(
    TNotExpect.Create(expect.FExpect)
  );
end;

class operator TMockExpectWrapper.LogicalOr(lhs,
  rhs: TMockExpectWrapper): TMockExpectWrapper;
begin
  Result := TMockExpectWrapper.Create(
    TOrExpect.Create(lhs.FExpect, rhs.FExpect)
  );
end;

class operator TMockExpectWrapper.LogicalAnd(lhs,
  rhs: TMockExpectWrapper): TMockExpectWrapper;
begin
  Result := TMockExpectWrapper.Create(
    TAndExpect.Create(lhs.FExpect, rhs.FExpect)
  );
end;

{ TNotExpect }

constructor TNotExpect.Create(const expect: IMockExpect);
begin
  Assert(Assigned(expect));
  FParentExpect := expect;
end;

function TNotExpect.CreateRole(const callerInfo: IMockSession): IMockRole;
begin
  Result := TMockRole.Create(FParentExpect.CreateRole(callerInfo));
end;

{ TNotExpect.TMockRoleNot }

constructor TNotExpect.TMockRole.Create(const role: IMockRole);
begin
  Assert(Assigned(role));
  FParentRole := role;
end;

procedure TNotExpect.TMockRole.DoInvoke(const methodName: TRttiMethod;
  var outResult: TValue);
begin
  FParentRole.DoInvoke(methodName, outResult);
end;

function TNotExpect.TMockRole.Verify(invoker: TMockAction): TVerifyResult;
begin
  Result := FParentRole.Verify(invoker);

  if Result.FOption = TVerifyResult.TOption.Negate then begin
    Result.FOption := TVerifyResult.TOption.None;
  end
  else begin
    Result.FOption := TVerifyResult.TOption.Negate;
  end;
end;

{ TAndExpect }

constructor TAndExpect.Create(const lhs, rhs: IMockExpect);
begin
  Assert(Assigned(lhs));
  Assert(Assigned(rhs));

  FLeftExpect := lhs;
  FRightExpect := rhs;
end;

function TAndExpect.CreateRole(const callerInfo: IMockSession): IMockRole;
begin
  Result := TMockRole.Create(FLeftExpect.CreateRole(callerInfo), FRightExpect.CreateRole(callerInfo));
end;

{ TAndExpect.TMockRole }

constructor TAndExpect.TMockRole.Create(const lhs, rhs: IMockRole);
begin
  Assert(Assigned(lhs));
  Assert(Assigned(rhs));

  FLeftRole := lhs;
  FRightRole := rhs;
end;

procedure TAndExpect.TMockRole.DoInvoke(const methodName: TRttiMethod;
  var outResult: TValue);
begin
  FLeftRole.DoInvoke(methodName, outResult);
  FRightRole.DoInvoke(methodName, outResult);
end;

function TAndExpect.TMockRole.Verify(invoker: TMockAction): TVerifyResult;
begin
  Result := FLeftRole.Verify(invoker);

  if Result.Status = TVerifyResult.TStatus.Passed then begin
    Result := FRightRole.Verify(invoker);
  end;
end;

{ TOrExpect }

constructor TOrExpect.Create(const lhs, rhs: IMockExpect);
begin
  Assert(Assigned(lhs));
  Assert(Assigned(rhs));

  FLeftExpect := lhs;
  FRightExpect := rhs;
end;

function TOrExpect.CreateRole(const callerInfo: IMockSession): IMockRole;
begin
  Result := TMockRole.Create(FLeftExpect.CreateRole(callerInfo), FRightExpect.CreateRole(callerInfo));
end;

{ TOrExpect.TMockRole }

constructor TOrExpect.TMockRole.Create(const lhs, rhs: IMockRole);
begin
  Assert(Assigned(lhs));
  Assert(Assigned(rhs));

  FLeftRole := lhs;
  FRightRole := rhs;
end;

procedure TOrExpect.TMockRole.DoInvoke(const methodName: TRttiMethod;
  var outResult: TValue);
begin
  FLeftRole.DoInvoke(methodName, outResult);
  FRightRole.DoInvoke(methodName, outResult);
end;

function TOrExpect.TMockRole.Verify(invoker: TMockAction): TVerifyResult;
begin
  Result := FLeftRole.Verify(invoker);

  if Result.Status = TVerifyResult.TStatus.Failed then begin
    Result := FRightRole.Verify(invoker);
  end;
end;

end.
