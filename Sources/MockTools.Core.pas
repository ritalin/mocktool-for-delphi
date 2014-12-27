unit MockTools.Core;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections,
  MockTools.Mocks, MockTools.Core.Types
;


type
  TExpectRole = class(TInterfacedObject, IMockRole)
  private
    FCount: integer;
    FVerifire: TPredicate<integer>;
    FReportProvider: TFunc<integer, string>;
  protected
    { IMockRole }
    procedure DoInvoke(var outResult: TValue);
    function Verify: TVerifyResult;
  public
    constructor Create(const verifire: TPredicate<integer>; const provider: TFunc<integer, string>);
  end;

  TAbstractSetupRole<T> = class abstract(TInterfacedObject, IMockRole)
  private
    FInvoked: boolean;
    FProvider: TFunc<T>;
  protected
    procedure DoInvokeInternal(const willReturn: T; var outResult: TValue); virtual; abstract;
  protected
    { IMockRole }
    procedure DoInvoke(var outResult: TValue);
    function Verify: TVerifyResult;
  public
    constructor Create(const provider: TFunc<T>);
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

  TExpect<T> = class(TInterfacedObject, IExpect<T>)
  private
    FBuilder: IRoleInvokerBuilder<T>;
  protected
    { IExpect<T> }
    function Exactly(const times: integer): IWhen<T>;
  public
    constructor Create(const builder: IRoleInvokerBuilder<T>);
  end;

  TWhen<T> = class(TInterfacedObject, IWhen<T>, IWhenOrExpect<T>)
  private
    FBuilder: IRoleInvokerBuilder<T>;
  protected
    { IWhen<T> }
    function GetSubject: T;
  protected
    { IWhenOrExpect<T> }
    function GetExprct: IExpect<T>;
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
    function Build(const method: TRttiMethod; const args: TArray<TValue>): TMockInvoker;
  protected
    { IProxy<T> }
    function GetSubject: T;
  public
    constructor Create(const recordProxy: IRecordProxy<T>; const storage: IActionStorage);
    destructor Destroy; override;
  end;

  TActionStorage = class(TInterfacedObject, IActionStorage)
  private
    FActions: TList<TMockInvoker>;
  protected
    { IActionStrage }
    procedure RecordInvoker(const invoker: TMockInvoker);
    function GetActions: TArray<TMockInvoker>;
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
  protected
    { IRecordProxy<T> }
    procedure BeginRecord(const callback: TInterceptBeforeNotify);
    procedure EndRecord;
    function IsRecording: boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SyncObjs
;

{ TExpectRole }

constructor TExpectRole.Create(const verifire: TPredicate<integer>; const provider: TFunc<integer, string>);
begin
  System.Assert(Assigned(verifire));
  System.Assert(Assigned(provider));

  FVerifire := verifire;
  FReportProvider := provider;
end;

procedure TExpectRole.DoInvoke(var outResult: TValue);
begin
  TInterlocked.Increment(FCount);
end;

function TExpectRole.Verify: TVerifyResult;
begin
  if FVerifire(FCount) then begin
    Result := TVerifyResult.Create('');
  end
  else begin
    Result := TVerifyResult.Create(FReportProvider(FCount));
  end;
end;

{ TAbstractSetupRole<T> }

constructor TAbstractSetupRole<T>.Create(const provider: TFunc<T>);
begin
  System.Assert(Assigned(provider));

  FProvider := provider;
end;

procedure TAbstractSetupRole<T>.DoInvoke(var outResult: TValue);
begin
  FInvoked := true;

  DoInvokeInternal(FProvider(), outResult);
end;

function TAbstractSetupRole<T>.Verify: TVerifyResult;
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

constructor TExpect<T>.Create(const builder: IRoleInvokerBuilder<T>);
begin
  FBuilder := builder;
end;

function TExpect<T>.Exactly(const times: integer): IWhen<T>;
begin
  FBuilder.PushRole(TExpectRole.Create(
    function (count: integer): boolean
    begin
      Result := count = times;
    end,

    function (count: integer): string
    begin
      Result := Format('Not match call count (expect: %d, actual: %d)', [times, count]);
    end
  ));

  Result := TWhen<T>.Create(FBuilder);
end;

{ TWhen<T> }

constructor TWhen<T>.Create(const builder: IRoleInvokerBuilder<T>);
begin
  FBuilder := builder;
end;

function TWhen<T>.GetExprct: IExpect<T>;
begin
  Result := TExpect<T>.Create(FBuilder);
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

function TRoleInvokerBuilder<T>.Build(const method: TRttiMethod; const args: TArray<TValue>): TMockInvoker;
begin
  Result := TMockInvoker.Create(method, args, Self.GetRoles);
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
end;

destructor TActionStorage.Destroy;
begin
  FActions.Free;
  inherited;
end;

function TActionStorage.GetActions: TArray<TMockInvoker>;
begin
  Result := FActions.ToArray;
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
  FBuilder.PushRole(TMethodSetupRole.Create(fn));

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
  FBuilder.PushRole(TExceptionSetupRole.Create(provider));

  Result := TWhen<T>.Create(FBuilder);
end;

end.
