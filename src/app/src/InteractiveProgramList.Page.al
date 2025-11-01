page 50002 "Interactive Program List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Interactive Program";
    Caption = 'Interactive Programs';
    CardPageId = "Interactive Code Runner";
    Editable = true;
    SourceTableView = where("Is Demo" = const(false));

    layout
    {
        area(content)
        {
            repeater(Programs)
            {
                field("ID"; Rec."ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Program ID';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Program name';
                }
                field("Has Code"; HasCode)
                {
                    ApplicationArea = All;
                    Caption = 'Has Code';
                    ToolTip = 'Indicates if the program contains AL code';
                }
            }
        }

        area(factboxes)
        {
            part(ProgramInfo; "Program Info FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "ID" = field("ID");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RunProgram)
            {
                ApplicationArea = All;
                Caption = 'Run Program';
                Image = ExecuteBatch;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Execute the selected program';

                trigger OnAction()
                var
                    CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                begin
                    CodeRunnerImpl.RunProgramFromList(Rec);
                end;
            }

            action(ExportCode)
            {
                ApplicationArea = All;
                Caption = 'Export Code';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Export the program code';

                trigger OnAction()
                var
                    CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                begin
                    CodeRunnerImpl.ExportProgramCode(Rec);
                end;
            }
        }

        area(navigation)
        {
            action(Statistics)
            {
                ApplicationArea = All;
                Caption = 'Statistics';
                Image = Statistics;
                ToolTip = 'View statistics about saved programs';

                trigger OnAction()
                var
                    CodeRunnerImpl: Codeunit "Interactive Code Runner Impl";
                begin
                    CodeRunnerImpl.ShowProgramStatistics();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HasCode := Rec."AL Code".HasValue;
    end;

    var
        HasCode: Boolean;
}

