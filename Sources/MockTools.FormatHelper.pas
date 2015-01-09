unit MockTools.FormatHelper;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo
;

function FormatVerifyResultOption(negate: boolean): string;
function FormatMethodName(const t: PTypeInfo; const method: TRttiMethod): string;

implementation

function FormatVerifyResultOption(negate: boolean): string;
begin
  if negate then begin
    Result := ' not';
  end
  else begin
    Result := '';
  end;
end;

function FormatMethodName(const t: PTypeInfo; const method: TRttiMethod): string;
begin
  Result := Format('%s.%s', [t^.Name, method.Name]);
end;

end.
