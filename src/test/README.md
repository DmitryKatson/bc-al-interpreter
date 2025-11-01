# Test Code

This folder contains all test codeunits and test-related files for the Interactive AL Code Runner extension.

## Test Structure

The test suite is organized into three main test codeunits:

### 1. Program Executor Tests (Codeunit 50100)
Comprehensive unit tests for the core interpreter functionality:
- **Variable Management**: Variable declarations, assignments, and type handling
- **Expression Evaluation**: Arithmetic, comparison, and logical operators
- **Control Structures**: If/then/else statements, repeat/until loops, begin/end blocks
- **Built-in Functions**: Message(), string functions, math functions, system functions
- **Error Handling**: Division by zero, undefined variables, invalid syntax
- **Advanced Features**: Expression precedence, parenthesized expressions, unary operators, nested statements

### 2. Record Operations Tests (Codeunit 50101)
Tests for record-related operations:
- **Record Methods**: FindSet(), FindFirst(), FindLast(), Next(), Reset()
- **Record Filtering**: SetRange(), SetFilter()
- **Field Operations**: Field access, field assignment, quoted field names
- **Record Properties**: IsEmpty(), Count()
- **Record Loops**: Iterating through records with FindSet()
- **Multiple Records**: Handling multiple record variables

### 3. Script Execution Tests (Codeunit 50102)
End-to-end integration tests with complete scripts:
- **Complete Scripts**: Real-world script examples (customer listing, inventory analysis, sales calculations)
- **Complex Logic**: Conditional logic, nested loops, string manipulation
- **Mathematical Calculations**: Various arithmetic operations
- **Mixed Data Types**: Tests with multiple data types in one script
- **Error Scenarios**: Scripts that should produce errors

## Test Execution

Tests follow the AL Testability Framework guidelines:
- Use **given/when/then** structure in test naming and comments
- Use `Assert` statements for validations
- Group related tests logically in codeunits
- Each test is independent and can run in isolation

## Running Tests

Tests can be executed using:
1. **AL Test Tool** in Visual Studio Code
2. **Test Runner** page in Business Central
3. **AL-Go** CI/CD pipeline

## Test Coverage

The test suite covers:
- ✅ Variable declarations and assignments
- ✅ All data types (Integer, Text, Boolean, Decimal, Date, DateTime, Record, etc.)
- ✅ All operators (arithmetic, comparison, logical)
- ✅ Control structures (if/then/else, repeat/until, begin/end)
- ✅ Built-in functions (Message, StrLen, UpperCase, LowerCase, Format, etc.)
- ✅ Record operations (FindSet, SetRange, SetFilter, field access)
- ✅ Expression evaluation and precedence
- ✅ Error handling and validation
- ✅ Complete script execution scenarios

## Test Naming Convention

Tests follow this naming pattern:
- `Test[Feature][Scenario]()` - e.g., `TestIntegerAssignment()`
- `Test[Component][Operation]()` - e.g., `TestRecordFindSet()`
- `Test[CompleteScenario]()` - e.g., `TestCompleteCustomerListingScript()`

## Example Test Structure

```al
[Test]
procedure TestBasicVariableDeclaration()
var
    Code: Text;
    LF: Text[1];
begin
    LF := GetLineFeed();
    
    // [Given] AL code with variable declarations
    Code := 'Counter: Integer;' + LF +
            'Name: Text;' + LF +
            'IsActive: Boolean;' + LF +
            'Price: Decimal;';

    // [When] Execute the program
    ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

    // [Then] Program should execute without errors
    Assert.AreEqual('', ExecutionOutput, 'Program should execute without errors');
end;
```

## Notes

- Tests use `Char(10)` for line breaks in AL code strings to properly test tokenization
- Console-only mode (`true`) is used to prevent Message dialogs during test execution
- Some tests may have different results depending on the Business Central environment data

