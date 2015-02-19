unit MockTools.Core;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections, System.Generics.Defaults,
  MockTools.Mocks, MockTools.Core.Types
;


type
  TCountExpectRole = class(TInterfacedObject, IMockRole)
  private
    FCount: integer;
    FVerifire: TPredicate<integer>;
    FReportProvider: TFunc<TMockAction, integer, TVerifyResult.TOption, string>;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; const args: TArray<TValue>; var outResult: TValue);
    function Verify(invoker: TMockAction): TVerifyResult;
  public
    function OnVerify(const verifire: TPredicate<integer>): TCountExpectRole;
    function OnErrorReport(const provider: TFunc<TMockAction, integer, TVerifyResult.TOption, string>): TCountExpectRole;
  end;

  TMethodCallExpectRole = class(TInterfacedObject, IMockRole)
  public type
    TStatus = (NoCall, Called, Failed);
    TVerifyProc = TFunc<integer, integer, TMethodCallExpectRole.TStatus, TMethodCallExpectRole.TStatus>;
  private
    FIndicies: TList<integer>;
    FOnInvoke: TProc<TList<integer>>;
    FBeforeVerify: TProc<TList<integer>>;
    FOnVerify: TVerifyProc;
    FReportProvider: TFunc<TMockAction, TVerifyResult.TOption, string>;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; const args: TArray<TValue>; var outResult: TValue);
    function Verify(invoker: TMockAction): TVerifyResult;
  public
    constructor Create(const onInvoke: TProc<TList<integer>>; const beforeVerify: TProc<TList<integer>>);
    destructor Destroy; override;
    function OnVerify(const fn: TVerifyProc): TMethodCallExpectRole;
    function OnErrorReport(const fn: TFunc<TMockAction, TVerifyResult.TOption, string>): TMethodCallExpectRole;
  end;

  TAbstractSetupRole<T> = class abstract(TInterfacedObject, IMockRole)
  private
    FInvoked: boolean;
    FProvider: TFunc<TRttiMethod, TArray<TValue>, T>;
    FStub: Boolean;
    function FailedReportText(action: TMockAction): TFunc<TVerifyResult.TOption, string>;
  protected
    procedure DoInvokeInternal(const willReturn: T; var outResult: TValue); virtual; abstract;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; const args: TArray<TValue>; var outResult: TValue);
    function Verify(invoker: TMockAction): TVerifyResult;
  public
    constructor Create(const provider: TFunc<TRttiMethod, TArray<TValue>, T>; const isStub: boolean);
  end;

  TMethodSetupRole = class(TAbstractSetupRole<TValue>)
  protected
    { IMockRole }
    procedure DoInvokeInternal(const willReturn: TValue; var outResult: TValue); override;
  end;

  TExceptionSetupRole = class(TAbstractSetupRole<Exception>)
  protected
    { IMockRole }
    procedure DoInvokeInternal(const willReturn: Exception; var outResult: TValue); override;
  end;

  TExpectRoleFactory = class(TInterfacedObject, IMockExpect)
  private
    FFactory: TFunc<IMockSession, IMockRole>;
  private
    constructor Create(const factory: TFunc<IMockSession, IMockRole>);
  protected
    { IExpect<T> }
    function CreateRole(const callerInfo: IMockSession): IMockRole;
  public
    class function CreateAsWrapper(const factory: TFunc<IMockSession, IMockRole>): TMockExpectWrapper;
  end;

  TWhen<T> = class(TInterfacedObject, IWhen<T>, IWhenOrExpect<T>)
  private
    FBuilder: IMockRoleBuilder<T>;
  protected
    { IWhen<T> }
    function GetSubject: T;
  protected
    { IWhenOrExpect<T> }
    function Expect(const expect: TMockExpectWrapper): IWhen<T>;
  public
    constructor Create(const builder: IMockRoleBuilder<T>);
  end;

  TMockSetup<T> = class(TInterfacedObject, IMockSetup<T>)
  private
    FBuilder: IMockRoleBuilder<T>;
    FIsStub: boolean;
  private
    function WillExecuteInternal(const fn: TFunc<TRttiMethod, TArray<TValue>, TValue>): IWhenOrExpect<T>;
  protected
    { IMockSetup<T> }
    function WillReturn(value: TValue): IWhenOrExpect<T>; overload;
    function WillReturn(intf: IInterface): IWhenOrExpect<T>; overload;
    function WillExecute(const proc: TProc<TArray<TValue>>): IWhenOrExpect<T>; overload;
    function WillExecute(const fn: TFunc<TArray<TValue>, TValue>): IWhenOrExpect<T>; overload;
    function WillRaise(const provider: TFunc<Exception>): IWhen<T>; overload;
  public
    constructor Create(const builder: IMockRoleBuilder<T>; const isStub: boolean);
  end;

  TRoleInvokerBuilder<T> = class(TInterfacedObject, IMockRoleBuilder<T>)
  private
    FRoles: TStack<IMockRole>;
    FRecordProxy: IProxy<T>;
    FActionStorage: IMockSessionRecorder;
  private
    procedure NotifyMethodCalled(Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
      out Result: TValue);
  protected
    { IRoleInvokerBuilder }
    procedure PushRole(const role: IMockRole);
    function GetRoles: TArray<IMockRole>;
    function GetSession: IMockSession;
    function Build(const method: TRttiMethod; const args: TArray<TValue>): TMockAction;
  protected
    { IProxy<T> }
    function GetSubject: T;
    function TryGetSubject(const info: PTypeInfo; out outResult): boolean;
  public
    constructor Create(const recordProxy: IProxy<T>; const storage: IMockSessionRecorder);
    destructor Destroy; override;
  end;

  TMockSessionRecorder = class(TInterfacedObject, IMockSessionRecorder)
  private
    FActions: TList<TMockAction>;
    FCallstacks: TList<TRttiMEthod>;
  protected
    { IMockSession }
    function GetActions: TArray<TMockAction>;
    function TryFindAction(const method: TRttiMethod; const args: TArray<TValue>; out outResult: TMockAction): boolean;
    function GetCallstacks: TList<TRttiMEthod>;
  protected
    { IMockSessionRecorder }
    procedure RecordAction(const invoker: TMockAction);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TObjectRecordProxy<T> = class(TInterfacedObject, IProxy<T>)
  private
    FVmi: TVirtualMethodInterceptor;
    FInstance: TValue;
    FOnCallback: TInterceptBeforeNotify;
  private
    constructor Create(const instance: TValue; const classType: TClass); overload;
  private
    function CreateInstance(const t: TRttiType): TValue;
    procedure NotifyMethodCalled(Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
      out Result: TValue);
    function IsDestructProcess(methodName: string;
      const names: array of string): boolean;
  protected
    { IReadOnlyProxy<T> }
    function GetSubject: T;
    function TryGetSubject(const info: PTypeInfo; out outResult): boolean;
  protected
    { IRecordProxy<T> }
    procedure BeginProxify(const callback: TInterceptBeforeNotify);
    procedure EndProxify;
    function IsProxifying: boolean;
    function QueryProxy(const iid: TGuid; out outResult): HResult;
  public
    constructor Create; overload;
    constructor Create(const instance: TObject); overload;
    destructor Destroy; override;
  end;

  TInterfaceRecordProxy<T: IInterface> = class(TVirtualInterface, IProxy<T>, IRecordable, IInterfaceedSubject, IInterface)
  private var
    FIID: TGUID;
    FChildProxies: TDictionary<TGUID, IInterface>;
    FOnCallback: TInterceptBeforeNotify;
  private
    function ResolveTypes(const intf: array of TGUID): TArray<TRttiInterfaceType>;
    function QueryImplementedInterface(const IID: TGUID; out Obj): HResult;
    function GetSubjectAsInterface: IInterface;
  protected
    { IRecordable }
    procedure BeginProxify(const callback: TInterceptBeforeNotify);
    procedure EndProxify;
    function IsProxifying: boolean;
    function QueryProxy(const iid: TGuid; out outResult): HResult;
  protected
    { IReadOnlyProxy<T> }
    function GetSubject: T;
    function TryGetSubject(const info: PTypeInfo; out outResult): boolean;
  protected
    { IInterfaceedSubject }
    function IInterfaceedSubject.GetSubject = GetSubjectAsInterface;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
  public
    constructor Create(const iid: TGUID; const info: PTypeInfo; const intf: array of TGUID);
    destructor Destroy; override;
  end;

  TTypeBridgeProxy<TFrom; TTo: IInterface> = class(TInterfacedObject, IProxy<TTo>, IInterface)
  private
    FProxy: IProxy<TFrom>;
  protected
    { IRecordable }
    procedure BeginProxify(const callback: TInterceptBeforeNotify);
    procedure EndProxify;
    function IsProxifying: boolean;
    function QueryProxy(const iid: TGuid; out outResult): HResult;
  protected
    { IReadOnlyProxy<T> }
    function GetSubject: TTo;
    function TryGetSubject(const info: PTypeInfo; out outResult): boolean;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    constructor Create(const proxy: IProxy<TFrom>);
  end;

  TVirtualProxy<T> = class(TInterfacedObject, IReadOnlyProxy<T>)
  private var
    FProxy: IReadOnlyProxy<T>;
    FSession: IMockSession;
  private

  protected
    { IProxy<T> }
    property Proxy: IReadOnlyProxy<T> read FProxy implements IReadOnlyProxy<T>;
  public
    constructor Create(const proxy: IProxy<T>; const session: IMockSession);
  end;

