# Test Suite Overview

This directory contains automated verification for the Interactive AL Code Runner. The tests validate both the interpreter core and higher-level script scenarios so we can confidently evolve parsing logic, built-in functions, and record handling.

## What the Interpreter Does

The runtime tokenises AL text, builds an in-memory execution plan, and evaluates statements sequentially. Tests focus on ensuring:

- Variables honour declared data types and default initialisation.
- Expressions, operators, and control flow behave like native AL.
- Built-in helper functions (string, math, system) return consistent results.
- Record methods (FindSet, SetRange, CalcFields, etc.) surface friendly errors when misused.
- Error reporting prefixes messages with `Error:` for easy assertion.

## Codeunit Inventory

| Codeunit | Scope | Highlights |
| --- | --- | --- |
| `Program Executor Tests` (80100) | Unit tests for expression engine and built-ins | Variable declaration, arithmetic precedence, logical operations, math utilities, string helpers (`StrSubstNo`, `StrLen`, `CopyStr`, `InsStr`, `DelStr`), for-loop step handling, div/mod behaviour, message placeholder substitution, GUID generation, procedure declarations (with parameters, returns, local scope, and exit return-value propagation), case statement (with/without else, nested, in loops), exit with return values, date functions (DMY2Date, Date2DMY, Date2DWY, CalcDate, WorkDate), math functions (Random, Randomize), control functions (Clear, Error, Commit), UI functions (StrMenu, Confirm), execution functions (Page.Run, Page.RunModal, Report.Run, Codeunit.Run), and defensive checks for unknown functions. |
| `Record Operations Tests` (80101) | Record reference handling | Find/Set variants, field access, quoted identifiers, CalcFields/CalcSums, LockTable, filter validation, error surfacing for missing arguments, and guard rails for unsupported record methods. |
| `Script Execution Tests` (80102) | End-to-end scenarios | Customer listings, inventory analysis, sales totals, nested loops, message formatting, mixed data types, error paths, and composite scripts leveraging for-loops and GUID output. |

Each procedure follows a Given/When/Then comment style and uses `Program Executor` in console-only mode to keep the tests deterministic.

## Running the Tests

1. Deploy the extension to a sandbox or Docker container with test symbols.
2. Open **AL Test Tool** in Visual Studio Code or use the **Test Tool** page in Business Central.
3. Select the desired suite (`Program Executor Tests`, `Record Operations Tests`, `Script Execution Tests`) and run.
4. In CI, AL-Go orchestrates the same suites; see `.AL-Go/` for pipeline configuration.

> Tip: The interpreter relies on live application data. When verifying record scenarios, ensure key tables (Customer, Item, Sales Header) exist; tests assert for error messages rather than data contents.

## Coverage Map

- ✅ Data types: Integer, Decimal, Boolean, Text/Code, Char, BigText, Date, DateTime, GUID, Option, Duration, Blob, Record.
- ✅ Operators & expressions: arithmetic, logical, unary, comparison, precedence, parentheses.
- ✅ Control flow: `if`, `repeat until`, `for` (with `step`), `while`, `case` (with/without else, nested, in loops), block scoping, nested logic, `exit` (with/without return value), `break`, `continue`, procedure declarations/calls with typed parameters (including length qualifiers and `var` parameters), local `var` sections, and return-value propagation.
- ✅ Built-in functions: Message placeholders, CopyStr, InsStr, StrLen, DelStr, Power, Min/Max, Round, Abs, Format, CreateGuid, CurrentDateTime, Today, Time, UserId, CompanyName, DMY2Date, Date2DMY, Date2DWY, CalcDate, WorkDate, Random, Randomize, Clear, Error, Commit, StrMenu, Confirm, Page.Run, Page.RunModal, Report.Run, Codeunit.Run.
- ✅ Record operations: SetRange/SetFilter/GetFilter validation, CalcFields/CalcSums guards, LockTable, Count/CountApprox, IsEmpty, Next loops, Find (with operators), Init, ChangeCompany, Validate, TestField, ModifyAll, DeleteAll, Insert/Modify/Delete.
- ✅ Query execution: inline definitions, nested dataitems with `DataItemLink`, `DataItemTableFilter`, `ColumnFilter`, and aggregation via `Method = Count` / `Method = Sum`, plus defensive checks for duplicates and formatting regressions.
- ✅ Error scenarios: division by zero, undefined variables, missing arguments, unknown functions/methods, invalid fields, invalid operators.

## Naming & Style Guide

- `Test<Area><Scenario>()` naming keeps AL Test Tool navigation predictable.
- Each test initialises its own code string and asserts exclusively on local results.
- `Type Helper` supplies the platform-specific LF separator to ensure consistent tokenisation tests.

## Extending the Suite

- Add new unit tests to the most specific codeunit that matches the behaviour under test.
- Prefer asserting on explicit output strings; avoid comparing entire execution logs when a substring suffices.
- When covering error paths, assert on the exact `Error:` prefix to keep expectations robust across locales.

