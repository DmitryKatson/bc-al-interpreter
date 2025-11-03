codeunit 50001 "Program Executor"
{
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
        CurrentTokenIndex := 0;
        ErrorMessage := '';
        ExecutionOutput := '';
        CurrentLine := 1;

        // Clear active RecordRefs
        for i := 1 to 10 do begin
            if ActiveRecordRefs[i].Number <> 0 then
                ActiveRecordRefs[i].Close();
            Clear(ActiveRecordRefs[i]);
            Clear(ActiveRecordRefNames[i]);
        end;
        ActiveRecordRefCount := 0;
    end;

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
          'true', 'false', 'case', 'of', 'exit':
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

    /// <summary>
    /// Parse and execute the tokenized code
    /// </summary>
    local procedure ParseAndExecute(): Boolean
    begin
        CurrentTokenIndex := 1;

        while CurrentTokenIndex <= TokenList.Count do begin
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
        if CurrentTokenIndex > TokenList.Count then
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
        VarType: Text;
        TableName: Text;
    begin
        VarName := GetCurrentToken();
        Advance();

        if not ConsumeToken(':') then begin
            SetError('Expected : after variable name');
            exit(false);
        end;

        VarType := GetCurrentToken();
        Advance();

        case LowerCase(VarType) of
            'integer':
                begin
                    if not AddVariable(VarName, '0', 'Integer') then
                        exit(false);
                end;
            'text', 'code':
                begin
                    if not AddVariable(VarName, '', 'Text') then
                        exit(false);
                end;
            'boolean':
                begin
                    if not AddVariable(VarName, 'false', 'Boolean') then
                        exit(false);
                end;
            'decimal':
                begin
                    if not AddVariable(VarName, '0', 'Decimal') then
                        exit(false);
                end;
            'date':
                begin
                    if not AddVariable(VarName, Format(0D), 'Date') then
                        exit(false);
                end;
            'datetime':
                begin
                    if not AddVariable(VarName, Format(0DT), 'DateTime') then
                        exit(false);
                end;
            'record':
                begin
                    TableName := GetCurrentToken();
                    Advance();
                    if not CreateRecordVariable(VarName, TableName) then
                        exit(false);
                end;
            'char':
                begin
                    if not AddVariable(VarName, '', 'Char') then
                        exit(false);
                end;
            'bigtext':
                begin
                    if not AddVariable(VarName, '', 'BigText') then
                        exit(false);
                end;
            'guid':
                begin
                    if not AddVariable(VarName, Format(CreateGuid()), 'GUID') then
                        exit(false);
                end;
            'option':
                begin
                    if not AddVariable(VarName, '0', 'Option') then
                        exit(false);
                end;
            'duration':
                begin
                    if not AddVariable(VarName, '0', 'Duration') then
                        exit(false);
                end;
            'blob':
                begin
                    if not AddVariable(VarName, '', 'Blob') then
                        exit(false);
                end;
            else begin
                SetError('Unsupported type: ' + VarType + '. Supported types: Integer, Text, Code, Boolean, Date, DateTime, Decimal, Record, Char, BigText, GUID, Option, Duration, Blob. Check for copy-paste formatting issues.');
                exit(false);
            end;
        end;

        ConsumeSemicolon();
        exit(true);
    end;

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
        for i := 1 to VariableNames.Count do begin
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
            if not ExecuteBuiltInFunction(MethodName, Result) then
                exit(false);
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

    local procedure EvaluateFunctionCall(var Result: Text): Boolean
    var
        FunctionName: Text;
    begin
        FunctionName := GetCurrentToken();
        Advance();
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

    local procedure ExecuteBuiltInFunction(FunctionName: Text; var Result: Text): Boolean
    var
        Args: List of [Text];
        ArgValue: Text;
        Arg1, Arg2, Arg3 : Text;
        IntVal, IntVal2 : Integer;
        DecVal, DecVal2 : Decimal;
        TypeHelper: Codeunit "Type Helper";
    begin
        if not ConsumeToken('(') then begin
            SetError('Expected ( after function name');
            exit(false);
        end;

        // Parse arguments
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
            else begin
                SetError('Unknown function: ' + FunctionName);
                exit(false);
            end;
        end;
    end;

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
        FieldRef.Value := Value;
        exit(true);
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
        NewValue: Text;
    begin
        FieldName := Args.Get(1);
        NewValue := Args.Get(2);

        FieldNo := GetFieldNumber(RecRef, FieldName);
        if FieldNo = 0 then begin
            SetError('Field not found for ModifyAll: ' + FieldName);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);

        if RecRef.FindSet() then begin
            repeat
                FieldRef.Value := NewValue;
                RecRef.Modify(true);
            until RecRef.Next() = 0;
        end;

        exit(true);
    end;

    // Math and comparison helpers
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
        i: Integer;
    begin
        Advance(); // Skip 'for'

        // Parse: for VarName := StartValue to EndValue do
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

        // Optional step value: for i := 1 to 10 step 2 do
        StepValue := '1';
        if GetCurrentToken() = 'step' then begin
            Advance();
            if not EvaluateExpression(StepValue) then
                exit(false);
        end;

        if not ConsumeToken('do') then begin
            SetError('Expected do after for loop');
            exit(false);
        end;

        // Convert values to integers
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

        // Store loop start position
        LoopStartIndex := CurrentTokenIndex;

        // Find the end of the loop body
        LoopEndIndex := FindStatementEnd(CurrentTokenIndex);
        if LoopEndIndex = 0 then begin
            SetError('Could not find end of for loop');
            exit(false);
        end;

        // Execute the loop
        while CurrentValue <= EndInt do begin
            // Set loop variable
            if not SetVariableValue(VarName, Format(CurrentValue)) then
                if not AddVariable(VarName, Format(CurrentValue), 'Integer') then
                    exit(false);

            // Execute loop body - reset to loop start and parse until end
            CurrentTokenIndex := LoopStartIndex;
            while CurrentTokenIndex < LoopEndIndex do begin
                if not ParseStatement() then
                    exit(false);
            end;

            // Check if we hit break or continue
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

        // Skip to end of loop
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
}
