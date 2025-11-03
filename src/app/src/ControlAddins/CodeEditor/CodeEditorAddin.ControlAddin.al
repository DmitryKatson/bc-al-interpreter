controladdin CodeEditorAddin
{
    Scripts = 'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js',
              'CodeEditorAddin-al-mode.js',
              'CodeEditorAddin.js';
    Stylesheets = 'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css',
                  'al-theme.css';
    RequestedHeight = 650;
    RequestedWidth = 400;
    MinimumHeight = 200;
    MinimumWidth = 200;
    MaximumHeight = 1000;
    MaximumWidth = 1000;
    VerticalStretch = true;
    HorizontalStretch = true;

    procedure SetContent(Content: Text);

    event ContentChanged(Content: Text);
    event ControlAddInReady();
}