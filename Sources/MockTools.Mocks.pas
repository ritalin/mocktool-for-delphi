unit MockTools.Mocks;

interface

uses
  System.SysUtils, Classes, System.Rtti, System.TypInfo, System.Generics.Collections, System.Generics.Defaults,
  MockTools.Core.Types
;

type
  TMock<T> = record
  private var
    FSession: IMockSessionRecorder;
    FRecordProxy: IProxy<T>;
    FVirtualProxy: IReadOnlyProxy<T>;
    FDependencies: TList<TFunc<boolean, TVerifyResult>>;
  private
    function BridgeRecordProxy<U: IInterface>(
      const recordProxy: IProxy<T>; const fromType, toType: PTypeInfo): IProxy<U>;

    class function CreateNewMock(
      const session: IMockSessionRecorder; const recordProxy: IProxy<T>;
      const virtualProxy: IReadOnlyProxy<T>;
      const dependencies: TList<TFunc<boolean, TVerifyResult>>): TMock<T>; static;

    class function ReportNoError(opt: TVerifyResult.TOption): string; static;
    function BridgeVirtualProxy<U: IInterface>(const virtualProxy: IReadOnlyProxy<T>;
      const fromType, toType: PTypeInfo): IReadOnlyProxy<U>;
  public
    class operator Implicit(const Value: TMock<T>): T;

    function Setup: IMockSetup<T>; overload;
    function Setup<U: IInterface>: IMockSetup<U>; overload;

    function Stub: IMockSetup<T>; overload;
    function Stub<U: IInterface>: IMockSetup<U>; overload;

    function Expect(const expect: TMockExpectWrapper): IWhen<T>; overload;
    function Expect<U: IInterface>(const expect: TMockExpectWrapper): IWhen<U>; overload;

    procedure DependsOn<U>(slaveMock: TMock<U>);

    procedure VerifyAll; overload;
    function VerifyAll(const noThrow: boolean): TVerifyResult; overload;

    function Instance: T; overload;
    function Instance<U: IInterface>: U; overload;

    function AsType<U: IInterface>: TMock<U>;
  end;

  TMock = record
  private
    class function ExtractGuid(info: PTypeInfo): TGUID; static;
  public
    class function Create<T: class>: TMock<T>; overload; static;
    class function Create<T: class>(const instance: T): TMock<T>; overload; static;
    class function Implements<T: IInterface>: TMock<T>; overload; static;
    class function Implements<T: IInterface>(const withInterfaces: array of TGUID): TMock<T>; overload; static;
  end;

  EMockToolsException = class(Exception);
  EMockVerifyException = class(EMockToolsException);

procedure RegisterExceptionProc(const proc: TProc<string>);

var
  gFalureProc: TProc<string>;

implementation

uses
  MockTools.Core
;

{ TMock<T> }

class function TMock<T>.CreateNewMock(
  const session: IMockSessionRecorder; const recordProxy: IProxy<T>;
  const virtualProxy: IReadOnlyProxy<T>;
  const dependencies: TList<TFunc<boolean, TVerifyResult>>): TMock<T>;
begin
  Result.FSession := session;
  Result.FRecordProxy := recordProxy;
  Result.FVirtualProxy := virtualProxy;
  Result.FDependencies := dependencies;
end;

procedure TMock<T>.DependsOn<U>(slaveMock: TMock<U>);
begin
  FDependencies.Add(
    function (noThrow: boolean): TVerifyResult
    begin
      Result := slaveMock.VerifyAll(noThrow);
    end
  );
end;

function TMock<T>.Expect(const expect: TMockExpectWrapper): IWhen<T>;
begin
  Result :=
    TWhen<T>.Create(TRoleInvokerBuilder<T>.Create(FRecordProxy, FSession))
    .Expect(expect)
  ;
end;

class operator TMock<T>.Implicit(const Value: TMock<T>): T;
begin
  Result := Value.Instance;
end;

function TMock<T>.Setup: IMockSetup<T>;
begin
  Result := TMockSetup<T>.Create(TRoleInvokerBuilder<T>.Create(FRecordProxy, FSession), false);
end;

class function TMock<T>.ReportNoError(opt: TVerifyResult.TOption): string;
begin
  Result := '';
end;

procedure TMock<T>.VerifyAll;
begin
  Self.VerifyAll(false);
end;

function TMock<T>.VerifyAll(const noThrow: boolean): TVerifyResult;
var
  action: TMockAction;
  roles: TArray<IMockRole>;
  dep: TFunc<boolean, TVerifyResult>;
begin
  for action in FSession.Actions do begin
    roles := action.Roles;

    Result := roles[High(roles)].Verify(action);
    if Result.Status <> TVerifyResult.TStatus.Passed then begin
      if noThrow then Exit(Result);

      Assert(Assigned(gFalureProc), 'A failure procedure is not assigned.');

      gFalureProc(Result.Report);
    end;
  end;

  for dep in FDependencies do begin
    Result := dep(noThrow);
    if Result.Status <> TVerifyResult.TStatus.Passed then Exit;
  end;

  Result := TVerifyResult.Create(ReportNoError, TVerifyResult.TStatus.Passed, TVerifyResult.TOption.None);
