page 50003 "Program Info FactBox"
{
    PageType = CardPart;
    SourceTable = "Interactive Program";
    Caption = 'Program Information';

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';

                field("ID"; Rec."ID")
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    ToolTip = 'Program ID';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Program name';
                }
                field(CodeLength; CodeLengthText)
                {
                    ApplicationArea = All;
                    Caption = 'Code Size';
                    ToolTip = 'Approximate size of the AL code';
                }
            }

            group(Description)
            {
                Caption = 'Description';

                field(Info; InfoText)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Program information';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        InStream: InStream;
        CodeText: Text;
    begin
        if Rec."AL Code".HasValue then begin
            Rec."AL Code".CreateInStream(InStream);
            InStream.ReadText(CodeText);
            CodeLengthText := Format(StrLen(CodeText)) + ' characters';

            InfoText := 'This program contains AL code and can be executed.';
        end else begin
            CodeLengthText := 'No code';
            InfoText := 'This program does not contain any AL code yet.';
        end;
    end;

    var
        CodeLengthText: Text;
        InfoText: Text;
}

