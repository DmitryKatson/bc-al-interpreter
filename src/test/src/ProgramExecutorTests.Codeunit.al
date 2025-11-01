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
}