function HasRtti(info: PTypeInfo): boolean;

implementation

uses
  System.Math,
  System.SyncObjs, MockTools.FormatHelper
;

{ TExpectRole }

function TCountExpectRole.OnErrorReport(
  const provider: TFunc<TMockAction, integer, TVerifyResult.TOption, string>): TCountExpectRole;
begin
  System.Assert(Assigned(provider));
  FReportProvider := provider;

  Result := Self;
end;

function TCountExpectRole.OnVerify(
  const verifire: TPredicate<integer>): TCountExpectRole;
begin
  System.Assert(Assigned(verifire));
  FVerifire := verifire;

  Result := Self;
end;

procedure TCountExpectRole.DoInvoke(const method: TRttiMEthod; const args: TArray<TValue>; var outResult: TValue);
begin
  TInterlocked.Increment(FCount);
end;

function TCountExpectRole.Verify(invoker: TMockAction): TVerifyResult;
var
  status: TVerifyResult.TStatus;
begin
  if FVerifire(FCount) then begin
    status := TVerifyResult.TStatus.Passed;
  end
  else begin
    status := TVerifyResult.TStatus.Failed;
  end;

  Result := TVerifyResult.Create(
    function (opt: TVerifyResult.TOption): string
    begin
      Result := FReportProvider(invoker, FCount, opt);
    end,
    status,
    TVerifyResult.TOption.None
  );
