unit MockTools.Mocks.CoreExpect;

interface

uses
  SysUtils, Rtti, System.Generics.Collections,
  MockTools.Core.Types
;

function Once : IMockExpect;
function Never : IMockExpect;
function AtLeastOnce : IMockExpect;
function AtLeast(const times : integer) : IMockExpect;
function AtMost(const times : integer) : IMockExpect;
function Between(const a, b : integer) : IMockExpect;
function Exactly(const times: integer): IMockExpect;
function Before(const AMethodName : string) : IMockExpect;
function BeforeOnce(const AMethodName : string) : IMockExpect;
function After(const AMethodName : string) : IMockExpect;
function AfterOnce(const AMethodName : string) : IMockExpect;

implementation

uses
  MockTools.Core
;

{ TExpects }

function Exactly(const times: integer): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker; count: integer): string
          begin
            Result := Format('A method (%s) did not match call count (expect: %d, actual: %d)', [invoker.Method.Name, times, count]);
          end
        );
    end
  );
end;

function Never: IMockExpect;
begin
  Result := Exactly(0);
end;

function Once: IMockExpect;
begin
  Result := Exactly(1);
end;

function AtLeast(const times: integer): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker; count: integer): string
          begin
            Result := Format('At least %d times, a method (%s) must be called (actual: %d)', [times, invoker.Method.Name, count]);
          end
        );
    end
  );
end;

function AtLeastOnce: IMockExpect;
begin
  Result := AtLeast(1);
end;

function AtMost(const times: integer): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker; count: integer): string
          begin
            Result := Format('A method (%s) must be called greater than %d times (actual: %d)', [invoker.Method.Name, times, count]);
          end
        );
    end
  );
end;

function Between(const a, b: integer): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker; count: integer): string
          begin
            Result := Format('A method (%s) must be called between %d and %d (actual: %d)', [invoker.Method.Name, a, b, count]);
          end
        );
    end
  );
end;

function BeforeOnce(const AMethodName: string): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker): string
          begin
            Result := Format('Exactly once, a method (%s) must be called before "%s"', [AMethodName, invoker.Method.Name]);
          end
        );
    end
  );
end;

function Before(const AMethodName: string): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker): string
          begin
            Result := Format('At least once, a method (%s) must be called before "%s"', [AMethodName, invoker.Method.Name]);
          end
        );
    end
  );
end;

function AfterOnce(const AMethodName: string): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker): string
          begin
            Result := Format('Exactly once, a method (%s) must be called after "%s"', [AMethodName, invoker.Method.Name]);
          end
        );
    end
  );
end;

function After(const AMethodName: string): IMockExpect;
begin
  Result := TExpectRoleFactory.Create(
    function (callerInfo: ICallerInfo): IMockRole
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
          function (invoker: TMockInvoker): string
          begin
            Result := Format('At least once, a method (%s) must be called after "%s"', [AMethodName, invoker.Method.Name]);
          end
        );
    end
  );
end;

end.
