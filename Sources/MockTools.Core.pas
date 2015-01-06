unit MockTools.Core;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections,
  MockTools.Mocks, MockTools.Core.Types
;


type
  TCountExpectRole = class(TInterfacedObject, IMockRole)
  private
    FCount: integer;
    FVerifire: TPredicate<integer>;
    FReportProvider: TFunc<TMockInvoker, integer, string>;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; var outResult: TValue);
    function Verify(invoker: TMockInvoker): TVerifyResult;
  public
    function OnVerify(const verifire: TPredicate<integer>): TCountExpectRole;
    function OnErrorReport(const provider: TFunc<TMockInvoker, integer, string>): TCountExpectRole;
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
    FReportProvider: TFunc<TMockInvoker, string>;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; var outResult: TValue);
    function Verify(invoker: TMockInvoker): TVerifyResult;
  public
    constructor Create(const onInvoke: TProc<TList<integer>>; const beforeVerify: TProc<TList<integer>>);
    destructor Destroy; override;
    function OnVerify(const fn: TVerifyProc): TMethodCallExpectRole;
    function OnErrorReport(const fn: TFunc<TMockInvoker, string>): TMethodCallExpectRole;
  end;

  TAbstractSetupRole<T> = class abstract(TInterfacedObject, IMockRole)
  private
    FInvoked: boolean;
    FProvider: TFunc<TRttiMethod, T>;
  protected
    procedure DoInvokeInternal(const willReturn: T; var outResult: TValue); virtual; abstract;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; var outResult: TValue);
    function Verify(invoker: TMockInvoker): TVerifyResult;
  public
    constructor Create(const provider: TFunc<TRttiMethod, T>);
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
    FFactory: TFunc<ICallerInfo, IMockRole>;
  protected
    { IExpect<T> }
    function CreateRole(const callerInfo: ICallerInfo): IMockRole;
  public
    constructor Create(const factory: TFunc<ICallerInfo, IMockRole>);
  end;

  TWhen<T> = class(TInterfacedObject, IWhen<T>, IWhenOrExpect<T>)
  private
    FBuilder: IRoleInvokerBuilder<T>;
  protected
    { IWhen<T> }
    function GetSubject: T;
  protected
    { IWhenOrExpect<T> }
    function Expect(const expect: IMockExpect): IWhen<T>;
  public
    constructor Create(const builder: IRoleInvokerBuilder<T>);
  end;

  TMockSetup<T> = class(TInterfacedObject, IMockSetup<T>)
  private
    FBuilder: IRoleInvokerBuilder<T>;
  protected
    { IMockSetup<T> }
    function WillReturn(value: TValue): IWhenOrExpect<T>; overload;
    function WillExecute(const proc: TProc): IWhenOrExpect<T>; overload;
    function WillExecute(const fn: TFunc<TValue>): IWhenOrExpect<T>; overload;
    function WillRaise(const provider: TFunc<Exception>): IWhen<T>; overload;
  public
    constructor Create(const builder: IRoleInvokerBuilder<T>);
  end;

  TRoleInvokerBuilder<T> = class(TInterfacedObject, IRoleInvokerBuilder<T>)
  private
    FRoles: TStack<IMockRole>;
    FRecordProxy: IRecordProxy<T>;
    FActionStorage: IActionStorage;
  private
    procedure NotifyMethodCalled(Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
      out Result: TValue);
  protected
    { IRoleInvokerBuilder }
    procedure PushRole(const role: IMockRole);
    function GetRoles: TArray<IMockRole>;
    function GetCallerInfo: ICallerInfo;
    function Build(const method: TRttiMethod; const args: TArray<TValue>): TMockInvoker;
  protected
    { IProxy<T> }
    function GetSubject: T;
    procedure Extends(const intf: array of TGUID); overload;
    procedure Extends(const intf: TGUID); overload;
  public
    constructor Create(const recordProxy: IRecordProxy<T>; const storage: IActionStorage);
    destructor Destroy; override;
  end;

  TActionStorage = class(TInterfacedObject, IActionStorage)
  private
    FActions: TList<TMockInvoker>;
    FCallstacks: TList<TRttiMEthod>;
  protected
    { IActionStrage }
    procedure RecordInvoker(const invoker: TMockInvoker);
    function GetActions: TArray<TMockInvoker>;
    function GetCallstacks: TList<TRttiMEthod>;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TObjectRecordProxy<T: class> = class(TInterfacedObject, IRecordProxy<T>)
  private
    FVmi: TVirtualMethodInterceptor;
    FInstance: T;
    FOnCallback: TInterceptBeforeNotify;
  private
    function CreateInstance(const t: TRttiType): TValue;
    procedure NotifyMethodCalled(Instance: TObject;
      Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
      out Result: TValue);
    function IsDestructProcess(methodName: string;
      const names: array of string): boolean;
  protected
    { IProxy<T> }
    function GetSubject: T;
    procedure Extends(const intf: array of TGUID); overload;
    procedure Extends(const intf: TGUID); overload;
  protected
    { IRecordProxy<T> }
    procedure BeginRecord(const callback: TInterceptBeforeNotify);
    procedure EndRecord;
    function IsRecording: boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TInterfaceRecordProxy<T> = class(TVirtualInterface, IRecordProxy<T>)
  private
    FOnCallback: TInterceptBeforeNotify;
    FIID: TGUID;
  protected
    { IRecordProxy<T> }
    procedure BeginRecord(const callback: TInterceptBeforeNotify);
    procedure EndRecord;
    function IsRecording: boolean;
  protected
    { IProxy<T> }
    function GetSubject: T;
    procedure Extends(const intf: array of TGUID); overload;
    procedure Extends(const intf: TGUID); overload;
  public
    constructor Create(const iid: TGUID);
  end;

