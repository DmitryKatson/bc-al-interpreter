page 50000 "Interactive Code Runner"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Interactive Program";
    Caption = 'Code Runner';

    layout
    {
        area(content)
        {

            // Split Layout with Code Editor and Output Console
            group(SplitLayoutGroup)
            {
                Caption = 'Code Editor and Output';
                ShowCaption = false;

                usercontrol(SplitLayout; SplitLayoutAddin)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady()
                    var
                        CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                    begin
                        // Load content from BLOB when control is ready
                        ALCodeText := CodeRunnerImpl.LoadCodeFromBlob(Rec);
                        CurrPage.SplitLayout.SetCodeContent(ALCodeText);
                        // Initialize output with empty content
                        CurrPage.SplitLayout.SetOutputContent('');
                    end;

                    trigger CodeContentChanged(Content: Text)
                    begin
                        ALCodeText := Content;
                        // Just store the content, don't save to BLOB yet
                        // BLOB will be saved when user clicks Save button
                    end;
                }
            }

            group(ConsoleOptions)
            {
                Caption = 'Output Options';
                ShowCaption = false;
                field(ShowConsoleOnly; ShowMessagesInConsoleOnly)
                {
                    ApplicationArea = All;
                    Caption = 'Show output in console';
                    ToolTip = 'When enabled, Messages and errors are written to the console only.';
                }
            }

        }
    }

    actions
    {
        area(processing)
        {
            action(RunScript)
            {
                ApplicationArea = All;
                Caption = 'Run';
                Image = ExecuteBatch;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Execute the AL code';

                trigger OnAction()
                var
                    Executor: Codeunit "Program Executor";
                    Result: Text;
                    CodeText: Text;
                    TypeHelper: Codeunit "Type Helper";
                begin
                    // Get code from the editor - use ALCodeText which is updated by ContentChanged
                    CodeText := ALCodeText;

                    ClearLastRun();

                    if CodeText = '' then begin
                        ExecutionOutput := 'Info: Please enter some code to execute.' + TypeHelper.LFSeparator();
                        CurrPage.SplitLayout.SetOutputContent(ExecutionOutput);
                        CurrPage.Update(false);
                        exit;
                    end;

                    Result := Executor.ExecuteProgram(CodeText, ShowMessagesInConsoleOnly);

                    if Result <> '' then
                        ExecutionOutput := 'Execution completed successfully.' + TypeHelper.LFSeparator() + Result
                    else
                        ExecutionOutput := 'Execution completed. No output generated.';

                    CurrPage.SplitLayout.SetOutputContent(ExecutionOutput);
                    CurrPage.Update(false);
                end;
            }

            action(SaveProgram)
            {
                ApplicationArea = All;
                Caption = 'Save';
                Image = Save;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Save this program';

                trigger OnAction()
                var
                    CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                    TypeHelper: Codeunit "Type Helper";
                begin
                    // Check if record exists, if not create a new one
                    CodeRunnerImpl.EnsureRecordExists(Rec);

                    // Auto-generate a name if none exists
                    CodeRunnerImpl.GenerateDefaultName(Rec);

                    // Save code to BLOB
                    CodeRunnerImpl.SaveCodeToBlob(Rec, ALCodeText);
                    Rec.Modify(true);
                    ExecutionOutput := 'Info: Program saved successfully.' + TypeHelper.LFSeparator();
                    CurrPage.SplitLayout.SetOutputContent(ExecutionOutput);
                end;
            }

            action(ClearOutput)
            {
                ApplicationArea = All;
                Caption = 'Clear Output';
                Image = ClearLog;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Clear the execution output';

                trigger OnAction()
                begin
                    ClearLastRun();
                    CurrPage.SplitLayout.SetOutputContent('');
                    CurrPage.Update(false);
                end;
            }

            action(ToggleHelp)
            {
                ApplicationArea = All;
                Caption = 'Show Help';
                Image = Info;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Show quick reference guide';

                trigger OnAction()
                var
                    CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                begin
                    ExecutionOutput := CodeRunnerImpl.GetHelpContent();
                    CurrPage.SplitLayout.SetOutputContent(ExecutionOutput);
                end;
            }



            action(LoadSample)
            {
                ApplicationArea = All;
                Caption = 'Load Sample';
                Image = ShowList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Load a sample program';

                trigger OnAction()
                var
                    CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                begin
                    if not CodeRunnerImpl.TrySelectDemoAndGetCode(ALCodeText) then
                        ALCodeText := CodeRunnerImpl.LoadSampleCode();
                    CurrPage.SplitLayout.SetCodeContent(ALCodeText);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        // Code loading is handled in ControlAddInReady
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ALCodeText := '';
        CurrPage.SplitLayout.SetCodeContent('');
        ClearLastRun();
        CurrPage.SplitLayout.SetOutputContent('');
    end;

    trigger OnOpenPage()
    begin
        ShowMessagesInConsoleOnly := true;
    end;

    local procedure ClearLastRun()
    begin
        ExecutionOutput := '';
        OutputStyle := 'Standard';
        CurrPage.SplitLayout.ClearOutput();
    end;


    var
        ALCodeText: Text;
        ExecutionOutput: Text;
        OutputStyle: Text;
        ShowMessagesInConsoleOnly: Boolean;
}