end;

{ TAbstractSetupRole<T> }

constructor TAbstractSetupRole<T>.Create(const provider: TFunc<TRttiMEthod, TArray<TValue>, T>; const isStub: boolean);
begin
  System.Assert(Assigned(provider));

  FProvider := provider;
  FStub := isStub;
end;

procedure TAbstractSetupRole<T>.DoInvoke(const method: TRttiMEthod; const args: TArray<TValue>; var outResult: TValue);
begin
  FInvoked := true;

  DoInvokeInternal(FProvider(method, args), outResult);
end;

function TAbstractSetupRole<T>.FailedReportText(action: TMockAction): TFunc<TVerifyResult.TOption, string>;
begin
  Result :=
    function (opt: TVerifyResult.TOption): string
    begin
      Result := Format('%s is not called', [FormatMethodName(TypeInfo(T), action.Method)]);
    end
  ;
end;

function TAbstractSetupRole<T>.Verify(invoker: TMockAction): TVerifyResult;
var
  status: TVerifyResult.TStatus;
begin
  if FInvoked or FStub then begin
    status := TVerifyResult.TStatus.Passed;
  end
  else begin
    status := TVerifyResult.TStatus.Failed;
  end;

  Result := TVerifyResult.Create(
    Self.FailedReportText(invoker), status, TVerifyResult.TOption.None
  );
end;

{ TMethodSetupRole }

procedure TMethodSetupRole.DoInvokeInternal(const willReturn: TValue;
  var outResult: TValue);
begin
  outResult := willReturn;
end;

{ TExceptionSetupRole }

procedure TExceptionSetupRole.DoInvokeInternal(const willReturn: Exception;
  var outResult: TValue);
begin
  raise willReturn;
end;

{ TExpect<T> }

constructor TExpectRoleFactory.Create(const factory: TFunc<IMockSession, IMockRole>);
begin
  Assert(Assigned(factory));

  FFactory := factory;
end;

class function TExpectRoleFactory.CreateAsWrapper(
  const factory: TFunc<IMockSession, IMockRole>): TMockExpectWrapper;
begin
  Result := TMockExpectWrapper.Create(TExpectRoleFactory.Create(factory));
end;

function TExpectRoleFactory.CreateRole(
  const callerInfo: IMockSession): IMockRole;
begin
  Result := FFactory(callerInfo);
end;

{ TWhen<T> }

constructor TWhen<T>.Create(const builder: IMockRoleBuilder<T>);
begin
  FBuilder := builder;
end;

function TWhen<T>.Expect(const expect: TMockExpectWrapper): IWhen<T>;
begin
  FBuilder.PushRole(expect.CreateRole(FBuilder.Session));

  Result := TWhen<T>.Create(FBuilder);
end;

function TWhen<T>.GetSubject: T;
begin
  Result := FBuilder.Subject;
end;

{ TRoleInvokerBuilder<T> }

constructor TRoleInvokerBuilder<T>.Create(const recordProxy: IProxy<T>;
  const storage: IMockSessionRecorder);
