codeunit 50000 "Interactive Code Runner Impl"
{
    var
        ALCodeText: Text;
        ExecutionOutput: Text;
        OutputStyle: Text;
        HelpContent: Text;

    procedure LoadSampleCode(): Text
    var
        SampleCode: Text;
        TypeHelper: Codeunit "Type Helper";
        LF: Text[1];
    begin
        LF := TypeHelper.LFSeparator();

        SampleCode := '// Sample: List all customers' + LF +
                      'Cust: Record Customer;' + LF +
                      'Counter: Integer;' + LF +
                      LF +
                      'Counter := 0;' + LF +
                      'if Cust.FindSet() then begin' + LF +
                      '  repeat' + LF +
                      '    Counter := Counter + 1;' + LF +
                      '    Message(Cust.Name);' + LF +
                      '  until Cust.Next() = 0;' + LF +
                      'end;' + LF +
                      LF +
                      'Message(''Total customers: '' + Format(Counter));' + LF +
                      LF +
                      '// Query example' + LF +
                      'query CustomerList' + LF +
                      '{' + LF +
                      '  dataitem(Customer; Customer)' + LF +
                      '  {' + LF +
                      '    column(NoColumn; ""No."")' + LF +
                      '    column(NameColumn; Name)' + LF +
                      '  }' + LF +
                      '}' + LF +
                      LF +
                      'ExecuteQuery(''CustomerList'');';

        exit(SampleCode);
    end;

    procedure GetHelpContent(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        LF: Text;
        HelpText: Text;
    begin
        LF := TypeHelper.LFSeparator();

        HelpText := '=== Interactive AL Code Runner - Quick Reference ===' + LF + LF +
                    'Welcome! This tool lets you write and execute AL code directly in Business Central.' + LF +
                    'No compilation or deployment required - perfect for quick diagnostics and learning!' + LF + LF +

                    '--- Data Types ---' + LF +
                    'Integer, Decimal, Text, Code (incl. Code[20]), Boolean, Date, DateTime, Duration' + LF +
                    'Char, BigText, GUID, Option, Blob, Record <Table>' + LF + LF +

                    '--- Variable Declaration ---' + LF +
                    'Counter: Integer;' + LF +
                    'CustomerName: Text;' + LF +
                    'IsActive: Boolean;' + LF +
                    'Price: Decimal;' + LF +
                    'Customer: Record Customer;' + LF + LF +

                    '--- Procedures ---' + LF +
                    'procedure Update(var Amount: Decimal)' + LF +
                    'begin' + LF +
                    '  Amount := Amount + 1;' + LF +
                    'end;' + LF + LF +

                    '--- Control Flow ---' + LF +
                    'if Condition then ... [else ...];' + LF +
                    'repeat ... until Condition;' + LF +
                    'for Index := 1 to 10 [step 2] do ...;' + LF +
                    'while Condition do ...;' + LF +
                    'begin ... end;' + LF +
                    'exit; break; continue;' + LF + LF +

                    '--- Record Operations ---' + LF +
                    'Customer.FindSet(); Customer.FindFirst(); Customer.FindLast();' + LF +
                    'Customer.Next(); Customer.Reset();' + LF +
                    'Customer.SetRange("No.", 10000);' + LF +
                    'Customer.SetFilter(Name, ''A*'');' + LF +
                    'Customer.CalcFields(Balance); Customer.CalcSums(Amount);' + LF +
                    'Customer.IsEmpty(); Customer.Count();' + LF +
                    'Customer.Insert(true); Customer.Modify(true); Customer.Delete(true);' + LF + LF +

                    '--- Queries ---' + LF +
                    'query CustomerList { dataitem(Customer; Customer) { column(NoColumn; ""No.""); column(NameColumn; Name); } }' + LF +
                    'ExecuteQuery(''CustomerList''); // Runs the defined query and prints rows' + LF + LF +

                    '--- String Functions ---' + LF +
                    'StrLen(Text), CopyStr(Text, Start, Length), UpperCase(Text), LowerCase(Text)' + LF +
                    'StrPos(Text, SubText), DelChr(Text, Where, Which), InsStr(Text, Insert, Position)' + LF + LF +

                    '--- Math Functions ---' + LF +
                    'Abs(Value), Round(Value, Precision), Power(Base, Exponent)' + LF +
                    'Min(Val1, Val2), Max(Val1, Val2)' + LF + LF +

                    '--- System Functions ---' + LF +
                    'Message(''Text %1'', Arg);  // Supports %1-%9 placeholders' + LF +
                    'Format(Value), Today(), Time(), CurrentDateTime()' + LF +
                    'UserId(), CompanyName(), CreateGuid()' + LF + LF +

                    '--- Common Patterns ---' + LF +
                    '// Loop through records:' + LF +
                    'if Customer.FindSet() then' + LF +
                    '  repeat' + LF +
                    '    Message(Customer.Name);' + LF +
                    '  until Customer.Next() = 0;' + LF + LF +

                    '--- Runtime Limits ---' + LF +
                    'Up to 100 variables, 10 record references per script' + LF +
                    'Loops automatically stop after 10,000 iterations' + LF +
                    'Execution stops at the first error encountered' + LF + LF +

                    'Tip: Use the "Load Sample" action to see working examples!' + LF +
                    'Tip: Enable "Show output in console" to suppress GUI dialogs.';

        exit(HelpText);
    end;

    procedure SaveCodeToBlob(var InteractiveProgram: Record "Interactive Program"; CodeText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(InteractiveProgram."AL Code");
        InteractiveProgram."AL Code".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(CodeText);
    end;

    procedure LoadCodeFromBlob(var InteractiveProgram: Record "Interactive Program"): Text
    var
        InStream: InStream;
        TypeHelper: Codeunit "Type Helper";
        CodeText: Text;
    begin
        InteractiveProgram.CalcFields("AL Code");
        if not InteractiveProgram."AL Code".HasValue then
            exit('');

        InteractiveProgram."AL Code".CreateInStream(InStream, TextEncoding::UTF8);
        CodeText := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());

        exit(CodeText);
    end;

    procedure EnsureRecordExists(var InteractiveProgram: Record "Interactive Program"): Boolean
    begin
        if not InteractiveProgram.Get(InteractiveProgram."ID") then begin
            InteractiveProgram.Init();
            InteractiveProgram.Insert(true);
            exit(true);
        end;
        exit(false);
    end;

    procedure GenerateDefaultName(var InteractiveProgram: Record "Interactive Program")
    begin
        if InteractiveProgram."Name" = '' then
            InteractiveProgram."Name" := 'Program ' + Format(InteractiveProgram."ID");
    end;

    procedure LoadDemoScriptsFromResources()
    var
        InteractiveProgram: Record "Interactive Program";
        NewProgram: Record "Interactive Program";
        Resources: List of [Text];
        i: Integer;
        ResourceName: Text;
        ResourceContent: Text;
        ProgramName: Text;
        ProgramExists: Boolean;
    begin
        // Check if demo scripts are already loaded
        InteractiveProgram.SetRange("Is Demo", true);
        if not InteractiveProgram.IsEmpty then
            exit; // Demo scripts already loaded

        // Get all resources from the demos folder
        Resources := NavApp.ListResources();

        for i := 1 to Resources.Count() do begin
            ResourceName := Resources.Get(i);

            // ResourceName is the file name; resourceFolders handles scoping
            ResourceContent := NavApp.GetResourceAsText(ResourceName);

            if ResourceContent <> '' then begin
                // Extract program name from content (first line after // DEMO)
                ProgramName := ExtractProgramName(ResourceContent);

                // Check if this demo already exists
                InteractiveProgram.SetRange("Name", ProgramName);
                ProgramExists := not InteractiveProgram.IsEmpty;
                InteractiveProgram.SetRange("Name");

                if not ProgramExists then begin
                    // Create new program record
                    NewProgram.Reset();
                    NewProgram.Init();
                    // Manually assign next available ID to avoid PK conflicts during install
                    NewProgram."ID" := GetNextProgramId();
                    NewProgram."Name" := ProgramName;
                    NewProgram."Is Demo" := true;
                    NewProgram.Insert(false);

                    // Save code to BLOB
                    SaveCodeToBlob(NewProgram, ResourceContent);
                    NewProgram.Modify(true);
                end;
            end;
        end;
    end;

    local procedure GetNextProgramId(): Integer
    var
        Prog: Record "Interactive Program";
        NextId: Integer;
    begin
        if Prog.FindLast() then
            NextId := Prog."ID" + 1
        else
            NextId := 1;
        exit(NextId);
    end;

    procedure TrySelectDemoAndGetCode(var CodeText: Text): Boolean
    var
        DemoRec: Record "Interactive Program";
        Names: List of [Text];
        Index: Integer;
        i: Integer;
        Name: Text;
        MenuText: Text;
        Choice: Integer;
    begin
        // Build menu from demo programs (sorted by Name)
        DemoRec.Reset();
        DemoRec.SetRange("Is Demo", true);
        DemoRec.SetCurrentKey("Name");
        DemoRec.Ascending(true);
        if not DemoRec.FindSet() then
            exit(false);

        // Build menu lines
        repeat
            Names.Add(DemoRec."Name");
        until DemoRec.Next() = 0;

        // Construct StrMenu string
        for i := 1 to Names.Count() do begin
            Name := Names.Get(i);
            if MenuText <> '' then
                MenuText += ',';
            MenuText += Name;
        end;

        Choice := StrMenu(MenuText, 1);
        if Choice = 0 then
            exit(false);

        Name := Names.Get(Choice);
        DemoRec.Reset();
        DemoRec.SetRange("Is Demo", true);
        DemoRec.SetRange("Name", Name);
        if DemoRec.FindFirst() then begin
            CodeText := LoadCodeFromBlob(DemoRec);
            exit(true);
        end;

        exit(false);
    end;

    local procedure ExtractProgramName(Content: Text): Text
    var
        Lines: List of [Text];
        FirstLine: Text;
        CleanLine: Text;
        TypeHelper: Codeunit "Type Helper";
    begin
        // Split content into lines
        Lines := Content.Split(TypeHelper.LFSeparator());

        if Lines.Count() > 0 then begin
            FirstLine := Lines.Get(1);

            // If the line starts with //, remove it and leading spaces, keep full title
            if CopyStr(FirstLine, 1, 2) = '//' then
                CleanLine := DelChr(CopyStr(FirstLine, 3), '<', ' ')
            else
                CleanLine := FirstLine;

            if CleanLine <> '' then
                exit(CleanLine);
        end;

        // Fallback to generic name
        exit('Demo Script');
    end;

    procedure RunProgramFromList(var InteractiveProgram: Record "Interactive Program")
    var
        Executor: Codeunit "Program Executor";
        CodeText: Text;
        Result: Text;
    begin
        if not InteractiveProgram."AL Code".HasValue then begin
            Message('This program has no code.');
            exit;
        end;

        CodeText := LoadCodeFromBlob(InteractiveProgram);
        Result := Executor.ExecuteProgram(CodeText, false);

        if Result <> '' then
            Message('Execution completed:\%1', Result)
        else
            Message('Execution completed successfully.');
    end;

    procedure ExportProgramCode(var InteractiveProgram: Record "Interactive Program")
    var
        CodeText: Text;
    begin
        if not InteractiveProgram."AL Code".HasValue then begin
            Message('This program has no code.');
            exit;
        end;

        CodeText := LoadCodeFromBlob(InteractiveProgram);
        Message('Code for "%1":\%2', InteractiveProgram."Name", CodeText);
    end;

    procedure ShowProgramStatistics()
    var
        InteractiveProgram: Record "Interactive Program";
        TotalPrograms: Integer;
        PublicPrograms: Integer;
        ProgramsWithCode: Integer;
    begin
        InteractiveProgram.Reset();
        TotalPrograms := InteractiveProgram.Count;

        InteractiveProgram.Reset();
        if InteractiveProgram.FindSet() then
            repeat
                if InteractiveProgram."AL Code".HasValue then
                    ProgramsWithCode += 1;
            until InteractiveProgram.Next() = 0;

        Message('Total Programs: %1\Programs with Code: %2',
                TotalPrograms, ProgramsWithCode);
    end;
}
