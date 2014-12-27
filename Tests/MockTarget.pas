unit MockTarget;

interface

uses
  System.SysUtils, System.Rtti
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

end.
