unit MockTools.Mocks.CoreExpect;

interface

uses
  SysUtils, Rtti, System.Generics.Collections,
  MockTools.Core.Types
;

function Once : TMockExpectWrapper;
function Never : TMockExpectWrapper;
function AtLeastOnce : TMockExpectWrapper;
function AtLeast(const times : integer) : TMockExpectWrapper;
function AtMost(const times : integer) : TMockExpectWrapper;
function Between(const a, b : integer) : TMockExpectWrapper;
function Exactly(const times: integer): TMockExpectWrapper;
function Before(const AMethodName : string) : TMockExpectWrapper;
function BeforeOnce(const AMethodName : string) : TMockExpectWrapper;
function After(const AMethodName : string) : TMockExpectWrapper;
function AfterOnce(const AMethodName : string) : TMockExpectWrapper;

implementation

uses
  MockTools.Core, MockTools.FormatHelper
;

function EvalOption(negate: boolean): string;
begin
  if negate then begin
    Result := ' not';
  end
  else begin
    Result := '';
  end;

end;

{ TExpects }

function Exactly(const times: integer): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TCountExpectRole.Create
        .OnVerify(
          function (count: integer): boolean
          begin
            Result := count = times;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; count: integer; opt: TVerifyResult.TOption): string
          begin
            Result := Format('A method (%s), call count must%s match (expect: %d, actual: %d)', [
              FormatMethodName(invoker.Method), EvalOption(not (opt in [TVerifyResult.TOption.Negate])), times, count
            ]);
          end
        );
    end
  );
end;

function Never: TMockExpectWrapper;
begin
  Result := Exactly(0);
end;

function Once: TMockExpectWrapper;
begin
  Result := Exactly(1);
end;

function AtLeast(const times: integer): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TCountExpectRole.Create
        .OnVerify(
          function (count: integer): boolean
          begin
            Result := count >= times;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; count: integer; opt: TVerifyResult.TOption): string
          begin
            Result := Format('At least %d times, a method (%s) must%s be called (actual: %d)', [
              times, EvalOption(opt in [TVerifyResult.TOption.Negate]), FormatMethodName(invoker.Method), count
            ]);
          end
        );
    end
  );
end;

function AtLeastOnce: TMockExpectWrapper;
begin
  Result := AtLeast(1);
end;

function AtMost(const times: integer): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TCountExpectRole.Create
        .OnVerify(
          function (count: integer): boolean
          begin
            Result := count <= times;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; count: integer; opt: TVerifyResult.TOption): string
          begin
            Result := Format('A method (%s) must%s be called greater than %d times (actual: %d)', [
              FormatMethodName(invoker.Method), EvalOption(opt in [TVerifyResult.TOption.Negate]), times, count
            ]);
          end
        );
    end
  );
end;

function Between(const a, b: integer): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TCountExpectRole.Create
        .OnVerify(
          function (count: integer): boolean
          begin
            Result := (count >= a) and (count <= b);
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; count: integer; opt: TVerifyResult.TOption): string
          begin
            Result := Format('A method (%s) must%s be called between %d and %d (actual: %d)', [
              FormatMethodName(invoker.Method), EvalOption(opt in [TVerifyResult.TOption.Negate]), a, b, count
            ]);
          end
        );
    end
  );
end;

function BeforeOnce(const AMethodName: string): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TMethodCallExpectRole.Create(
          procedure (indicies: TList<integer>)
          begin
            indicies.Add(callerInfo.GetCallStacks.Count);
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
            if callerInfo.GetCallStacks.Count = 0 then Exit(curStatus);

            count := 0;
            for i := start to stop do begin
              if callerInfo.GetCallStacks[i].Name = AMethodName then begin
                Inc(count);
              end;
            end;

            if (curStatus = TMethodCallExpectRole.TStatus.Called) or (count > 1) then begin
              Result := TMethodCallExpectRole.TStatus.Failed;
            end
            else if (curStatus = TMethodCallExpectRole.TStatus.NoCall) and (count = 1) then begin
              Result := TMethodCallExpectRole.TStatus.Called;
            end
            else begin
              Result := curStatus;
            end;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; opt: TVerifyResult.TOption): string
          begin
            Result := Format('Exactly once, a method (%s) must%s be called before "%s"', [
              AMethodName, EvalOption(opt in [TVerifyResult.TOption.Negate]), FormatMethodName(invoker.Method)
            ]);
          end
        );
    end
  );
