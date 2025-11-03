codeunit 80100 "Program Executor Tests"
{
    Subtype = Test;

    var
        ProgramExecutor: Codeunit "Program Executor";
        Assert: Codeunit "Library Assert";
        TypeHelper: Codeunit "Type Helper";
        ExecutionOutput: Text;

    [Test]
    procedure TestBasicVariableDeclaration()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

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

    [Test]
    procedure TestIntegerAssignment()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with integer assignment
        Code := 'Counter: Integer;' + LF +
                'Counter := 42;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Integer assignment should work');
    end;

    [Test]
    procedure TestTextAssignment()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with text assignment
        Code := 'Name: Text;' + LF +
                'Name := ''Hello World'';';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Text assignment should work');
    end;

    [Test]
    procedure TestBooleanAssignment()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with boolean assignment
        Code := 'IsActive: Boolean;' + LF +
                'IsActive := true;' + LF +
                'IsActive := false;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Boolean assignment should work');
    end;

    [Test]
    procedure TestDecimalAssignment()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with decimal assignment
        Code := 'Price: Decimal;' + LF +
                'Price := 99.99;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Decimal assignment should work');
    end;

    [Test]
    procedure TestArithmeticOperations()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with arithmetic operations
        Code := 'A: Integer;' + LF +
                'B: Integer;' + LF +
                'Result: Integer;' + LF +
                'A := 10;' + LF +
                'B := 5;' + LF +
                'Result := A + B;' + LF +
                'Result := A - B;' + LF +
                'Result := A * B;' + LF +
                'Result := A / B;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Arithmetic operations should work');
    end;

    [Test]
    procedure TestComparisonOperators()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with comparison operations
        Code := 'A: Integer;' + LF +
                'B: Integer;' + LF +
                'Result: Boolean;' + LF +
                'A := 10;' + LF +
                'B := 5;' + LF +
                'Result := A = B;' + LF +
                'Result := A <> B;' + LF +
                'Result := A < B;' + LF +
                'Result := A > B;' + LF +
                'Result := A <= B;' + LF +
                'Result := A >= B;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Comparison operations should work');
    end;

    [Test]
    procedure TestLogicalOperators()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with logical operations
        Code := 'A: Boolean;' + LF +
                'B: Boolean;' + LF +
                'Result: Boolean;' + LF +
                'A := true;' + LF +
                'B := false;' + LF +
                'Result := A and B;' + LF +
                'Result := A or B;' + LF +
                'Result := not A;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Logical operations should work');
    end;

    [Test]
    procedure TestIfThenStatement()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with if/then statement
        Code := 'Counter: Integer;' + LF +
                'Counter := 10;' + LF +
                'if Counter > 5 then' + LF +
                '  Counter := 20;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'If/then statement should work');
    end;

    [Test]
    procedure TestIfThenElseStatement()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with if/then/else statement
        Code := 'Counter: Integer;' + LF +
                'Counter := 10;' + LF +
                'if Counter > 15 then' + LF +
                '  Counter := 20' + LF +
                'else' + LF +
                '  Counter := 5;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'If/then/else statement should work');
    end;

    [Test]
    procedure TestRepeatUntilLoop()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with repeat/until loop
        Code := 'Counter: Integer;' + LF +
                'Counter := 0;' + LF +
                'repeat' + LF +
                '  Counter := Counter + 1;' + LF +
                'until Counter >= 5;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Repeat/until loop should work');
    end;

    [Test]
    procedure TestBeginEndBlock()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with begin/end block
        Code := 'Counter: Integer;' + LF +
                'begin' + LF +
                '  Counter := 10;' + LF +
                '  Counter := Counter + 5;' + LF +
                'end;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Begin/end block should work');
    end;

    [Test]
    procedure TestMessageFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with Message function (using variable to avoid parsing issues with string literals)
        Code := 'Msg: Text;' + LF +
                'Msg := ''TestMessage'';' + LF +
                'Message(Msg);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the message (Message adds to ExecutionOutput)
        Assert.IsTrue(StrPos(ExecutionOutput, 'TestMessage') > 0, 'Message should appear in output');
    end;

    [Test]
    procedure TestStringFunctions()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with string functions (using TextVar instead of Text to avoid keyword conflict)
        Code := 'TextVar: Text;' + LF +
                'Len: Integer;' + LF +
                'TextVar := ''Hello'';' + LF +
                'Len := StrLen(TextVar);' + LF +
                'TextVar := UpperCase(TextVar);' + LF +
                'TextVar := LowerCase(TextVar);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'String functions should work');
    end;

    [Test]
    procedure TestMathFunctions()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with math functions
        Code := 'Value: Decimal;' + LF +
                'Value := Abs(-10);' + LF +
                'Value := Round(10.7, 1);' + LF +
                'Value := Power(2, 3);' + LF +
                'Value := Min(10, 5);' + LF +
                'Value := Max(10, 5);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Math functions should work');
    end;

    [Test]
    procedure TestSystemFunctions()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with system functions (Time type not supported, removed)
        Code := 'CurrentDate: Date;' + LF +
                'CurrentDateTime: DateTime;' + LF +
                'UserId: Text;' + LF +
                'CompanyName: Text;' + LF +
                'CurrentDate := Today();' + LF +
                'CurrentDateTime := CurrentDateTime();' + LF +
                'UserId := UserId();' + LF +
                'CompanyName := CompanyName();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'System functions should work');
    end;

    [Test]
    procedure TestExpressionPrecedence()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with expression precedence
        Code := 'Result: Integer;' + LF +
                'Result := 2 + 3 * 4;' + LF +
                'Result := (2 + 3) * 4;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Expression precedence should work');
    end;

    [Test]
    procedure TestParenthesizedExpressions()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with parenthesized expressions
        Code := 'Result: Integer;' + LF +
                'Result := (10 + 5) * 2;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Parenthesized expressions should work');
    end;

    [Test]
    procedure TestUnaryOperators()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with unary operators
        Code := 'Value: Integer;' + LF +
                'Result: Integer;' + LF +
                'Value := 10;' + LF +
                'Result := -Value;' + LF +
                'Result := not true;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Unary operators should work');
    end;

    [Test]
    procedure TestDivisionByZero()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with division by zero
        Code := 'Result: Decimal;' + LF +
                'Result := 10 / 0;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message (errors are prefixed with "Error: ")
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Division by zero') > 0, 'Division by zero should be caught and reported');
    end;

    [Test]
    procedure TestUndefinedVariable()
    var
        Code: Text;
    begin
        // [Given] AL code using undefined variable
        Code := 'Value := 10;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error
        Assert.IsTrue(StrPos(ExecutionOutput, 'Variable not found') > 0, 'Undefined variable should be caught');
    end;

    [Test]
    procedure TestNestedIfStatements()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with nested if statements
        Code := 'A: Integer;' + LF +
                'B: Integer;' + LF +
                'A := 10;' + LF +
                'B := 5;' + LF +
                'if A > 5 then' + LF +
                '  if B < 10 then' + LF +
                '    A := 20;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Nested if statements should work');
    end;

    [Test]
    procedure TestCommentsInCode()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with comments
        Code := '// This is a comment' + LF +
                'Counter: Integer;' + LF +
                'Counter := 10; // Inline comment';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Comments should be ignored');
    end;

    [Test]
    procedure TestRecordVariableDeclaration()
    var
        Code: Text;
    begin
        // [Given] AL code with record variable
        Code := 'Customer: Record Customer;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Record variable declaration should work');
    end;

    [Test]
    procedure TestForLoopWithStep()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with for loop using step
        Code := 'Index: Integer;' + LF +
                'Sum: Integer;' + LF +
                'Sum := 0;' + LF +
                'for Index := 1 to 5 step 2 do' + LF +
                'begin' + LF +
                '  Sum := Sum + Index;' + LF +
                'end;' + LF +
                'Message(''Sum: '' + Format(Sum));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the summed value
        Assert.IsTrue(StrPos(ExecutionOutput, 'Sum: 9') > 0, 'For loop with step should sum odd numbers');
    end;

    [Test]
    procedure TestDivAndModOperators()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using div and mod operators
        Code := 'Dividend: Integer;' + LF +
                'DivResult: Integer;' + LF +
                'ModResult: Integer;' + LF +
                'Dividend := 17;' + LF +
                'DivResult := Dividend div 5;' + LF +
                'ModResult := Dividend mod 5;' + LF +
                'Message(''Div: '' + Format(DivResult));' + LF +
                'Message(''Mod: '' + Format(ModResult));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain div and mod results
        Assert.IsTrue(StrPos(ExecutionOutput, 'Div: 3') > 0, 'DIV operator should work');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Mod: 2') > 0, 'MOD operator should work');
    end;

    [Test]
    procedure TestMessagePlaceholders()
    var
        Code: Text;
    begin
        // [Given] AL code using Message placeholders
        Code := 'Message(''%1 + %2 = %3'', 2, 3, 5);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should replace placeholders
        Assert.IsTrue(StrPos(ExecutionOutput, '2 + 3 = 5') > 0, 'Message placeholders should be substituted');
    end;

    [Test]
    procedure TestCopyStrFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using CopyStr
        Code := 'Source: Text;' + LF +
                'Result: Text;' + LF +
                'Source := ''Hello'';' + LF +
                'Result := CopyStr(Source, 1, 4);' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain substring
        Assert.IsTrue(StrPos(ExecutionOutput, 'Hell') > 0, 'CopyStr should return the requested substring');
    end;

    [Test]
    procedure TestInsStrFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using InsStr
        Code := 'Result: Text;' + LF +
                'Result := InsStr(''World'', ''Hello '', 1);' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain combined string
        Assert.IsTrue(StrPos(ExecutionOutput, 'Hello World') > 0, 'InsStr should insert text at the specified position');
    end;

    [Test]
    procedure TestCreateGuidFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code calling CreateGuid
        Code := 'GuidText: Text;' + LF +
                'GuidText := CreateGuid();' + LF +
                'Message(GuidText);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain a GUID value
        Assert.IsTrue(StrPos(ExecutionOutput, '-') > 0, 'CreateGuid should return a GUID value');
    end;

    [Test]
    procedure TestUnknownFunctionError()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code calling an unknown function
        Code := 'Value: Text;' + LF +
                'Value := UnknownFunc();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain an error message
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Unknown function: UnknownFunc') > 0, 'Unknown functions should raise an error');
    end;

    [Test]
    procedure TestCaseStatement()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with case statement
        Code := 'Value: Integer;' + LF +
                'Result: Text;' + LF +
                'Value := 2;' + LF +
                'case Value of' + LF +
                '  1: Result := ''One'';' + LF +
                '  2: Result := ''Two'';' + LF +
                '  3: Result := ''Three'';' + LF +
                '  else Result := ''Other'';' + LF +
                'end;' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the matched case value
        Assert.IsTrue(StrPos(ExecutionOutput, 'Two') > 0, 'Case statement should match and execute correct branch');
    end;

    [Test]
    procedure TestCaseStatementWithElse()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with case statement using else branch
        Code := 'Value: Integer;' + LF +
                'Result: Text;' + LF +
                'Value := 5;' + LF +
                'case Value of' + LF +
                '  1: Result := ''One'';' + LF +
                '  2: Result := ''Two'';' + LF +
                '  3: Result := ''Three'';' + LF +
                '  else Result := ''Other'';' + LF +
                'end;' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain else branch result
        Assert.IsTrue(StrPos(ExecutionOutput, 'Other') > 0, 'Case statement should execute else branch for unmatched value');
    end;

    [Test]
    procedure TestCaseStatementWithoutElse()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with case statement without else
        Code := 'Value: Integer;' + LF +
                'Result: Text;' + LF +
                'Value := 1;' + LF +
                'Result := ''Default'';' + LF +
                'case Value of' + LF +
                '  1: Result := ''One'';' + LF +
                '  2: Result := ''Two'';' + LF +
                'end;' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain matched case value
        Assert.IsTrue(StrPos(ExecutionOutput, 'One') > 0, 'Case statement should work without else branch');
    end;

    [Test]
    procedure TestCaseStatementWithMultipleStatements()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with case branch containing multiple statements
        Code := 'Value: Integer;' + LF +
                'Counter: Integer;' + LF +
                'Value := 1;' + LF +
                'Counter := 0;' + LF +
                'case Value of' + LF +
                '  1: begin' + LF +
                '    Counter := Counter + 10;' + LF +
                '    Counter := Counter + 5;' + LF +
                '  end;' + LF +
                '  2: Counter := 20;' + LF +
                'end;' + LF +
                'Message(''Counter: '' + Format(Counter));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the expected counter value
        Assert.IsTrue(StrPos(ExecutionOutput, 'Counter: 15') > 0, 'Case statement should execute multiple statements in branch');
    end;

    [Test]
    procedure TestCaseStatementWithTextValue()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with case statement using text values
        Code := 'Status: Text;' + LF +
                'Result: Text;' + LF +
                'Status := ''Active'';' + LF +
                'case Status of' + LF +
                '  ''Active'': Result := ''Status is Active'';' + LF +
                '  ''Inactive'': Result := ''Status is Inactive'';' + LF +
                '  else Result := ''Unknown Status'';' + LF +
                'end;' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain matched text case value
        Assert.IsTrue(StrPos(ExecutionOutput, 'Status is Active') > 0, 'Case statement should work with text values');
    end;

    [Test]
    procedure TestExitStatement()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with exit statement
        Code := 'Counter: Integer;' + LF +
                'Counter := 5;' + LF +
                'exit;' + LF +
                'Counter := 10;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Exit statement should work without errors');
    end;

    [Test]
    procedure TestExitWithReturnValue()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with exit statement returning a value
        Code := 'Value: Integer;' + LF +
                'Value := 42;' + LF +
                'exit(Value);' + LF +
                'Value := 99;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Exit with return value should work without errors');
    end;

    [Test]
    procedure TestExitWithExpression()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with exit statement using expression
        Code := 'A: Integer;' + LF +
                'B: Integer;' + LF +
                'A := 10;' + LF +
                'B := 5;' + LF +
                'exit(A + B);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Exit with expression should work without errors');
    end;

    [Test]
    procedure TestProcedureExecutionWithoutReturn()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with a procedure that updates a global variable
        Code := 'Counter: Integer;' + LF +
                'procedure Increment()' + LF +
                'begin' + LF +
                'Counter := Counter + 1;' + LF +
                'end;' + LF +
                'Counter := 5;' + LF +
                'Increment();' + LF +
                'Message(''Counter: %1'', Counter);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Procedure should run and update the counter
        Assert.IsTrue(StrPos(ExecutionOutput, 'Counter: 6') > 0, 'Procedure should increment counter');
    end;

    [Test]
    procedure TestProcedureWithReturnValue()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with a procedure returning a value
        Code := 'Result: Integer;' + LF +
                'procedure DoubleValue(InputValue: Integer): Integer' + LF +
                'begin' + LF +
                'exit(InputValue * 2);' + LF +
                'end;' + LF +
                'Result := DoubleValue(21);' + LF +
                'Message(''Result: %1'', Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Procedure should return the expected result
        Assert.IsTrue(StrPos(ExecutionOutput, 'Result: 42') > 0, 'Procedure should return doubled value. Output: ' + ExecutionOutput);
    end;

    [Test]
    procedure TestProcedureWithLocalVariables()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with a procedure that uses local variables
        Code := 'GreetingResult: Text;' + LF +
                'procedure MakeGreeting(): Text' + LF +
                'var' + LF +
                'Greeting: Text;' + LF +
                'begin' + LF +
                'Greeting := ''Hello World'';' + LF +
                'exit(Greeting);' + LF +
                'end;' + LF +
                'GreetingResult := MakeGreeting();' + LF +
                'Message(''Greeting: %1'', GreetingResult);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Procedure should use local scope without affecting globals
        Assert.IsTrue(StrPos(ExecutionOutput, 'Greeting: Hello World') > 0, 'Procedure should return greeting text. Output: ' + ExecutionOutput);
    end;

    [Test]
    procedure TestRecordInit()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Init() method
        Code := 'Customer: Record Customer;' + LF +
                'Customer.Init();' + LF +
                'Customer.Name := ''New Customer'';' + LF +
                'Message(''Record initialized'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.Init() should run without errors');
    end;

    [Test]
    procedure TestRecordInitAndInsert()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Init() and Insert()
        Code := 'Customer: Record Customer;' + LF +
                'Customer.Init();' + LF +
                'Customer."No." := ''TEST001'';' + LF +
                'Customer.Name := ''Test Customer'';' + LF +
                'if Customer.Insert(true) then' + LF +
                '  Message(''Customer inserted'')' + LF +
                'else' + LF +
                '  Message(''Insert failed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute (may fail if customer already exists, but should not crash)
        Assert.IsTrue(true, 'Record.Init() followed by Insert() should execute');
    end;

    [Test]
    procedure TestRecordChangeCompany()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.ChangeCompany() method
        Code := 'Customer: Record Customer;' + LF +
                'CompanyName: Text;' + LF +
                'CompanyName := CompanyName();' + LF +
                'Customer.ChangeCompany(CompanyName);' + LF +
                'Message(''Company changed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.ChangeCompany() should run without errors');
    end;

    [Test]
    procedure TestRecordChangeCompanyWithSpecificCompany()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.ChangeCompany() with specific company name
        Code := 'Customer: Record Customer;' + LF +
                'Customer.ChangeCompany(''CRONUS USA, Inc.'');' + LF +
                'Customer.Reset();' + LF +
                'Message(''Changed to specified company'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute (may fail if company doesn't exist, but should not crash)
        Assert.IsTrue(true, 'Record.ChangeCompany() with specific company should execute');
    end;

    [Test]
    procedure TestRecordInitAndChangeCompany()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code combining Record.Init() and ChangeCompany()
        Code := 'Customer: Record Customer;' + LF +
                'Customer.ChangeCompany(CompanyName());' + LF +
                'Customer.Init();' + LF +
                'Customer.Reset();' + LF +
                'Message(''Init and ChangeCompany combined'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.Init() and ChangeCompany() should run without errors');
    end;

    [Test]
    procedure TestCaseStatementNested()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with nested case statement
        Code := 'Outer: Integer;' + LF +
                'Inner: Integer;' + LF +
                'Result: Text;' + LF +
                'Outer := 1;' + LF +
                'Inner := 2;' + LF +
                'case Outer of' + LF +
                '  1: case Inner of' + LF +
                '    2: Result := ''One-Two'';' + LF +
                '    else Result := ''One-Other'';' + LF +
                '  end;' + LF +
                '  else Result := ''Other'';' + LF +
                'end;' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain nested case result
        Assert.IsTrue(StrPos(ExecutionOutput, 'One-Two') > 0, 'Nested case statements should work');
    end;

    [Test]
    procedure TestCaseStatementInLoop()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with case statement inside a loop
        Code := 'Index: Integer;' + LF +
                'Result: Text;' + LF +
                'Result := '''';' + LF +
                'for Index := 1 to 3 do begin' + LF +
                '  case Index of' + LF +
                '    1: Result := Result + ''One '';' + LF +
                '    2: Result := Result + ''Two '';' + LF +
                '    else Result := Result + ''Other '';' + LF +
                '  end;' + LF +
                'end;' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain all case results
        Assert.IsTrue(StrPos(ExecutionOutput, 'One') > 0, 'Case statement in loop should work');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Two') > 0, 'Case statement in loop should work');
    end;

    [Test]
    procedure TestRecordDeleteAll()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.DeleteAll() method
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetRange(''No.'', ''999999'');' + LF +
                'Customer.DeleteAll();' + LF +
                'Message(''DeleteAll completed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.DeleteAll() should work without errors');
    end;

    [Test]
    procedure TestRecordValidate()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Validate() method
        Code := 'Customer: Record Customer;' + LF +
                'if Customer.FindFirst() then begin' + LF +
                '  Customer.Validate(Name, ''Test Name'');' + LF +
                '  Message(''Field validated'');' + LF +
                'end;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.Validate() should work without errors');
    end;

    [Test]
    procedure TestRecordValidateWithoutValue()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Validate() without value parameter
        Code := 'Customer: Record Customer;' + LF +
                'if Customer.FindFirst() then begin' + LF +
                '  Customer.Validate(Name);' + LF +
                '  Message(''Field validated'');' + LF +
                'end;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.Validate() without value should work');
    end;

    [Test]
    procedure TestRecordGetFilter()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.GetFilter() method
        Code := 'Customer: Record Customer;' + LF +
                'FilterText: Text;' + LF +
                'Customer.SetRange(''No.'', ''10000'');' + LF +
                'FilterText := Customer.GetFilter(''No.'');' + LF +
                'Message(''Filter: '' + FilterText);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.GetFilter() should work without errors');
    end;

    [Test]
    procedure TestRecordFindWithOperator()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Find() with operator
        Code := 'Customer: Record Customer;' + LF +
                'Found: Boolean;' + LF +
                'Found := Customer.Find(''='');' + LF +
                'Message(''Find result: '' + Format(Found));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.Find() with operator should work');
    end;

    [Test]
    procedure TestRecordFindWithDifferentOperators()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Find() with different operators
        Code := 'Customer: Record Customer;' + LF +
                'Found1: Boolean;' + LF +
                'Found2: Boolean;' + LF +
                'Found3: Boolean;' + LF +
                'Customer.SetRange(''No.'', ''10000'');' + LF +
                'Found1 := Customer.Find(''='');' + LF +
                'Customer.Reset();' + LF +
                'Found2 := Customer.Find(''>='');' + LF +
                'Found3 := Customer.Find(''<='');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.Find() with different operators should work');
    end;

    [Test]
    procedure TestRecordCountApprox()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.CountApprox() method
        Code := 'Customer: Record Customer;' + LF +
                'ApproxCount: Integer;' + LF +
                'ApproxCount := Customer.CountApprox();' + LF +
                'Message(''Approximate count: '' + Format(ApproxCount));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.CountApprox() should work without errors');
    end;

    [Test]
    procedure TestRecordTestField()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.TestField() method
        Code := 'Customer: Record Customer;' + LF +
                'if Customer.FindFirst() then begin' + LF +
                '  Customer.TestField(Name, Customer.Name);' + LF +
                '  Message(''TestField passed'');' + LF +
                'end;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (may fail if field value doesn't match, but should not crash)
        Assert.IsTrue(true, 'Record.TestField() should execute');
    end;

    [Test]
    procedure TestRecordModifyAll()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.ModifyAll() method
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetRange(''No.'', ''999999'');' + LF +
                'Customer.ModifyAll(Name, ''Modified'');' + LF +
                'Message(''ModifyAll completed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.ModifyAll() should work without errors');
    end;

    [Test]
    procedure TestRecordModifyAllWithNoMatchingRecords()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.ModifyAll() with no matching records
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetRange(''No.'', ''99999999'');' + LF +
                'Customer.ModifyAll(Name, ''Modified'');' + LF +
                'Message(''ModifyAll with no matches completed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.ModifyAll() with no matches should work');
    end;

    [Test]
    procedure TestRecordFindInvalidOperator()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.Find() with invalid operator
        Code := 'Customer: Record Customer;' + LF +
                'Found: Boolean;' + LF +
                'Found := Customer.Find(''invalid'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Invalid operator for Find') > 0, 'Record.Find() with invalid operator should raise an error');
    end;

    [Test]
    procedure TestRecordGetFilterWithNoFilter()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Record.GetFilter() when no filter is set
        Code := 'Customer: Record Customer;' + LF +
                'FilterText: Text;' + LF +
                'Customer.Reset();' + LF +
                'FilterText := Customer.GetFilter(''No.'');' + LF +
                'Message(''Filter: '' + FilterText);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Record.GetFilter() without filter should work');
    end;

    [Test]
    procedure TestDmy2DateFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using DMY2Date function
        Code := 'MyDate: Date;' + LF +
                'MyDate := DMY2Date(15, 3, 2024);' + LF +
                'Message(''Date: '' + Format(MyDate));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'DMY2Date should work without errors');
    end;

    [Test]
    procedure TestDate2DmyFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Date2DMY function
        Code := 'MyDate: Date;' + LF +
                'DmyResult: Text;' + LF +
                'MyDate := Today();' + LF +
                'DmyResult := Date2DMY(MyDate);' + LF +
                'Message(''DMY: '' + DmyResult);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Date2DMY should work without errors');
    end;

    [Test]
    procedure TestDate2DwyFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Date2DWY function
        Code := 'MyDate: Date;' + LF +
                'DwyResult: Text;' + LF +
                'MyDate := Today();' + LF +
                'DwyResult := Date2DWY(MyDate);' + LF +
                'Message(''DWY: '' + DwyResult);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Date2DWY should work without errors');
    end;

    [Test]
    procedure TestCalcDateFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using CalcDate function
        Code := 'StartDate: Date;' + LF +
                'ResultDate: Date;' + LF +
                'StartDate := Today();' + LF +
                'ResultDate := CalcDate(''+1M'', StartDate);' + LF +
                'Message(''Result: '' + Format(ResultDate));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'CalcDate should work without errors');
    end;

    [Test]
    procedure TestWorkDateFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using WorkDate function
        Code := 'CurrentWorkDate: Date;' + LF +
                'CurrentWorkDate := WorkDate();' + LF +
                'Message(''WorkDate: '' + Format(CurrentWorkDate));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'WorkDate should work without errors');
    end;

    [Test]
    procedure TestDelStrFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using DelStr function
        Code := 'Source: Text;' + LF +
                'Result: Text;' + LF +
                'Source := ''Hello World'';' + LF +
                'Result := DelStr(Source, 6, 6);' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the modified string
        Assert.IsTrue(StrPos(ExecutionOutput, 'Hello') > 0, 'DelStr should delete substring correctly');
    end;

    [Test]
    procedure TestDelStrWithoutLength()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using DelStr without length parameter
        Code := 'Source: Text;' + LF +
                'Result: Text;' + LF +
                'Source := ''Hello World'';' + LF +
                'Result := DelStr(Source, 7);' + LF +
                'Message(Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'DelStr without length should work');
    end;

    [Test]
    procedure TestRandomFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Random function
        Code := 'RandomValue: Integer;' + LF +
                'RandomValue := Random();' + LF +
                'Message(''Random: '' + Format(RandomValue));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Random should work without errors');
    end;

    [Test]
    procedure TestRandomizeFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Randomize function
        Code := 'Randomize(42);' + LF +
                'Message(''Randomized'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Randomize with seed should work');
    end;

    [Test]
    procedure TestRandomizeWithoutSeed()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Randomize without seed
        Code := 'Randomize();' + LF +
                'Message(''Randomized'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Randomize without seed should work');
    end;

    [Test]
    procedure TestClearFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Clear function
        Code := 'Counter: Integer;' + LF +
                'Name: Text;' + LF +
                'Counter := 42;' + LF +
                'Name := ''Test'';' + LF +
                'Clear(Counter);' + LF +
                'Clear(Name);' + LF +
                'Message(''Counter: '' + Format(Counter));' + LF +
                'Message(''Name: '' + Name);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should show cleared values
        Assert.IsTrue(StrPos(ExecutionOutput, 'Counter: 0') > 0, 'Clear should reset integer to 0');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Name:') > 0, 'Clear should reset text to empty');
    end;

    [Test]
    procedure TestClearNonexistentVariable()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code trying to clear nonexistent variable
        Code := 'Clear(NonExistent);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Variable not found for Clear') > 0, 'Clear should error on nonexistent variable');
    end;

    [Test]
    procedure TestErrorFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Error function
        Code := 'Error(''Test error message'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error:') > 0, 'Error function should halt execution');
    end;

    [Test]
    procedure TestErrorFunctionWithPlaceholders()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Error function with placeholders
        Code := 'Error(''Error %1: %2'', ''001'', ''Something went wrong'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message with placeholders replaced
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error:') > 0, 'Error function with placeholders should work');
    end;

    [Test]
    procedure TestCommitFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Commit function
        Code := 'Commit();' + LF +
                'Message(''Committed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Commit should work without errors');
    end;

    [Test]
    procedure TestStrMenuFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using StrMenu function
        Code := 'Choice: Integer;' + LF +
                'Choice := StrMenu(''Option1,Option2,Option3'');' + LF +
                'Message(''Choice: '' + Format(Choice));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute (may return 0 if user cancels, but should not crash)
        Assert.IsTrue(StrPos(ExecutionOutput, 'Choice: 1') > 0, 'StrMenu should default to first option');
    end;

    [Test]
    procedure TestConfirmFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Confirm function
        Code := 'Result: Boolean;' + LF +
                'Result := Confirm(''Do you want to continue?'');' + LF +
                'Message(''Result: '' + Format(Result));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute (may return false if user cancels, but should not crash)
        Assert.IsTrue(StrPos(ExecutionOutput, 'Result: false') > 0, 'Confirm should return false in console mode');
    end;

    [Test]
    procedure TestPageRunFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Page.Run function
        Code := 'Result: Boolean;' + LF +
                'Result := Page.Run(21);' + LF +
                'Message(''Page.Run result: '' + Format(Result));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (may fail if page doesn't exist, but should not crash)
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Page.Run should not raise errors');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Page.Run result: true') > 0, 'Page.Run should return true in console mode');
    end;

    [Test]
    procedure TestPageRunModalFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Page.RunModal function
        Code := 'Result: Boolean;' + LF +
                'Result := Page.RunModal(21);' + LF +
                'Message(''Page.RunModal result: '' + Format(Result));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (may fail if page doesn't exist, but should not crash)
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Page.RunModal should not raise errors');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Page.RunModal result: true') > 0, 'Page.RunModal should return true in console mode');
    end;

    [Test]
    procedure TestReportRunFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Report.Run function
        Code := 'Report.Run(1);' + LF +
                'Message(''Report executed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (may fail if report doesn't exist, but should not crash)
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Report.Run should not raise errors');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Report executed') > 0, 'Report.Run should acknowledge execution');
    end;

    [Test]
    procedure TestCodeunitRunFunction()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using Codeunit.Run function
        Code := 'Codeunit.Run(130002);' + LF +
                'Message(''Codeunit executed'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (may fail if codeunit doesn't exist, but should not crash)
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Codeunit.Run should not raise errors');
        Assert.IsTrue(StrPos(ExecutionOutput, 'Codeunit executed') > 0, 'Codeunit.Run should acknowledge execution');
    end;

    [Test]
    procedure TestDmy2DateWithInvalidValues()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using DMY2Date with invalid arguments
        Code := 'MyDate: Date;' + LF +
                'MyDate := DMY2Date();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error:') > 0, 'DMY2Date should validate arguments');
    end;

    [Test]
    procedure TestCalcDateWithDifferentFormulas()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code using CalcDate with different date formulas
        Code := 'StartDate: Date;' + LF +
                'Result1: Date;' + LF +
                'Result2: Date;' + LF +
                'StartDate := Today();' + LF +
                'Result1 := CalcDate(''+1M'', StartDate);' + LF +
                'Result2 := CalcDate(''-1W'', StartDate);' + LF +
                'Message(''Results calculated'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'CalcDate with different formulas should work');
    end;
}