end;

function TMock<T>.Instance: T;
begin
  Result := FVirtualProxy.Subject;
end;

function TMock<T>.Instance<U>: U;
begin
  FVirtualProxy.TryGetSubject(TypeInfo(U), Result);
end;

function TMock<T>.AsType<U>: TMock<U>;
var
  instance: U;
begin
  Result := TMock<U>.CreateNewMock(
    FSession,
    Self.BridgeRecordProxy<U>(FRecordProxy, TypeInfo(T), TypeInfo(U)),
    Self.BridgeVirtualProxy<U>(FVirtualProxy, TypeInfo(T), TypeInfo(U)),
    TList<TFunc<boolean, TVerifyResult>>.Create(FDependencies)
  );
end;

function TMock<T>.BridgeRecordProxy<U>(const recordProxy: IProxy<T>; const fromType, toType: PTypeInfo): IProxy<U>;
var
  tmp: IInterface;
  childProxy: IProxy<IInterface>;
begin
  if fromType = toType then begin
    Result := TTypeProxyBridge<T, U>.Create(recordProxy);
  end
  else begin
    Assert(recordProxy.QueryProxy(TMock.ExtractGuid(toType), tmp) = S_OK, 'Not Implemented interface.');
    Assert(Supports(tmp, IProxy<IInterface>, childProxy));

    Result := TTypeProxyBridge<IInterface, U>.Create(childProxy);
  end;
end;

function TMock<T>.BridgeVirtualProxy<U>(const virtualProxy: IReadOnlyProxy<T>; const fromType, toType: PTypeInfo): IReadOnlyProxy<U>;
begin
  Result := TTypeReadOnlyProxyBridge<T, U>.Create(virtualProxy);
end;

function TMock<T>.Setup<U>: IMockSetup<U>;
begin
  Result := TMockSetup<U>.Create(TRoleInvokerBuilder<U>.Create(
    Self.BridgeRecordProxy<U>(FRecordProxy, TypeInfo(T), TypeInfo(U)), FSession
  ), false);
end;

function TMock<T>.Stub<U>: IMockSetup<U>;
begin
  Result := TMockSetup<U>.Create(TRoleInvokerBuilder<U>.Create(
    Self.BridgeRecordProxy<U>(FRecordProxy, TypeInfo(T), TypeInfo(U)), FSession
  ), true);
end;

function TMock<T>.Expect<U>(const expect: TMockExpectWrapper): IWhen<U>;
begin
  Result :=
    TWhen<U>.Create(TRoleInvokerBuilder<U>.Create(
      Self.BridgeRecordProxy<U>(FRecordProxy, TypeInfo(T), TypeInfo(U)), FSession))
    .Expect(expect)
  ;
end;

function TMock<T>.Stub: IMockSetup<T>;
begin
  Result := TMockSetup<T>.Create(TRoleInvokerBuilder<T>.Create(FRecordProxy, FSession), true);
end;

{ TMock }

class function TMock.Create<T>: TMock<T>;
var
  session: IMockSessionRecorder;
begin
  session := TMockSessionRecorder.Create;

  Result := TMock<T>.CreateNewMock(
    session,
    TObjectRecordProxy<T>.Create,
    TVirtualProxy<T>.Create(TObjectRecordProxy<T>.Create, session),
    TList<TFunc<boolean, TVerifyResult>>.Create
  );
end;

class function TMock.Create<T>(const instance: T): TMock<T>;
var
  session: IMockSessionRecorder;
begin
  Assert(Assigned(instance));

  session := TMockSessionRecorder.Create;

  Result := TMock<T>.CreateNewMock(
    session,
    TObjectRecordProxy<T>.Create,
    TVirtualProxy<T>.Create(TObjectRecordProxy<T>.Create(instance), session),
    TList<TFunc<boolean, TVerifyResult>>.Create
  );
end;

class function TMock.ExtractGuid(info: PTypeInfo): TGUID;
var
  d: PTypeData;
begin
  Assert(info.Kind = tkInterface);

  d := GetTypeData(info);
  Result := d.Guid;
end;

class function TMock.Implements<T>: TMock<T>;
begin
  Result := Implements<T>([]);
end;

class function TMock.Implements<T>(
  const withInterfaces: array of TGUID): TMock<T>;
var
  info: PTypeInfo;
  iid: TGUID;
  session: IMockSessionRecorder;
begin
  info := TypeInfo(T);
  iid := ExtractGuid(info);
  session := TMockSessionRecorder.Create;

  Result := TMock<T>.CreateNewMock(
    session,
    TInterfaceRecordProxy<T>.Create(iid, info, withInterfaces),
    TVirtualProxy<T>.Create(
      TInterfaceRecordProxy<T>.Create(iid, info, withInterfaces),
      session
    ),
    TList<TFunc<boolean, TVerifyResult>>.Create
  );
end;

procedure RegisterExceptionProc(const proc: TProc<string>);
begin
  gFalureProc := proc;
end;

end.