begin
  System.Assert(Assigned(recordProxy));
  System.Assert(Assigned(storage));

  FRoles := TStack<IMockRole>.Create;
  FRecordProxy := recordProxy;
  FActionStorage := storage;

  FRecordProxy.BeginProxify(Self.NotifyMethodCalled);
end;

destructor TRoleInvokerBuilder<T>.Destroy;
begin
  FRoles.Free;
  inherited;
end;

function TRoleInvokerBuilder<T>.Build(const method: TRttiMethod; const args: TArray<TValue>): TMockAction;
begin
  Result := TMockAction.Create(method, args, Self.GetRoles);
end;

function TRoleInvokerBuilder<T>.GetSession: IMockSession;
begin
  Result := FActionStorage;
end;

function TRoleInvokerBuilder<T>.GetRoles: TArray<IMockRole>;
begin
  Result := FRoles.ToArray;
end;

function TRoleInvokerBuilder<T>.GetSubject: T;
begin
  Result := FRecordProxy.Subject;
end;

procedure TRoleInvokerBuilder<T>.PushRole(const role: IMockRole);
begin
  FRoles.Push(role);
end;

function TRoleInvokerBuilder<T>.TryGetSubject(const info: PTypeInfo; out outResult): boolean;
begin
  Result := FRecordProxy.TryGetSubject(info, outResult);
end;

procedure TRoleInvokerBuilder<T>.NotifyMethodCalled(Instance: TObject;
  Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
  out Result: TValue);
begin
  FActionStorage.RecordAction(Self.Build(Method, Args));

  FRecordProxy.EndProxify;
end;

{ TMockSessionRecorder }

constructor TMockSessionRecorder.Create;
begin
  FActions := TList<TMockAction>.Create;
  FCallstacks := TList<TRttiMethod>.Create;
end;

destructor TMockSessionRecorder.Destroy;
begin
  FActions.Free;
  FCallstacks.Free;
  inherited;
end;

function TMockSessionRecorder.GetActions: TArray<TMockAction>;
begin
  Result := FActions.ToArray;
end;

function TMockSessionRecorder.GetCallstacks: TList<TRttiMEthod>;
begin
  Result := FCallstacks;
end;

procedure TMockSessionRecorder.RecordAction(const invoker: TMockAction);
begin
  FActions.Add(invoker);
end;

type
  TArgComparer = record
  private
    class function IsNumeric(value: TValue): boolean; static;
  public
    class function IsSameArgValue(const ctx: TRttiContext; value1, value2: TValue): boolean; static;
    class function IsSameNumeric(const ctx: TRttiContext; value1, value2: TValue): boolean; static;
    class function IsSameObject(const ctx: TRttiContext; value1, value2: TValue): boolean; static;
    class function IsSameInterface(const ctx: TRttiContext; value1, value2: TValue): boolean; static;
    class function IsSameRecord(const ctx: TRttiContext; value1, value2: TValue): boolean; static;
    class function IsSameArray(const ctx: TRttiContext; value1, value2: TValue): boolean; static;
  end;

class function TArgComparer.IsSameObject(const ctx: TRttiContext; value1, value2: TValue): boolean;
begin
  if not (value1.IsEmpty xor value2.IsEmpty) then begin
    Exit(false);
  end
  else if value1.IsEmpty and value2.IsEmpty then begin
    Exit(true);
  end
  else begin
    Result := value1.AsObject.Equals(value2.AsObject);
  end;
end;

class function TArgComparer.IsSameInterface(const ctx: TRttiContext; value1, value2: TValue): boolean;
var
  t: TRttiType;
  prop: TRttiProperty;
  same: boolean;
begin
  if not (value1.IsEmpty xor value2.IsEmpty) then begin
    Exit(false);
  end
  else if value1.IsEmpty and value2.IsEmpty then begin
    Exit(true);
  end
  else begin
    t := ctx.GetType(value1.TypeInfo);
    for prop in t.GetProperties do begin
      same := IsSameArgValue(
        ctx,
        prop.GetValue(value1.GetReferenceToRawData),
        prop.GetValue(value2.GetReferenceToRawData)
      );

      if not same then begin
        Exit(false);
      end;
    end;

    Exit(true);
  end;
end;

class function TArgComparer.IsSameRecord(const ctx: TRttiContext; value1, value2: TValue): boolean;
var
  t: TRttiType;
  f: TRttiField;
  same: boolean;
begin
  t := ctx.GetType(value1.TypeInfo);
  for f in t.GetFields do begin
    same := IsSameArgValue(
      ctx,
      f.GetValue(value1.GetReferenceToRawData),
      f.GetValue(value2.GetReferenceToRawData)
    );
    if not same then Exit(false);
  end;

  Exit(true);
end;

