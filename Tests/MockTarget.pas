unit MockTarget;

interface

uses
  System.SysUtils, System.Rtti,
  MockTools.Core.Types
;

type
  TCounterObject = class
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
