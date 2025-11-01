table 50000 "Interactive Program"
{
    DataClassification = SystemMetadata;
    Caption = 'Interactive Program';

    fields
    {
        field(1; "ID"; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Name';
        }
        field(3; "AL Code"; Blob)
        {
            DataClassification = ToBeClassified;
            SubType = Memo;
            Caption = 'AL Code';
        }
        field(4; "Is Demo"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Is Demo';
        }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
    }
}