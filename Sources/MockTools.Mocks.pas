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
    function BridgeProxy<U: IInterface>(const fromType, toType: PTypeInfo): IProxy<U>;
    class function ReportNoError(opt: TVerifyResult.TOption): string; static;
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
  end;

  TMock = record
  private
    class function ExtractGuid(info: PTypeInfo): TGUID; static;
  public
    class function Create<T: class>: TMock<T>; static;
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

function TMock<T>.BridgeProxy<U>(const fromType, toType: PTypeInfo): IProxy<U>;
var
  tmp: IInterface;
  childProxy: IProxy<IInterface>;
begin
  if fromType = toType then begin
    Result := TTypeBridgeProxy<T, U>.Create(FRecordProxy);
  end
  else begin
    Assert(FRecordProxy.QueryProxy(TMock.ExtractGuid(toType), tmp) = S_OK, 'Not Implemented interface.');
    Assert(Supports(tmp, IProxy<IInterface>, childProxy));

    Result := TTypeBridgeProxy<IInterface, U>.Create(childProxy);
  end;
end;

function TMock<T>.Setup<U>: IMockSetup<U>;
begin
  Result := TMockSetup<U>.Create(TRoleInvokerBuilder<U>.Create(
    Self.BridgeProxy<U>(TypeInfo(T), TypeInfo(U)), FSession
  ), false);
end;

function TMock<T>.Stub<U>: IMockSetup<U>;
begin
  Result := TMockSetup<U>.Create(TRoleInvokerBuilder<U>.Create(
    Self.BridgeProxy<U>(TypeInfo(T), TypeInfo(U)), FSession
  ), true);
end;

function TMock<T>.Expect<U>(const expect: TMockExpectWrapper): IWhen<U>;
begin
  Result :=
    TWhen<U>.Create(TRoleInvokerBuilder<U>.Create(
      Self.BridgeProxy<U>(TypeInfo(T), TypeInfo(U)), FSession))
    .Expect(expect)
  ;
end;

function TMock<T>.Stub: IMockSetup<T>;
begin
  Result := TMockSetup<T>.Create(TRoleInvokerBuilder<T>.Create(FRecordProxy, FSession), true);
end;

{ TMock }

class function TMock.Create<T>: TMock<T>;
begin
  Result.FDependencies := TList<TFunc<boolean, TVerifyResult>>.Create;
  Result.FSession := TMockSessionRecorder.Create;
  Result.FRecordProxy := TObjectRecordProxy<T>.Create;
  Result.FVirtualProxy := TVirtualProxy<T>.Create(TObjectRecordProxy<T>.Create, Result.FSession);
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
begin
  info := TypeInfo(T);
  iid := ExtractGuid(info);

  Result.FDependencies := TList<TFunc<boolean, TVerifyResult>>.Create;
  Result.FSession := TMockSessionRecorder.Create;
  Result.FRecordProxy := TInterfaceRecordProxy<T>.Create(iid, info, withInterfaces);
  Result.FVirtualProxy := TVirtualProxy<T>.Create(
    TInterfaceRecordProxy<T>.Create(iid, info, withInterfaces),
    Result.FSession
  );
end;

procedure RegisterExceptionProc(const proc: TProc<string>);
begin
  gFalureProc := proc;
end;

end.
