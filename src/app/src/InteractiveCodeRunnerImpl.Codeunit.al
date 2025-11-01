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
                      'Message(''Total customers: '' + Format(Counter));';

        exit(SampleCode);
    end;

    procedure GetHelpContent(): Text
    begin
        exit('AL INTERPRETER - TOOLBOX COMPATIBLE' + '\n\n' +
             'DATA TYPES: Integer, Text, Code, Boolean, Date, DateTime, Decimal, Record, Char, BigText, GUID, Option, Duration, Blob' + '\n\n' +
             'VARIABLES: Counter: Integer; Name: Text; IsActive: Boolean; Price: Decimal; OrderDate: Date; Customer: Record Customer;' + '\n\n' +
             'ASSIGNMENTS: Counter := 10; Name := ''Hello''; Customer.Name := ''Test'';' + '\n\n' +
             'LOOPS: repeat ... until Condition; for i := 1 to 10 do ...; while Condition do ...;' + '\n\n' +
             'CONTROL FLOW: if Condition then ... else ...; exit; break; continue;' + '\n\n' +
             'RECORD OPERATIONS: Customer.FindSet(); Customer.Next(); Customer.SetRange(''No.'', ''10000''); Customer.CalcFields(Balance); Customer.IsEmpty; Customer.Count; Customer.Insert(); Customer.Modify(); Customer.Delete();' + '\n\n' +
             'STRING FUNCTIONS: StrLen(Text); CopyStr(Text, Start, Length); UpperCase(Text); LowerCase(Text); Pos(SubStr, Text); DelChr(Text, Char);' + '\n\n' +
             'MATH FUNCTIONS: Abs(Number); Round(Number, Precision); Power(Base, Exponent); Min(Val1, Val2); Max(Val1, Val2);' + '\n\n' +
             'SYSTEM FUNCTIONS: Message(Text); Today(); Time(); CurrentDateTime(); UserId(); CompanyName(); Format(Value);' + '\n\n' +
             'Supports most features from Erik''s ToolBox!');
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
