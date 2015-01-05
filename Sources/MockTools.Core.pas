unit MockTools.Core;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections,
  MockTools.Mocks, MockTools.Core.Types
;


type
  TCountExpectRole = class(TInterfacedObject, IMockRole)
  private
    FCount: integer;
    FVerifire: TPredicate<integer>;
    FReportProvider: TFunc<integer, string>;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; var outResult: TValue);
    function Verify: TVerifyResult;
  public
    constructor Create(const verifire: TPredicate<integer>; const provider: TFunc<integer, string>);
  end;

  TMethodCallExpectRole = class(TInterfacedObject, IMockRole)
  private type
    TStatus = (NoCall, Called, Failed);
    TVerifyProc = TFunc<integer, integer, TMethodCallExpectRole.TStatus, TMethodCallExpectRole.TStatus>;
  private
    FIndicies: TList<integer>;
    FOnInvoke: TProc<TList<integer>>;
    FBeforeVerify: TProc<TList<integer>>;
    FOnVerify: TVerifyProc;
    FReportProvider: TFunc<string>;
  protected
    { IMockRole }
    procedure DoInvoke(const method: TRttiMethod; var outResult: TValue);
    function Verify: TVerifyResult;
  public
    constructor Create(const onInvoke: TProc<TList<integer>>; const beforeVerify: TProc<TList<integer>>);
    destructor Destroy; override;
    function OnVerify(const fn: TVerifyProc): TMethodCallExpectRole;
    function OnErrorReport(const fn: TFunc<string>): TMethodCallExpectRole;
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
    function Verify: TVerifyResult;
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

  TExpect<T> = class(TInterfacedObject, IMockExpect<T>)
  private
    FBuilder: IRoleInvokerBuilder<T>;
  protected
    { IExpect<T> }
    function Once : IWhen<T>;
    function Never : IWhen<T>;
    function AtLeastOnce : IWhen<T>;
    function AtLeast(const times : integer) : IWhen<T>;
    function AtMost(const times : integer) : IWhen<T>;
    function Between(const a, b : integer) : IWhen<T>;
    function Exactly(const times: integer): IWhen<T>;
    function Before(const AMethodName : string) : IWhen<T>;
    function BeforeOnce(const AMethodName : string) : IWhen<T>;
    function After(const AMethodName : string) : IWhen<T>;
    function AfterOnce(const AMethodName : string) : IWhen<T>;
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
    function GetExprct: IMockExpect<T>;
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
    function GetCallStacks: TList<TRttiMethod>;
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

constructor TCountExpectRole.Create(const verifire: TPredicate<integer>; const provider: TFunc<integer, string>);
begin
  System.Assert(Assigned(verifire));
  System.Assert(Assigned(provider));

  FVerifire := verifire;
  FReportProvider := provider;
end;

procedure TCountExpectRole.DoInvoke(const method: TRttiMEthod; var outResult: TValue);
begin
  TInterlocked.Increment(FCount);
end;

function TCountExpectRole.Verify: TVerifyResult;
begin
  if FVerifire(FCount) then begin
    Result := TVerifyResult.Create('');
  end
  else begin
    Result := TVerifyResult.Create(FReportProvider(FCount));
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

function TExpect<T>.AtLeast(const times: integer): IWhen<T>;
begin
  FBuilder.PushRole(TCountExpectRole.Create(
    function (count: integer): boolean
    begin
      Result := count >= times;
    end,

    function (count: integer): string
    begin
      Result := Format('At least, %d times must be called (actual: %d)', [times, count]);
    end
  ));

  Result := TWhen<T>.Create(FBuilder);
end;

function TExpect<T>.AtLeastOnce: IWhen<T>;
begin
  Result := Self.AtLeast(1);
end;

function TExpect<T>.AtMost(const times: integer): IWhen<T>;
begin
  FBuilder.PushRole(TCountExpectRole.Create(
    function (count: integer): boolean
    begin
      Result := count <= times;
    end,

    function (count: integer): string
    begin
      Result := Format('It must be called greater than %d times (actual: %d)', [times, count]);
    end
  ));

  Result := TWhen<T>.Create(FBuilder);
