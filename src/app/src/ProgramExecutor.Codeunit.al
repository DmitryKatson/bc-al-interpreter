codeunit 50001 "Program Executor"
{
    #region "Interpreter Setup"
    var
        TokenList: List of [Text];
        TokenTypeList: List of [Text];
        CurrentTokenIndex: Integer;
        ErrorMessage: Text;
        ExecutionOutput: Text;
        CurrentLine: Integer;
        VariableNames: List of [Text];
        VariableValues: List of [Text];
        VariableTypes: List of [Text];
        RecordVarNames: List of [Text];
        ActiveRecordRefs: array[10] of RecordRef;
        ActiveRecordRefNames: array[10] of Text[50];
        ActiveRecordRefCount: Integer;
        MaxVariables: Integer;
        ForceConsoleOnly: Boolean;
        ProcedureNames: List of [Text];
        ProcedureBodyStartIndexes: List of [Integer];
        ProcedureBodyEndIndexes: List of [Integer];
        ProcedureParamSignatures: List of [Text];
        ProcedureReturnTypes: List of [Text];
        ProcedureLocalVarSignatures: List of [Text];
        QueryNames: List of [Text];
        QueryDefinitions: List of [Text];
        CurrentExecutionEndIndex: Integer;
        ProcedureExecutionDepth: Integer;
        ProcedureExitRequested: Boolean;
        ProcedureReturnValue: Text;

    /// <summary>
    /// Main entry point to execute AL code
    /// </summary>
    procedure ExecuteProgram(CodeText: Text; ConsoleOnly: Boolean): Text
    var
        TypeHelper: Codeunit "Type Helper";
        ErrLine: Text;
    begin
        MaxVariables := 100;
        ClearContext();
        ForceConsoleOnly := ConsoleOnly;

        if not Tokenize(CodeText) then begin
            if ErrorMessage <> '' then begin
                ErrLine := 'Error: ' + ErrorMessage;
                ExecutionOutput += ErrLine + TypeHelper.LFSeparator();
                if GuiAllowed and not ForceConsoleOnly then
                    Message(ErrLine);
            end;
            exit(ExecutionOutput);
        end;

        if not ParseAndExecute() then begin
            if ErrorMessage <> '' then begin
                ErrLine := 'Error: ' + ErrorMessage;
                ExecutionOutput += ErrLine + TypeHelper.LFSeparator();
                if GuiAllowed and not ForceConsoleOnly then
                    Message(ErrLine);
            end;
            exit(ExecutionOutput);
        end;

        // Check for runtime errors even if parsing succeeded
        if ErrorMessage <> '' then begin
            ErrLine := 'Error: ' + ErrorMessage;
            ExecutionOutput += ErrLine + TypeHelper.LFSeparator();
            if GuiAllowed and not ForceConsoleOnly then
                Message(ErrLine);
        end;

        if (ExecutionOutput <> '') and GuiAllowed and not ForceConsoleOnly then
            Message(ExecutionOutput);

        exit(ExecutionOutput);
    end;

    local procedure ClearContext()
    var
        i: Integer;
    begin
        Clear(VariableNames);
        Clear(VariableValues);
        Clear(VariableTypes);
        Clear(RecordVarNames);
        Clear(TokenList);
        Clear(TokenTypeList);
        Clear(ProcedureNames);
        Clear(ProcedureBodyStartIndexes);
        Clear(ProcedureBodyEndIndexes);
        Clear(ProcedureParamSignatures);
        Clear(ProcedureReturnTypes);
        Clear(ProcedureLocalVarSignatures);
        Clear(QueryNames);
        Clear(QueryDefinitions);
        CurrentTokenIndex := 0;
        ErrorMessage := '';
        ExecutionOutput := '';
        CurrentLine := 1;
        CurrentExecutionEndIndex := 0;
        ProcedureExecutionDepth := 0;
        ProcedureExitRequested := false;
        ProcedureReturnValue := '';

        // Clear active RecordRefs
        for i := 1 to 10 do begin
            if ActiveRecordRefs[i].Number <> 0 then
                ActiveRecordRefs[i].Close();
            Clear(ActiveRecordRefs[i]);
            Clear(ActiveRecordRefNames[i]);
        end;
        ActiveRecordRefCount := 0;
    end;

    #endregion

    #region Tokenization & Navigation

    /// <summary>
    /// Tokenize the input code into tokens
    /// </summary>
    local procedure Tokenize(CodeText: Text): Boolean
    var
        i: Integer;
        CurrentToken: Text;
        Ch: Char;
        InString: Boolean;
        InQuotedField: Boolean;
        InComment: Boolean;
    begin
        CurrentToken := '';
        InString := false;
        InQuotedField := false;
        InComment := false;

        i := 1;
        while i <= StrLen(CodeText) do begin
            Ch := CodeText[i];

            // Handle comments
            if (Ch = '/') and (i < StrLen(CodeText)) and (CodeText[i + 1] = '/') and (not InString) and (not InQuotedField) then begin
                InComment := true;
                i += 2;
                continue;
            end;

            if InComment then begin
                if (Ch = 10) or (Ch = 13) then begin
                    InComment := false;
                    CurrentLine += 1;
                end;
                i += 1;
                continue;
            end;

            // Handle strings (single quotes)
            if Ch = '''' then begin
                if InString then begin
                    AddToken(CurrentToken, 'STRING');
                    CurrentToken := '';
                    InString := false;
                end else begin
                    if CurrentToken <> '' then
                        AddToken(CurrentToken, GetTokenType(CurrentToken));
                    CurrentToken := '';
                    InString := true;
                end;
                i += 1;
                continue;
            end;

            // Handle double-quoted field names (AL syntax for fields with spaces)
            if Ch = '"' then begin
                if InQuotedField then begin
                    // End of quoted field name - add as identifier (with quotes removed)
                    AddToken(CurrentToken, 'IDENTIFIER');
                    CurrentToken := '';
                    InQuotedField := false;
                end else begin
                    if CurrentToken <> '' then
                        AddToken(CurrentToken, GetTokenType(CurrentToken));
                    CurrentToken := '';
                    InQuotedField := true;
                end;
                i += 1;
                continue;
            end;

            if InString then begin
                CurrentToken += Format(Ch);
                i += 1;
                continue;
            end;

            if InQuotedField then begin
                CurrentToken += Format(Ch);
                i += 1;
                continue;
            end;

            // Handle line breaks
            if (Ch = 10) or (Ch = 13) then begin
                if CurrentToken <> '' then
                    AddToken(CurrentToken, GetTokenType(CurrentToken));
                CurrentToken := '';
                CurrentLine += 1;
                i += 1;
                continue;
            end;

            // Handle whitespace
            if Ch = ' ' then begin
                if CurrentToken <> '' then
                    AddToken(CurrentToken, GetTokenType(CurrentToken));
                CurrentToken := '';
                i += 1;
                continue;
            end;

            // Handle operators and delimiters
            if IsOperatorChar(Ch) then begin
                // Special case: dot in decimal number (e.g., 3.14)
                if (Ch = '.') and (CurrentToken <> '') and IsNumeric(CurrentToken) then begin
                    if (i < StrLen(CodeText)) and IsDigit(CodeText[i + 1]) then begin
                        // This is a decimal point, include it in the number
                        CurrentToken += Format(Ch);
                        i += 1;
                        continue;
                    end;
                end;

                if CurrentToken <> '' then
                    AddToken(CurrentToken, GetTokenType(CurrentToken));
                CurrentToken := '';

                // Check for two-character operators
                if (i < StrLen(CodeText)) then begin
                    if (Ch = ':') and (CodeText[i + 1] = ':') then begin
                        AddToken('::', 'OPERATOR');
                        i += 2;
                        continue;
                    end;
                    if (Ch = ':') and (CodeText[i + 1] = '=') then begin
                        AddToken(':=', 'OPERATOR');
                        i += 2;
                        continue;
                    end;
                    if (Ch = '<') and (CodeText[i + 1] = '>') then begin
                        AddToken('<>', 'OPERATOR');
                        i += 2;
                        continue;
                    end;
                    if (Ch = '<') and (CodeText[i + 1] = '=') then begin
                        AddToken('<=', 'OPERATOR');
                        i += 2;
                        continue;
                    end;
                    if (Ch = '>') and (CodeText[i + 1] = '=') then begin
                        AddToken('>=', 'OPERATOR');
                        i += 2;
                        continue;
                    end;
                    if (Ch = '.') and (CodeText[i + 1] = '.') then begin
                        AddToken('..', 'OPERATOR');
                        i += 2;
                        continue;
                    end;
                end;

                AddToken(Format(Ch), 'OPERATOR');
                i += 1;
                continue;
            end;

            // Build identifier or number
            CurrentToken += Format(Ch);
            i += 1;
        end;

        if CurrentToken <> '' then
            AddToken(CurrentToken, GetTokenType(CurrentToken));

        exit(true);
    end;

    local procedure AddToken(Token: Text; TokenType: Text)
    begin
        TokenList.Add(Token);
        TokenTypeList.Add(TokenType);
    end;

    local procedure GetTokenType(Token: Text): Text
    var
        LowerToken: Text;
        TestInt: Integer;
        TestDec: Decimal;
    begin
        LowerToken := LowerCase(Token);

        // Keywords
        case LowerToken of
            'var', 'begin', 'end', 'if', 'then', 'else', 'repeat',
          'until', 'while', 'do', 'for', 'to', 'downto',
          'record', 'integer', 'text', 'boolean', 'date', 'datetime',
          'decimal', 'code', 'and', 'or', 'not', 'div', 'mod',
          'true', 'false', 'case', 'of', 'exit', 'procedure',
          'query', 'dataitem', 'column', 'filter', 'elements', 'dataitemlink':
                exit('KEYWORD');
        end;

        // Check if number (integer or decimal)
        if Evaluate(TestInt, Token) then
            exit('NUMBER');
        if Evaluate(TestDec, Token) then
            exit('NUMBER');

        exit('IDENTIFIER');
    end;

    local procedure IsOperatorChar(Ch: Char): Boolean
    begin
        case Ch of
            ':', '=', '<', '>', '+', '-', '*', '/', '(', ')', ';', '.', ',', '[', ']':
                exit(true);
            else
                exit(false);
        end;
    end;

    local procedure IsDigit(Ch: Char): Boolean
    begin
        exit(Ch in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);
    end;

    local procedure IsNumeric(Token: Text): Boolean
    var
        TestInt: Integer;
        TestDec: Decimal;
    begin
        if Evaluate(TestInt, Token) then
            exit(true);
        if Evaluate(TestDec, Token) then
            exit(true);
        exit(false);
    end;

    // Token navigation helpers
    local procedure GetCurrentToken(): Text
    begin
        if (CurrentTokenIndex > 0) and (CurrentTokenIndex <= TokenList.Count) then
            exit(TokenList.Get(CurrentTokenIndex));
        exit('');
    end;

    local procedure GetCurrentTokenType(): Text
    begin
        if (CurrentTokenIndex > 0) and (CurrentTokenIndex <= TokenTypeList.Count) then
            exit(TokenTypeList.Get(CurrentTokenIndex));
        exit('');
    end;

    local procedure Advance()
    begin
        CurrentTokenIndex += 1;
    end;

    local procedure PeekNextToken(Expected: Text): Boolean
    begin
        if CurrentTokenIndex < TokenList.Count then
            exit(TokenList.Get(CurrentTokenIndex + 1) = Expected);
        exit(false);
    end;

    local procedure PeekTokenAt(TokenIndex: Integer): Text
    begin
        if (TokenIndex > 0) and (TokenIndex <= TokenList.Count) then
            exit(TokenList.Get(TokenIndex));
        exit('');
    end;

    local procedure PeekAheadForToken(Expected: Text): Boolean
    var
        i: Integer;
    begin
        for i := CurrentTokenIndex + 1 to TokenList.Count do begin
            if TokenList.Get(i) = Expected then
                exit(true);
            if TokenList.Get(i) = ';' then
                exit(false);
        end;
        exit(false);
    end;

    local procedure ConsumeToken(Expected: Text): Boolean
    begin
        if GetCurrentToken() = Expected then begin
            Advance();
            exit(true);
        end;
        exit(false);
    end;

    local procedure ConsumeKeyword(Expected: Text): Boolean
    begin
        if LowerCase(GetCurrentToken()) = LowerCase(Expected) then begin
            Advance();
            exit(true);
        end;
        exit(false);
    end;

    local procedure ConsumeSemicolon()
    begin
        if GetCurrentToken() = ';' then
            Advance();
    end;

    local procedure FindKeyword(Keyword: Text; StartIndex: Integer): Integer
    var
        i: Integer;
    begin
        for i := StartIndex to TokenList.Count do begin
            if LowerCase(TokenList.Get(i)) = LowerCase(Keyword) then
                exit(i);
        end;
        exit(0);
    end;

    local procedure FindElseForIf(ThenIndex: Integer): Integer
    var
        i: Integer;
        IfNestLevel: Integer;
        BeginNestLevel: Integer;
    begin
        IfNestLevel := 0;
        BeginNestLevel := 0;

        for i := ThenIndex to TokenList.Count do begin
            case LowerCase(TokenList.Get(i)) of
                'begin':
                    BeginNestLevel += 1;
                'end':
                    BeginNestLevel -= 1;
                'if':
                    IfNestLevel += 1;
                'else':
                    begin
                        // Check if this else belongs to a nested if
                        if IfNestLevel > 0 then begin
                            IfNestLevel -= 1; // This else closes a nested if
                        end else if BeginNestLevel = 0 then begin
                            // This is our matching else (same level, not inside begin/end)
                            exit(i);
                        end;
                    end;
            end;

            // If we hit a semicolon at the top level, the if statement ends without else
            if (TokenList.Get(i) = ';') and (IfNestLevel = 0) and (BeginNestLevel = 0) then
                exit(0);

            // If begin nesting goes negative, we've exited the structure
            if BeginNestLevel < 0 then
                exit(0);
        end;
        exit(0);
    end;

    local procedure FindStatementEnd(StartIndex: Integer): Integer
    var
        i: Integer;
        NestLevel: Integer;
        Token: Text;
    begin
        NestLevel := 0;
        for i := StartIndex to TokenList.Count do begin
            Token := LowerCase(TokenList.Get(i));

            case Token of
                'begin', 'repeat':
                    NestLevel += 1;
                'end', 'until':
                    if NestLevel > 0 then
                        NestLevel -= 1;
            end;

            if (NestLevel = 0) and (TokenList.Get(i) = ';') then
                exit(i + 1);
        end;

        exit(TokenList.Count);
    end;

    #endregion



    #region Statement Parsing

    /// <summary>
    /// Parse and execute the tokenized code
    /// </summary>
    local procedure ParseAndExecute(): Boolean
    begin
        CurrentTokenIndex := 1;
        CurrentExecutionEndIndex := TokenList.Count;

        while CurrentTokenIndex <= CurrentExecutionEndIndex do begin
            if not ParseStatement() then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ParseStatement(): Boolean
    var
        Token: Text;
        TokenType: Text;
    begin
        if (CurrentExecutionEndIndex = 0) or (CurrentExecutionEndIndex > TokenList.Count) then
            CurrentExecutionEndIndex := TokenList.Count;

        if CurrentTokenIndex > CurrentExecutionEndIndex then
            exit(true);

        Token := GetCurrentToken();
        TokenType := GetCurrentTokenType();

        // Control structures (check FIRST to avoid confusion with assignments)
        if TokenType = 'KEYWORD' then begin
            case LowerCase(Token) of
                'if':
                    exit(ParseIfStatement());
                'repeat':
                    exit(ParseRepeatLoop());
                'for':
                    exit(ParseForLoop());
                'while':
                    exit(ParseWhileLoop());
                'begin':
                    exit(ParseBeginEnd());
                'case':
                    exit(ParseCaseStatement());
                'exit':
                    exit(ParseExitStatement());
                'procedure':
                    exit(ParseProcedureDeclaration());
                'query':
                    exit(ParseQueryDeclaration());
                'var':
                    begin
                        Advance();
                        exit(true);
                    end;
                'break':
                    begin
                        Advance();
                        ConsumeSemicolon();
                        exit(true);
                    end;
                'continue':
                    begin
                        Advance();
                        ConsumeSemicolon();
                        exit(true);
                    end;
            end;
        end;

        // Variable declaration
        if (TokenType = 'IDENTIFIER') and PeekNextToken(':') then
            exit(ParseVariableDeclaration());

        // Method call - check before assignment to handle Rec.Method() correctly
        if (TokenType = 'IDENTIFIER') and PeekNextToken('(') then
            exit(ParseMethodCall());

        // Record method call - VarName.MethodName()
        if (TokenType = 'IDENTIFIER') and PeekNextToken('.') then begin
            // Look ahead to see if this is a method call (has parentheses) or field assignment
            // CurrentTokenIndex = VarName, +1 = '.', +2 = MethodName/FieldName, +3 = '(' or ':='
            if PeekTokenAt(CurrentTokenIndex + 3) = '(' then
                exit(ParseRecordMethodCallStatement())
            else
                exit(ParseAssignment());
        end;

        // Simple assignment - VarName :=
        if (TokenType = 'IDENTIFIER') and PeekNextToken(':=') then
            exit(ParseAssignment());

        // Skip semicolons
        if Token = ';' then begin
            Advance();
            exit(true);
        end;

        // Skip unknown tokens
        Advance();
        exit(true);
    end;

    local procedure ParseVariableDeclaration(): Boolean
    var
        VarName: Text;
        TypeDescriptor: Text;
    begin
        VarName := GetCurrentToken();
        Advance();

        if not ConsumeToken(':') then begin
            SetError('Expected : after variable name');
            exit(false);
        end;

        if not ParseTypeReference(TypeDescriptor) then
            exit(false);

        if not DeclareVariableFromSignature(VarName, TypeDescriptor) then
            exit(false);

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseTypeReference(var TypeDescriptor: Text): Boolean
    var
        BaseType: Text;
        LengthToken: Text;
    begin
        if not IsTypeToken(GetCurrentTokenType()) then begin
            SetError('Expected type specification');
            exit(false);
        end;

        BaseType := GetCurrentToken();
        Advance();
        TypeDescriptor := BaseType;

        if GetCurrentToken() = '[' then begin
            Advance();
            if (GetCurrentTokenType() <> 'NUMBER') and (GetCurrentTokenType() <> 'IDENTIFIER') then begin
                SetError('Expected length inside [] for type ' + BaseType);
                exit(false);
            end;
            LengthToken := GetCurrentToken();
            Advance();
            if not ConsumeToken(']') then begin
                SetError('Expected ] after length for type ' + BaseType);
                exit(false);
            end;
            TypeDescriptor := BaseType + '[' + LengthToken + ']';
        end;

        if LowerCase(BaseType) = 'record' then begin
            if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                SetError('Expected table name for record type');
                exit(false);
            end;
            TypeDescriptor := TypeDescriptor + '|' + GetCurrentToken();
            Advance();
        end;

        exit(true);
    end;

    #region Variable Management

    local procedure CreateRecordVariable(VarName: Text; TableName: Text): Boolean
    begin
        if not AddVariable(VarName, '', 'Record') then
            exit(false);
        RecordVarNames.Add(VarName + '|' + TableName);
        exit(true);
    end;

    local procedure AddVariable(VarName: Text; Value: Text; VarType: Text): Boolean
    begin
        if VariableNames.Count >= MaxVariables then begin
            SetError('Too many variables');
            exit(false);
        end;

        VariableNames.Add(VarName);
        VariableValues.Add(Value);
        VariableTypes.Add(VarType);
        exit(true);
    end;

    local procedure GetVariableIndex(VarName: Text): Integer
    var
        i: Integer;
    begin
        for i := VariableNames.Count downto 1 do begin
            if VariableNames.Get(i) = VarName then
                exit(i);
        end;
        exit(0);
    end;

    local procedure GetVariableValue(VarName: Text): Text
    var
        Idx: Integer;
    begin
        Idx := GetVariableIndex(VarName);
        if Idx > 0 then
            exit(VariableValues.Get(Idx));
        exit('');
    end;

    local procedure SetVariableValue(VarName: Text; Value: Text): Boolean
    var
        Idx: Integer;
    begin
        Idx := GetVariableIndex(VarName);
        if Idx = 0 then begin
            SetError('Variable not found: ' + VarName);
            exit(false);
        end;
        VariableValues.Set(Idx, Value);
        exit(true);
    end;

    local procedure GetVariableType(VarName: Text): Text
    var
        Idx: Integer;
    begin
        Idx := GetVariableIndex(VarName);
        if Idx > 0 then
            exit(VariableTypes.Get(Idx));
        exit('');
    end;

    local procedure ClearVariable(VarName: Text): Boolean
    var
        Idx: Integer;
        VarType: Text;
    begin
        Idx := GetVariableIndex(VarName);
        if Idx = 0 then
            exit(false);

        VarType := VariableTypes.Get(Idx);
        case VarType of
            'Integer':
                VariableValues.Set(Idx, '0');
            'Decimal':
                VariableValues.Set(Idx, '0');
            'Boolean':
                VariableValues.Set(Idx, 'false');
            'Text', 'Code', 'Char', 'BigText', 'Blob':
                VariableValues.Set(Idx, '');
            'Date':
                VariableValues.Set(Idx, Format(0D));
            'DateTime':
                VariableValues.Set(Idx, Format(0DT));
            'GUID':
                VariableValues.Set(Idx, Format(CreateGuid()));
            'Option':
                VariableValues.Set(Idx, '0');
            'Duration':
                VariableValues.Set(Idx, '0');
        end;
        exit(true);
    end;

    #endregion

    local procedure ParseAssignment(): Boolean
    var
        VarName: Text;
        FieldName: Text;
        Value: Text;
        IsFieldAssignment: Boolean;
    begin
        VarName := GetCurrentToken();
        Advance();

        // Check for field access
        IsFieldAssignment := false;
        if GetCurrentToken() = '.' then begin
            Advance();
            FieldName := GetCurrentToken();
            Advance();
            IsFieldAssignment := true;
        end;

        if not ConsumeToken(':=') then begin
            SetError('Expected := in assignment');
            exit(false);
        end;

        if not EvaluateExpression(Value) then
            exit(false);

        if IsFieldAssignment then begin
            if not SetRecordFieldValue(VarName, FieldName, Value) then
                exit(false);
        end else begin
            if not SetVariableValue(VarName, Value) then
                exit(false);
        end;

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseMethodCall(): Boolean
    var
        MethodName: Text;
        PreviousToken: Text;
        IsRecordMethod: Boolean;
        RecordVarName: Text;
        Result: Text;
    begin
        MethodName := GetCurrentToken();
        IsRecordMethod := false;

        // Check if this is a record method
        if PeekTokenAt(CurrentTokenIndex - 1) = '.' then begin
            RecordVarName := PeekTokenAt(CurrentTokenIndex - 2);
            if RecordVarName <> '' then
                IsRecordMethod := true;
        end;

        Advance();

        if IsRecordMethod then begin
            if not ExecuteRecordMethod(RecordVarName, MethodName, Result) then
                exit(false);
        end else begin
            if HasProcedure(MethodName) then begin
                if not ExecuteProcedureCall(MethodName, Result) then
                    exit(false);
            end else begin
                if not ExecuteBuiltInFunction(MethodName, Result) then
                    exit(false);
            end;
        end;

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseRecordMethodCallStatement(): Boolean
    var
        RecordVarName: Text;
        MethodName: Text;
        Result: Text;
    begin
        RecordVarName := GetCurrentToken();
        Advance(); // Skip record var name

        if not ConsumeToken('.') then begin
            SetError('Expected . after record variable');
            exit(false);
        end;

        MethodName := GetCurrentToken();
        Advance(); // Skip method name

        // ExecuteRecordMethod will handle the parentheses and arguments
        if not ExecuteRecordMethod(RecordVarName, MethodName, Result) then
            exit(false);

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseIfStatement(): Boolean
    var
        ConditionResult: Boolean;
        SavedIndex: Integer;
        ThenStartIndex: Integer;
        ElseIndex: Integer;
        NextStatementIndex: Integer;
    begin
        Advance(); // Skip 'if'

        if not EvaluateCondition(ConditionResult) then
            exit(false);

        if not ConsumeKeyword('then') then begin
            SetError('Expected THEN after IF condition');
            exit(false);
        end;

        ThenStartIndex := CurrentTokenIndex;
        ElseIndex := FindElseForIf(ThenStartIndex);

        if ConditionResult then begin
            // Execute THEN branch
            if ElseIndex > 0 then begin
                while (CurrentTokenIndex < ElseIndex) do begin
                    if not ParseStatement() then
                        exit(false);
                end;
                // Skip ELSE branch
                CurrentTokenIndex := FindStatementEnd(ElseIndex + 1);
            end else begin
                // Execute THEN statement, but continue execution after it
                if not ParseStatement() then
                    exit(false);
                // CurrentTokenIndex is already advanced by ParseStatement()
            end;
        end else begin
            // Skip THEN branch, execute ELSE if exists
            if ElseIndex > 0 then begin
                CurrentTokenIndex := ElseIndex + 1;
                // Execute ELSE statement, but continue execution after it
                if not ParseStatement() then
                    exit(false);
                // CurrentTokenIndex is already advanced by ParseStatement()
            end else begin
                // Skip THEN statement
                CurrentTokenIndex := FindStatementEnd(ThenStartIndex);
            end;
        end;

        exit(true);
    end;

    local procedure ParseRepeatLoop(): Boolean
    var
        LoopStartIndex: Integer;
        UntilIndex: Integer;
        ConditionResult: Boolean;
        MaxIterations: Integer;
        IterCount: Integer;
    begin
        Advance(); // Skip 'repeat'
        LoopStartIndex := CurrentTokenIndex;

        UntilIndex := FindKeyword('until', LoopStartIndex);
        if UntilIndex = 0 then begin
            SetError('Expected UNTIL for REPEAT loop');
            exit(false);
        end;

        MaxIterations := 10000;
        IterCount := 0;

        repeat
            IterCount += 1;
            if IterCount > MaxIterations then begin
                SetError('Loop exceeded maximum iterations');
                exit(false);
            end;

            // Execute loop body
            CurrentTokenIndex := LoopStartIndex;
            while (CurrentTokenIndex < UntilIndex) do begin
                if not ParseStatement() then
                    exit(false);
            end;

            // Move to condition
            CurrentTokenIndex := UntilIndex + 1;

            // Evaluate condition
            if not EvaluateCondition(ConditionResult) then
                exit(false);

            ConsumeSemicolon();

        until ConditionResult;

        exit(true);
    end;

    local procedure ParseBeginEnd(): Boolean
    begin
        Advance(); // Skip 'begin'

        while (CurrentTokenIndex <= TokenList.Count) and (LowerCase(GetCurrentToken()) <> 'end') do begin
            if not ParseStatement() then
                exit(false);
        end;

        if LowerCase(GetCurrentToken()) = 'end' then
            Advance();

        ConsumeSemicolon();
        exit(true);
    end;

    #region Expression Evaluation

    local procedure EvaluateExpression(var Result: Text): Boolean
    begin
        exit(EvaluateOrExpression(Result));
    end;

    local procedure EvaluateOrExpression(var Result: Text): Boolean
    var
        Right: Text;
        LeftBool, RightBool : Boolean;
    begin
        if not EvaluateAndExpression(Result) then
            exit(false);

        while (LowerCase(GetCurrentToken()) = 'or') do begin
            Advance();
            if not EvaluateAndExpression(Right) then
                exit(false);

            LeftBool := TextToBool(Result);
            RightBool := TextToBool(Right);
            Result := BoolToText(LeftBool or RightBool);
        end;

        exit(true);
    end;

    local procedure EvaluateAndExpression(var Result: Text): Boolean
    var
        Right: Text;
        LeftBool, RightBool : Boolean;
    begin
        if not EvaluateComparisonExpression(Result) then
            exit(false);

        while (LowerCase(GetCurrentToken()) = 'and') do begin
            Advance();
            if not EvaluateComparisonExpression(Right) then
                exit(false);

            LeftBool := TextToBool(Result);
            RightBool := TextToBool(Right);
            Result := BoolToText(LeftBool and RightBool);
        end;

        exit(true);
    end;

    local procedure EvaluateComparisonExpression(var Result: Text): Boolean
    var
        Operator: Text;
        Right: Text;
        CompResult: Boolean;
    begin
        if not EvaluateAddSubExpression(Result) then
            exit(false);

        if GetCurrentToken() in ['=', '<>', '<', '>', '<=', '>='] then begin
            Operator := GetCurrentToken();
            Advance();

            if not EvaluateAddSubExpression(Right) then
                exit(false);

            CompResult := CompareValues(Result, Right, Operator);
            Result := BoolToText(CompResult);
        end;

        exit(true);
    end;

    local procedure EvaluateAddSubExpression(var Result: Text): Boolean
    var
        Operator: Text;
        Right: Text;
    begin
        if not EvaluateMulDivExpression(Result) then
            exit(false);

        while GetCurrentToken() in ['+', '-'] do begin
            Operator := GetCurrentToken();
            Advance();

            if not EvaluateMulDivExpression(Right) then
                exit(false);

            case Operator of
                '+':
                    Result := AddTextValues(Result, Right);
                '-':
                    Result := SubtractTextValues(Result, Right);
            end;
        end;

        exit(true);
    end;

    local procedure EvaluateMulDivExpression(var Result: Text): Boolean
    var
        Operator: Text;
        Right: Text;
    begin
        if not EvaluateUnaryExpression(Result) then
            exit(false);

        while LowerCase(GetCurrentToken()) in ['*', '/', 'div', 'mod'] do begin
            Operator := LowerCase(GetCurrentToken());
            Advance();

            if not EvaluateUnaryExpression(Right) then
                exit(false);

            case Operator of
                '*':
                    Result := MultiplyTextValues(Result, Right);
                '/', 'div':
                    Result := DivideTextValues(Result, Right);
                'mod':
                    Result := ModTextValues(Result, Right);
            end;
        end;

        exit(true);
    end;

    local procedure EvaluateUnaryExpression(var Result: Text): Boolean
    var
        Operator: Text;
    begin
        if LowerCase(GetCurrentToken()) in ['-', 'not'] then begin
            Operator := LowerCase(GetCurrentToken());
            Advance();

            if not EvaluatePrimaryExpression(Result) then
                exit(false);

            case Operator of
                '-':
                    Result := NegateTextValue(Result);
                'not':
                    Result := BoolToText(not TextToBool(Result));
            end;

            exit(true);
        end;

        exit(EvaluatePrimaryExpression(Result));
    end;

    local procedure EvaluatePrimaryExpression(var Result: Text): Boolean
    var
        Token: Text;
        TokenType: Text;
        VarName: Text;
        FieldName: Text;
    begin
        Token := GetCurrentToken();
        TokenType := GetCurrentTokenType();

        // Parenthesized expression
        if Token = '(' then begin
            Advance();
            if not EvaluateExpression(Result) then
                exit(false);
            if not ConsumeToken(')') then begin
                SetError('Expected closing parenthesis');
                exit(false);
            end;
            exit(true);
        end;

        // String literal
        if TokenType = 'STRING' then begin
            Result := Token;
            Advance();
            exit(true);
        end;

        // Number literal
        if TokenType = 'NUMBER' then begin
            Result := Token;
            Advance();
            exit(true);
        end;

        // Boolean literal
        if LowerCase(Token) in ['true', 'false'] then begin
            Result := Token;
            Advance();
            exit(true);
        end;

        // Function call
        if (TokenType = 'IDENTIFIER') and PeekNextToken('(') then
            exit(EvaluateFunctionCall(Result));

        // Variable or field access
        if TokenType = 'IDENTIFIER' then begin
            VarName := Token;
            Advance();

            // Field access or record method call
            if GetCurrentToken() = '.' then begin
                Advance();
                FieldName := GetCurrentToken();
                Advance();

                // Check for enum access (Item.Type::Inventory)
                if GetCurrentToken() = '::' then begin
                    Advance();
                    // After :: comes the enum value name (e.g., Inventory, No, Yes, etc.)
                    // Return the enum value name as text (for now, actual enum conversion can be done later)
                    if GetCurrentTokenType() = 'IDENTIFIER' then begin
                        // Return enum value as text (e.g., "Inventory")
                        Result := GetCurrentToken();
                        Advance();
                        exit(true);
                    end else begin
                        SetError('Expected enum value after ::');
                        exit(false);
                    end;
                end;

                // Check if this is a method call (has parentheses)
                if GetCurrentToken() = '(' then
                    exit(ExecuteRecordMethod(VarName, FieldName, Result));

                // Otherwise it's field access
                exit(GetRecordFieldValue(VarName, FieldName, Result));
            end;

            // Simple variable
            if GetVariableIndex(VarName) > 0 then begin
                Result := GetVariableValue(VarName);
                exit(true);
            end;

            SetError('Undefined variable: ' + VarName);
            exit(false);
        end;

        SetError('Unexpected token: ' + Token);
        exit(false);
    end;

    // Math and comparison helpers for expression evaluation
    local procedure CompareValues(Left: Text; Right: Text; Operator: Text): Boolean
    var
        LeftInt, RightInt : Integer;
        LeftDec, RightDec : Decimal;
        LeftEvalInt, RightEvalInt : Boolean;
        LeftEvalDec, RightEvalDec : Boolean;
    begin
        LeftEvalInt := Evaluate(LeftInt, Left);
        RightEvalInt := Evaluate(RightInt, Right);

        if LeftEvalInt and RightEvalInt then begin
            case Operator of
                '=':
                    exit(LeftInt = RightInt);
                '<>':
                    exit(LeftInt <> RightInt);
                '<':
                    exit(LeftInt < RightInt);
                '>':
                    exit(LeftInt > RightInt);
                '<=':
                    exit(LeftInt <= RightInt);
                '>=':
                    exit(LeftInt >= RightInt);
            end;
        end;

        LeftEvalDec := Evaluate(LeftDec, Left);
        RightEvalDec := Evaluate(RightDec, Right);

        if LeftEvalDec and RightEvalDec then begin
            case Operator of
                '=':
                    exit(LeftDec = RightDec);
                '<>':
                    exit(LeftDec <> RightDec);
                '<':
                    exit(LeftDec < RightDec);
                '>':
                    exit(LeftDec > RightDec);
                '<=':
                    exit(LeftDec <= RightDec);
                '>=':
                    exit(LeftDec >= RightDec);
            end;
        end;

        // Text comparison
        case Operator of
            '=':
                exit(Left = Right);
            '<>':
                exit(Left <> Right);
            '<':
                exit(Left < Right);
            '>':
                exit(Left > Right);
            '<=':
                exit(Left <= Right);
            '>=':
                exit(Left >= Right);
        end;

        exit(false);
    end;

    local procedure AddTextValues(Left: Text; Right: Text): Text
    var
        LeftInt, RightInt : Integer;
        LeftDec, RightDec : Decimal;
    begin
        if Evaluate(LeftInt, Left) and Evaluate(RightInt, Right) then
            exit(Format(LeftInt + RightInt));
        if Evaluate(LeftDec, Left) and Evaluate(RightDec, Right) then
            exit(Format(LeftDec + RightDec));
        exit(Left + Right);
    end;

    local procedure SubtractTextValues(Left: Text; Right: Text): Text
    var
        LeftInt, RightInt : Integer;
        LeftDec, RightDec : Decimal;
    begin
        if Evaluate(LeftInt, Left) and Evaluate(RightInt, Right) then
            exit(Format(LeftInt - RightInt));
        if Evaluate(LeftDec, Left) and Evaluate(RightDec, Right) then
            exit(Format(LeftDec - RightDec));
        exit('0');
    end;

    local procedure MultiplyTextValues(Left: Text; Right: Text): Text
    var
        LeftInt, RightInt : Integer;
        LeftDec, RightDec : Decimal;
    begin
        if Evaluate(LeftInt, Left) and Evaluate(RightInt, Right) then
            exit(Format(LeftInt * RightInt));
        if Evaluate(LeftDec, Left) and Evaluate(RightDec, Right) then
            exit(Format(LeftDec * RightDec));
        exit('0');
    end;

    local procedure DivideTextValues(Left: Text; Right: Text): Text
    var
        LeftDec, RightDec : Decimal;
    begin
        if Evaluate(LeftDec, Left) and Evaluate(RightDec, Right) then begin
            if RightDec = 0 then begin
                SetError('Division by zero');
                exit('0');
            end;
            exit(Format(LeftDec / RightDec));
        end;
        exit('0');
    end;

    local procedure ModTextValues(Left: Text; Right: Text): Text
    var
        LeftInt, RightInt : Integer;
    begin
        if Evaluate(LeftInt, Left) and Evaluate(RightInt, Right) then begin
            if RightInt = 0 then begin
                SetError('Modulo by zero');
                exit('0');
            end;
            exit(Format(LeftInt mod RightInt));
        end;
        exit('0');
    end;

    local procedure NegateTextValue(Value: Text): Text
    var
        IntVal: Integer;
        DecVal: Decimal;
    begin
        if Evaluate(IntVal, Value) then
            exit(Format(-IntVal));
        if Evaluate(DecVal, Value) then
            exit(Format(-DecVal));
        exit('0');
    end;

    local procedure TextToBool(Value: Text): Boolean
    begin
        exit(LowerCase(Value) in ['true', '1', 'yes']);
    end;

    local procedure BoolToText(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;

    local procedure EvaluateFunctionCall(var Result: Text): Boolean
    var
        FunctionName: Text;
    begin
        FunctionName := GetCurrentToken();
        Advance();
        if HasProcedure(FunctionName) then
            exit(ExecuteProcedureCall(FunctionName, Result))
        else
            exit(ExecuteBuiltInFunction(FunctionName, Result));
    end;

    local procedure EvaluateCondition(var Result: Boolean): Boolean
    var
        TextResult: Text;
    begin
        if not EvaluateExpression(TextResult) then
            exit(false);
        Result := TextToBool(TextResult);
        exit(true);
    end;

    #endregion

    #region Built-In Library

    local procedure ExecuteBuiltInFunction(FunctionName: Text; var Result: Text): Boolean
    var
        Args: List of [Text];
        ArgValue: Text;
        Arg1, Arg2, Arg3 : Text;
        IntVal, IntVal2 : Integer;
        DecVal, DecVal2 : Decimal;
        DateVal: Date;
        TypeHelper: Codeunit "Type Helper";
        DayValue: Integer;
        MonthValue: Integer;
        YearValue: Integer;
        WeekValue: Integer;
        i: Integer;
        BoolResult: Boolean;
        ArgIndex: Integer;
        FirstArgIdentifier: Boolean;
    begin
        if not ConsumeToken('(') then begin
            SetError('Expected ( after function name');
            exit(false);
        end;

        // Parse arguments
        FirstArgIdentifier := LowerCase(FunctionName) in ['clear'];
        ArgIndex := 0;

        if GetCurrentToken() <> ')' then begin
            repeat
                ArgIndex += 1;
                if (ArgIndex = 1) and FirstArgIdentifier and (GetCurrentTokenType() = 'IDENTIFIER') then begin
                    ArgValue := GetCurrentToken();
                    Advance();
                end else begin
                    if not EvaluateExpression(ArgValue) then
                        exit(false);
                end;
                Args.Add(ArgValue);

                if GetCurrentToken() = ',' then
                    Advance()
                else
                    break;
            until GetCurrentToken() = ')';
        end;

        if not ConsumeToken(')') then begin
            SetError('Expected ) after function arguments');
            exit(false);
        end;

        case LowerCase(FunctionName) of
            'message':
                begin
                    if Args.Count > 0 then begin
                        Arg1 := Args.Get(1);
                        // Process placeholders %1, %2, %3, etc.
                        Arg1 := ProcessMessagePlaceholders(Arg1, Args);
                        ExecutionOutput += Arg1 + TypeHelper.LFSeparator();
                        if GuiAllowed and not ForceConsoleOnly then
                            Message(Arg1);
                    end;
                    Result := 'true';
                    exit(true);
                end;
            'strsubstno':
                begin
                    if Args.Count < 1 then begin
                        SetError('StrSubstNo requires at least 1 argument');
                        exit(false);
                    end;
                    Arg1 := ProcessMessagePlaceholders(Args.Get(1), Args);
                    Result := Arg1;
                    exit(true);
                end;
            'strlen':
                begin
                    if Args.Count < 1 then exit(false);
                    Result := Format(StrLen(Args.Get(1)));
                    exit(true);
                end;
            'copystr':
                begin
                    if Args.Count < 2 then exit(false);
                    Arg1 := Args.Get(1);
                    if not Evaluate(IntVal, Args.Get(2)) then exit(false);
                    if Args.Count >= 3 then begin
                        if not Evaluate(IntVal2, Args.Get(3)) then exit(false);
                        Result := CopyStr(Arg1, IntVal, IntVal2);
                    end else
                        Result := CopyStr(Arg1, IntVal);
                    exit(true);
                end;
            'uppercase':
                begin
                    if Args.Count < 1 then exit(false);
                    Result := UpperCase(Args.Get(1));
                    exit(true);
                end;
            'lowercase':
                begin
                    if Args.Count < 1 then exit(false);
                    Result := LowerCase(Args.Get(1));
                    exit(true);
                end;
            'format':
                begin
                    if Args.Count < 1 then exit(false);
                    Result := Format(Args.Get(1));
                    exit(true);
                end;
            'today':
                begin
                    Result := Format(Today);
                    exit(true);
                end;
            'round':
                begin
                    if Args.Count < 1 then exit(false);
                    if not Evaluate(DecVal, Args.Get(1)) then begin
                        Result := '0';
                        exit(true);
                    end;

                    if Args.Count >= 2 then begin
                        // Second argument is precision
                        if Evaluate(DecVal2, Args.Get(2)) then
                            Result := Format(Round(DecVal, DecVal2))
                        else
                            Result := Format(Round(DecVal, 1));
                    end else
                        Result := Format(Round(DecVal, 1));
                    exit(true);
                end;
            'abs':
                begin
                    if Args.Count < 1 then exit(false);
                    if Evaluate(IntVal, Args.Get(1)) then
                        Result := Format(Abs(IntVal))
                    else if Evaluate(DecVal, Args.Get(1)) then
                        Result := Format(Abs(DecVal))
                    else
                        Result := '0';
                    exit(true);
                end;
            'strpos':
                begin
                    if Args.Count < 2 then exit(false);
                    Arg1 := Args.Get(1);
                    Arg2 := Args.Get(2);
                    Result := Format(StrPos(Arg1, Arg2));
                    exit(true);
                end;
            'delchr':
                begin
                    if Args.Count < 2 then exit(false);
                    Arg1 := Args.Get(1);
                    Arg2 := Args.Get(2);
                    if Args.Count >= 3 then
                        Result := DelChr(Arg1, Arg2, Args.Get(3))
                    else
                        Result := DelChr(Arg1, Arg2);
                    exit(true);
                end;
            'insstr':
                begin
                    if Args.Count < 3 then exit(false);
                    Arg1 := Args.Get(1);
                    Arg2 := Args.Get(2);
                    if not Evaluate(IntVal, Args.Get(3)) then exit(false);
                    Result := InsStr(Arg1, Arg2, IntVal);
                    exit(true);
                end;
            'maxstrlen':
                begin
                    if Args.Count < 1 then exit(false);
                    if not Evaluate(IntVal, Args.Get(1)) then exit(false);
                    Result := Format(250); // MaxStrLen is deprecated, use fixed value
                    exit(true);
                end;
            'power':
                begin
                    if Args.Count < 2 then exit(false);
                    if not Evaluate(DecVal, Args.Get(1)) then exit(false);
                    if not Evaluate(DecVal2, Args.Get(2)) then exit(false);
                    Result := Format(Power(DecVal, DecVal2));
                    exit(true);
                end;
            'min':
                begin
                    if Args.Count < 2 then exit(false);
                    if Evaluate(IntVal, Args.Get(1)) and Evaluate(IntVal2, Args.Get(2)) then
                        Result := Format(IntVal < IntVal2 ? IntVal : IntVal2)
                    else if Evaluate(DecVal, Args.Get(1)) and Evaluate(DecVal2, Args.Get(2)) then
                        Result := Format(DecVal < DecVal2 ? DecVal : DecVal2)
                    else
                        Result := '0';
                    exit(true);
                end;
            'max':
                begin
                    if Args.Count < 2 then exit(false);
                    if Evaluate(IntVal, Args.Get(1)) and Evaluate(IntVal2, Args.Get(2)) then
                        Result := Format(IntVal > IntVal2 ? IntVal : IntVal2)
                    else if Evaluate(DecVal, Args.Get(1)) and Evaluate(DecVal2, Args.Get(2)) then
                        Result := Format(DecVal > DecVal2 ? DecVal : DecVal2)
                    else
                        Result := '0';
                    exit(true);
                end;
            'currentdatetime':
                begin
                    Result := Format(CurrentDateTime);
                    exit(true);
                end;
            'userid':
                begin
                    Result := UserId;
                    exit(true);
                end;
            'companyname':
                begin
                    Result := CompanyName;
                    exit(true);
                end;
            'time':
                begin
                    Result := Format(Time);
                    exit(true);
                end;
            'createdatetime':
                begin
                    if Args.Count < 2 then exit(false);
                    // Simplified implementation - just return current datetime
                    Result := Format(CurrentDateTime);
                    exit(true);
                end;
            'createguid':
                begin
                    Result := Format(CreateGuid());
                    exit(true);
                end;
            'dmy2date':
                begin
                    if Args.Count < 3 then begin
                        SetError('DMY2Date requires 3 arguments');
                        exit(false);
                    end;
                    if not Evaluate(DayValue, Args.Get(1)) then exit(false);
                    if not Evaluate(MonthValue, Args.Get(2)) then exit(false);
                    if not Evaluate(YearValue, Args.Get(3)) then exit(false);
                    Result := Format(DMY2Date(DayValue, MonthValue, YearValue));
                    exit(true);
                end;
            'date2dmy':
                begin
                    if Args.Count < 1 then begin
                        SetError('Date2DMY requires a date argument');
                        exit(false);
                    end;
                    if not Evaluate(DateVal, Args.Get(1)) then exit(false);
                    DayValue := Date2DMY(DateVal, 1);
                    MonthValue := Date2DMY(DateVal, 2);
                    YearValue := Date2DMY(DateVal, 3);
                    Result := Format(DayValue) + ',' + Format(MonthValue) + ',' + Format(YearValue);
                    exit(true);
                end;
            'date2dwy':
                begin
                    if Args.Count < 1 then begin
                        SetError('Date2DWY requires a date argument');
                        exit(false);
                    end;
                    if not Evaluate(DateVal, Args.Get(1)) then exit(false);
                    DayValue := Date2DWY(DateVal, 1);
                    WeekValue := Date2DWY(DateVal, 2);
                    YearValue := Date2DWY(DateVal, 3);
                    Result := Format(DayValue) + ',' + Format(WeekValue) + ',' + Format(YearValue);
                    exit(true);
                end;
            'workdate':
                begin
                    Result := Format(WorkDate);
                    exit(true);
                end;
            'calcdate':
                begin
                    if Args.Count < 2 then begin
                        SetError('CalcDate requires a delta and a date');
                        exit(false);
                    end;
                    if not Evaluate(DateVal, Args.Get(1)) then exit(false);
                    Arg1 := Args.Get(2);
                    Result := Format(CalcDate(Arg1, DateVal));
                    exit(true);
                end;
            'random':
                begin
                    Result := Format(Random(10000));
                    exit(true);
                end;
            'randomize':
                begin
                    if Args.Count >= 1 then begin
                        if not Evaluate(IntVal, Args.Get(1)) then exit(false);
                        Randomize(IntVal);
                    end else
                        Randomize();
                    Result := 'true';
                    exit(true);
                end;
            'delstr':
                begin
                    if Args.Count < 2 then begin
                        SetError('DelStr requires at least 2 arguments');
                        exit(false);
                    end;
                    Arg1 := Args.Get(1);
                    if not Evaluate(IntVal, Args.Get(2)) then exit(false);
                    if Args.Count >= 3 then begin
                        if not Evaluate(IntVal2, Args.Get(3)) then exit(false);
                        Result := DelStr(Arg1, IntVal, IntVal2);
                    end else
                        Result := DelStr(Arg1, IntVal);
                    exit(true);
                end;
            'clear':
                begin
                    if Args.Count < 1 then begin
                        SetError('Clear requires a variable name');
                        exit(false);
                    end;
                    if not ClearVariable(Args.Get(1)) then begin
                        SetError('Variable not found for Clear: ' + Args.Get(1));
                        exit(false);
                    end;
                    Result := 'true';
                    exit(true);
                end;
            'executequery', 'runquery':
                begin
                    if Args.Count < 1 then begin
                        SetError('ExecuteQuery requires a query name');
                        exit(false);
                    end;
                    if not ExecuteStoredQuery(Args.Get(1)) then
                        exit(false);
                    Result := 'true';
                    exit(true);
                end;
            'error':
                begin
                    if Args.Count > 0 then begin
                        Arg1 := ProcessMessagePlaceholders(Args.Get(1), Args);
                        SetError(Arg1);
                    end else
                        SetError('Execution error');
                    Result := 'false';
                    exit(false);
                end;
            'commit':
                begin
                    Result := 'true';
                    exit(true);
                end;
            'strmenu':
                begin
                    if Args.Count < 1 then begin
                        SetError('StrMenu requires an options string');
                        exit(false);
                    end;
                    Arg1 := ProcessMessagePlaceholders(Args.Get(1), Args);
                    // Simplified: always return first option index
                    Result := '1';
                    exit(true);
                end;
            'confirm':
                begin
                    if Args.Count < 1 then begin
                        SetError('Confirm requires a question');
                        exit(false);
                    end;
                    Arg1 := ProcessMessagePlaceholders(Args.Get(1), Args);
                    Result := BoolToText(false);
                    exit(true);
                end;
            'page.run':
                begin
                    if Args.Count < 1 then begin
                        SetError('Page.Run requires a page ID');
                        exit(false);
                    end;
                    if not Evaluate(IntVal, Args.Get(1)) then begin
                        SetError('Invalid page ID for Page.Run');
                        exit(false);
                    end;
                    Result := 'true';
                    exit(true);
                end;
            'page.runmodal':
                begin
                    if Args.Count < 1 then begin
                        SetError('Page.RunModal requires a page ID');
                        exit(false);
                    end;
                    if not Evaluate(IntVal, Args.Get(1)) then begin
                        SetError('Invalid page ID for Page.RunModal');
                        exit(false);
                    end;
                    Result := 'true';
                    exit(true);
                end;
            'report.run':
                begin
                    if Args.Count < 1 then begin
                        SetError('Report.Run requires a report ID');
                        exit(false);
                    end;
                    if not Evaluate(IntVal, Args.Get(1)) then begin
                        SetError('Invalid report ID for Report.Run');
                        exit(false);
                    end;
                    Result := 'true';
                    exit(true);
                end;
            'codeunit.run':
                begin
                    if Args.Count < 1 then begin
                        SetError('Codeunit.Run requires a codeunit ID');
                        exit(false);
                    end;
                    if not Evaluate(IntVal, Args.Get(1)) then begin
                        SetError('Invalid codeunit ID for Codeunit.Run');
                        exit(false);
                    end;
                    Result := 'true';
                    exit(true);
                end;
            else begin
                SetError('Unknown function: ' + FunctionName);
                exit(false);
            end;
        end;
    end;

    local procedure ProcessMessagePlaceholders(FormatString: Text; Args: List of [Text]): Text
    var
        Result: Text;
        i: Integer;
        Ch: Char;
        PlaceholderNum: Text;
        PlaceholderIndex: Integer;
        ArgValue: Text;
    begin
        Result := '';
        i := 1;

        while i <= StrLen(FormatString) do begin
            Ch := FormatString[i];

            if Ch = '%' then begin
                // Check if next character is a digit
                if (i < StrLen(FormatString)) and IsDigit(FormatString[i + 1]) then begin
                    // Extract the placeholder number
                    PlaceholderNum := Format(FormatString[i + 1]);
                    if Evaluate(PlaceholderIndex, PlaceholderNum) then begin
                        // Convert to 1-based index for Args list (Args.Get(1) is the format string)
                        PlaceholderIndex += 1;
                        if PlaceholderIndex <= Args.Count then begin
                            ArgValue := Args.Get(PlaceholderIndex);
                            Result += ArgValue;
                        end else begin
                            // Missing argument, keep the placeholder
                            Result += '%' + PlaceholderNum;
                        end;
                    end else begin
                        // Not a valid number, keep the %
                        Result += Ch;
                    end;
                    i += 2; // Skip both % and the digit
                end else begin
                    // % not followed by digit, keep it as-is
                    Result += Ch;
                    i += 1;
                end;
            end else begin
                Result += Ch;
                i += 1;
            end;
        end;

        exit(Result);
    end;

    #endregion

    #region Record Operations

    local procedure ExecuteRecordMethod(RecordVarName: Text; MethodName: Text; var Result: Text): Boolean
    var
        RecRef: RecordRef;
        Args: List of [Text];
        ArgValue: Text;
        FieldName: Text;
        FilterValue: Text;
        BoolResult: Boolean;
        IsCalcFields: Boolean;
        FieldNameFirstArg: Boolean;
    begin
        if LowerCase(RecordVarName) in ['page', 'report', 'codeunit'] then
            exit(ExecuteSystemObjectMethod(RecordVarName, MethodName, Result));

        if not GetActiveRecordRef(RecordVarName, RecRef) then begin
            SetError('Record variable not found: ' + RecordVarName);
            exit(false);
        end;

        if not ConsumeToken('(') then begin
            SetError('Expected ( after method name');
            exit(false);
        end;

        // Some methods require field names as strings, not evaluated expressions
        IsCalcFields := (LowerCase(MethodName) = 'calcfields') or (LowerCase(MethodName) = 'calcsums');
        FieldNameFirstArg := false;
        case LowerCase(MethodName) of
            'setrange', 'setfilter', 'validate', 'testfield', 'modifyall', 'getfilter':
                FieldNameFirstArg := true;
        end;

        // Parse arguments
        if GetCurrentToken() <> ')' then begin
            repeat
                if IsCalcFields then begin
                    // For CalcFields, parse as identifier (field name), not expression
                    ArgValue := GetCurrentToken();
                    Advance();
                    Args.Add(ArgValue);
                end else begin
                    // For methods where the first argument is a field name, support unquoted identifiers
                    if (Args.Count = 0) and FieldNameFirstArg and (GetCurrentTokenType() = 'IDENTIFIER') then begin
                        ArgValue := GetCurrentToken();
                        Advance();
                        Args.Add(ArgValue);
                    end else begin
                        if not EvaluateExpression(ArgValue) then
                            exit(false);
                        Args.Add(ArgValue);
                    end;
                end;

                if GetCurrentToken() = ',' then
                    Advance()
                else
                    break;
            until GetCurrentToken() = ')';
        end;

        if not ConsumeToken(')') then begin
            SetError('Expected ) after method arguments');
            exit(false);
        end;

        case LowerCase(MethodName) of
            'findfirst':
                begin
                    BoolResult := RecRef.FindFirst();
                    Result := BoolToText(BoolResult);
                    exit(true);
                end;
            'findlast':
                begin
                    BoolResult := RecRef.FindLast();
                    Result := BoolToText(BoolResult);
                    exit(true);
                end;
            'findset':
                begin
                    BoolResult := RecRef.FindSet();
                    Result := BoolToText(BoolResult);
                    exit(true);
                end;
            'next':
                begin
                    Result := Format(RecRef.Next());
                    exit(true);
                end;
            'setrange':
                begin
                    if Args.Count < 2 then begin
                        SetError('SetRange requires at least 2 arguments');
                        exit(false);
                    end;
                    FieldName := Args.Get(1);
                    FilterValue := Args.Get(2);
                    exit(SetRecordRange(RecRef, FieldName, FilterValue));
                end;
            'setfilter':
                begin
                    if Args.Count < 2 then begin
                        SetError('SetFilter requires at least 2 arguments');
                        exit(false);
                    end;
                    FieldName := Args.Get(1);
                    FilterValue := Args.Get(2);
                    exit(SetRecordFilter(RecRef, FieldName, FilterValue));
                end;
            'insert':
                begin
                    RecRef.Insert(true);
                    Result := 'true';
                    exit(true);
                end;
            'modify':
                begin
                    RecRef.Modify(true);
                    Result := 'true';
                    exit(true);
                end;
            'delete':
                begin
                    RecRef.Delete(true);
                    Result := 'true';
                    exit(true);
                end;
            'calcfields':
                begin
                    // CalcFields calculates flowfields
                    if Args.Count < 1 then begin
                        SetError('CalcFields requires at least 1 field name');
                        exit(false);
                    end;
                    // Calculate all specified fields
                    if not ExecuteCalcFields(RecRef, Args) then
                        exit(false);
                    Result := 'true';
                    exit(true);
                end;
            'calcsums':
                begin
                    // CalcSums calculates sums of SumIndexFields
                    if Args.Count < 1 then begin
                        SetError('CalcSums requires at least 1 field name');
                        exit(false);
                    end;
                    // Calculate sums using CalcSum (different from CalcFields)
                    if not ExecuteCalcSums(RecRef, Args) then
                        exit(false);
                    Result := 'true';
                    exit(true);
                end;
            'isempty':
                begin
                    BoolResult := RecRef.IsEmpty;
                    Result := BoolToText(BoolResult);
                    exit(true);
                end;
            'count':
                begin
                    Result := Format(RecRef.Count);
                    exit(true);
                end;
            'get':
                begin
                    if Args.Count < 1 then begin
                        SetError('Get requires at least 1 argument');
                        exit(false);
                    end;
                    // For Get, we'll use FindFirst as a simplified implementation
                    // This is a simplified implementation since Get requires RecordId
                    BoolResult := RecRef.FindFirst();
                    Result := BoolToText(BoolResult);
                    exit(true);
                end;
            'reset':
                begin
                    RecRef.Reset();
                    Result := 'true';
                    exit(true);
                end;
            'locktable':
                begin
                    RecRef.LockTable();
                    Result := 'true';
                    exit(true);
                end;
            'init':
                begin
                    RecRef.Init();
                    Result := 'true';
                    exit(true);
                end;
            'changecompany':
                begin
                    if Args.Count < 1 then begin
                        SetError('ChangeCompany requires 1 argument (company name)');
                        exit(false);
                    end;
                    RecRef.ChangeCompany(Args.Get(1));
                    Result := 'true';
                    exit(true);
                end;
            'deleteall':
                begin
                    RecRef.DeleteAll(true);
                    Result := 'true';
                    exit(true);
                end;
            'validate':
                begin
                    if Args.Count < 1 then begin
                        SetError('Validate requires at least 1 argument (field name)');
                        exit(false);
                    end;
                    if not ValidateRecordField(RecRef, Args) then
                        exit(false);
                    Result := 'true';
                    exit(true);
                end;
            'getfilter':
                begin
                    if Args.Count < 1 then begin
                        SetError('GetFilter requires 1 argument (field name)');
                        exit(false);
                    end;
                    if not GetRecordFilter(RecRef, Args.Get(1), Result) then
                        exit(false);
                    exit(true);
                end;
            'find':
                begin
                    // Find with operator: Find('=') or Find('<')
                    if Args.Count < 1 then begin
                        SetError('Find requires at least 1 argument (operator)');
                        exit(false);
                    end;
                    if not FindWithOperator(RecRef, Args, BoolResult) then
                        exit(false);
                    Result := BoolToText(BoolResult);
                    exit(true);
                end;
            'countapprox':
                begin
                    Result := Format(RecRef.CountApprox);
                    exit(true);
                end;
            'testfield':
                begin
                    if Args.Count < 2 then begin
                        SetError('TestField requires at least 2 arguments (field name, value)');
                        exit(false);
                    end;
                    if not TestRecordField(RecRef, Args) then
                        exit(false);
                    Result := 'true';
                    exit(true);
                end;
            'modifyall':
                begin
                    if Args.Count < 2 then begin
                        SetError('ModifyAll requires at least 2 arguments (field name, value)');
                        exit(false);
                    end;
                    if not ModifyAllRecords(RecRef, Args) then
                        exit(false);
                    Result := 'true';
                    exit(true);
                end;
            else begin
                SetError('Unknown record method: ' + MethodName);
                exit(false);
            end;
        end;
    end;

    local procedure ExecuteSystemObjectMethod(ObjectName: Text; MethodName: Text; var Result: Text): Boolean
    var
        Args: List of [Text];
        ArgValue: Text;
        PageId: Integer;
        ReportId: Integer;
        CodeunitId: Integer;
    begin
        if not ConsumeToken('(') then begin
            SetError('Expected ( after method name');
            exit(false);
        end;

        if GetCurrentToken() <> ')' then begin
            repeat
                if not EvaluateExpression(ArgValue) then
                    exit(false);
                Args.Add(ArgValue);

                if GetCurrentToken() = ',' then
                    Advance()
                else
                    break;
            until GetCurrentToken() = ')';
        end;

        if not ConsumeToken(')') then begin
            SetError('Expected ) after method arguments');
            exit(false);
        end;

        case LowerCase(ObjectName) of
            'page':
                case LowerCase(MethodName) of
                    'run':
                        begin
                            if Args.Count <> 1 then begin
                                SetError('Page.Run requires exactly 1 argument (page ID)');
                                exit(false);
                            end;
                            if not Evaluate(PageId, Args.Get(1)) then begin
                                SetError('Invalid page ID for Page.Run');
                                exit(false);
                            end;
                            if GuiAllowed and not ForceConsoleOnly then
                                Page.Run(PageId);
                            Result := 'true';
                            exit(true);
                        end;
                    'runmodal':
                        begin
                            if Args.Count <> 1 then begin
                                SetError('Page.RunModal requires exactly 1 argument (page ID)');
                                exit(false);
                            end;
                            if not Evaluate(PageId, Args.Get(1)) then begin
                                SetError('Invalid page ID for Page.RunModal');
                                exit(false);
                            end;
                            if GuiAllowed and not ForceConsoleOnly then
                                Page.RunModal(PageId);
                            Result := 'true';
                            exit(true);
                        end;
                end;
            'report':
                if LowerCase(MethodName) = 'run' then begin
                    if Args.Count <> 1 then begin
                        SetError('Report.Run requires exactly 1 argument (report ID)');
                        exit(false);
                    end;
                    if not Evaluate(ReportId, Args.Get(1)) then begin
                        SetError('Invalid report ID for Report.Run');
                        exit(false);
                    end;
                    if GuiAllowed and not ForceConsoleOnly then
                        Report.Run(ReportId, false);
                    Result := 'true';
                    exit(true);
                end;
            'codeunit':
                if LowerCase(MethodName) = 'run' then begin
                    if Args.Count <> 1 then begin
                        SetError('Codeunit.Run requires exactly 1 argument (codeunit ID)');
                        exit(false);
                    end;
                    if not Evaluate(CodeunitId, Args.Get(1)) then begin
                        SetError('Invalid codeunit ID for Codeunit.Run');
                        exit(false);
                    end;
                    Codeunit.Run(CodeunitId);
                    Result := 'true';
                    exit(true);
                end;
        end;

        SetError(UpperCase(ObjectName) + '.' + MethodName + ' is not supported');
        exit(false);
    end;

    local procedure GetRecordTableName(RecordVarName: Text): Text
    var
        i: Integer;
        Entry: Text;
        Parts: List of [Text];
    begin
        for i := 1 to RecordVarNames.Count do begin
            Entry := RecordVarNames.Get(i);
            if Entry.StartsWith(RecordVarName + '|') then begin
                Parts := Entry.Split('|');
                if Parts.Count >= 2 then
                    exit(Parts.Get(2));
            end;
        end;
        exit('');
    end;

    local procedure GetTableIdByName(TableName: Text): Integer
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Use Table Metadata to dynamically find table ID by name
        TableMetadata.SetRange(Name, TableName);
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::No);
        if TableMetadata.FindFirst() then
            exit(TableMetadata.ID);
        exit(0);
    end;

    local procedure GetActiveRecordRef(RecordVarName: Text; var RecRef: RecordRef): Boolean
    var
        i: Integer;
        TableName: Text;
        TableId: Integer;
    begin
        // Check if RecordRef already exists
        for i := 1 to 10 do begin
            if ActiveRecordRefNames[i] = RecordVarName then begin
                RecRef := ActiveRecordRefs[i];
                exit(true);
            end;
        end;

        // Create new active RecordRef
        TableName := GetRecordTableName(RecordVarName);
        if TableName = '' then
            exit(false);

        TableId := GetTableIdByName(TableName);
        if TableId = 0 then begin
            SetError('Table not found or not supported: ' + TableName);
            exit(false);
        end;

        // Find empty slot
        for i := 1 to 10 do begin
            if ActiveRecordRefNames[i] = '' then begin
                ActiveRecordRefs[i].Open(TableId);
                ActiveRecordRefNames[i] := CopyStr(RecordVarName, 1, 50);
                if ActiveRecordRefCount < i then
                    ActiveRecordRefCount := i;
                RecRef := ActiveRecordRefs[i];
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure ExecuteCalcFields(var RecRef: RecordRef; FieldNames: List of [Text]): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        i: Integer;
        FieldName: Text;
    begin
        // Calculate each specified field
        for i := 1 to FieldNames.Count do begin
            FieldName := FieldNames.Get(i);
            FieldNo := GetFieldNumber(RecRef, FieldName);
            if FieldNo = 0 then begin
                SetError('Field not found for CalcFields: ' + FieldName);
                exit(false);
            end;

            FieldRef := RecRef.Field(FieldNo);
            FieldRef.CalcField();
        end;

        exit(true);
    end;

    local procedure ExecuteCalcSums(var RecRef: RecordRef; FieldNames: List of [Text]): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        i: Integer;
        FieldName: Text;
    begin
        // Calculate sum for each specified field
        for i := 1 to FieldNames.Count do begin
            FieldName := FieldNames.Get(i);
            FieldNo := GetFieldNumber(RecRef, FieldName);
            if FieldNo = 0 then begin
                SetError('Field not found for CalcSums: ' + FieldName);
                exit(false);
            end;

            FieldRef := RecRef.Field(FieldNo);
            FieldRef.CalcSum();
        end;

        exit(true);
    end;

    local procedure SetRecordRange(var RecRef: RecordRef; FieldName: Text; FilterValue: Text): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        IntValue: Integer;
        DecValue: Decimal;
        DateValue: Date;
        BoolValue: Boolean;
    begin
        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);

        // Use SetFilter for all cases as it's most flexible and handles all field types
        // including Option/Enum fields with text values
        FieldRef.SetFilter(FilterValue);

        exit(true);
    end;

    local procedure SetRecordFilter(var RecRef: RecordRef; FieldName: Text; FilterText: Text): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
    begin
        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetFilter(FilterText);
        exit(true);
    end;

    local procedure GetRecordFieldValue(RecordVarName: Text; FieldName: Text; var Value: Text): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldNo: Integer;
    begin
        if not GetActiveRecordRef(RecordVarName, RecRef) then begin
            SetError('Record variable not found: ' + RecordVarName);
            exit(false);
        end;

        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        Value := Format(FieldRef.Value);
        exit(true);
    end;

    local procedure SetRecordFieldValue(RecordVarName: Text; FieldName: Text; Value: Text): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldNo: Integer;
    begin
        if not GetActiveRecordRef(RecordVarName, RecRef) then begin
            SetError('Record variable not found: ' + RecordVarName);
            exit(false);
        end;

        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);

        if FieldRef.Type = FieldRef.Type::Option then begin
            if not SetOptionFieldValue(FieldRef, FieldName, Value) then
                exit(false);
            exit(true);
        end;

        FieldRef.Value := Value;
        exit(true);
    end;

    local procedure SetOptionFieldValue(var FieldRef: FieldRef; FieldName: Text; OptionValue: Text): Boolean
    var
        OptionString: Text;
        OptionEntries: List of [Text];
        OptionEntry: Text;
        NormalizedOption: Text;
        NormalizedTarget: Text;
        CleanValue: Text;
        Index: Integer;
        EnumValue: Integer;
        DelimitPos: Integer;
    begin
        CleanValue := OptionValue;

        if Evaluate(EnumValue, CleanValue) then begin
            FieldRef.Value := EnumValue;
            exit(true);
        end;

        DelimitPos := StrPos(CleanValue, '::');
        if DelimitPos > 0 then
            CleanValue := CopyStr(CleanValue, DelimitPos + 2);

        CleanValue := DelChr(CleanValue, '=', '''" ');
        NormalizedTarget := LowerCase(DelChr(DelChr(CleanValue, '<', ' '), '>', ' '));

        OptionString := FieldRef.OptionMembers();
        OptionEntries := OptionString.Split(',');

        for Index := 1 to OptionEntries.Count do begin
            OptionEntry := OptionEntries.Get(Index);
            NormalizedOption := LowerCase(DelChr(DelChr(DelChr(OptionEntry, '=', ' '), '<', ' '), '>', ' '));

            if NormalizedOption = NormalizedTarget then begin
                FieldRef.Value := Index - 1;
                exit(true);
            end;
        end;

        if NormalizedTarget = '' then begin
            FieldRef.Value := 0;
            exit(true);
        end;

        SetError('Option value not recognized for field ' + FieldName + ': ' + OptionValue);
        exit(false);
    end;

    local procedure GetFieldNumber(RecRef: RecordRef; FieldName: Text): Integer
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if UpperCase(FieldRef.Name) = UpperCase(FieldName) then
                exit(FieldRef.Number);
        end;
        exit(0);
    end;

    local procedure ValidateRecordField(var RecRef: RecordRef; Args: List of [Text]): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        FieldName: Text;
        Value: Text;
    begin
        FieldName := Args.Get(1);
        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found for Validate: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);

        if Args.Count >= 2 then begin
            Value := Args.Get(2);
            FieldRef.Validate(Value);
        end else
            FieldRef.Validate();

        exit(true);
    end;

    local procedure GetRecordFilter(var RecRef: RecordRef; FieldName: Text; var FilterText: Text): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
    begin
        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found for GetFilter: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        FilterText := FieldRef.GetFilter();
        exit(true);
    end;

    local procedure FindWithOperator(var RecRef: RecordRef; Args: List of [Text]; var BoolResult: Boolean): Boolean
    var
        Operator: Text;
    begin
        Operator := Args.Get(1);
        case Operator of
            '=':
                BoolResult := RecRef.Find('=');
            '<>':
                BoolResult := RecRef.Find('<>');
            '<':
                BoolResult := RecRef.Find('<');
            '>':
                BoolResult := RecRef.Find('>');
            '<=':
                BoolResult := RecRef.Find('<=');
            '>=':
                BoolResult := RecRef.Find('>=');
            else begin
                SetError('Invalid operator for Find: ' + Operator);
                exit(false);
            end;
        end;
        exit(true);
    end;

    local procedure TestRecordField(var RecRef: RecordRef; Args: List of [Text]): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        FieldName: Text;
        TestValue: Text;
    begin
        FieldName := Args.Get(1);
        TestValue := Args.Get(2);

        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found for TestField: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        FieldRef.TestField(TestValue);
        exit(true);
    end;

    local procedure ModifyAllRecords(var RecRef: RecordRef; Args: List of [Text]): Boolean
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        FieldName: Text;
        Value: Text;
        BoolResult: Boolean;
    begin
        if Args.Count < 2 then begin
            SetError('ModifyAll requires at least 2 arguments (field name, value)');
            exit(false);
        end;

        FieldName := Args.Get(1);
        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found for ModifyAll: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        Value := Args.Get(2);

        // Iterate through filtered records and modify each record individually
        if RecRef.FindSet() then begin
            repeat
                FieldRef := RecRef.Field(FieldNo);
                FieldRef.Value := Value;
                BoolResult := RecRef.Modify(true);
                if not BoolResult then begin
                    SetError('Modify failed for record during ModifyAll');
                    exit(false);
                end;
            until RecRef.Next() = 0;
        end;

        exit(true);
    end;

    #endregion

    local procedure SetError(ErrMsg: Text)
    begin
        if ErrorMessage = '' then
            ErrorMessage := ErrMsg;
    end;

    local procedure ParseCaseStatement(): Boolean
    var
        ExpressionValue: Text;
        CaseValue: Text;
        BranchMatches: Boolean;
        Matched: Boolean;
        MatchedStart: Integer;
        MatchedEnd: Integer;
        CaseEndIndex: Integer;
        ScanIndex: Integer;
        SavedIndex: Integer;
        BranchStart: Integer;
        BranchEnd: Integer;
    begin
        Advance(); // Skip 'case'

        if not EvaluateExpression(ExpressionValue) then
            exit(false);

        if not ConsumeKeyword('of') then begin
            SetError('Expected OF after CASE expression');
            exit(false);
        end;

        Matched := false;
        MatchedStart := 0;
        MatchedEnd := 0;

        CaseEndIndex := FindCaseEndIndex(CurrentTokenIndex);
        if CaseEndIndex = 0 then begin
            SetError('Expected END for CASE statement');
            exit(false);
        end;

        ScanIndex := CurrentTokenIndex;

        while ScanIndex < CaseEndIndex do begin
            while (ScanIndex < CaseEndIndex) and (PeekTokenAt(ScanIndex) = ';') do
                ScanIndex := ScanIndex + 1;

            if ScanIndex >= CaseEndIndex then
                break;

            case LowerCase(PeekTokenAt(ScanIndex)) of
                'else':
                    begin
                        if not Matched then begin
                            Matched := true;
                            MatchedStart := ScanIndex + 1;
                            MatchedEnd := CaseEndIndex;
                        end;
                        ScanIndex := CaseEndIndex;
                        break;
                    end;
                'end':
                    break;
                else begin
                    SavedIndex := CurrentTokenIndex;
                    CurrentTokenIndex := ScanIndex;
                    BranchMatches := false;

                    repeat
                        if not EvaluateExpression(CaseValue) then begin
                            CurrentTokenIndex := SavedIndex;
                            exit(false);
                        end;

                        if not Matched and not BranchMatches then
                            BranchMatches := ValuesEqual(ExpressionValue, CaseValue);

                        if GetCurrentToken() = ',' then begin
                            Advance();
                            continue;
                        end else
                            break;
                    until false;

                    if not ConsumeToken(':') then begin
                        SetError('Expected : after CASE branch value');
                        CurrentTokenIndex := SavedIndex;
                        exit(false);
                    end;

                    BranchStart := CurrentTokenIndex;
                    BranchEnd := FindCaseBranchEnd(BranchStart, CaseEndIndex);

                    if BranchMatches and not Matched then begin
                        Matched := true;
                        MatchedStart := BranchStart;
                        MatchedEnd := BranchEnd;
                    end;

                    ScanIndex := BranchEnd;
                    CurrentTokenIndex := SavedIndex;
                end;
            end;
        end;

        if Matched and (MatchedStart > 0) then begin
            CurrentTokenIndex := MatchedStart;
            while CurrentTokenIndex < MatchedEnd do begin
                if not ParseStatement() then
                    exit(false);
            end;
            CurrentTokenIndex := MatchedEnd;
        end else begin
            CurrentTokenIndex := CaseEndIndex;
        end;

        if CurrentTokenIndex < CaseEndIndex then
            CurrentTokenIndex := CaseEndIndex;

        if LowerCase(GetCurrentToken()) = 'end' then
            Advance();

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure FindCaseEndIndex(StartIndex: Integer): Integer
    var
        i: Integer;
        NestLevel: Integer;
        Token: Text;
    begin
        NestLevel := 0;

        for i := StartIndex to TokenList.Count do begin
            Token := LowerCase(TokenList.Get(i));

            case Token of
                'case', 'begin', 'repeat':
                    NestLevel := NestLevel + 1;
                'end':
                    begin
                        if NestLevel = 0 then
                            exit(i);
                        NestLevel := NestLevel - 1;
                    end;
                'until':
                    if NestLevel > 0 then
                        NestLevel := NestLevel - 1;
            end;
        end;

        exit(0);
    end;

    local procedure FindCaseBranchEnd(StartIndex: Integer; CaseEndIndex: Integer): Integer
    var
        i: Integer;
        NestLevel: Integer;
        Token: Text;
    begin
        i := StartIndex;
        NestLevel := 0;

        while i < CaseEndIndex do begin
            Token := LowerCase(PeekTokenAt(i));

            case Token of
                'case', 'begin', 'repeat':
                    begin
                        NestLevel := NestLevel + 1;
                        i := i + 1;
                        continue;
                    end;
                'end':
                    begin
                        if NestLevel = 0 then
                            exit(i);
                        NestLevel := NestLevel - 1;
                        i := i + 1;
                        continue;
                    end;
                'until':
                    begin
                        if NestLevel > 0 then
                            NestLevel := NestLevel - 1;
                        i := i + 1;
                        continue;
                    end;
                'else':
                    if NestLevel = 0 then
                        exit(i);
            end;

            if (PeekTokenAt(i) = ';') and (NestLevel = 0) then begin
                if NextTokenIsCaseBranch(i + 1, CaseEndIndex) then
                    exit(i + 1);
            end;

            i := i + 1;
        end;

        exit(CaseEndIndex);
    end;

    local procedure NextTokenIsCaseBranch(StartIndex: Integer; CaseEndIndex: Integer): Boolean
    var
        i: Integer;
        Token: Text;
    begin
        i := StartIndex;

        while i < CaseEndIndex do begin
            Token := LowerCase(PeekTokenAt(i));

            if Token = 'else' then
                exit(false);
            if Token = 'end' then
                exit(false);
            if Token = ';' then
                exit(false);
            if Token = ':' then
                exit(true);

            i := i + 1;
        end;

        exit(false);
    end;

    local procedure ValuesEqual(Left: Text; Right: Text): Boolean
    begin
        exit(CompareValues(Left, Right, '='));
    end;

    local procedure ParseExitStatement(): Boolean
    var
        ReturnValue: Text;
    begin
        Advance(); // Skip 'exit'

        ReturnValue := '';

        // Check if exit has a return value: exit(expression)
        if GetCurrentToken() = '(' then begin
            Advance(); // Skip '('
            if not EvaluateExpression(ReturnValue) then
                exit(false);
            if not ConsumeToken(')') then begin
                SetError('Expected ) after exit return value');
                exit(false);
            end;
        end;

        if ProcedureExecutionDepth > 0 then begin
            ProcedureExitRequested := true;
            ProcedureReturnValue := ReturnValue;
        end else begin
            ProcedureReturnValue := ReturnValue;
            CurrentTokenIndex := CurrentExecutionEndIndex + 1;
        end;

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseForLoop(): Boolean
    var
        VarName: Text;
        StartValue: Text;
        EndValue: Text;
        StepValue: Text;
        CurrentValue: Integer;
        EndInt: Integer;
        StepInt: Integer;
        LoopStartIndex: Integer;
        LoopEndIndex: Integer;
    begin
        Advance(); // Skip 'for'

        if GetCurrentTokenType() <> 'IDENTIFIER' then begin
            SetError('Expected variable name after for');
            exit(false);
        end;
        VarName := GetCurrentToken();
        Advance();

        if not ConsumeToken(':=') then begin
            SetError('Expected := after for variable');
            exit(false);
        end;

        if not EvaluateExpression(StartValue) then
            exit(false);

        if not ConsumeToken('to') then begin
            SetError('Expected to after start value');
            exit(false);
        end;

        if not EvaluateExpression(EndValue) then
            exit(false);

        StepValue := '1';
        if LowerCase(GetCurrentToken()) = 'step' then begin
            Advance();
            if not EvaluateExpression(StepValue) then
                exit(false);
        end;

        if not ConsumeToken('do') then begin
            SetError('Expected do after for loop');
            exit(false);
        end;

        if not Evaluate(CurrentValue, StartValue) then begin
            SetError('Start value must be integer');
            exit(false);
        end;
        if not Evaluate(EndInt, EndValue) then begin
            SetError('End value must be integer');
            exit(false);
        end;
        if not Evaluate(StepInt, StepValue) then begin
            SetError('Step value must be integer');
            exit(false);
        end;
        if StepInt = 0 then begin
            SetError('Step value must not be zero');
            exit(false);
        end;

        LoopStartIndex := CurrentTokenIndex;
        LoopEndIndex := FindStatementEnd(CurrentTokenIndex);
        if LoopEndIndex = 0 then begin
            SetError('Could not find end of for loop');
            exit(false);
        end;

        while true do begin
            if StepInt > 0 then begin
                if CurrentValue > EndInt then
                    break;
            end else begin
                if CurrentValue < EndInt then
                    break;
            end;

            if not SetVariableValue(VarName, Format(CurrentValue)) then
                if not AddVariable(VarName, Format(CurrentValue), 'Integer') then
                    exit(false);

            CurrentTokenIndex := LoopStartIndex;
            while CurrentTokenIndex < LoopEndIndex do begin
                if not ParseStatement() then
                    exit(false);
            end;

            if ErrorMessage = 'BREAK' then begin
                ErrorMessage := '';
                break;
            end;
            if ErrorMessage = 'CONTINUE' then begin
                ErrorMessage := '';
                CurrentValue += StepInt;
                continue;
            end;

            CurrentValue += StepInt;
        end;

        CurrentTokenIndex := LoopEndIndex;
        exit(true);
    end;

    local procedure ParseWhileLoop(): Boolean
    var
        Condition: Text;
        ConditionResult: Boolean;
        LoopStartIndex: Integer;
        LoopEndIndex: Integer;
        i: Integer;
    begin
        Advance(); // Skip 'while'

        // Store loop start position
        LoopStartIndex := CurrentTokenIndex;

        // Find the end of the loop body
        LoopEndIndex := FindStatementEnd(CurrentTokenIndex);
        if LoopEndIndex = 0 then begin
            SetError('Could not find end of while loop');
            exit(false);
        end;

        // Execute the loop
        while true do begin
            // Evaluate condition
            if not EvaluateCondition(ConditionResult) then
                exit(false);

            if not ConditionResult then
                break;

            // Execute loop body
            i := CurrentTokenIndex;
            CurrentTokenIndex := LoopStartIndex;
            if not ParseAndExecute() then
                exit(false);
            CurrentTokenIndex := i;

            // Check if we hit break or continue
            if ErrorMessage = 'BREAK' then begin
                ErrorMessage := '';
                break;
            end;
            if ErrorMessage = 'CONTINUE' then begin
                ErrorMessage := '';
                continue;
            end;
        end;

        // Skip to end of loop
        CurrentTokenIndex := LoopEndIndex;
        exit(true);
    end;

    #endregion

    #region Procedure Runtime

    local procedure ParseProcedureDeclaration(): Boolean
    var
        ProcedureName: Text;
        ParamSignature: Text;
        ReturnType: Text;
        LocalVarSignature: Text;
        BodyStartIndex: Integer;
        BodyEndIndex: Integer;
        EndTokenIndex: Integer;
    begin
        Advance(); // Skip 'procedure'

        if GetCurrentTokenType() <> 'IDENTIFIER' then begin
            SetError('Expected procedure name');
            exit(false);
        end;
        ProcedureName := GetCurrentToken();
        Advance();

        if not ConsumeToken('(') then begin
            SetError('Expected ( after procedure name');
            exit(false);
        end;

        if not ParseProcedureParameters(ParamSignature) then
            exit(false);

        if not ConsumeToken(')') then begin
            SetError('Expected ) after procedure parameters');
            exit(false);
        end;

        ReturnType := '';
        if GetCurrentToken() = ':' then begin
            Advance();
            if not IsTypeToken(GetCurrentTokenType()) then begin
                SetError('Expected return type after procedure declaration');
                exit(false);
            end;
            ReturnType := GetCurrentToken();
            Advance();

            if LowerCase(ReturnType) = 'record' then begin
                if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                    SetError('Expected table name for record return type');
                    exit(false);
                end;
                ReturnType := ReturnType + '|' + GetCurrentToken();
                Advance();
            end;
        end;

        LocalVarSignature := '';
        if LowerCase(GetCurrentToken()) = 'var' then begin
            Advance();
            if not ParseProcedureVariables(LocalVarSignature) then
                exit(false);
        end;

        if LowerCase(GetCurrentToken()) <> 'begin' then begin
            SetError('Expected BEGIN in procedure ' + ProcedureName);
            exit(false);
        end;
        Advance(); // Skip 'begin'
        BodyStartIndex := CurrentTokenIndex;

        if not FindProcedureBodyEndIndex(BodyStartIndex, BodyEndIndex, EndTokenIndex) then
            exit(false);

        if not RegisterProcedure(ProcedureName, BodyStartIndex, BodyEndIndex, ParamSignature, ReturnType, LocalVarSignature) then
            exit(false);

        CurrentTokenIndex := EndTokenIndex + 1;
        if GetCurrentToken() = ';' then
            Advance();

        exit(true);
    end;

    local procedure ParseProcedureParameters(var Signature: Text): Boolean
    var
        ParamName: Text;
        TypeDescriptor: Text;
        Separator: Text;
        IsVarParam: Boolean;
    begin
        Signature := '';

        if GetCurrentToken() = ')' then
            exit(true);

        repeat
            IsVarParam := false;
            if LowerCase(GetCurrentToken()) = 'var' then begin
                IsVarParam := true;
                Advance();
            end;

            if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                SetError('Expected parameter name in procedure declaration');
                exit(false);
            end;
            ParamName := GetCurrentToken();
            Advance();

            if not ConsumeToken(':') then begin
                SetError('Expected : after parameter name');
                exit(false);
            end;

            if not ParseTypeReference(TypeDescriptor) then
                exit(false);

            if IsVarParam then
                TypeDescriptor := 'var ' + TypeDescriptor;

            if Signature <> '' then
                Signature += ';';
            Signature += ParamName + ':' + TypeDescriptor;

            if (GetCurrentToken() = ',') or (GetCurrentToken() = ';') then begin
                Separator := GetCurrentToken();
                Advance();
            end else
                break;
        until GetCurrentToken() = ')';

        exit(true);
    end;

    local procedure ParseProcedureVariables(var Signature: Text): Boolean
    var
        VarName: Text;
        TypeDescriptor: Text;
    begin
        Signature := '';

        while GetCurrentTokenType() = 'IDENTIFIER' do begin
            VarName := GetCurrentToken();
            Advance();

            if not ConsumeToken(':') then begin
                SetError('Expected : after local variable name');
                exit(false);
            end;

            if not ParseTypeReference(TypeDescriptor) then
                exit(false);

            if Signature <> '' then
                Signature += ';';
            Signature += VarName + ':' + TypeDescriptor;

            ConsumeSemicolon();
        end;

        exit(true);
    end;

    local procedure FindProcedureBodyEndIndex(StartIndex: Integer; var BodyEndIndex: Integer; var EndTokenIndex: Integer): Boolean
    var
        Depth: Integer;
        i: Integer;
        Token: Text;
    begin
        BodyEndIndex := StartIndex - 1;
        Depth := 1;
        i := StartIndex;

        while i <= TokenList.Count do begin
            Token := LowerCase(TokenList.Get(i));
            case Token of
                'begin':
                    Depth += 1;
                'end':
                    begin
                        Depth -= 1;
                        if Depth = 0 then begin
                            BodyEndIndex := i - 1;
                            EndTokenIndex := i;
                            exit(true);
                        end;
                    end;
            end;
            i += 1;
        end;

        SetError('Could not find END for procedure body');
        exit(false);
    end;

    local procedure RegisterProcedure(ProcedureName: Text; BodyStartIndex: Integer; BodyEndIndex: Integer; ParamSignature: Text; ReturnType: Text; LocalVarSignature: Text): Boolean
    begin
        if HasProcedure(ProcedureName) then begin
            SetError('Procedure already defined: ' + ProcedureName);
            exit(false);
        end;

        ProcedureNames.Add(ProcedureName);
        ProcedureBodyStartIndexes.Add(BodyStartIndex);
        ProcedureBodyEndIndexes.Add(BodyEndIndex);
        ProcedureParamSignatures.Add(ParamSignature);
        ProcedureReturnTypes.Add(ReturnType);
        ProcedureLocalVarSignatures.Add(LocalVarSignature);
        exit(true);
    end;

    local procedure HasProcedure(ProcedureName: Text): Boolean
    begin
        exit(GetProcedureIndex(ProcedureName) > 0);
    end;

    local procedure GetProcedureIndex(ProcedureName: Text): Integer
    var
        i: Integer;
    begin
        for i := 1 to ProcedureNames.Count do begin
            if LowerCase(ProcedureNames.Get(i)) = LowerCase(ProcedureName) then
                exit(i);
        end;
        exit(0);
    end;

    local procedure DecodeSignature(Signature: Text; var Names: List of [Text]; var Types: List of [Text])
    var
        Entries: List of [Text];
        Parts: List of [Text];
        i: Integer;
        Entry: Text;
    begin
        Clear(Names);
        Clear(Types);

        if Signature = '' then
            exit;

        Entries := Signature.Split(';');
        for i := 1 to Entries.Count do begin
            Entry := Entries.Get(i);
            Parts := Entry.Split(':');
            if Parts.Count >= 2 then begin
                Names.Add(Parts.Get(1));
                Types.Add(Parts.Get(2));
            end;
        end;
    end;

    local procedure ExecuteProcedureCall(ProcedureName: Text; var Result: Text): Boolean
    var
        Args: List of [Text];
        ArgIdentifiers: List of [Text];
        ArgValue: Text;
        ArgIdentifier: Text;
        StartIndex: Integer;
    begin
        Result := '';

        if not ConsumeToken('(') then begin
            SetError('Expected ( after procedure name ' + ProcedureName);
            exit(false);
        end;

        if GetCurrentToken() <> ')' then begin
            repeat
                ArgIdentifier := '';
                StartIndex := CurrentTokenIndex;
                if GetCurrentTokenType() = 'IDENTIFIER' then
                    ArgIdentifier := GetCurrentToken();

                if not EvaluateExpression(ArgValue) then
                    exit(false);

                if (ArgIdentifier <> '') and (CurrentTokenIndex <> StartIndex + 1) then
                    ArgIdentifier := '';

                Args.Add(ArgValue);
                ArgIdentifiers.Add(ArgIdentifier);

                if (GetCurrentToken() = ',') or (GetCurrentToken() = ';') then
                    Advance()
                else
                    break;
            until GetCurrentToken() = ')';
        end;

        if not ConsumeToken(')') then begin
            SetError('Expected ) after procedure arguments for ' + ProcedureName);
            exit(false);
        end;

        if not InvokeProcedure(ProcedureName, Args, ArgIdentifiers, Result) then
            exit(false);

        exit(true);
    end;

    local procedure InvokeProcedure(ProcedureName: Text; Args: List of [Text]; ArgIdentifiers: List of [Text]; var Result: Text): Boolean
    var
        ProcIndex: Integer;
        ParamNames: List of [Text];
        ParamTypes: List of [Text];
        LocalVarNames: List of [Text];
        LocalVarTypes: List of [Text];
        BodyStartIndex: Integer;
        BodyEndIndex: Integer;
        OldTokenIndex: Integer;
        OldExecutionEndIndex: Integer;
        OldVariableCount: Integer;
        OldRecordVarCount: Integer;
        OldProcedureExitRequested: Boolean;
        OldProcedureReturnValue: Text;
        OldProcedureExecutionDepth: Integer;
        i: Integer;
        LocalReturnValue: Text;
        TypeDescriptor: Text;
        VarParamOriginalNames: List of [Text];
        VarParamParamNames: List of [Text];
        VarParamValues: List of [Text];
        IsVarParam: Boolean;
        OriginalName: Text;
    begin
        ProcIndex := GetProcedureIndex(ProcedureName);
        if ProcIndex = 0 then begin
            SetError('Unknown procedure: ' + ProcedureName);
            exit(false);
        end;

        DecodeSignature(ProcedureParamSignatures.Get(ProcIndex), ParamNames, ParamTypes);
        if Args.Count <> ParamNames.Count then begin
            SetError(ProcedureName + ' expects ' + Format(ParamNames.Count) + ' argument(s) but received ' + Format(Args.Count));
            exit(false);
        end;

        Clear(VarParamOriginalNames);
        Clear(VarParamParamNames);
        Clear(VarParamValues);

        DecodeSignature(ProcedureLocalVarSignatures.Get(ProcIndex), LocalVarNames, LocalVarTypes);

        BodyStartIndex := ProcedureBodyStartIndexes.Get(ProcIndex);
        BodyEndIndex := ProcedureBodyEndIndexes.Get(ProcIndex);

        OldTokenIndex := CurrentTokenIndex;
        OldExecutionEndIndex := CurrentExecutionEndIndex;
        OldVariableCount := VariableNames.Count;
        OldRecordVarCount := RecordVarNames.Count;
        OldProcedureExitRequested := ProcedureExitRequested;
        OldProcedureReturnValue := ProcedureReturnValue;
        OldProcedureExecutionDepth := ProcedureExecutionDepth;

        ProcedureExecutionDepth += 1;
        ProcedureExitRequested := false;
        ProcedureReturnValue := '';

        // Declare parameters
        for i := 1 to ParamNames.Count do begin
            TypeDescriptor := ParamTypes.Get(i);
            IsVarParam := IsVarType(TypeDescriptor);

            if IsVarParam then begin
                OriginalName := '';
                if ArgIdentifiers.Count >= i then
                    OriginalName := ArgIdentifiers.Get(i);
                if OriginalName = '' then begin
                    SetError('VAR parameter ' + ParamNames.Get(i) + ' requires a variable argument');
                    PopVariableScope(OldVariableCount, OldRecordVarCount);
                    ProcedureExecutionDepth := OldProcedureExecutionDepth;
                    ProcedureExitRequested := OldProcedureExitRequested;
                    ProcedureReturnValue := OldProcedureReturnValue;
                    CurrentTokenIndex := OldTokenIndex;
                    CurrentExecutionEndIndex := OldExecutionEndIndex;
                    exit(false);
                end;

                if GetVariableIndex(OriginalName) = 0 then begin
                    SetError('Variable not found for VAR parameter: ' + OriginalName);
                    PopVariableScope(OldVariableCount, OldRecordVarCount);
                    ProcedureExecutionDepth := OldProcedureExecutionDepth;
                    ProcedureExitRequested := OldProcedureExitRequested;
                    ProcedureReturnValue := OldProcedureReturnValue;
                    CurrentTokenIndex := OldTokenIndex;
                    CurrentExecutionEndIndex := OldExecutionEndIndex;
                    exit(false);
                end;

                VarParamOriginalNames.Add(OriginalName);
                VarParamParamNames.Add(ParamNames.Get(i));
            end;

            if not DeclareVariableFromSignature(ParamNames.Get(i), TypeDescriptor) then begin
                PopVariableScope(OldVariableCount, OldRecordVarCount);
                ProcedureExecutionDepth := OldProcedureExecutionDepth;
                ProcedureExitRequested := OldProcedureExitRequested;
                ProcedureReturnValue := OldProcedureReturnValue;
                CurrentTokenIndex := OldTokenIndex;
                CurrentExecutionEndIndex := OldExecutionEndIndex;
                exit(false);
            end;
            if not SetVariableValue(ParamNames.Get(i), Args.Get(i)) then begin
                PopVariableScope(OldVariableCount, OldRecordVarCount);
                ProcedureExecutionDepth := OldProcedureExecutionDepth;
                ProcedureExitRequested := OldProcedureExitRequested;
                ProcedureReturnValue := OldProcedureReturnValue;
                CurrentTokenIndex := OldTokenIndex;
                CurrentExecutionEndIndex := OldExecutionEndIndex;
                exit(false);
            end;
        end;

        // Declare local variables
        for i := 1 to LocalVarNames.Count do begin
            if not DeclareVariableFromSignature(LocalVarNames.Get(i), LocalVarTypes.Get(i)) then begin
                PopVariableScope(OldVariableCount, OldRecordVarCount);
                ProcedureExecutionDepth := OldProcedureExecutionDepth;
                ProcedureExitRequested := OldProcedureExitRequested;
                ProcedureReturnValue := OldProcedureReturnValue;
                CurrentTokenIndex := OldTokenIndex;
                CurrentExecutionEndIndex := OldExecutionEndIndex;
                exit(false);
            end;
        end;

        CurrentTokenIndex := BodyStartIndex;
        CurrentExecutionEndIndex := BodyEndIndex;

        while (CurrentTokenIndex <= CurrentExecutionEndIndex) and (not ProcedureExitRequested) do begin
            if not ParseStatement() then begin
                PopVariableScope(OldVariableCount, OldRecordVarCount);
                ProcedureExecutionDepth := OldProcedureExecutionDepth;
                ProcedureExitRequested := OldProcedureExitRequested;
                ProcedureReturnValue := OldProcedureReturnValue;
                CurrentTokenIndex := OldTokenIndex;
                CurrentExecutionEndIndex := OldExecutionEndIndex;
                exit(false);
            end;
        end;

        Clear(VarParamValues);
        for i := 1 to VarParamParamNames.Count do
            VarParamValues.Add(GetVariableValue(VarParamParamNames.Get(i)));

        LocalReturnValue := ProcedureReturnValue;
        if (LocalReturnValue = '') and (ProcedureReturnTypes.Get(ProcIndex) <> '') then
            LocalReturnValue := GetDefaultValueForType(NormalizeVarType(ExtractBaseType(ProcedureReturnTypes.Get(ProcIndex))));

        Result := LocalReturnValue;

        CurrentTokenIndex := OldTokenIndex;
        CurrentExecutionEndIndex := OldExecutionEndIndex;
        ProcedureExecutionDepth := OldProcedureExecutionDepth;
        ProcedureExitRequested := OldProcedureExitRequested;
        ProcedureReturnValue := OldProcedureReturnValue;

        PopVariableScope(OldVariableCount, OldRecordVarCount);

        for i := 1 to VarParamOriginalNames.Count do
            SetVariableValue(VarParamOriginalNames.Get(i), VarParamValues.Get(i));

        exit(true);
    end;

    local procedure DeclareVariableFromSignature(VarName: Text; TypeDescriptor: Text): Boolean
    var
        BaseType: Text;
        NormalizedType: Text;
        SubType: Text;
        CleanDescriptor: Text;
    begin
        CleanDescriptor := StripVarModifier(TypeDescriptor);
        BaseType := ExtractBaseType(CleanDescriptor);
        NormalizedType := NormalizeVarType(BaseType);

        if LowerCase(NormalizedType) = 'record' then begin
            SubType := ExtractSubtype(CleanDescriptor);
            if SubType = '' then begin
                SetError('Record variable ' + VarName + ' requires a table name');
                exit(false);
            end;
            exit(CreateRecordVariable(VarName, SubType));
        end;

        exit(AddVariable(VarName, GetDefaultValueForType(NormalizedType), NormalizedType));
    end;

    local procedure NormalizeVarType(BaseType: Text): Text
    var
        Lower: Text;
    begin
        Lower := LowerCase(BaseType);
        Lower := StripLengthSpecifier(Lower);
        case Lower of
            'integer':
                exit('Integer');
            'text', 'code':
                exit('Text');
            'boolean':
                exit('Boolean');
            'decimal':
                exit('Decimal');
            'date':
                exit('Date');
            'datetime':
                exit('DateTime');
            'char':
                exit('Char');
            'bigtext':
                exit('BigText');
            'guid':
                exit('GUID');
            'option':
                exit('Option');
            'duration':
                exit('Duration');
            'blob':
                exit('Blob');
            'record':
                exit('Record');
            else
                exit(BaseType);
        end;
    end;

    local procedure IsVarType(TypeDescriptor: Text): Boolean
    var
        Lower: Text;
    begin
        Lower := LowerCase(TypeDescriptor);
        if (StrLen(Lower) >= 4) and (CopyStr(Lower, 1, 4) = 'var ') then
            exit(true);
        exit(false);
    end;

    local procedure StripVarModifier(TypeDescriptor: Text): Text
    var
        Lower: Text;
    begin
        Lower := LowerCase(TypeDescriptor);
        if (StrLen(TypeDescriptor) >= 4) and (CopyStr(Lower, 1, 4) = 'var ') then
            exit(CopyStr(TypeDescriptor, 5));
        exit(TypeDescriptor);
    end;

    local procedure StripLengthSpecifier(Value: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(Value, '[');
        if Pos > 0 then
            exit(CopyStr(Value, 1, Pos - 1));
        exit(Value);
    end;

    local procedure ExtractBaseType(TypeDescriptor: Text): Text
    var
        Parts: List of [Text];
        CleanDescriptor: Text;
    begin
        CleanDescriptor := StripVarModifier(TypeDescriptor);
        Parts := CleanDescriptor.Split('|');
        if Parts.Count >= 1 then
            exit(Parts.Get(1));
        exit(CleanDescriptor);
    end;

    local procedure ExtractSubtype(TypeDescriptor: Text): Text
    var
        Parts: List of [Text];
        CleanDescriptor: Text;
    begin
        CleanDescriptor := StripVarModifier(TypeDescriptor);
        Parts := CleanDescriptor.Split('|');
        if Parts.Count >= 2 then
            exit(Parts.Get(2));
        exit('');
    end;

    local procedure GetDefaultValueForType(VarType: Text): Text
    begin
        case LowerCase(VarType) of
            'integer', 'decimal', 'option', 'duration':
                exit('0');
            'boolean':
                exit('false');
            'text', 'code', 'char', 'bigtext', 'blob':
                exit('');
            'date':
                exit(Format(0D));
            'datetime':
                exit(Format(0DT));
            'guid':
                exit(Format(CreateGuid()));
            'record':
                exit('');
            else
                exit('');
        end;
    end;

    local procedure PopVariableScope(KeepVariableCount: Integer; KeepRecordVarCount: Integer)
    begin
        while VariableNames.Count > KeepVariableCount do
            RemoveVariableAt(VariableNames.Count);

        TrimRecordVariables(KeepRecordVarCount);
    end;

    local procedure RemoveVariableAt(Index: Integer)
    begin
        VariableNames.RemoveAt(Index);
        VariableValues.RemoveAt(Index);
        VariableTypes.RemoveAt(Index);
    end;

    local procedure TrimRecordVariables(KeepCount: Integer)
    var
        i: Integer;
    begin
        while RecordVarNames.Count > KeepCount do
            RecordVarNames.RemoveAt(RecordVarNames.Count);

        for i := 1 to 10 do begin
            if ActiveRecordRefNames[i] <> '' then begin
                if not RecordVariableExists(ActiveRecordRefNames[i]) then begin
                    if ActiveRecordRefs[i].Number <> 0 then
                        ActiveRecordRefs[i].Close();
                    Clear(ActiveRecordRefs[i]);
                    Clear(ActiveRecordRefNames[i]);
                end;
            end;
        end;

        ActiveRecordRefCount := 0;
        for i := 1 to 10 do begin
            if ActiveRecordRefNames[i] <> '' then
                ActiveRecordRefCount := i;
        end;
    end;

    local procedure RecordVariableExists(VarName: Text): Boolean
    var
        i: Integer;
        Entry: Text;
    begin
        for i := 1 to RecordVarNames.Count do begin
            Entry := RecordVarNames.Get(i);
            if Entry.StartsWith(VarName + '|') then
                exit(true);
        end;
        exit(false);
    end;

    #endregion

    local procedure IsTypeToken(TokenType: Text): Boolean
    begin
        exit((TokenType = 'IDENTIFIER') or (TokenType = 'KEYWORD'));
    end;

    #region Query Support

    local procedure ParseQueryDeclaration(): Boolean
    var
        QueryName: Text;
        QueryDefinition: Text;
    begin
        Advance(); // Skip 'query'

        if GetCurrentTokenType() <> 'IDENTIFIER' then begin
            SetError('Expected query name');
            exit(false);
        end;
        QueryName := GetCurrentToken();
        Advance();

        if GetCurrentToken() = ';' then
            Advance();

        if not ConsumeToken('{') then begin
            SetError('Expected { after query name ' + QueryName);
            exit(false);
        end;

        if not ParseQueryBody(QueryDefinition) then
            exit(false);

        if not RegisterQuery(QueryName, QueryDefinition) then
            exit(false);

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseQueryBody(var QueryDefinition: Text): Boolean
    var
        DataItemDefinitions: List of [Text];
        TokenText: Text;
        TypeHelper: Codeunit "Type Helper";
    begin
        Clear(DataItemDefinitions);

        while CurrentTokenIndex <= TokenList.Count do begin
            TokenText := LowerCase(GetCurrentToken());

            if TokenText = 'elements' then begin
                Advance();
                if not ConsumeToken('{') then begin
                    SetError('Expected { after elements keyword');
                    exit(false);
                end;

                while CurrentTokenIndex <= TokenList.Count do begin
                    TokenText := LowerCase(GetCurrentToken());
                    if TokenText = 'dataitem' then begin
                        if not ParseQueryDataItem('', DataItemDefinitions) then
                            exit(false);
                        continue;
                    end;

                    if GetCurrentToken() = ';' then begin
                        Advance();
                        continue;
                    end;

                    if GetCurrentToken() = '}' then begin
                        Advance();
                        break;
                    end;

                    // Skip unknown element statements
                    Advance();
                end;

                continue;
            end;

            if TokenText = 'dataitem' then begin
                if not ParseQueryDataItem('', DataItemDefinitions) then
                    exit(false);
                continue;
            end;

            if GetCurrentToken() = ';' then begin
                Advance();
                continue;
            end;

            if GetCurrentToken() = '}' then
                break;

            // Skip query properties (e.g., QueryType, DataAccessIntent, Caption, Namespace)
            if PeekNextToken('=') then begin
                Advance(); // Skip property name
                Advance(); // Skip '='
                while (CurrentTokenIndex <= TokenList.Count) and (GetCurrentToken() <> ';') do
                    Advance();
                ConsumeSemicolon();
                continue;
            end;

            Advance();
        end;

        if not ConsumeToken('}') then begin
            SetError('Expected } to close query definition');
            exit(false);
        end;

        if DataItemDefinitions.Count = 0 then begin
            SetError('Query requires at least one dataitem');
            exit(false);
        end;

        QueryDefinition := JoinWithSeparator(DataItemDefinitions, TypeHelper.LFSeparator());
        exit(true);
    end;

    local procedure ParseQueryDataItem(ParentName: Text; var DataItemDefinitions: List of [Text]): Boolean
    var
        DataItemName: Text;
        TableName: Text;
        ColumnDefinitions: List of [Text];
        ColumnFilterDefinitions: List of [Text];
        ColumnMethodDefinitions: List of [Text];
        FilterDefinitions: List of [Text];
        LinkDefinitions: List of [Text];
        TableFilterDefinitions: List of [Text];
        ColumnSpec: Text;
        FilterSpec: Text;
        LinkSpec: Text;
        TableFilterSpec: Text;
        ColumnFilterSpec: Text;
        ColumnMethodSpec: Text;
        TokenText: Text;
    begin
        Advance(); // Skip 'dataitem'

        if not ConsumeToken('(') then begin
            SetError('Expected ( after dataitem');
            exit(false);
        end;

        if GetCurrentTokenType() <> 'IDENTIFIER' then begin
            SetError('Expected dataitem name');
            exit(false);
        end;
        DataItemName := GetCurrentToken();
        Advance();

        if not ConsumeToken(';') then begin
            SetError('Expected ; after dataitem name ' + DataItemName);
            exit(false);
        end;

        if (GetCurrentTokenType() <> 'IDENTIFIER') and (GetCurrentTokenType() <> 'STRING') and (GetCurrentTokenType() <> 'KEYWORD') then begin
            SetError('Expected table name for dataitem ' + DataItemName);
            exit(false);
        end;
        TableName := GetCurrentToken();
        Advance();

        if not ConsumeToken(')') then begin
            SetError('Expected ) after dataitem declaration ' + DataItemName);
            exit(false);
        end;

        if not ConsumeToken('{') then begin
            SetError('Expected { to start dataitem ' + DataItemName);
            exit(false);
        end;

        Clear(ColumnDefinitions);
        Clear(ColumnFilterDefinitions);
        Clear(ColumnMethodDefinitions);
        Clear(FilterDefinitions);
        Clear(LinkDefinitions);
        Clear(TableFilterDefinitions);

        while CurrentTokenIndex <= TokenList.Count do begin
            if GetCurrentToken() = '}' then
                break;

            TokenText := LowerCase(GetCurrentToken());

            case TokenText of
                'column':
                    begin
                        if not ParseQueryColumn(ColumnDefinitions, ColumnFilterDefinitions, ColumnMethodDefinitions) then
                            exit(false);
                        continue;
                    end;
                'filter':
                    begin
                        if not ParseQueryFilter(FilterDefinitions) then
                            exit(false);
                        continue;
                    end;
                'dataitemlink':
                    begin
                        if not ParseQueryDataItemLink(LinkDefinitions) then
                            exit(false);
                        continue;
                    end;
                'dataitemtablefilter':
                    begin
                        if not ParseQueryDataItemTableFilter(TableFilterDefinitions) then
                            exit(false);
                        continue;
                    end;
                'dataitem':
                    begin
                        if not ParseQueryDataItem(DataItemName, DataItemDefinitions) then
                            exit(false);
                        continue;
                    end;
            end;

            if GetCurrentToken() = ';' then begin
                Advance();
                continue;
            end;

            if PeekNextToken('=') then begin
                Advance(); // Skip property name
                Advance(); // Skip '='
                while (CurrentTokenIndex <= TokenList.Count) and (GetCurrentToken() <> ';') do
                    Advance();
                ConsumeSemicolon();
                continue;
            end;

            Advance();
        end;

        if not ConsumeToken('}') then begin
            SetError('Expected } to close dataitem ' + DataItemName);
            exit(false);
        end;

        if ColumnDefinitions.Count = 0 then begin
            SetError('Dataitem ' + DataItemName + ' must define at least one column');
            exit(false);
        end;

        ColumnSpec := JoinWithSeparator(ColumnDefinitions, ',');
        ColumnFilterSpec := JoinWithSeparator(ColumnFilterDefinitions, ',');
        ColumnMethodSpec := JoinWithSeparator(ColumnMethodDefinitions, ',');
        FilterSpec := JoinWithSeparator(FilterDefinitions, ',');
        LinkSpec := JoinWithSeparator(LinkDefinitions, ',');
        TableFilterSpec := JoinWithSeparator(TableFilterDefinitions, ',');

        DataItemDefinitions.Add(DataItemName + '|' + TableName + '|' + ColumnSpec + '|' + FilterSpec + '|' + ParentName + '|' + LinkSpec + '|' + TableFilterSpec + '|' + ColumnFilterSpec + '|' + ColumnMethodSpec);
        exit(true);
    end;

    local procedure ParseQueryDataItemTableFilter(var TableFilterDefinitions: List of [Text]): Boolean
    var
        FieldName: Text;
        FilterOperator: Text;
        FilterValue: Text;
        Definition: Text;
        FieldNameTokenType: Text;
        FilterValueTokenType: Text;
    begin
        Advance(); // Skip 'dataitemtablefilter'

        if not ConsumeToken('=') then begin
            SetError('Expected = after DataItemTableFilter');
            exit(false);
        end;

        // Parse comma-separated list of filter expressions: "Field" = filter(operator value), ...
        repeat
            // Field name (may be quoted)
            if (GetCurrentTokenType() = 'IDENTIFIER') or (GetCurrentTokenType() = 'STRING') then begin
                FieldName := GetCurrentToken();
                FieldNameTokenType := GetCurrentTokenType();
                // Strip quotes if field name is a string token
                if FieldNameTokenType = 'STRING' then begin
                    if (StrLen(FieldName) >= 2) and (FieldName[1] = '''') and (FieldName[StrLen(FieldName)] = '''') then
                        FieldName := CopyStr(FieldName, 2, StrLen(FieldName) - 2);
                end;
                Advance();
            end else begin
                SetError('Expected field name in DataItemTableFilter');
                exit(false);
            end;

            if not ConsumeToken('=') then begin
                SetError('Expected = after field name in DataItemTableFilter');
                exit(false);
            end;

            // Parse filter or const expression
            FilterOperator := '';
            FilterValue := '';

            case LowerCase(GetCurrentToken()) of
                'filter':
                    begin
                        Advance();
                        if not ConsumeToken('(') then begin
                            SetError('Expected ( after filter in DataItemTableFilter');
                            exit(false);
                        end;

                        if GetCurrentToken() = '<>' then begin
                            FilterOperator := '<>';
                            Advance();
                        end else if GetCurrentToken() = '<=' then begin
                            FilterOperator := '<=';
                            Advance();
                        end else if GetCurrentToken() = '>=' then begin
                            FilterOperator := '>=';
                            Advance();
                        end else if GetCurrentToken() in ['=', '<', '>'] then begin
                            FilterOperator := GetCurrentToken();
                            Advance();
                        end else begin
                            SetError('Expected filter operator (e.g., =, <>, <, >, <=, >=) in DataItemTableFilter');
                            exit(false);
                        end;

                        FilterValueTokenType := '';

                        if GetCurrentToken() = ')' then
                            FilterValue := ''''''
                        else begin
                            FilterValue := GetCurrentToken();
                            FilterValueTokenType := GetCurrentTokenType();

                            if (FilterValueTokenType = 'STRING') and (FilterValue = '') then
                                FilterValue := ''''''
                            else if FilterValueTokenType = 'STRING' then begin
                                if (StrLen(FilterValue) < 2) or (FilterValue[1] <> '''') or (FilterValue[StrLen(FilterValue)] <> '''') then
                                    FilterValue := '''' + FilterValue + '''';
                            end;

                            Advance();
                        end;

                        if not ConsumeToken(')') then begin
                            SetError('Expected ) after filter expression in DataItemTableFilter');
                            exit(false);
                        end;
                    end;
                'const':
                    begin
                        FilterOperator := '=';
                        Advance();
                        if not ConsumeToken('(') then begin
                            SetError('Expected ( after const in DataItemTableFilter');
                            exit(false);
                        end;

                        if not CollectParenthesizedExpression(FilterValue) then begin
                            SetError('Invalid const expression in DataItemTableFilter');
                            exit(false);
                        end;

                        if not ConsumeToken(')') then begin
                            SetError('Expected ) after const expression in DataItemTableFilter');
                            exit(false);
                        end;

                        FilterValue := NormalizeConstExpression(FilterValue);
                    end;
                else begin
                    SetError('Expected filter or const keyword in DataItemTableFilter');
                    exit(false);
                end;
            end;

            // Build filter definition: FieldName=OperatorValue
            // For empty string, ensure we have quotes: <>''
            // For other values, use as-is: =true, =1, ='value'
            Definition := FieldName + '=' + FilterOperator + FilterValue;
            TableFilterDefinitions.Add(Definition);

            // Check for comma separator (more filters)
            if GetCurrentToken() = ',' then begin
                Advance();
                continue;
            end;

            break;
        until false;

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseQueryDataItemLink(var LinkDefinitions: List of [Text]): Boolean
    var
        FieldName: Text;
        ParentAlias: Text;
        ParentField: Text;
        Definition: Text;
    begin
        Advance(); // Skip 'dataitemlink'

        if not ConsumeToken('=') then begin
            SetError('Expected = after DataItemLink');
            exit(false);
        end;

        repeat
            if GetCurrentToken() = '}' then begin
                SetError('Expected field mapping in DataItemLink');
                exit(false);
            end;

            if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                SetError('Expected field name in DataItemLink');
                exit(false);
            end;
            FieldName := GetCurrentToken();
            Advance();

            if not ConsumeToken('=') then begin
                SetError('Expected = in DataItemLink mapping');
                exit(false);
            end;

            ParentAlias := '';
            ParentField := '';

            if GetCurrentTokenType() in ['IDENTIFIER', 'KEYWORD'] then begin
                ParentAlias := GetCurrentToken();
                Advance();
                if GetCurrentToken() = '.' then begin
                    Advance();
                end else begin
                    ParentField := ParentAlias;
                    ParentAlias := '';
                end;
            end;

            if ParentField = '' then begin
                if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                    SetError('Expected parent field name in DataItemLink');
                    exit(false);
                end;
                ParentField := GetCurrentToken();
                Advance();
            end;

            Definition := FieldName + '=' + ParentField;
            LinkDefinitions.Add(Definition);

            if GetCurrentToken() = ',' then begin
                Advance();
                continue;
            end;

            break;
        until false;

        ConsumeSemicolon();
        exit(true);
    end;

    local procedure ParseQueryColumn(var ColumnDefinitions: List of [Text]; var ColumnFilterDefinitions: List of [Text]; var ColumnMethodDefinitions: List of [Text]): Boolean
    var
        ColumnName: Text;
        FieldName: Text;
        Definition: Text;
        ColumnFilterExpr: Text;
        ColumnMethod: Text;
        TokenText: Text;
        FilterExpression: Text;
        FilterAlias: Text;
    begin
        ColumnFilterExpr := '';
        ColumnMethod := '';

        Advance(); // Skip 'column'

        if not ConsumeToken('(') then begin
            SetError('Expected ( after column');
            exit(false);
        end;

        if GetCurrentTokenType() <> 'IDENTIFIER' then begin
            SetError('Expected column name');
            exit(false);
        end;
        ColumnName := GetCurrentToken();
        Advance();

        if not ConsumeToken(';') then begin
            SetError('Expected ; after column name ' + ColumnName);
            exit(false);
        end;

        if (GetCurrentTokenType() <> 'IDENTIFIER') and (GetCurrentTokenType() <> 'STRING') then begin
            SetError('Expected field name for column ' + ColumnName);
            exit(false);
        end;
        FieldName := GetCurrentToken();
        Advance();

        if not ConsumeToken(')') then begin
            SetError('Expected ) after column ' + ColumnName);
            exit(false);
        end;

        if GetCurrentToken() = '{' then begin
            Advance();
            while (CurrentTokenIndex <= TokenList.Count) and (GetCurrentToken() <> '}') do begin
                TokenText := LowerCase(GetCurrentToken());

                case TokenText of
                    'columnfilter':
                        begin
                            Advance();
                            if not ConsumeToken('=') then begin
                                SetError('Expected = after ColumnFilter');
                                exit(false);
                            end;

                            if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                                SetError('Expected column identifier in ColumnFilter');
                                exit(false);
                            end;
                            FilterAlias := GetCurrentToken();
                            Advance();

                            if not ConsumeToken('=') then begin
                                SetError('Expected = after ColumnFilter alias ' + FilterAlias);
                                exit(false);
                            end;

                            TokenText := LowerCase(GetCurrentToken());
                            if TokenText = 'filter' then begin
                                Advance();
                                if not ConsumeToken('(') then begin
                                    SetError('Expected ( after filter in ColumnFilter');
                                    exit(false);
                                end;

                                if not CollectParenthesizedExpression(FilterExpression) then begin
                                    SetError('Invalid filter expression in ColumnFilter');
                                    exit(false);
                                end;

                                if not ConsumeToken(')') then begin
                                    SetError('Expected ) after filter expression in ColumnFilter');
                                    exit(false);
                                end;

                                ColumnFilterExpr := FilterExpression;
                            end else if TokenText = 'const' then begin
                                Advance();
                                if not ConsumeToken('(') then begin
                                    SetError('Expected ( after const in ColumnFilter');
                                    exit(false);
                                end;

                                if not CollectParenthesizedExpression(FilterExpression) then begin
                                    SetError('Invalid const expression in ColumnFilter');
                                    exit(false);
                                end;

                                if not ConsumeToken(')') then begin
                                    SetError('Expected ) after const expression in ColumnFilter');
                                    exit(false);
                                end;

                                ColumnFilterExpr := NormalizeConstExpression(FilterExpression);
                            end else begin
                                SetError('Unsupported ColumnFilter expression');
                                exit(false);
                            end;

                            ConsumeSemicolon();
                            continue;
                        end;
                    'method':
                        begin
                            Advance();
                            if not ConsumeToken('=') then begin
                                SetError('Expected = after Method');
                                exit(false);
                            end;

                            if GetCurrentTokenType() <> 'IDENTIFIER' then begin
                                SetError('Expected method name in column definition');
                                exit(false);
                            end;
                            ColumnMethod := GetCurrentToken();
                            Advance();
                            ConsumeSemicolon();
                            continue;
                        end;
                end;

                // Skip unknown property or statements within column block
                while (CurrentTokenIndex <= TokenList.Count) and (GetCurrentToken() <> ';') and (GetCurrentToken() <> '}') do
                    Advance();
                ConsumeSemicolon();
            end;

            if not ConsumeToken('}') then begin
                SetError('Expected } to close column properties for ' + ColumnName);
                exit(false);
            end;
        end;

        Definition := ColumnName + ':' + FieldName;
        ColumnDefinitions.Add(Definition);
        ColumnFilterDefinitions.Add(ColumnFilterExpr);
        ColumnMethodDefinitions.Add(ColumnMethod);
        exit(true);
    end;

    local procedure ParseQueryFilter(var FilterDefinitions: List of [Text]): Boolean
    var
        FilterName: Text;
        FieldName: Text;
        FilterValue: Text;
        Definition: Text;
        FieldNameTokenType: Text;
        FilterValueTokenType: Text;
    begin
        Advance(); // Skip 'filter'

        if not ConsumeToken('(') then begin
            SetError('Expected ( after filter');
            exit(false);
        end;

        // First token is the filter identifier/name (optional, can be different from field name)
        if GetCurrentTokenType() <> 'IDENTIFIER' then begin
            SetError('Expected filter identifier');
            exit(false);
        end;
        FilterName := GetCurrentToken();
        Advance();

        if not ConsumeToken(';') then begin
            SetError('Expected ; after filter identifier ' + FilterName);
            exit(false);
        end;

        // After semicolon is the actual field name (may be quoted) or filter value
        // In AL query syntax: filter(FilterName; "Field Name") or filter(FilterName; "Field Name"; 'Value')
        if (GetCurrentTokenType() = 'IDENTIFIER') or (GetCurrentTokenType() = 'STRING') then begin
            FieldName := GetCurrentToken();
            FieldNameTokenType := GetCurrentTokenType();
            // Strip quotes if field name is a string token (double-quoted field names are already IDENTIFIER)
            if FieldNameTokenType = 'STRING' then begin
                // Remove surrounding quotes from string token
                if (StrLen(FieldName) >= 2) and (FieldName[1] = '''') and (FieldName[StrLen(FieldName)] = '''') then
                    FieldName := CopyStr(FieldName, 2, StrLen(FieldName) - 2);
            end;
            Advance();
        end else begin
            SetError('Expected field name or filter value after semicolon');
            exit(false);
        end;

        // Check if there's a filter value (third parameter)
        if GetCurrentToken() = ';' then begin
            Advance(); // Skip second semicolon
            if GetCurrentToken() in ['(', ')'] then begin
                SetError('Expected filter value after second semicolon');
                exit(false);
            end;
            FilterValue := GetCurrentToken();
            FilterValueTokenType := GetCurrentTokenType();
            // Strip quotes from filter value if it's a string token
            if FilterValueTokenType = 'STRING' then begin
                if (StrLen(FilterValue) >= 2) and (FilterValue[1] = '''') and (FilterValue[StrLen(FilterValue)] = '''') then
                    FilterValue := CopyStr(FilterValue, 2, StrLen(FilterValue) - 2);
            end;
            Advance();
        end else begin
            // No explicit filter value - use empty string (filter is defined but not set)
            FilterValue := '';
        end;

        if not ConsumeToken(')') then begin
            SetError('Expected ) after filter definition');
            exit(false);
        end;

        if GetCurrentToken() = '{' then begin
            if not SkipCurlyBlock() then
                exit(false);
        end;

        // Store as FieldName=FilterValue where FieldName is the actual field name (after semicolon)
        Definition := FieldName + '=' + FilterValue;
        FilterDefinitions.Add(Definition);
        exit(true);
    end;

    local procedure CollectParenthesizedExpression(var Expression: Text): Boolean
    var
        TokenValue: Text;
        TokenType: Text;
    begin
        Expression := '';

        while CurrentTokenIndex <= TokenList.Count do begin
            if GetCurrentToken() = ')' then
                exit(true);

            TokenValue := GetCurrentToken();
            TokenType := GetCurrentTokenType();

            if TokenType = 'STRING' then
                TokenValue := '''' + TokenValue + '''';

            Expression += TokenValue;
            Advance();
        end;

        exit(false);
    end;

    local procedure NormalizeConstExpression(Expression: Text): Text
    var
        IntValue: Integer;
        DecValue: Decimal;
    begin
        if Evaluate(IntValue, Expression) then
            exit(Expression);

        if Evaluate(DecValue, Expression) then
            exit(Expression);

        if LowerCase(Expression) in ['true', 'false'] then
            exit(LowerCase(Expression));

        if Expression = '' then
            exit(Expression);

        if (StrLen(Expression) >= 2) and (Expression[1] = '''') and (Expression[StrLen(Expression)] = '''') then
            exit(Expression);

        exit('''' + Expression + '''');
    end;

    local procedure SkipCurlyBlock(): Boolean
    var
        Depth: Integer;
    begin
        if GetCurrentToken() <> '{' then
            exit(true);

        Depth := 0;

        while CurrentTokenIndex <= TokenList.Count do begin
            if GetCurrentToken() = '{' then begin
                Depth += 1;
                Advance();
                continue;
            end;

            if GetCurrentToken() = '}' then begin
                Depth -= 1;
                Advance();
                if Depth = 0 then
                    exit(true);
                continue;
            end;

            Advance();
        end;

        SetError('Expected } to close block');
        exit(false);
    end;

    local procedure RegisterQuery(QueryName: Text; QueryDefinition: Text): Boolean
    begin
        if HasQuery(QueryName) then begin
            SetError('Query already defined: ' + QueryName);
            exit(false);
        end;

        QueryNames.Add(QueryName);
        QueryDefinitions.Add(QueryDefinition);
        exit(true);
    end;

    local procedure HasQuery(QueryName: Text): Boolean
    begin
        exit(GetQueryIndex(QueryName) > 0);
    end;

    local procedure GetQueryIndex(QueryName: Text): Integer
    var
        i: Integer;
    begin
        for i := 1 to QueryNames.Count do begin
            if LowerCase(QueryNames.Get(i)) = LowerCase(QueryName) then
                exit(i);
        end;
        exit(0);
    end;

    local procedure ExecuteStoredQuery(QueryName: Text): Boolean
    var
        QueryIdx: Integer;
        QueryDefinition: Text;
    begin
        QueryIdx := GetQueryIndex(QueryName);
        if QueryIdx = 0 then begin
            SetError('Query not found: ' + QueryName);
            exit(false);
        end;

        QueryDefinition := QueryDefinitions.Get(QueryIdx);
        exit(ExecuteQueryDefinition(QueryName, QueryDefinition));
    end;

    local procedure ExecuteQueryDefinition(QueryName: Text; QueryDefinition: Text): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        DefinitionEntries: List of [Text];
        Parts: List of [Text];
        Entry: Text;
        DataItemNames: List of [Text];
        DataItemTables: List of [Text];
        DataItemColumns: List of [Text];
        DataItemFilters: List of [Text];
        DataItemParents: List of [Text];
        DataItemLinks: List of [Text];
        DataItemTableFilters: List of [Text];
        DataItemColumnFilters: List of [Text];
        DataItemColumnMethods: List of [Text];
        RootRecRef: RecordRef;
        i: Integer;
    begin
        if QueryDefinition = '' then begin
            SetError('Query definition is empty for ' + QueryName);
            exit(false);
        end;

        DefinitionEntries := QueryDefinition.Split(TypeHelper.LFSeparator());

        for i := 1 to DefinitionEntries.Count do begin
            Entry := DefinitionEntries.Get(i);
            if Entry = '' then
                continue;

            Parts := Entry.Split('|');
            if Parts.Count < 4 then begin
                SetError('Invalid query definition encountered');
                exit(false);
            end;

            DataItemNames.Add(Parts.Get(1));
            DataItemTables.Add(Parts.Get(2));
            DataItemColumns.Add(Parts.Get(3));

            if Parts.Count >= 4 then
                DataItemFilters.Add(Parts.Get(4))
            else
                DataItemFilters.Add('');

            if Parts.Count >= 5 then
                DataItemParents.Add(Parts.Get(5))
            else
                DataItemParents.Add('');

            if Parts.Count >= 6 then
                DataItemLinks.Add(Parts.Get(6))
            else
                DataItemLinks.Add('');

            if Parts.Count >= 7 then
                DataItemTableFilters.Add(Parts.Get(7))
            else
                DataItemTableFilters.Add('');

            if Parts.Count >= 8 then
                DataItemColumnFilters.Add(Parts.Get(8))
            else
                DataItemColumnFilters.Add('');

            if Parts.Count >= 9 then
                DataItemColumnMethods.Add(Parts.Get(9))
            else
                DataItemColumnMethods.Add('');
        end;

        for i := 1 to DataItemNames.Count do begin
            if DataItemParents.Get(i) = '' then
                if not ExecuteQueryDataItemRecursive(QueryName, DataItemNames, DataItemTables, DataItemColumns, DataItemFilters, DataItemParents, DataItemLinks, DataItemTableFilters, DataItemColumnFilters, DataItemColumnMethods, i, RootRecRef, 0) then
                    exit(false);
        end;

        exit(true);
    end;

    local procedure ExecuteQueryDataItemRecursive(QueryName: Text; var DataItemNames: List of [Text]; var DataItemTables: List of [Text]; var DataItemColumns: List of [Text]; var DataItemFilters: List of [Text]; var DataItemParents: List of [Text]; var DataItemLinks: List of [Text]; var DataItemTableFilters: List of [Text]; var DataItemColumnFilters: List of [Text]; var DataItemColumnMethods: List of [Text]; DataItemIndex: Integer; var ParentRecRef: RecordRef; Level: Integer): Boolean
    var
        DataItemName: Text;
        TableName: Text;
        ColumnSpec: Text;
        FilterSpec: Text;
        LinkSpec: Text;
        TableFilterSpec: Text;
        ColumnFilterSpec: Text;
        ColumnMethodSpec: Text;
        TableId: Integer;
        RecRef: RecordRef;
        ColumnEntries: List of [Text];
        ColumnEntry: Text;
        ColumnParts: List of [Text];
        ColumnNames: List of [Text];
        ColumnFields: List of [Text];
        ColumnValues: List of [Text];
        ColumnFilterEntries: List of [Text];
        ColumnMethodEntries: List of [Text];
        ColumnFilterExpr: Text;
        FilterEntries: List of [Text];
        FilterEntry: Text;
        FilterField: Text;
        FilterValue: Text;
        TableFilterEntries: List of [Text];
        TableFilterEntry: Text;
        TableFilterField: Text;
        TableFilterExpression: Text;
        LinkEntries: List of [Text];
        LinkEntry: Text;
        LinkField: Text;
        LinkParentField: Text;
        ParentFieldNo: Integer;
        ParentFieldRef: FieldRef;
        FieldNo: Integer;
        FieldRef: FieldRef;
        TypeHelper: Codeunit "Type Helper";
        LF: Text;
        HeaderContent: Text;
        SeparatorLine: Text;
        RowLine: Text;
        i: Integer;
        ChildIndex: Integer;
        Indent: Text;
    begin
        DataItemName := DataItemNames.Get(DataItemIndex);
        TableName := DataItemTables.Get(DataItemIndex);
        ColumnSpec := DataItemColumns.Get(DataItemIndex);
        FilterSpec := DataItemFilters.Get(DataItemIndex);
        LinkSpec := DataItemLinks.Get(DataItemIndex);
        TableFilterSpec := DataItemTableFilters.Get(DataItemIndex);
        ColumnFilterSpec := DataItemColumnFilters.Get(DataItemIndex);
        ColumnMethodSpec := DataItemColumnMethods.Get(DataItemIndex);

        TableId := GetTableIdByName(TableName);
        if TableId = 0 then begin
            SetError('Table not found or not supported: ' + TableName);
            exit(false);
        end;

        RecRef.Open(TableId);
        RecRef.Reset();

        // Apply DataItemTableFilter first (table-level filters)
        if TableFilterSpec <> '' then begin
            TableFilterEntries := TableFilterSpec.Split(',');
            for i := 1 to TableFilterEntries.Count do begin
                TableFilterEntry := TableFilterEntries.Get(i);
                if TableFilterEntry = '' then
                    continue;

                // Split on first '=' only - field name is before, expression is after
                // Format: FieldName=OperatorValue
                if StrPos(TableFilterEntry, '=') > 0 then begin
                    TableFilterField := CopyStr(TableFilterEntry, 1, StrPos(TableFilterEntry, '=') - 1);
                    TableFilterExpression := CopyStr(TableFilterEntry, StrPos(TableFilterEntry, '=') + 1);
                    // TableFilterExpression format: OperatorValue (e.g., "<>''", "=true", "=1")
                    if TableFilterExpression <> '' then begin
                        if CopyStr(TableFilterExpression, 1, 1) = '=' then
                            TableFilterExpression := CopyStr(TableFilterExpression, 2);
                        if not SetRecordFilter(RecRef, TableFilterField, TableFilterExpression) then begin
                            RecRef.Close();
                            exit(false);
                        end;
                    end;
                end;
            end;
        end;

        // Apply regular filters
        if FilterSpec <> '' then begin
            FilterEntries := FilterSpec.Split(',');
            for i := 1 to FilterEntries.Count do begin
                FilterEntry := FilterEntries.Get(i);
                if FilterEntry = '' then
                    continue;

                FilterField := FilterEntry.Split('=').Get(1);
                FilterValue := FilterEntry.Split('=').Get(2);
                // Skip filters with empty values (filter is defined but not set)
                if FilterValue <> '' then begin
                    if not SetRecordFilter(RecRef, FilterField, FilterValue) then begin
                        RecRef.Close();
                        exit(false);
                    end;
                end;
            end;
        end;

        if (DataItemParents.Get(DataItemIndex) <> '') then begin
            if (Level = 0) or (ParentRecRef.Number = 0) then begin
                RecRef.Close();
                exit(true);
            end;

            if LinkSpec <> '' then begin
                LinkEntries := LinkSpec.Split(',');
                for i := 1 to LinkEntries.Count do begin
                    LinkEntry := LinkEntries.Get(i);
                    if LinkEntry = '' then
                        continue;

                    LinkField := LinkEntry.Split('=').Get(1);
                    LinkParentField := LinkEntry.Split('=').Get(2);

                    ParentFieldNo := GetFieldNumber(ParentRecRef, LinkParentField);
                    if ParentFieldNo = 0 then begin
                        RecRef.Close();
                        SetError('Field not found on parent dataitem: ' + LinkParentField);
                        exit(false);
                    end;

                    ParentFieldRef := ParentRecRef.Field(ParentFieldNo);
                    FilterValue := Format(ParentFieldRef.Value);

                    if not SetRecordFilter(RecRef, LinkField, FilterValue) then begin
                        RecRef.Close();
                        exit(false);
                    end;
                end;
            end;
        end;

        ColumnEntries := ColumnSpec.Split(',');
        for i := 1 to ColumnEntries.Count do begin
            ColumnEntry := ColumnEntries.Get(i);
            if ColumnEntry = '' then
                continue;

            ColumnParts := ColumnEntry.Split(':');
            if ColumnParts.Count = 0 then
                continue;

            ColumnNames.Add(ColumnParts.Get(1));
            if ColumnParts.Count >= 2 then
                ColumnFields.Add(ColumnParts.Get(2))
            else
                ColumnFields.Add(ColumnParts.Get(1));
        end;

        if ColumnFilterSpec <> '' then begin
            ColumnFilterEntries := ColumnFilterSpec.Split(',');
            for i := 1 to ColumnFilterEntries.Count do begin
                if i > ColumnFields.Count then
                    break;

                ColumnFilterExpr := ColumnFilterEntries.Get(i);
                if ColumnFilterExpr = '' then
                    continue;

                FilterField := ColumnFields.Get(i);
                if FilterField = '' then
                    continue;

                if not SetRecordFilter(RecRef, FilterField, ColumnFilterExpr) then begin
                    RecRef.Close();
                    exit(false);
                end;
            end;
        end;

        LF := TypeHelper.LFSeparator();
        Indent := PadStr('', Level * 2, ' ');

        HeaderContent := JoinWithSeparator(ColumnNames, ' | ');
        if HeaderContent <> '' then begin
            ExecutionOutput += Indent + HeaderContent + LF;
            SeparatorLine := CreateSeparatorLine(StrLen(HeaderContent));
            if SeparatorLine <> '' then
                ExecutionOutput += Indent + SeparatorLine + LF;
        end;

        if RecRef.FindSet() then begin
            repeat
                Clear(ColumnValues);
                for i := 1 to ColumnFields.Count do begin
                    FilterField := ColumnFields.Get(i);
                    FieldNo := GetFieldNumber(RecRef, FilterField);
                    if FieldNo = 0 then begin
                        RecRef.Close();
                        SetError('Field not found: ' + FilterField);
                        exit(false);
                    end;

                    FieldRef := RecRef.Field(FieldNo);
                    if FieldRef.Class = FieldRef.Class::FlowField then
                        FieldRef.CalcField();
                    ColumnValues.Add(Format(FieldRef.Value));
                end;

                RowLine := JoinWithSeparator(ColumnValues, ' | ');
                ExecutionOutput += Indent + RowLine + LF;

                for ChildIndex := 1 to DataItemNames.Count do begin
                    if LowerCase(DataItemParents.Get(ChildIndex)) = LowerCase(DataItemName) then
                        if not ExecuteQueryDataItemRecursive(QueryName, DataItemNames, DataItemTables, DataItemColumns, DataItemFilters, DataItemParents, DataItemLinks, DataItemTableFilters, DataItemColumnFilters, DataItemColumnMethods, ChildIndex, RecRef, Level + 1) then begin
                            RecRef.Close();
                            exit(false);
                        end;
                end;
            until RecRef.Next() = 0;
        end else
            ExecutionOutput += Indent + '(no rows)' + LF;

        ExecutionOutput += LF;
        RecRef.Close();
        exit(true);
    end;

    local procedure JoinWithSeparator(Values: List of [Text]; Separator: Text): Text
    var
        ResultText: Text;
        i: Integer;
    begin
        ResultText := '';

        for i := 1 to Values.Count do begin
            if i > 1 then
                ResultText += Separator;
            ResultText += Values.Get(i);
        end;

        exit(ResultText);
    end;

    local procedure CreateSeparatorLine(TargetLength: Integer): Text
    begin
        if TargetLength <= 0 then
            exit('');
        exit(PadStr('', TargetLength, '-'));
    end;

    #endregion
}