class function TArgComparer.IsSameArray(const ctx: TRttiContext; value1, value2: TValue): boolean;
var
  i: integer;
  same: boolean;
begin
  if value1.GetArrayLength <> value2.GetArrayLength then Exit(false);

  for i := 0 to value1.GetArrayLength-1 do begin
    same := IsSameArgValue(
      ctx,
      value1.GetArrayElement(i),
      value2.GetArrayElement(i)
    );
    if not same then Exit(false);
  end;

  Exit(true);
end;

class function TArgComparer.IsNumeric(value: TValue): boolean;
begin
  Result := value.TypeInfo.Kind in [
    tkInteger, tkChar, tkEnumeration, tkFloat, tkSet, tkWChar, tkInt64
  ];
end;

class function TArgComparer.IsSameNumeric(const ctx: TRttiContext; value1, value2: TValue): boolean;

  function AsNumber(value: TValue): extended;
  begin
    if value.IsOrdinal then begin
      Result := value.AsOrdinal;
    end
    else if value.TypeInfo.Kind = TTypeKind.tkFloat then begin
      Result := value.AsType<Extended>;
    end;
  end;

begin
  Result := System.Math.SameValue(AsNumber(value1), AsNumber(value2));
end;

class function TArgComparer.IsSameArgValue(const ctx: TRttiContext; value1, value2: TValue): boolean;
begin
  if value1.TypeInfo = value2.TypeInfo then begin
    case value1.Kind of
      TTypeKind.tkRecord: begin
        Exit(TArgComparer.IsSameRecord(ctx, value1, value2));
      end;
      TTypeKind.tkArray, TTypeKind.tkDynArray: begin
        Exit(TArgComparer.IsSameArray(ctx, value1, value2));
      end;
      TTypeKind.tkClass: begin
        Exit(TArgComparer.IsSameObject(ctx, value1, value2));
      end;
      TTypeKind.tkInterface: begin
        Exit(TArgComparer.IsSameInterface(ctx, value1, value2));
      end;
    end;
  end;

  if IsNumeric(value1) and IsNumeric(value2) then begin
    Exit(TArgComparer.IsSameNumeric(ctx, value1, value2));
  end;

  Result := TEqualityComparer<string>.Default.Equals(value1.ToString, value2.ToString);
end;

function IsSameArgs(const ctx: TRttiContext; const lhs, rhs: TArray<TValue>; const isStaticMethod: boolean): boolean;
var
  i, fromIndex: integer;
begin
  if Length(lhs) <> Length(rhs) then Exit(false);

  fromIndex := Low(lhs);
  if not isStaticMethod then Inc(fromIndex);

  for i := fromIndex to High(lhs) do begin
    if not TArgComparer.IsSameArgValue(ctx, lhs[i], rhs[i]) then Exit(false);
  end;
  Result := true;
end;

function TMockSessionRecorder.TryFindAction(const method: TRttiMethod;
  const args: TArray<TValue>; out outResult: TMockAction): boolean;
var
  action: TMockAction;
  ctx: TRttiContext;
begin
  ctx := TRttiContext.Create;
  try
    for action in Self.GetActions do begin
      if action.Method <> Method then Continue;
      if not IsSameArgs(ctx, args, action.Args, true) then Continue;

      outResult := action;
      Exit(true);
    end;
  finally
    ctx.Free;
  end;

  Result := false;
end;

{ TObjectRecordProxy<T> }

procedure TObjectRecordProxy<T>.BeginProxify(
  const callback: TInterceptBeforeNotify);
begin
  FOnCallback := callback;
end;

procedure TObjectRecordProxy<T>.EndProxify;
begin
  FOnCallback := nil;
end;

constructor TObjectRecordProxy<T>.Create;
var
  ctx: TRttiContext;
  tt: TRttiType;
begin
  ctx := TRttiContext.Create;
  try
    tt := ctx.GetType(System.TypeInfo(T));

    Create(Self.CreateInstance(tt), tt.AsInstance.MetaclassType);
  finally
    ctx.Free;
  end;
end;

constructor TObjectRecordProxy<T>.Create(const instance: TObject);
begin
  Create(instance, instance.ClassType);
end;

constructor TObjectRecordProxy<T>.Create(const instance: TValue;
  const classType: TClass);
begin
  FInstance := instance;

  FVmi := TVirtualMethodInterceptor.Create(classType);
  FVmi.Proxify(FInstance.AsObject);
  FVmi.OnBefore := Self.NotifyMethodCalled;
end;

destructor TObjectRecordProxy<T>.Destroy;
begin
  FVmi.Unproxify(FInstance.AsObject);

  FVmi.Free;
  FInstance.AsObject.Free;
  inherited;
end;

