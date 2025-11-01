controladdin OutputConsoleAddin
{
    Scripts = 'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js',
              'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/javascript/javascript.min.js',
              'OutputConsoleAddin.js';
    Stylesheets = 'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css',
                  'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/dracula.min.css';
    RequestedHeight = 650;
    RequestedWidth = 400;
    MinimumHeight = 200;
    MinimumWidth = 200;
    MaximumHeight = 1000;
    MaximumWidth = 1000;
    VerticalStretch = true;
    HorizontalStretch = true;

    procedure SetContent(Content: Text);

    event ControlAddInReady();
}