function HasRtti(info: PTypeInfo): boolean;

implementation

uses
  System.SyncObjs
;

{ TExpectRole }

function TCountExpectRole.OnErrorReport(
  const provider: TFunc<TMockInvoker, integer, string>): TCountExpectRole;
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

procedure TCountExpectRole.DoInvoke(const method: TRttiMEthod; var outResult: TValue);
begin
  TInterlocked.Increment(FCount);
end;

function TCountExpectRole.Verify(invoker: TMockInvoker): TVerifyResult;
begin
  if FVerifire(FCount) then begin
    Result := TVerifyResult.Create('');
  end
  else begin
    Result := TVerifyResult.Create(FReportProvider(invoker, FCount));
  end;
end;

{ TAbstractSetupRole<T> }

constructor TAbstractSetupRole<T>.Create(const provider: TFunc<TRttiMEthod, T>);
begin
  System.Assert(Assigned(provider));

  FProvider := provider;
end;

procedure TAbstractSetupRole<T>.DoInvoke(const method: TRttiMEthod; var outResult: TValue);
begin
  FInvoked := true;

  DoInvokeInternal(FProvider(method), outResult);
end;

function TAbstractSetupRole<T>.Verify(invoker: TMockInvoker): TVerifyResult;
begin
  if FInvoked then begin
    Result := TVerifyResult.Create('');
  end
  else begin
    Result := TVerifyResult.Create('Not called');
  end;
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

constructor TExpectRoleFactory.Create(const factory: TFunc<ICallerInfo, IMockRole>);
begin
  Assert(Assigned(factory));

  FFactory := factory;
end;

function TExpectRoleFactory.CreateRole(
  const callerInfo: ICallerInfo): IMockRole;
begin
  Result := FFactory(callerInfo);
end;

{ TWhen<T> }

constructor TWhen<T>.Create(const builder: IRoleInvokerBuilder<T>);
begin
  FBuilder := builder;
end;

function TWhen<T>.Expect(const expect: IMockExpect): IWhen<T>;
begin
  Assert(Assigned(expect));

  FBuilder.PushRole(expect.CreateRole(FBuilder.CallerInfo));

  Result := TWhen<T>.Create(FBuilder);