function TObjectRecordProxy<T>.GetSubject: T;
begin
  Result := FInstance.AsType<T>;
end;

function TObjectRecordProxy<T>.IsProxifying: boolean;
begin
  Result := Assigned(FOnCallback);
end;

function TObjectRecordProxy<T>.IsDestructProcess(methodName: string; const names: array of string): boolean;
var
  n: string;
begin
  for n in names do begin
    if methodName = n then Exit(true);
  end;

  Exit(false);
end;

procedure TObjectRecordProxy<T>.NotifyMethodCalled(Instance: TObject;
  Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
  out Result: TValue);
begin
  DoInvoke := false;

  if IsDestructProcess(Method.Name, ['BeforeDestruction', 'FreeInstance']) then Exit;

  System.Assert(Assigned(FOnCallback));

  FOnCallback(Instance, Method, Args, DoInvoke, Result);
end;

function TObjectRecordProxy<T>.QueryProxy(const iid: TGuid;
  out outResult): HResult;
begin
  Result := E_NOINTERFACE;
end;

function TObjectRecordProxy<T>.TryGetSubject(const info: PTypeInfo;
  out outResult): boolean;
begin
  Assert(false, 'Not supported');
end;

function TObjectRecordProxy<T>.CreateInstance(const t: TRttiType): TValue;
var
  m: TRttiMethod;
begin
  System.Assert(Assigned(t));

  for m in t.GetMethods do begin
    if m.IsConstructor and (Length(m.GetParameters) = 0) then begin
      Exit(m.Invoke(t.AsInstance.MetaclassType, []));
    end;
  end;

  System.Assert(false);
end;

{ TMockSetup<T> }

constructor TMockSetup<T>.Create(const builder: IMockRoleBuilder<T>; const isStub: boolean);
begin
  FBuilder := builder;
  FIsStub := isStub;
end;

function TMockSetup<T>.WillReturn(value: TValue): IWhenOrExpect<T>;
begin
  Result := Self.WillExecuteInternal(
    function (method: TRttiMethod; args: TArray<TValue>) : TValue
    begin
      Result := value;
    end
  );
end;

function TMockSetup<T>.WillReturn(intf: IInterface): IWhenOrExpect<T>;
begin
  Result := Self.WillExecuteInternal(
    function (method: TRttiMethod; args: TArray<TValue>) : TValue
    begin
      if Supports(intf, IInterfaceedSubject) then begin
        TValue.Make(@intf, method.ReturnType.Handle, Result);
      end
      else begin
        Result := TValue.From<TObject>(TObject(intf));
      end;
    end
  );
end;

function TMockSetup<T>.WillExecuteInternal(
  const fn: TFunc<TRttiMethod, TArray<TValue>, TValue>): IWhenOrExpect<T>;
begin
  FBuilder.PushRole(TMethodSetupRole.Create(fn, FIsStub));

  Result := TWhen<T>.Create(FBuilder);
end;

function TMockSetup<T>.WillExecute(const fn: TFunc<TArray<TValue>, TValue>): IWhenOrExpect<T>;
begin
  Result := Self.WillExecuteInternal(
    function (method: TRttiMethod; args: TArray<TValue>): TValue
    begin
      Result := fn(args);
    end
  );
end;

function TMockSetup<T>.WillExecute(const proc: TProc<TArray<TValue>>): IWhenOrExpect<T>;
begin
  Result := Self.WillExecuteInternal(
    function (method: TRttiMethod; args: TArray<TValue>): TValue
    begin
      proc(args);

      Result := TValue.Empty;
    end
  );
end;

function TMockSetup<T>.WillRaise(
  const provider: TFunc<Exception>): IWhen<T>;
begin
  FBuilder.PushRole(TExceptionSetupRole.Create(
    function (method: TRttiMethod; args: TArray<TValue>): Exception
    begin
      Result := provider();
    end,
    FIsStub
  ));

  Result := TWhen<T>.Create(FBuilder);
end;

{ TMethodCallExpectRole }

constructor TMethodCallExpectRole.Create(const onInvoke,
  beforeVerify: TProc<TList<integer>>);
begin
  FIndicies := TList<integer>.Create;

  FOnInvoke := onInvoke;
  FBeforeVerify := beforeVerify;
end;

destructor TMethodCallExpectRole.Destroy;
begin
  FIndicies.Free;
  inherited;
end;

function TMethodCallExpectRole.OnErrorReport(
  const fn: TFunc<TMockAction, TVerifyResult.TOption, string>): TMethodCallExpectRole;
begin
  FReportProvider := fn;
  Result := Self;
end;

function TMethodCallExpectRole.OnVerify(
  const fn: TVerifyProc): TMethodCallExpectRole;
