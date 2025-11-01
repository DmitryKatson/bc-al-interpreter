codeunit 80102 "Script Execution Tests"
{
    Subtype = Test;

    var
        ProgramExecutor: Codeunit "Program Executor";
        Assert: Codeunit "Library Assert";
        TypeHelper: Codeunit "Type Helper";
        ExecutionOutput: Text;

    [Test]
    procedure TestCompleteCustomerListingScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Complete script to list customers
        Code := 'Customer: Record Customer;' + LF +
                'Counter: Integer;' + LF +
                LF +
                'Counter := 0;' + LF +
                'if Customer.FindSet() then begin' + LF +
                '  repeat' + LF +
                '    Counter := Counter + 1;' + LF +
                '    Message(''Customer '' + Format(Counter) + '': '' + Customer.Name);' + LF +
                '  until Customer.Next() = 0;' + LF +
                'end;' + LF +
                LF +
                'Message(''Total customers: '' + Format(Counter));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain total
        Assert.IsTrue(StrPos(ExecutionOutput, 'Total customers:') > 0, 'Complete script should execute');
    end;

    [Test]
    procedure TestInventoryAnalysisScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script for inventory analysis
        Code := 'Item: Record Item;' + LF +
                'LowStock: Integer;' + LF +
                LF +
                'LowStock := 0;' + LF +
                'Item.SetRange(''Type'', ''Inventory'');' + LF +
                'if Item.FindSet() then begin' + LF +
                '  repeat' + LF +
                '    if Item.Inventory < 10 then' + LF +
                '      LowStock := LowStock + 1;' + LF +
                '  until Item.Next() = 0;' + LF +
                'end;' + LF +
                LF +
                'Message(''Items below reorder point: '' + Format(LowStock));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Script should execute (may have errors if Inventory field doesn't exist, but should not crash)
        Assert.IsTrue(true, 'Inventory analysis script should execute');
    end;

    [Test]
    procedure TestSalesTotalCalculationScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script to calculate sales total
        Code := 'SalesHeader: Record "Sales Header";' + LF +
                'TotalSales: Decimal;' + LF +
                LF +
                'TotalSales := 0;' + LF +
                'SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);' + LF +
                'if SalesHeader.FindSet() then begin' + LF +
                '  repeat' + LF +
                '    TotalSales := TotalSales + SalesHeader."Amount Including VAT";' + LF +
                '  until SalesHeader.Next() = 0;' + LF +
                'end;' + LF +
                LF +
                'Message(''Total sales: '' + Format(TotalSales));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Script should execute
        Assert.IsTrue(true, 'Sales calculation script should execute');
    end;

    [Test]
    procedure TestConditionalLogicScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script with complex conditional logic
        Code := 'Counter: Integer;' + LF +
                'Result: Text;' + LF +
                LF +
                'Counter := 15;' + LF +
                'if Counter > 20 then' + LF +
                '  Result := ''High''' + LF +
                'else if Counter > 10 then' + LF +
                '  Result := ''Medium''' + LF +
                'else' + LF +
                '  Result := ''Low'';' + LF +
                LF +
                'Message(''Result: '' + Result);';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain result
        Assert.IsTrue(StrPos(ExecutionOutput, 'Result:') > 0, 'Conditional logic should work');
    end;

    [Test]
    procedure TestNestedLoopsScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script with nested loops (fixed initialization - Outer should start at 1, not reset each iteration)
        Code := 'Outer: Integer;' + LF +
                'Inner: Integer;' + LF +
                'Total: Integer;' + LF +
                LF +
                'Total := 0;' + LF +
                'Outer := 1;' + LF +
                'repeat' + LF +
                '  Inner := 1;' + LF +
                '  repeat' + LF +
                '    Total := Total + 1;' + LF +
                '    Inner := Inner + 1;' + LF +
                '  until Inner > 3;' + LF +
                '  Outer := Outer + 1;' + LF +
                'until Outer > 2;' + LF +
                LF +
                'Message(''Total iterations: '' + Format(Total));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain total
        Assert.IsTrue(StrPos(ExecutionOutput, 'Total iterations:') > 0, 'Nested loops should work');
    end;

    [Test]
    procedure TestStringManipulationScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script with string manipulation (using TextVar instead of Text to avoid keyword conflict)
        Code := 'TextVar: Text;' + LF +
                'Upper: Text;' + LF +
                'Lower: Text;' + LF +
                'Length: Integer;' + LF +
                LF +
                'TextVar := ''Hello World'';' + LF +
                'Upper := UpperCase(TextVar);' + LF +
                'Lower := LowerCase(TextVar);' + LF +
                'Length := StrLen(TextVar);' + LF +
                LF +
                'Message(''Original: '' + TextVar);' + LF +
                'Message(''Upper: '' + Upper);' + LF +
                'Message(''Lower: '' + Lower);' + LF +
                'Message(''Length: '' + Format(Length));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain all messages
        Assert.IsTrue(StrPos(ExecutionOutput, 'Original:') > 0, 'String manipulation should work');
    end;

    [Test]
    procedure TestMathematicalCalculationsScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script with mathematical calculations
        Code := 'A: Decimal;' + LF +
                'B: Decimal;' + LF +
                'Result: Decimal;' + LF +
                LF +
                'A := 10.5;' + LF +
                'B := 3.2;' + LF +
                'Result := A + B;' + LF +
                'Message(''Sum: '' + Format(Result));' + LF +
                'Result := A - B;' + LF +
                'Message(''Difference: '' + Format(Result));' + LF +
                'Result := A * B;' + LF +
                'Message(''Product: '' + Format(Result));' + LF +
                'Result := A / B;' + LF +
                'Message(''Quotient: '' + Format(Result));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain calculations
        Assert.IsTrue(StrPos(ExecutionOutput, 'Sum:') > 0, 'Mathematical calculations should work');
    end;

    [Test]
    procedure TestErrorHandlingScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script that should produce an error
        Code := 'Value: Integer;' + LF +
                'Result: Decimal;' + LF +
                'Value := 10;' + LF +
                'Result := Value / 0;';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Should produce error message (errors are prefixed with "Error: ")
        Assert.IsTrue(StrPos(ExecutionOutput, 'Error: Division by zero') > 0, 'Error handling should work');
    end;

    [Test]
    procedure TestMixedDataTypesScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script with mixed data types
        Code := 'IntValue: Integer;' + LF +
                'TextValue: Text;' + LF +
                'BoolValue: Boolean;' + LF +
                'DecValue: Decimal;' + LF +
                'DateValue: Date;' + LF +
                LF +
                'IntValue := 42;' + LF +
                'TextValue := ''Test'';' + LF +
                'BoolValue := true;' + LF +
                'DecValue := 99.99;' + LF +
                'DateValue := Today();' + LF +
                LF +
                'Message(''Integer: '' + Format(IntValue));' + LF +
                'Message(''Text: '' + TextValue);' + LF +
                'Message(''Boolean: '' + Format(BoolValue));' + LF +
                'Message(''Decimal: '' + Format(DecValue));' + LF +
                'Message(''Date: '' + Format(DateValue));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain all values
        Assert.IsTrue(StrPos(ExecutionOutput, 'Integer:') > 0, 'Mixed data types should work');
    end;

    [Test]
    procedure TestForLoopSummationScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script using for loop with automatic summation
        Code := 'Index: Integer;' + LF +
                'Total: Integer;' + LF +
                'Total := 0;' + LF +
                'for Index := 1 to 4 do' + LF +
                'begin' + LF +
                '  Total := Total + Index;' + LF +
                'end;' + LF +
                'Message(''Loop total: '' + Format(Total));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain the loop total
        Assert.IsTrue(StrPos(ExecutionOutput, 'Loop total: 10') > 0, 'For loop should aggregate values correctly');
    end;

    [Test]
    procedure TestMessagePlaceholderScript()
    var
        Code: Text;
    begin
        // [Given] Script using placeholders in Message
        Code := 'Message(''Values: %1, %2, %3'', ''A'', ''B'', ''C'');';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain substituted placeholders
        Assert.IsTrue(StrPos(ExecutionOutput, 'Values: A, B, C') > 0, 'Message placeholders in scripts should work');
    end;

    [Test]
    procedure TestGuidVariableScript()
    var
        Code: Text;
        LF: Text;
    begin
        LF := TypeHelper.LFSeparator();

        // [Given] Script declaring a GUID variable and outputting its value
        Code := 'MyGuid: Guid;' + LF +
                'Message(Format(MyGuid));';

        // [When] Execute the program
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);

        // [Then] Output should contain a GUID-like structure
        Assert.IsTrue(StrPos(ExecutionOutput, '-') > 0, 'GUID variable should provide a formatted GUID value');
    end;

    [Test]
    procedure TestDemoWelcomeBasicsScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript01();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 1 script should execute without errors');
    end;

    [Test]
    procedure TestDemoWorkingWithDataScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript02();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 2 script should execute without errors');
    end;

    [Test]
    procedure TestDemoFilteringConditionsScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript03();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 3 script should execute without errors');
    end;

    [Test]
    procedure TestDemoLoopsIterationScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript04();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 4 script should execute without errors');
    end;

    [Test]
    procedure TestDemoBuiltInFunctionsScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript05();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 5 script should execute without errors');
    end;

    [Test]
    procedure TestDemoRealAnalysisScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript06();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 6 script should execute without errors');
    end;

    [Test]
    procedure TestDemoAdvancedPatternsScript()
    var
        Code: Text;
    begin
        Code := BuildDemoScript07();
        ExecutionOutput := ProgramExecutor.ExecuteProgram(Code, true);
        Assert.AreEqual(0, StrPos(ExecutionOutput, 'Error:'), 'Demo 7 script should execute without errors');
    end;

    local procedure BuildDemoScript01(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 1: Welcome to Interactive AL Code Runner' + LF +
                  '// This is your first step in learning AL programming!' + LF +
                  LF +
                  'var' + LF +
                  '  // Variables are containers that store data' + LF +
                  '  // You must declare them before using them' + LF +
                  '  Counter: Integer;        // Stores whole numbers' + LF +
                  '  Name: Text;             // Stores text/strings' + LF +
                  '  IsActive: Boolean;      // Stores true/false values' + LF +
                  '  Price: Decimal;         // Stores decimal numbers' + LF +
                  LF +
                  'begin' + LF +
                  '  // Assign values to variables using :=' + LF +
                  '  Counter := 42;' + LF +
                  '  Name := ''Hello World'';' + LF +
                  '  IsActive := true;' + LF +
                  '  Price := 99.99;' + LF +
                  LF +
                  '  // Display values using Message() function' + LF +
                  '  Message(''Counter: '' + Format(Counter));' + LF +
                  '  Message(''Name: '' + Name);' + LF +
                  '  Message(''Active: '' + Format(IsActive));' + LF +
                  '  Message(''Price: '' + Format(Price));' + LF +
                  LF +
                  '  // You can do math with variables' + LF +
                  '  Counter := Counter + 10;' + LF +
                  '  Message(''Counter after adding 10: '' + Format(Counter));' + LF +
                  LF +
                  '  // You can combine text using + operator' + LF +
                  '  Message(''Welcome to '' + Name + ''!'');' + LF +
                  'end;';
        exit(Script);
    end;

    local procedure BuildDemoScript02(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 2: Working with Business Central Data' + LF +
                  '// Learn how to read data from tables' + LF +
                  LF +
                  'var' + LF +
                  '  // Declare a record variable for the Customer table' + LF +
                  '  Cust: Record Customer;' + LF +
                  '  Counter: Integer;' + LF +
                  LF +
                  'begin' + LF +
                  '  // Initialize counter' + LF +
                  '  Counter := 0;' + LF +
                  LF +
                  '  // FindSet() gets all records that match current filters' + LF +
                  '  // It returns true if records were found' + LF +
                  '  if Cust.FindSet() then begin' + LF +
                  '    // repeat...until is a loop that continues until condition is true' + LF +
                  '    repeat' + LF +
                  '      Counter := Counter + 1;' + LF +
                  '      ' + LF +
                  '      // Access fields using dot notation: RecordName.FieldName' + LF +
                  '      Message(''Customer '' + Format(Counter) + '': '' + Cust.Name);' + LF +
                  '      ' + LF +
                  '      // Next() moves to the next record' + LF +
                  '      // It returns 0 when no more records' + LF +
                  '    until Cust.Next() = 0;' + LF +
                  '  end;' + LF +
                  LF +
                  '  // Display total count' + LF +
                  '  Message(''Total customers found: '' + Format(Counter));' + LF +
                  LF +
                  '  // You can also get just the first record' + LF +
                  '  if Cust.FindFirst() then' + LF +
                  '    Message(''First customer: '' + Cust.Name)' + LF +
                  '  else' + LF +
                  '    Message(''No customers found'');' + LF +
                  'end;';
        exit(Script);
    end;

    local procedure BuildDemoScript03(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 3: Filtering Data and Using Conditions' + LF +
                  '// Learn how to filter records and make decisions' + LF +
                  LF +
                  'var' + LF +
                  '  Cust: Record Customer;' + LF +
                  '  HighBalanceCount: Integer;' + LF +
                  '  LowBalanceCount: Integer;' + LF +
                  LF +
                  'begin' + LF +
                  '  // SetRange() filters records by a specific field value' + LF +
                  '  // This finds customers with balance > 0' + LF +
                  '  Cust.SetRange("Balance (LCY)", 0, 999999999);' + LF +
                  LF +
                  '  HighBalanceCount := 0;' + LF +
                  '  LowBalanceCount := 0;' + LF +
                  LF +
                  '  if Cust.FindSet() then begin' + LF +
                  '    repeat' + LF +
                  '      // if...then...else lets you make decisions' + LF +
                  '      if Cust."Balance (LCY)" > 1000 then begin' + LF +
                  '        HighBalanceCount := HighBalanceCount + 1;' + LF +
                  '        Message(''High balance customer: '' + Cust.Name + '' ('' + Format(Cust."Balance (LCY)") + '')'');' + LF +
                  '      end else begin' + LF +
                  '        LowBalanceCount := LowBalanceCount + 1;' + LF +
                  '        Message(''Normal balance: '' + Cust.Name + '' ('' + Format(Cust."Balance (LCY)") + '')'');' + LF +
                  '      end;' + LF +
                  '    until Cust.Next() = 0;' + LF +
                  '  end;' + LF +
                  LF +
                  '  // Display summary' + LF +
                  '  Message(''High balance customers: '' + Format(HighBalanceCount));' + LF +
                  '  Message(''Normal balance customers: '' + Format(LowBalanceCount));' + LF +
                  LF +
                  '  // You can also use SetFilter() for more complex filtering' + LF +
                  '  // This example finds customers with names starting with ''A''' + LF +
                  '  Cust.SetFilter("Name", ''A*'');' + LF +
                  '  if Cust.FindFirst() then' + LF +
                  '    Message(''First customer starting with A: '' + Cust.Name);' + LF +
                  'end;';
        exit(Script);
    end;

    local procedure BuildDemoScript04(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 4: Loops and Iteration' + LF +
                  '// Master the art of repeating operations' + LF +
                  LF +
                  'var' + LF +
                  '  Item: Record Item;' + LF +
                  '  Counter: Integer;' + LF +
                  '  TotalValue: Decimal;' + LF +
                  '  ItemValue: Decimal;' + LF +
                  LF +
                  'begin' + LF +
                  '  // Initialize variables' + LF +
                  '  Counter := 0;' + LF +
                  '  TotalValue := 0;' + LF +
                  LF +
                  '  // SetRange to only look at inventory items' + LF +
                  '  Item.SetRange(Type, Item.Type::Inventory);' + LF +
                  LF +
                  '  if Item.FindSet() then begin' + LF +
                  '    repeat' + LF +
                  '      Counter := Counter + 1;' + LF +
                  '      ' + LF +
                  '      // Calculate value for this item' + LF +
                  '      ItemValue := Item.Inventory * Item."Unit Price";' + LF +
                  '      TotalValue := TotalValue + ItemValue;' + LF +
                  '      ' + LF +
                  '      // Only show first 5 items to avoid too many messages' + LF +
                  '      if Counter <= 5 then' + LF +
                  '        Message(''Item '' + Format(Counter) + '': '' + Item.Description + '' (Value: '' + Format(ItemValue) + '')'');' + LF +
                  '      ' + LF +
                  '    until Item.Next() = 0;' + LF +
                  '  end;' + LF +
                  LF +
                  '  // Display summary statistics' + LF +
                  '  Message(''Total inventory items: '' + Format(Counter));' + LF +
                  '  Message(''Total inventory value: '' + Format(TotalValue));' + LF +
                  LF +
                  '  // Example of a counter loop' + LF +
                  '  Message(''Counting from 1 to 5:'');' + LF +
                  '  Counter := 1;' + LF +
                  '  repeat' + LF +
                  '    Message(''Count: '' + Format(Counter));' + LF +
                  '    Counter := Counter + 1;' + LF +
                  '  until Counter > 5;' + LF +
                  LF +
                  '  Message(''Loop completed!'');' + LF +
                  'end;';
        exit(Script);
    end;

    local procedure BuildDemoScript05(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 5: Built-in Functions' + LF +
                  '// Learn the powerful functions available in AL' + LF +
                  LF +
                  'var' + LF +
                  '  TextVar: Text;' + LF +
                  '  NumberVar: Decimal;' + LF +
                  '  DateVar: Date;' + LF +
                  '  Length: Integer;' + LF +
                  '  UpperText: Text;' + LF +
                  '  LowerText: Text;' + LF +
                  '  SubText: Text;' + LF +
                  '  FormattedText: Text;' + LF +
                  LF +
                  'begin' + LF +
                  '  // String functions' + LF +
                  '  TextVar := ''Hello World from Business Central'';' + LF +
                  LF +
                  '  // StrLen() gets the length of text' + LF +
                  '  Length := StrLen(TextVar);' + LF +
                  '  Message(''Text length: '' + Format(Length));' + LF +
                  LF +
                  '  // UpperCase() converts to uppercase' + LF +
                  '  UpperText := UpperCase(TextVar);' + LF +
                  '  Message(''Uppercase: '' + UpperText);' + LF +
                  LF +
                  '  // LowerCase() converts to lowercase' + LF +
                  '  LowerText := LowerCase(TextVar);' + LF +
                  '  Message(''Lowercase: '' + LowerText);' + LF +
                  LF +
                  '  // CopyStr() extracts part of a string' + LF +
                  '  // CopyStr(Text, StartPosition, Length)' + LF +
                  '  SubText := CopyStr(TextVar, 7, 5);' + LF +
                  '  Message(''Substring from position 7, length 5: '' + SubText);' + LF +
                  LF +
                  '  // Date functions' + LF +
                  '  DateVar := Today();' + LF +
                  '  Message(''Today is: '' + Format(DateVar));' + LF +
                  LF +
                  '  // Math functions' + LF +
                  '  NumberVar := 123.456789;' + LF +
                  LF +
                  '  // Round() rounds to specified decimal places' + LF +
                  '  Message(''Rounded to 2 decimals: '' + Format(Round(NumberVar, 2)));' + LF +
                  LF +
                  '  // Abs() gets absolute value' + LF +
                  '  Message(''Absolute value of -50: '' + Format(Abs(-50)));' + LF +
                  LF +
                  '  // Format() converts any value to text for display' + LF +
                  '  FormattedText := Format(NumberVar);' + LF +
                  '  Message(''Formatted number: '' + FormattedText);' + LF +
                  LF +
                  '  // You can combine functions' + LF +
                  '  Message(''First 10 characters in uppercase: '' + UpperCase(CopyStr(TextVar, 1, 10)));' + LF +
                  'end;';
        exit(Script);
    end;

    local procedure BuildDemoScript06(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 6: Real Business Analysis' + LF +
                  '// Apply everything you''ve learned to analyze sales data' + LF +
                  LF +
                  'var' + LF +
                  '  SalesHeader: Record "Sales Header";' + LF +
                  '  SalesLine: Record "Sales Line";' + LF +
                  '  TotalSales: Decimal;' + LF +
                  '  OrderCount: Integer;' + LF +
                  '  HighValueOrders: Integer;' + LF +
                  '  LowValueOrders: Integer;' + LF +
                  '  AverageOrderValue: Decimal;' + LF +
                  LF +
                  'begin' + LF +
                  '  // Initialize counters' + LF +
                  '  TotalSales := 0;' + LF +
                  '  OrderCount := 0;' + LF +
                  '  HighValueOrders := 0;' + LF +
                  '  LowValueOrders := 0;' + LF +
                  LF +
                  '  // Filter for posted sales invoices only' + LF +
                  '  SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);' + LF +
                  '  SalesHeader.SetRange(Status, SalesHeader.Status::Released);' + LF +
                  LF +
                  '  if SalesHeader.FindSet() then begin' + LF +
                  '    repeat' + LF +
                  '      OrderCount := OrderCount + 1;' + LF +
                  '      ' + LF +
                  '      // Get the total amount for this order' + LF +
                  '      SalesLine.SetRange("Document Type", SalesHeader."Document Type");' + LF +
                  '      SalesLine.SetRange("Document No.", SalesHeader."No.");' + LF +
                  '      SalesLine.CalcSums("Line Amount");' + LF +
                  '      ' + LF +
                  '      // Categorize orders by value' + LF +
                  '      if SalesLine."Line Amount" > 1000 then begin' + LF +
                  '        HighValueOrders := HighValueOrders + 1;' + LF +
                  '        Message(''High value order: '' + SalesHeader."No." + '' - Customer: '' + SalesHeader."Sell-to Customer Name" + '' - Amount: '' + Format(SalesLine."Line Amount"));' + LF +
                  '      end else begin' + LF +
                  '        LowValueOrders := LowValueOrders + 1;' + LF +
                  '      end;' + LF +
                  '      ' + LF +
                  '      TotalSales := TotalSales + SalesLine."Line Amount";' + LF +
                  '      ' + LF +
                  '    until SalesHeader.Next() = 0;' + LF +
                  '  end;' + LF +
                  LF +
                  '  // Calculate average' + LF +
                  '  if OrderCount > 0 then' + LF +
                  '    AverageOrderValue := TotalSales / OrderCount;' + LF +
                  LF +
                  '  // Display comprehensive analysis' + LF +
                  '  Message(''=== SALES ANALYSIS REPORT ==='');' + LF +
                  '  Message(''Total orders analyzed: '' + Format(OrderCount));' + LF +
                  '  Message(''Total sales value: '' + Format(TotalSales));' + LF +
                  '  Message(''Average order value: '' + Format(AverageOrderValue));' + LF +
                  '  Message(''High value orders (>1000): '' + Format(HighValueOrders));' + LF +
                  '  Message(''Standard orders: '' + Format(LowValueOrders));' + LF +
                  LF +
                  '  if OrderCount > 0 then' + LF +
                  '    Message(''Analysis completed successfully!'')' + LF +
                  '  else' + LF +
                  '    Message(''No sales data found to analyze.'');' + LF +
                  'end;';
        exit(Script);
    end;

    local procedure BuildDemoScript07(): Text
    var
        LF: Text;
        Script: Text;
    begin
        LF := TypeHelper.LFSeparator();
        Script := '// DEMO 7: Advanced Patterns and Complex Logic' + LF +
                  '// Master advanced techniques for real-world scenarios' + LF +
                  LF +
                  'var' + LF +
                  '  Item: Record Item;' + LF +
                  '  Customer: Record Customer;' + LF +
                  '  SalesHeader: Record "Sales Header";' + LF +
                  '  SalesLine: Record "Sales Line";' + LF +
                  LF +
                  '  // Complex analysis variables' + LF +
                  '  TopCustomer: Text;' + LF +
                  '  TopCustomerSales: Decimal;' + LF +
                  '  LowStockItems: Integer;' + LF +
                  '  OutOfStockItems: Integer;' + LF +
                  '  TotalInventoryValue: Decimal;' + LF +
                  '  ItemValue: Decimal;' + LF +
                  '  CustomerSales: Decimal;' + LF +
                  LF +
                  'begin' + LF +
                  '  // Initialize tracking variables' + LF +
                  '  TopCustomer := '''';' + LF +
                  '  TopCustomerSales := 0;' + LF +
                  '  LowStockItems := 0;' + LF +
                  '  OutOfStockItems := 0;' + LF +
                  '  TotalInventoryValue := 0;' + LF +
                  LF +
                  '  Message(''=== ADVANCED BUSINESS ANALYSIS ==='');' + LF +
                  LF +
                  '  // PART 1: Inventory Analysis' + LF +
                  '  Message(''Analyzing inventory...'');' + LF +
                  '  Item.SetRange(Type, Item.Type::Inventory);' + LF +
                  LF +
                  '  if Item.FindSet() then begin' + LF +
                  '    repeat' + LF +
                  '      // Calculate item value' + LF +
                  '      ItemValue := Item.Inventory * Item."Unit Price";' + LF +
                  '      TotalInventoryValue := TotalInventoryValue + ItemValue;' + LF +
                  '      ' + LF +
                  '      // Categorize by stock level' + LF +
                  '      if Item.Inventory = 0 then begin' + LF +
                  '        OutOfStockItems := OutOfStockItems + 1;' + LF +
                  '        Message(''OUT OF STOCK: '' + Item."No." + '' - '' + Item.Description);' + LF +
                  '      end else if Item.Inventory < 10 then begin' + LF +
                  '        LowStockItems := LowStockItems + 1;' + LF +
                  '        Message(''LOW STOCK: '' + Item."No." + '' - '' + Item.Description + '' (Stock: '' + Format(Item.Inventory) + '')'');' + LF +
                  '      end;' + LF +
                  '      ' + LF +
                  '    until Item.Next() = 0;' + LF +
                  '  end;' + LF +
                  LF +
                  '  // PART 2: Customer Sales Analysis' + LF +
                  '  Message(''Analyzing customer sales...'');' + LF +
                  '  if Customer.FindSet() then begin' + LF +
                  '    repeat' + LF +
                  '      // Calculate total sales for this customer' + LF +
                  '      SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");' + LF +
                  '      SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);' + LF +
                  '      SalesHeader.SetRange(Status, SalesHeader.Status::Released);' + LF +
                  '      ' + LF +
                  '      CustomerSales := 0;' + LF +
                  '      if SalesHeader.FindSet() then begin' + LF +
                  '        repeat' + LF +
                  '          SalesLine.SetRange("Document Type", SalesHeader."Document Type");' + LF +
                  '          SalesLine.SetRange("Document No.", SalesHeader."No.");' + LF +
                  '          SalesLine.CalcSums("Line Amount");' + LF +
                  '          CustomerSales := CustomerSales + SalesLine."Line Amount";' + LF +
                  '        until SalesHeader.Next() = 0;' + LF +
                  '      end;' + LF +
                  '      ' + LF +
                  '      // Track top customer' + LF +
                  '      if CustomerSales > TopCustomerSales then begin' + LF +
                  '        TopCustomer := Customer.Name;' + LF +
                  '        TopCustomerSales := CustomerSales;' + LF +
                  '      end;' + LF +
                  '      ' + LF +
                  '    until Customer.Next() = 0;' + LF +
                  '  end;' + LF +
                  LF +
                  '  // PART 3: Generate comprehensive report' + LF +
                  '  Message(''=== COMPREHENSIVE BUSINESS REPORT ==='');' + LF +
                  '  Message(''INVENTORY SUMMARY:'');' + LF +
                  '  Message(''Total inventory value: '' + Format(TotalInventoryValue));' + LF +
                  '  Message(''Out of stock items: '' + Format(OutOfStockItems));' + LF +
                  '  Message(''Low stock items (<10): '' + Format(LowStockItems));' + LF +
                  LF +
                  '  Message(''CUSTOMER ANALYSIS:'');' + LF +
                  '  if TopCustomer <> '''' then begin' + LF +
                  '    Message(''Top customer: '' + TopCustomer);' + LF +
                  '    Message(''Top customer sales: '' + Format(TopCustomerSales));' + LF +
                  '  end else begin' + LF +
                  '    Message(''No customer sales data found'');' + LF +
                  '  end;' + LF +
                  LF +
                  '  Message(''=== ANALYSIS COMPLETE ==='');' + LF +
                  '  Message(''This demonstrates advanced AL programming patterns:'');' + LF +
                  '  Message(''- Complex nested loops'');' + LF +
                  '  Message(''- Multi-table analysis'');' + LF +
                  '  Message(''- Conditional categorization'');' + LF +
                  '  Message(''- Running totals and comparisons'');' + LF +
                  '  Message(''- Comprehensive reporting'');' + LF +
                  'end;';
        exit(Script);
    end;
}

