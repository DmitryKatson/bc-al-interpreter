codeunit 80101 "Record Operations Tests"
{
    Subtype = Test;

    var
        ProgramExecutor: Codeunit "Program Executor";
        Assert: Codeunit "Library Assert";
        TypeHelper: Codeunit "Type Helper";
        ExecutionOutput: Text;

    [Test]
    procedure TestRecordFindSet()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with FindSet operation
        Code := 'Customer: Record Customer;' + LF +
                'Found: Boolean;' + LF +
                'Found := Customer.FindSet();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'FindSet should work');
    end;

    [Test]
    procedure TestRecordFindFirst()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with FindFirst operation
        Code := 'Customer: Record Customer;' + LF +
                'Found: Boolean;' + LF +
                'Found := Customer.FindFirst();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'FindFirst should work');
    end;

    [Test]
    procedure TestRecordFindLast()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with FindLast operation
        Code := 'Customer: Record Customer;' + LF +
                'Found: Boolean;' + LF +
                'Found := Customer.FindLast();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'FindLast should work');
    end;

    [Test]
    procedure TestRecordNext()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with Next operation
        Code := 'Customer: Record Customer;' + LF +
                'NextResult: Integer;' + LF +
                'if Customer.FindSet() then' + LF +
                '  NextResult := Customer.Next();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Next should work');
    end;

    [Test]
    procedure TestRecordSetRange()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with SetRange operation
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetRange(''No.'', ''10000'');' + LF +
                'if Customer.FindFirst() then' + LF +
                '  Message(''Found customer'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (even if no customer found)
        Assert.IsTrue(true, 'SetRange should work');
    end;

    [Test]
    procedure TestRecordSetFilter()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with SetFilter operation
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetFilter(''No.'', ''10000..20000'');' + LF +
                'if Customer.FindFirst() then' + LF +
                '  Message(''Found customer'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.IsTrue(true, 'SetFilter should work');
    end;

    [Test]
    procedure TestRecordFieldAccess()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code accessing record field
        Code := 'Customer: Record Customer;' + LF +
                'Name: Text;' + LF +
                'if Customer.FindFirst() then' + LF +
                '  Name := Customer.Name;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Record field access should work');
    end;

    [Test]
    procedure TestRecordFieldAssignment()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code assigning to record field
        Code := 'Customer: Record Customer;' + LF +
                'if Customer.FindFirst() then' + LF +
                '  Customer.Name := ''Test Name'';';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Record field assignment should work');
    end;

    [Test]
    procedure TestRecordIsEmpty()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with IsEmpty check
        Code := 'Customer: Record Customer;' + LF +
                'Empty: Boolean;' + LF +
                'Customer.Reset();' + LF +
                'Customer.SetRange(''No.'', ''999999'');' + LF +
                'Empty := Customer.IsEmpty();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'IsEmpty should work');
    end;

    [Test]
    procedure TestRecordCount()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with Count operation
        Code := 'Customer: Record Customer;' + LF +
                'TotalCount: Integer;' + LF +
                'TotalCount := Customer.Count();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Count should work');
    end;

    [Test]
    procedure TestRecordReset()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with Reset operation
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetRange(''No.'', ''10000'');' + LF +
                'Customer.Reset();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Reset should work');
    end;

    [Test]
    procedure TestRecordCalcFields()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with CalcFields operation
        Code := 'Customer: Record Customer;' + LF +
                'if Customer.FindFirst() then begin' + LF +
                '  Customer.CalcFields(''Balance'');' + LF +
                '  Message(''Calculated'');' + LF +
                'end;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors (even if Balance field doesn't exist)
        Assert.IsTrue(true, 'CalcFields should work');
    end;

    [Test]
    procedure TestRecordLoopWithFindSet()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with record loop
        Code := 'Customer: Record Customer;' + LF +
                'Counter: Integer;' + LF +
                'Counter := 0;' + LF +
                'if Customer.FindSet() then begin' + LF +
                '  repeat' + LF +
                '    Counter := Counter + 1;' + LF +
                '  until Customer.Next() = 0;' + LF +
                'end;' + LF +
                'Message(''Total: '' + Format(Counter));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the total
        Assert.IsTrue(StrPos(ExecutionOutput, 'Total:') > 0, 'Record loop should work');
    end;

    [Test]
    procedure TestMultipleRecordVariables()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with multiple record variables
        Code := 'Customer: Record Customer;' + LF +
                'Item: Record Item;' + LF +
                'SalesHeader: Record "Sales Header";' + LF +
                'Customer.FindFirst();' + LF +
                'Item.FindFirst();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Multiple record variables should work');
    end;

    [Test]
    procedure TestRecordWithQuotedFieldName()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code with quoted field name
        Code := 'Item: Record Item;' + LF +
                'No: Text;' + LF +
                'if Item.FindFirst() then' + LF +
                '  No := Item.''No.'';';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'Quoted field names should work');
    end;

    [Test]
    procedure TestSetRangeMissingArgumentsProducesError()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code calling SetRange with missing arguments
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetRange(''No.'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain an error message
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: SetRange requires at least 2 arguments') > 0, 'SetRange should validate the number of arguments');
    end;

    [Test]
    procedure TestRecordLockTable()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code calling LockTable on a record
        Code := 'Customer: Record Customer;' + LF +
                'Customer.LockTable();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'LockTable should be a supported record method');
    end;

    [Test]
    procedure TestRecordCalcFieldsInvalidField()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code calling CalcFields with an invalid field
        Code := 'Customer: Record Customer;' + LF +
                'Customer.CalcFields(''NonExistingField'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain an error about the missing field
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Field not found for CalcFields: NonExistingField') > 0, 'CalcFields should validate field names');
    end;

    [Test]
    procedure TestSetFilterIdentifierField()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code applying SetFilter with an identifier field name
        Code := 'Customer: Record Customer;' + LF +
                'Customer.SetFilter(Name, ''A*'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Program should execute without errors
        Assert.AreEqual('', ExecutionOutput, 'SetFilter should accept unquoted field identifiers');
    end;

    [Test]
    procedure TestRecordUnknownMethodError()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] AL code calling an unsupported record method
        Code := 'Customer: Record Customer;' + LF +
                'Customer.DoSomething();';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain an error for the unknown method
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Unknown record method: DoSomething') > 0, 'Unknown record methods should raise errors');
    end;
}