end;

function TWhen<T>.GetSubject: T;
begin
  Result := FBuilder.Subject;
end;

{ TRoleInvokerBuilder<T> }

constructor TRoleInvokerBuilder<T>.Create(const recordProxy: IRecordProxy<T>;
  const storage: IActionStorage);
begin
  System.Assert(Assigned(recordProxy));
  System.Assert(Assigned(storage));

  FRoles := TStack<IMockRole>.Create;
  FRecordProxy := recordProxy;
  FActionStorage := storage;

  FRecordProxy.BeginRecord(Self.NotifyMethodCalled);
end;

destructor TRoleInvokerBuilder<T>.Destroy;
begin
  FRoles.Free;
  inherited;
end;

procedure TRoleInvokerBuilder<T>.Extends(const intf: array of TGUID);
begin
  FRecordProxy.Extends(intf);
end;

procedure TRoleInvokerBuilder<T>.Extends(const intf: TGUID);
begin
  Self.Extends([intf]);
end;

function TRoleInvokerBuilder<T>.Build(const method: TRttiMethod; const args: TArray<TValue>): TMockInvoker;
begin
  Result := TMockInvoker.Create(method, args, Self.GetRoles);
end;

function TRoleInvokerBuilder<T>.GetCallerInfo: ICallerInfo;
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

procedure TRoleInvokerBuilder<T>.NotifyMethodCalled(Instance: TObject;
  Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
  out Result: TValue);
begin
  FActionStorage.RecordInvoker(Self.Build(Method, Args));
end;

{ TActionStorage }

constructor TActionStorage.Create;
begin
  FActions := TList<TMockInvoker>.Create;
  FCallstacks := TList<TRttiMethod>.Create;
end;

destructor TActionStorage.Destroy;
begin
  FActions.Free;
  FCallstacks.Free;
  inherited;
end;

function TActionStorage.GetActions: TArray<TMockInvoker>;
begin
  Result := FActions.ToArray;
end;

function TActionStorage.GetCallstacks: TList<TRttiMEthod>;
begin
  Result := FCallstacks;
end;

procedure TActionStorage.RecordInvoker(const invoker: TMockInvoker);
begin
  FActions.Add(invoker);
end;

{ TObjectRecordProxy<T> }

procedure TObjectRecordProxy<T>.BeginRecord(
  const callback: TInterceptBeforeNotify);
begin
  FOnCallback := callback;
end;

procedure TObjectRecordProxy<T>.EndRecord;
begin
  FOnCallback := nil;
end;

procedure TObjectRecordProxy<T>.Extends(const intf: array of TGUID);
begin
  Assert(false, 'Not supported procedure');
end;

procedure TObjectRecordProxy<T>.Extends(const intf: TGUID);
begin
  Assert(false, 'Not supported procedure');
end;

constructor TObjectRecordProxy<T>.Create;
var
  ctx: TRttiContext;
  obj: TValue;
begin
  ctx := TRttiContext.Create;
  try
    obj := Self.CreateInstance(ctx.GetType(System.TypeInfo(T)));

    FInstance := obj.AsType<T>;
    FVmi := TVirtualMethodInterceptor.Create(T);
    FVmi.Proxify(obj.AsObject);
    FVmi.OnBefore := Self.NotifyMethodCalled;
  finally
    ctx.Free;
  end;
end;

destructor TObjectRecordProxy<T>.Destroy;
begin
  FVmi.Unproxify(FInstance);

  FVmi.Free;
  FInstance.Free;
  inherited;
end;

function TObjectRecordProxy<T>.GetSubject: T;
begin
  Result := FInstance;
end;

function TObjectRecordProxy<T>.IsRecording: boolean;
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

  try
    FOnCallback(Instance, Method, Args, DoInvoke, Result);
  finally
    Self.EndRecord;
  end;
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

constructor TMockSetup<T>.Create(const builder: IRoleInvokerBuilder<T>);
begin
  FBuilder := builder;
