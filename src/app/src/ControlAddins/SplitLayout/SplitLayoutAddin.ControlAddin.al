controladdin SplitLayoutAddin
{
    Scripts = 'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js',
              'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/javascript/javascript.min.js',
              '../CodeEditor/CodeEditorAddin-al-mode.js',
              'SplitLayoutAddin.js';
    Stylesheets = 'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css',
                  '../CodeEditor/al-theme.css';
    RequestedHeight = 650;
    RequestedWidth = 1200;
    MinimumHeight = 300;
    MinimumWidth = 600;
    MaximumHeight = 1000;
    MaximumWidth = 2000;
    VerticalStretch = true;
    HorizontalStretch = true;

    procedure SetCodeContent(Content: Text);
    procedure SetOutputContent(Content: Text);
    procedure ClearOutput();

    event CodeContentChanged(Content: Text);
    event ControlAddInReady();
}
