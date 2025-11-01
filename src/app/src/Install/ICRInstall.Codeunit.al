codeunit 50004 "ICR Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Impl: Codeunit "Interactive Code Runner Impl";
    begin
        // Load demo scripts during installation
        Impl.LoadDemoScriptsFromResources();
    end;
}