begin
  FOnVerify := fn;
  Result := Self;
end;

procedure TMethodCallExpectRole.DoInvoke(const method: TRttiMethod; const args: TArray<TValue>;
  var outResult: TValue);
begin
  Assert(Assigned(FOnInvoke));

  FOnInvoke(FIndicies);
end;

function TMethodCallExpectRole.Verify(invoker: TMockAction): TVerifyResult;
var
  provider: TFunc<TVerifyResult.TOption, string>;
  indicies: TList<integer>;
  i: integer;
  status: TStatus;
begin
  Assert(Assigned(FBeforeVerify));
  Assert(Assigned(FOnVerify));
  Assert(Assigned(FReportProvider));

  provider :=
    function (opt: TVerifyResult.TOption): string
    begin
      Result := FReportProvider(invoker, opt);
    end
  ;

  if FIndicies.Count = 0 then begin
    Exit(TVerifyResult.Create(provider, TVerifyResult.TStatus.Failed, TVerifyResult.TOption.None));
  end;

  indicies := TList<integer>.Create(FIndicies);

  FBeforeVerify(indicies);

  status := TStatus.NoCall;
  for i := 0 to indicies.Count-2 do begin
    status := FOnVerify(indicies[i], indicies[i+1]-1, status);

    if status = TStatus.Failed then begin
      Exit(TVerifyResult.Create(provider, TVerifyResult.TStatus.Failed, TVerifyResult.TOption.None));
    end;
  end;

  if status = TStatus.NoCall then begin
    Result := TVerifyResult.Create(provider, TVerifyResult.TStatus.Failed, TVerifyResult.TOption.None);
  end
  else begin
    Result := TVerifyResult.Create(provider, TVerifyResult.TStatus.Passed, TVerifyResult.TOption.None);
  end;
end;

function HasRttiRecursive(t: TRttiType): boolean;
begin
  if (not Assigned(t)) or (t.Handle = TypeInfo(IInterface)) then Exit(true);

  Result := (Length(t.GetMethods) > 0) and HasRttiRecursive(t.BaseType);
end;

function HasRtti(info: PTypeInfo): boolean;
var
  ctx: TRttiContext;
  t: TRttiType;
begin
  Assert(Assigned(info));

  ctx := TRttiContext.Create;
  try
    t := ctx.GetType(info);
    Assert(Assigned(t), 'Interface not found.');

    Result := HasRttiRecursive(t);
  finally
    ctx.Free;
  end;
end;

{ TInterfaceRecordProxy<T> }

constructor TInterfaceRecordProxy<T>.Create(const iid: TGUID; const info: PTypeInfo; const intf: array of TGUID);
var
  t: TRttiInterfaceType;
begin
  Assert(Assigned(info));
  Assert(HasRtti(info), Format('"%s" or parent interface does not have RTTI. Please use "{$M+}"', [info^.Name]));

  FIID := iid;
  FChildProxies := TDictionary<TGUID, IInterface>.Create;

  for t in Self.ResolveTypes(intf) do begin
    FChildProxies.Add(t.GUID, TInterfaceRecordProxy<IInterface>.Create(t.GUID, t.Handle, []));
  end;

  inherited Create(info,
    procedure (Method: TRttiMethod;
      const Args: TArray<TValue>; out Result: TValue)
    var
      doInvoke: boolean;
      shiftedArgs: TArray<TValue>;
    begin
      Assert(Assigned(FOnCallback));

      doInvoke := false;
      shiftedArgs := Copy(Args, Low(Args)+1, Integer.MaxValue);
      FOnCallback(Self, Method, shiftedArgs, doInvoke, Result);
    end
  );
end;

destructor TInterfaceRecordProxy<T>.Destroy;
begin
  FChildProxies.Free;
  inherited;
end;

procedure TInterfaceRecordProxy<T>.BeginProxify(
  const callback: TInterceptBeforeNotify);
var
  child: IInterface;
  recorder: IRecordable;
begin
  FOnCallback := callback;

  for child in FChildProxies.Values do begin
    if Supports(child, IRecordable, recorder) then begin
      recorder.BeginProxify(callback);
    end;
  end;
end;

procedure TInterfaceRecordProxy<T>.EndProxify;
var
  child: IInterface;
  recorder: IRecordable;
begin
  FOnCallback := nil;

  for child in FChildProxies.Values do begin
    if Supports(child, IRecordable, recorder) then begin
      recorder.EndProxify;
    end;
  end;
end;

function TInterfaceRecordProxy<T>.ResolveTypes(const intf: array of TGUID): TArray<TRttiInterfaceType>;
var
  ctx: TRttiContext;
  list: TList<TRttiInterfaceType>;
  t: TRttiType;
  tt: TRttiInterfaceType;
  i: integer;
