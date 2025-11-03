# Interactive AL Code Runner for Business Central

## Overview

This extension enables administrators and power users to write and execute AL code directly within Business Central—no compilation or deployment required. Perfect for quick diagnostics, data exploration, learning AL fundamentals, or running ad-hoc scripts against your Business Central data.

## Getting Started

1. **Install the Extension**: Deploy to a Business Central 2024 Wave 2 (v27.0) or later environment
2. **Open the Page**: Search for **Interactive Code Runner** in Business Central
3. **Write Your Code**: Use the built-in code editor to write AL statements
4. **Execute**: Click the **Run** button to execute your code
5. **View Results**: Output appears in the console pane below the editor; errors are clearly marked

### User Interface Features

- **Code Editor**: Syntax-aware editor with standard editing capabilities
- **Run Button**: Execute your code immediately
- **Console Output**: View execution results, messages, and errors in real-time
- **Console Only Mode**: Toggle to suppress GUI dialogs (useful for automated testing)
- **Script Management**: Save and organize your scripts for reuse
- **Demo Scripts**: Access built-in learning examples from the demo library

## Common Use Cases

- **Data Analysis**: Quickly analyze customer data, inventory levels, or sales figures
- **Troubleshooting**: Test queries and data access without deploying code
- **Learning AL**: Practice AL programming concepts with immediate feedback
- **Ad-Hoc Reporting**: Generate quick reports by querying Business Central tables
- **Data Validation**: Verify data integrity and identify inconsistencies
- **Quick Calculations**: Perform calculations on Business Central data in real-time

## Supported Syntax Overview

### Data Types

| Type | Default value | Notes |
| --- | --- | --- |
| Integer | `0` | Supports arithmetic, `div`, `mod` |
| Decimal | `0` | Uses invariant culture in string form |
| Boolean | `false` | Accepts `true`, `false`, `1`, `0`, `yes`, `no` |
| Text / Code | `''` | Text joins with `+` |
| Char | `''` | Single-character strings |
| BigText | `''` | Treated as Text in runtime |
| Date | `0D` | Works with `Today()` |
| DateTime | `0DT` | Works with `CurrentDateTime()` |
| Duration | `0` | Stored as text representation |
| GUID | Generated via `CreateGuid()` | Declaring a GUID initialises it with a new value |
| Option | `0` | No option members defined; use integers for values |
| Blob | `''` | Managed as empty text |
| Record `<Table>` | Uninitialised | Resolved dynamically through `RecordRef` |

### Statements & Control Flow

| Statement | Syntax | Example | Notes |
| --- | --- | --- | --- |
| Variable declaration | `<Name>: <Type>;` | `Counter: Integer;` | Records require table name `Customer: Record Customer;` |
| Assignment | `<Name> := <Expression>;` | `Counter := Counter + 1;` | Field assignment `Customer.Name := 'New';` |
| If / Then / Else | `if Condition then ... [else ...];` | `if Amount > 0 then Message('Positive');` | Nested `if` supported; requires `then` keyword |
| Repeat / Until | `repeat ... until Condition;` | `repeat Counter += 1; until Counter = 10;` | Guarded by 10,000 iteration limit |
| For loop | `for Var := From to To [step N] do ...;` | `for Index := 1 to 5 step 2 do begin ... end;` | Step must evaluate to integer |
| Begin / End block | `begin ... end;` | `begin ... end;` | Semicolon required after `end` |
| While loop | `while Condition do ...;` | `while Counter < 5 do begin ... end;` | Executed with limited support; prefer `repeat`/`for` |
| Case statement | `case Expression of Value: Statement [else Statements] end;` | `case Status of 1: Result := 'One'; else Result := 'Other'; end;` | Supports text and numeric values; nested cases supported |
| Exit / Break / Continue | `exit;` or `exit(Value);` | `exit;` or `exit(42);` | Parsed; `break/continue` currently behave as no-ops |

### Expressions & Operators

| Operator | Description | Example |
| --- | --- | --- |
| `+`, `-`, `*`, `/` | Arithmetic with auto coercion | `Total := Price * Quantity;` |
| `div`, `mod` | Integer division & remainder | `Part := Counter div 10;` |
| Unary `-`, `not` | Negation | `Value := -Value;` |
| `=`, `<>`, `<`, `>`, `<=`, `>=` | Comparisons return Boolean text | `if A >= B then ...;` |
| `and`, `or` | Logical operators | `if IsOpen and not IsBlocked then ...;` |
| Parentheses | Explicit precedence | `Result := (2 + 3) * 4;` |

### Built-In Functions