end;

function TExpect<T>.Never: IWhen<T>;
begin
  Result := Self.Exactly(0);
end;

function TExpect<T>.Once: IWhen<T>;
begin
  Result := Self.Exactly(1);
end;

function TExpect<T>.Between(const a, b: integer): IWhen<T>;
begin
  FBuilder.PushRole(TCountExpectRole.Create(
    function (count: integer): boolean
    begin
      Result := (count >= a) and (count <= b);
    end,

    function (count: integer): string
    begin
      Result := Format('It must be called between %d and %d (actual: %d)', [a, b, count]);
    end
  ));

  Result := TWhen<T>.Create(FBuilder);
end;

function TExpect<T>.Exactly(const times: integer): IWhen<T>;
begin
  FBuilder.PushRole(TCountExpectRole.Create(
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

function TExpect<T>.Before(const AMethodName: string): IWhen<T>;
begin
  System.Assert(false, '–¢ŽÀ‘•');
end;

function TExpect<T>.BeforeOnce(const AMethodName: string): IWhen<T>;
begin
  FBuilder.PushRole(
    TMethodCallExpectRole.Create(
      procedure (indicies: TList<integer>)
      begin
        indicies.Add(FBuilder.CallStacks.Count);
      end,

      procedure (indicies: TList<integer>)
      begin
        indicies.Insert(0, 0);
      end
    )
    .OnVerify(
      function (start, stop: integer; curStatus: TMethodCallExpectRole.TStatus): TMethodCallExpectRole.TStatus
      var
        i, count: integer;
      begin
        if FBuilder.CallStacks.Count = 0 then Exit(curStatus);

        count := 0;
        for i := start to stop do begin
          if FBuilder.CallStacks[i].Name = AMethodName then begin
            Inc(count);
          end;
        end;

        if (curStatus = TMethodCallExpectRole.TStatus.Called) or (count > 1) then begin
          Result := TMethodCallExpectRole.TStatus.Failed;
        end
        else if curStatus = TMethodCallExpectRole.TStatus.NoCall then begin
          Result := TMethodCallExpectRole.TStatus.Called;
        end
        else begin
          Result := curStatus;
        end;
      end
    )
    .OnErrorReport(
      function: string
      begin
        Result := Format('Exactly once, a method (%s) must be called', [AMethodName]);
      end
    )
  );

  Result := TWhen<T>.Create(FBuilder);
end;

function TExpect<T>.After(const AMethodName: string): IWhen<T>;
begin
  System.Assert(false, '–¢ŽÀ‘•');
end;

function TExpect<T>.AfterOnce(const AMethodName: string): IWhen<T>;
begin
  System.Assert(false, '–¢ŽÀ‘•');
end;

{ TWhen<T> }

constructor TWhen<T>.Create(const builder: IRoleInvokerBuilder<T>);
begin
  FBuilder := builder;
end;

function TWhen<T>.GetExprct: IMockExpect<T>;
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

function TRoleInvokerBuilder<T>.GetCallStacks: TList<TRttiMethod>;
begin
  Result := FActionStorage.Callstacks;
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
  const fn: TFunc<string>): TMethodCallExpectRole;
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

function TMethodCallExpectRole.Verify: TVerifyResult;
var
  indicies: TList<integer>;
  i: integer;
  status: TStatus;
begin
  Assert(Assigned(FBeforeVerify));
  Assert(Assigned(FOnVerify));
  Assert(Assigned(FReportProvider));

  if FIndicies.Count = 0 then begin
    Exit(TVerifyResult.Create(FReportProvider()));
  end;

  indicies := TList<integer>.Create(FIndicies);

  FBeforeVerify(indicies);

  status := TStatus.NoCall;
  for i := 0 to indicies.Count-2 do begin
    status := FOnVerify(indicies[i], indicies[i+1]-1, status);

    if status = TStatus.Failed then Exit(TVerifyResult.Create(FReportProvider()));
  end;

  if status = TStatus.NoCall then begin
    Result := TVerifyResult.Create(FReportProvider());
  end;
end;

end.