end;

function TMockSetup<T>.WillReturn(value: TValue): IWhenOrExpect<T>;
begin
  Result := Self.WillExecute(
    function : TValue
    begin
      Result := value;
    end
  );
end;

function TMockSetup<T>.WillExecute(const fn: TFunc<TValue>): IWhenOrExpect<T>;
begin
  FBuilder.PushRole(TMethodSetupRole.Create(
    function (method: TRttiMethod): TValue
    begin
      Result := fn();
    end
  ));

  Result := TWhen<T>.Create(FBuilder);
end;

function TMockSetup<T>.WillExecute(const proc: TProc): IWhenOrExpect<T>;
begin
  Result := Self.WillExecute(
    function : TValue
    begin
      proc();

      Result := TValue.Empty;
    end
  );
end;

function TMockSetup<T>.WillRaise(
  const provider: TFunc<Exception>): IWhen<T>;
begin
  FBuilder.PushRole(TExceptionSetupRole.Create(
    function (method: TRttiMethod): Exception
    begin
      Result := provider();
    end
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
  const fn: TFunc<TMockInvoker, string>): TMethodCallExpectRole;
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

procedure TMethodCallExpectRole.DoInvoke(const method: TRttiMethod;
  var outResult: TValue);
begin
  Assert(Assigned(FOnInvoke));

  FOnInvoke(FIndicies);
end;

function TMethodCallExpectRole.Verify(invoker: TMockInvoker): TVerifyResult;
var
  indicies: TList<integer>;
  i: integer;
  status: TStatus;
begin
  Assert(Assigned(FBeforeVerify));
  Assert(Assigned(FOnVerify));
  Assert(Assigned(FReportProvider));

  if FIndicies.Count = 0 then begin
    Exit(TVerifyResult.Create(FReportProvider(invoker)));
  end;

  indicies := TList<integer>.Create(FIndicies);

  FBeforeVerify(indicies);

  status := TStatus.NoCall;
  for i := 0 to indicies.Count-2 do begin
    status := FOnVerify(indicies[i], indicies[i+1]-1, status);

    if status = TStatus.Failed then Exit(TVerifyResult.Create(FReportProvider(invoker)));
  end;

  if status = TStatus.NoCall then begin
    Result := TVerifyResult.Create(FReportProvider(invoker));
  end;
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

    Result := Length(t.GetMethods) > 0;
  finally
    ctx.Free;
  end;
end;

{ TInterfaceRecordProxy<T> }

constructor TInterfaceRecordProxy<T>.Create(const iid: TGUID);
var
  info: PTypeInfo;
begin
  info := TypeInfo(T);
  Assert(HasRtti(info), 'This interface do not have RTTI. Please use "{$M+}"');

  FIID := iid;

  inherited Create(info,
    procedure (Method: TRttiMethod;
      const Args: TArray<TValue>; out Result: TValue)
    var
      doInvoke: boolean;
    begin
      Assert(Assigned(FOnCallback));

      doInvoke := false;
      FOnCallback(Self, Method, Args, doInvoke, Result);
    end
  );
end;

procedure TInterfaceRecordProxy<T>.BeginRecord(
  const callback: TInterceptBeforeNotify);
begin
  FOnCallback := callback;
end;

procedure TInterfaceRecordProxy<T>.EndRecord;
begin
  FOnCallback := nil;
end;

procedure TInterfaceRecordProxy<T>.Extends(const intf: array of TGUID);
begin
  Assert(false, '–¢ŽÀ‘•');
end;

procedure TInterfaceRecordProxy<T>.Extends(const intf: TGUID);
begin
  Self.Extends([intf]);
end;

function TInterfaceRecordProxy<T>.GetSubject: T;
var
  err: HRESULT;
begin
  err := Self.QueryInterface(FIID, Result);
end;

function TInterfaceRecordProxy<T>.IsRecording: boolean;
begin
  Result := Assigned(FOnCallback);
end;

end.
