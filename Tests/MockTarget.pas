unit MockTarget;

interface

uses
  System.SysUtils, System.Rtti,
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

end.