begin
  ctx := TRttiContext.Create;
  list := TList<TRttiInterfaceType>.Create;
  try
    for t in ctx.GetTypes do begin
      if t is TRttiInterfaceType then begin
        tt := TRttiInterfaceType(t);

        for i := Low(intf) to High(intf) do begin
          if tt.GUID = intf[i] then begin
            list.Add(tt);
          end;
        end;
      end;
    end;

    Result := list.ToArray;
  finally
    list.Free;
    ctx.Free;
  end;
end;

function TInterfaceRecordProxy<T>.TryGetSubject(const info: PTypeInfo;
  out outResult): boolean;
var
  ctx: TRttiContext;
  t: TRttiType;
begin
  ctx := TRttiContext.Create;
  try
    t := ctx.GetType(info);

    Assert(t is TRttiInterfaceType);

    Result := Self.QueryInterface(TRttiInterfaceType(t).GUID, outResult) = S_OK;
  finally
    ctx.Free;
  end;
end;

function TInterfaceRecordProxy<T>.GetSubject: T;
begin
  Self.QueryInterface(FIID, Result);
end;

function TInterfaceRecordProxy<T>.GetSubjectAsInterface: IInterface;
begin
  Self.QueryInterface(FIID, Result);
end;

function TInterfaceRecordProxy<T>.IsProxifying: boolean;
begin
  Result := Assigned(FOnCallback);
end;

function TInterfaceRecordProxy<T>.QueryImplementedInterface(const IID: TGUID; out Obj): HResult;
var
  proxy: IInterface;
begin
  if not FChildProxies.TryGetValue(IID, proxy) then Exit(E_NOTIMPL);

  Result := proxy.QueryInterface(IID, Obj);
end;

function TInterfaceRecordProxy<T>.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  Result := inherited QueryInterface(IID, Obj);

  if Result <> 0 then begin
    Result := Self.QueryImplementedInterface(IID, Obj);
  end;
end;

function TInterfaceRecordProxy<T>.QueryProxy(const IID: TGuid;
  out outResult): HRESULT;
var
  proxy: IInterface;
begin
  if IID = FIID then begin
    IInterface(outResult) := Self;
    Result := S_OK;
  end
  else if FChildProxies.TryGetValue(IID, proxy) then begin
    IInterface(outResult) := proxy;
    Result := S_OK;
  end
  else begin
    Result := E_NOTIMPL;
  end;
end;

{ TVirtualProxy<T> }

constructor TVirtualProxy<T>.Create(const proxy: IProxy<T>;
  const session: IMockSession);
begin
  proxy.BeginProxify(
    procedure (Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean; out Result: TValue)
    var
      action: TMockAction;
      role: IMockRole;
    begin
      FSession.Callstacks.Add(Method);

      if not FSession.TryFindAction(Method, Args, action) then begin
        DoInvoke := Method.DispatchKind <> TDispatchKind.dkInterface;

        Assert(DoInvoke, Format('Method (%s) is not arranged.', [FormatMethodName(TypeInfo(T), Method)]));
      end
      else begin
        for role in action.Roles do begin
          role.DoInvoke(Method, Args, Result);
        end;
      end;
    end
  );

  FProxy := proxy;
  FSession := session;
end;

{ TTypeBridgeProxy<TFrom, TTo> }

constructor TTypeBridgeProxy<TFrom, TTo>.Create(const proxy: IProxy<TFrom>);
begin
  FProxy := proxy;
end;

procedure TTypeBridgeProxy<TFrom, TTo>.BeginProxify(
  const callback: TInterceptBeforeNotify);
begin
  FProxy.BeginProxify(callback);
end;

procedure TTypeBridgeProxy<TFrom, TTo>.EndProxify;
begin
  FProxy.EndProxify;
end;

function TTypeBridgeProxy<TFrom, TTo>.GetSubject: TTo;
begin
  Assert(Self.TryGetSubject(TypeInfo(TTo), Result));
end;

function TTypeBridgeProxy<TFrom, TTo>.IsProxifying: boolean;
begin
  Result := FProxy.IsProxifying;
end;

function TTypeBridgeProxy<TFrom, TTo>.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  Result := FProxy.QueryInterface(IID, Obj);
end;

function TTypeBridgeProxy<TFrom, TTo>.QueryProxy(const IID: TGuid;
  out outResult): HResult;
begin
  Result := FProxy.QueryProxy(IID, outResult);
end;

function TTypeBridgeProxy<TFrom, TTo>.TryGetSubject(const info: PTypeInfo;
  out outResult): boolean;
begin
  Result := FProxy.TryGetSubject(info, outResult);
end;

end.
