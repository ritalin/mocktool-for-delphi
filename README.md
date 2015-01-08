# mocktool-for-delphi

## Introduction
Delphi test double library for DUnit / DUnitX

Inspired by [VSoftTechnologies/Delphi-Mocks](https://github.com/VSoftTechnologies/Delphi-Mocks)

VSoftTechnologies/Delphi-Mocks is very awesome !

But VSoftTechnologies/Delphi-Mocks is

* Only setup or a expection can not specify one mock method.
* Multiple expection can not specify one mock method.

On the other hand,this library is

* it can specify setup and expection simaltanuously.
* expections can combine using not / or / and operators.

In addition to, This library is supported follow features similar with VSoftTechnologies/Delphi-Mocks
* AAA (Arrange-Act-Assert) style mock.
* Interface instanciation.

## Requirement
* Tests for this library is useed [VSoftTechnologies/DUnitX](https://github.com/VSoftTechnologies/DUnitX) 
and [ritalin/haxe-should](https://github.com/ritalin/haxe-should)

* This library is only tested by Delphi XE5.

## Usage
1. Add unit: *MockTools.Mocks* in uses declative.
2. Arrange mock object.
3. Act it.
4. Assert expection.

## Examples 

### Object mocking

```delphi
var
  mock: TMock<TSomeObject>;
begin
  mock := TMock.Create<TSomeObject>;
  mock.Setup.WillReturn('Foo').Expect(Exactry(2)).When.ToString;
  
  mock.Instance.ToString;
  mock.Instance.ToString;
  
  mock.VerifyAll;
end;
```

### Interface instanciation

**Hint** : interface most activated RTTI. Please, use {$M+}/{$M-} compiler instruction.

```delphi
{$M+}
type ICounter = interface
  procedure CountUp;
  function CallCount: integer;
end;
{$M-}
var
  mock: TMock<TSomeObject>;
begin
  mock := TMock.Create<ICounter>;
  mock.Setup.WillReturn(108).Expect(Exactry(2)).When.CallCount;
  
  mock.Instance.CallCount;
  mock.Instance.CallCount;
  
  mock.VerifyAll;
end;
```

### Interface switching

```delphi
{$M+}
type IShowing = interface
  function ToString;
end;
{$M-}

var
  mock: TMock<TSomeObject>;
begin
  mock := TMock.Create<ICounter>([IShowing]);
  mock.SetUp<IShowing>.WillReturn('Foo').Expect(Only).When.ToString;
  
  mock.Instance<IShowing>.ToString;
  
  mock.VerifyAll;
```

**Hint** : SysUtils.Support function allow to switch interface.

### Stub setup

```delphi
var
  mock: TMock<TSomeObject>;
begin
  mock := TMock.Create<TSomeObject>;
  mock.Stub.WillReturn('Foo').When.ToString;
  
  mock.Instance.ToString;
```

**Hint** : Stub also supprt interface switching.