end;

function Before(const AMethodName: string): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TMethodCallExpectRole.Create(
          procedure (indicies: TList<integer>)
          begin
            indicies.Add(callerInfo.GetCallStacks.Count);
          end,

          procedure (indicies: TList<integer>)
          begin
            indicies.Insert(0, 0);
          end
        )
        .OnVerify(
          function (start, stop: integer; curStatus: TMethodCallExpectRole.TStatus): TMethodCallExpectRole.TStatus
          var
            i: integer;
          begin
            if callerInfo.GetCallStacks.Count = 0 then Exit(curStatus);

            for i := start to stop do begin
              if callerInfo.GetCallStacks[i].Name = AMethodName then begin
                Exit(TMethodCallExpectRole.TStatus.Called);
              end;
            end;

            Result := TMethodCallExpectRole.TStatus.Failed;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; opt: TVerifyResult.TOption): string
          begin
            Result := Format('At least once, a method (%s) must%s be called before "%s"', [
              AMethodName, EvalOption(opt in [TVerifyResult.TOption.Negate]), FormatMethodName(invoker.Method)
            ]);
          end
        );
    end
  );
end;

function AfterOnce(const AMethodName: string): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TMethodCallExpectRole.Create(
          procedure (indicies: TList<integer>)
          begin
            indicies.Add(callerInfo.GetCallStacks.Count);
          end,

          procedure (indicies: TList<integer>)
          begin
            indicies.Add(callerInfo.GetCallStacks.Count);
          end
        )
        .OnVerify(
          function (start, stop: integer; curStatus: TMethodCallExpectRole.TStatus): TMethodCallExpectRole.TStatus
          var
            i, count: integer;
          begin
            if callerInfo.GetCallStacks.Count = 0 then Exit(curStatus);

            count := 0;
            for i := start to stop do begin
              if callerInfo.GetCallStacks[i].Name = AMethodName then begin
                Inc(count);
              end;
            end;

            if (curStatus = TMethodCallExpectRole.TStatus.Called) or (count > 1) then begin
              Result := TMethodCallExpectRole.TStatus.Failed;
            end
            else if (curStatus = TMethodCallExpectRole.TStatus.NoCall) and (count = 1) then begin
              Result := TMethodCallExpectRole.TStatus.Called;
            end
            else begin
              Result := curStatus;
            end;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; opt: TVerifyResult.TOption): string
          begin
            Result := Format('Exactly once, a method (%s) must%s be called after "%s"', [
              AMethodName, EvalOption(opt in [TVerifyResult.TOption.Negate]), FormatMethodName(invoker.Method)
            ]);
          end
        );
    end
  );
end;

function After(const AMethodName: string): TMockExpectWrapper;
begin
  Result := TExpectRoleFactory.CreateAsWrapper(
    function (callerInfo: IMockSession): IMockRole
    begin
      Result :=
        TMethodCallExpectRole.Create(
          procedure (indicies: TList<integer>)
          begin
            indicies.Add(callerInfo.GetCallStacks.Count);
          end,

          procedure (indicies: TList<integer>)
          begin
            indicies.Add(callerInfo.GetCallStacks.Count);
          end
        )
        .OnVerify(
          function (start, stop: integer; curStatus: TMethodCallExpectRole.TStatus): TMethodCallExpectRole.TStatus
          var
            i: integer;
          begin
            if callerInfo.GetCallStacks.Count = 0 then Exit(curStatus);

            for i := start to stop do begin
              if callerInfo.GetCallStacks[i].Name = AMethodName then begin
                Exit(TMethodCallExpectRole.TStatus.Called);
              end;
            end;

            Result := TMethodCallExpectRole.TStatus.Failed;
          end
        )
        .OnErrorReport(
          function (invoker: TMockAction; opt: TVerifyResult.TOption): string
          begin
            Result := Format('At least once, a method (%s) must%s be called after "%s"', [
              AMethodName, EvalOption(opt in [TVerifyResult.TOption.Negate]), FormatMethodName(invoker.Method)
            ]);
          end
        );
    end
  );
end;

end.
