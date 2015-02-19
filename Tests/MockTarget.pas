unit MockTarget;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo,
  MockTools.Core.Types
;

type
  INoRttiIntf = interface
    function SomeFunc(const n: integer; const s: string): string;
  end;

  {$M+}
  ICounter = interface
    ['{84A318BD-84DA-4183-B55D-6878976C28F3}']
    procedure CountUp;
    function CallCount: integer;
    function SomeFunc(const n: integer; const s: string): string;
  end;
  {$M-}


  TCounterObject = class(TInterfacedObject, ICounter)
  private
    FCount: integer;
  public
    procedure CountUp; virtual;
    function CallCount: integer; virtual;
    function SomeFunc(const n: integer; const s: string): string; virtual;
    function NoneVirtualFunc(const n: integer): string;
  public
    constructor Create; overload;
    constructor Create(const count: integer); overload;
  end;

  {$M+}
  IShowing = interface
    ['{E1B6AB03-FF6F-4424-A54E-9C829B42529D}']
    function ToString: string;
  end;
  {$M-}

  IReadOnlyInfo = interface
    function GetInfomation: integer;
  end;

  {$M+}
  IInfo = interface(IReadOnlyInfo)
    procedure SetInfomation(const i: integer);
  end;
  {$M-}

  TVerifyResultStatusHelpeer = record helper for TVerifyResult.TStatus
    function AsTValue: TValue;
  end;

implementation

{ TCounterObject }

function TCounterObject.CallCount: integer;
begin
  Result := FCount;
end;

procedure TCounterObject.CountUp;
begin
  Inc(FCount);
end;

constructor TCounterObject.Create;
begin
  FCount := 0;
end;

constructor TCounterObject.Create(const count: integer);
begin
  FCount := count;
end;

function TCounterObject.NoneVirtualFunc(const n: integer): string;
begin
  Result := n.ToString();
end;

function TCounterObject.SomeFunc(const n: integer; const s: string): string;
begin
  Result := Format('%d-%s', [n, s]);
end;

{ TVerifyResultStatusHelpeer }

function TVerifyResultStatusHelpeer.AsTValue: TValue;
begin
  Result := TValue.From<TVerifyResult.TStatus>(Self);
end;

function Init: PTypeInfo;
begin
  Result := TypeInfo(IShowing);
end;

initialization

Init;

end.
