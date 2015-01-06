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
  end;
  {$M-}

  TCounterObject = class(TInterfacedObject, ICounter)
  private
    FCount: integer;
  public
    procedure CountUp; virtual;
    function CallCount: integer; virtual;
    function SomeFunc(const n: integer; const s: string): string;
  end;

  {$M+}
  IShowing = interface
    ['{E1B6AB03-FF6F-4424-A54E-9C829B42529D}']
    function ToString: string;
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
