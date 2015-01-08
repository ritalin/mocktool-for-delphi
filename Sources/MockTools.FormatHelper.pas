unit MockTools.FormatHelper;

interface

uses
  System.SysUtils, System.Rtti
;

function FormatVerifyResultOption(negate: boolean): string;
function FormatMethodName(const method: TRttiMethod): string;

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

function FormatMethodName(const method: TRttiMethod): string;
begin
  Result := Format('%s.%s', [method.Parent.Name, method.Name]);
end;

end.
