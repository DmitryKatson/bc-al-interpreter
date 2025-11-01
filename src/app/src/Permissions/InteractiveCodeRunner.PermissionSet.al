permissionset 50000 "AL Code Runner"
{
    Assignable = true;
    Caption = 'Interactive AL Code Runner';

    Permissions = 
        tabledata "Interactive Program" = RIMD,
        table "Interactive Program" = X,
        page "Interactive Code Runner" = X,
        page "Interactive Program List" = X,
        page "Program Info FactBox" = X,
        codeunit "Program Executor" = X,
        codeunit "Interactive Code Runner Impl" = X;
}