| Function | Purpose | Example | Notes |
| --- | --- | --- | --- |
| `Message(Text[, Arg...])` | Emits output | `Message('Customer %1', Cust.No.);` | Supports `%1..%9` placeholders |
| `StrLen(Text)` | String length | `Len := StrLen(Name);` | Returns textified integer |
| `CopyStr(Text, Start[, Length])` | Substring | `CopyStr(Code, 1, 3);` | Start is 1-based |
| `UpperCase(Text)` / `LowerCase(Text)` | Case transforms | `UpperCase(Name);` | |
| `Format(Value)` | Converts to text | `Format(Total);` | |
| `Today()` | Current date | `WorkDate := Today();` | |
| `CurrentDateTime()` | Current DateTime | `CurrentDateTime();` | |
| `Time()` | Current time | `Time();` | |
| `Round(Value[, Precision])` | Numeric rounding | `Round(Amount, 0.01);` | Defaults to precision `1` if omitted |
| `Abs(Value)` | Absolute value | `Abs(-10);` | Works for Integer/Decimal |
| `Power(Value, Exponent)` | Exponentiation | `Power(2, 3);` | |
| `Min(Value1, Value2)` / `Max(Value1, Value2)` | Min/Max | `Max(Amount, 0);` | Supports Integer & Decimal |
| `StrPos(Text, SubText)` | Find substring | `StrPos(Name, 'A');` | |
| `DelChr(Text, Where[, Which])` | Delete characters | `DelChr(Code, '=', '-');` | |
| `InsStr(Text, Insert, Position)` | Insert substring | `InsStr('World', 'Hello ', 1);` | |
| `MaxStrLen(Value)` | Returns `250` | `MaxStrLen(Name);` | Simplified implementation |
| `CreateGuid()` | Generates GUID | `CreateGuid();` | Returns formatted text |
| `CreateDateTime(Date, Time)` | Current DateTime | `CreateDateTime(Today(), Time());` | Returns current DateTime regardless of arguments |
| `UserId()` / `CompanyName()` | Session metadata | `UserId();` | |

### Record Methods

| Method | Description | Notes |
| --- | --- | --- |
| `FindFirst()` / `FindLast()` | Locate first/last record | Returns Boolean text |
| `FindSet()` | Opens dataset for iteration | Returns Boolean text |
| `Find(Operator)` | Find with operator | Supports `=`, `<>`, `<`, `>`, `<=`, `>=`; returns Boolean text |
| `Next()` | Advances current record | Returns `Integer` count |
| `SetRange(Field, Value[, Value2])` | Applies range filter | Field can be identifier or quoted name |
| `SetFilter(Field, Filter)` | Applies filter expression | Supports Business Central filter syntax |
| `GetFilter(Field)` | Get filter text from field | Returns filter expression as text |
| `Insert(True)` / `Modify(True)` / `Delete(True)` | Persists record changes | Enforces Business Central validation; may fail without required fields |
| `ModifyAll(Field, Value)` | Modify all filtered records | Updates all records matching current filters |
| `DeleteAll()` | Delete all filtered records | Removes all records matching current filters |
| `Init()` | Initialize empty record | Sets default values for all fields |
| `Validate(Field[, Value])` | Validate field value | Simulates field entry validation; optional value parameter |
| `TestField(Field, Value)` | Test field against value | Raises error if field value doesn't match |
| `CalcFields(Field, ...)` | Calculates FlowFields | Raises error if field missing |
| `CalcSums(Field, ...)` | Calculates SumIndexFields | Raises error if field missing |
| `IsEmpty()` | Checks if record set is empty | Returns Boolean text |
| `Count()` | Returns record count | Exact count |
| `CountApprox()` | Returns approximate record count | Faster for large datasets |
| `Get(...)` | Simplified record lookup | Basic record retrieval |
| `Reset()` | Clears filters | Removes all filters |
| `LockTable()` | Locks records | Obeys current session permissions |
| `ChangeCompany(CompanyName)` | Change company context | Switches record context to specified company |

## Runtime Limits

- **Variables**: Up to 100 variables per script
- **Record References**: Up to 10 simultaneous record variables
- **Loop Protection**: Loops are automatically stopped after 10,000 iterations to prevent runaway scripts
- **Error Handling**: Execution stops at the first error encountered; error messages appear in the console output

## Usage Examples

### Looping with Record Filters
```al
Customer: Record Customer;
Counter: Integer;

Counter := 0;
Customer.SetFilter(Name, 'A*');
if Customer.FindSet() then begin
  repeat
    Counter := Counter + 1;
    Message('Customer %1: %2', Counter, Customer.Name);
  until Customer.Next() = 0;
end;

Message('Total: %1', Counter);
```

### String Utilities and Placeholders
```al
TextVar: Text;
Result: Text;

TextVar := 'Hello World';
Result := CopyStr(TextVar, 1, 5);
Message('Original: %1', TextVar);
Message('Slice: %1', Result);
Message('Injected: %1', InsStr('World', 'Hello ', 1));
```

## Troubleshooting

- **Table not found** – confirm the table exists in your Business Central environment and the current company grants access.
- **Field not found** – check spelling; quoted field names must include the surrounding double quotes in code (`Customer."No."`).
- **Variable not found** – declare variables before use; names are case-sensitive.
- **Loop exceeded maximum iterations** – ensure loop conditions will eventually become true; prefer `for` loops when iteration bounds are known.
- **Unknown function** – only functions listed in the Built-In Functions table above are available.
- **Syntax error** – verify your AL syntax matches the examples in the Supported Syntax Overview.

## Limitations & Roadmap

- Procedure declarations, arrays, and complex types are not yet supported.
- `break` / `continue` tokens parse but currently exit without altering loop flow.
- `CreateDateTime(Date, Time)` returns the current DateTime rather than evaluating arguments.
- File I/O, HTTP, and external system calls are intentionally blocked.
- Some advanced AL features may not be fully supported—refer to the Supported Syntax Overview for details.

## Support & Contributions

The project follows AL-Go guidelines for development and deployment. For questions, feature requests, or to report issues, please refer to the repository documentation. For environment setup and CI/CD configuration, consult `.AL-Go/` and the repository root README.