unit MockTools.Mocks;

interface

uses
  System.SysUtils, System.Rtti
;

type
  IWhen<T> = interface;
  IExpect<T> = interface;
  IMockSetup<T> = interface;

  TMock<T> = record

  end;

  IWhen<T> = interface
    function GetSubject: T;

    property When: T read GetSubject;
  end;

  IExpect<T> = interface
    function Once : IWhen<T>;
    function Never : IWhen<T>;
    function AtLeastOnce : IWhen<T>;
    function AtLeast(const times : integer) : IWhen<T>;
    function AtMost(const times : integer) : IWhen<T>;
    function Between(const a, b : integer) : IWhen<T>;
    function Exactly(const times: integer): IWhen<T>;
  end;

  IWhenOrExpect<T> = interface(IWhen<T>)
    function GetExprct: IExpect<T>;

    property Expect: IExpect<T> read GetExprct;
  end;

  IMockSetup<T> = interface
    function WillReturn(value: TValue): IWhenOrExpect<T>; overload;
    function WillExecute(const proc: TProc): IWhenOrExpect<T>; overload;
    function WillExecute(const fn: TFunc<TValue>): IWhenOrExpect<T>; overload;
    function WillRaise(const provider: TFunc<Exception>): IWhen<T>; overload;
  end;

implementation

end.
