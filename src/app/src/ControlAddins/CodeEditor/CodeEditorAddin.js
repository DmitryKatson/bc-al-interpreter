// CodeEditorAddin.js - CodeMirror-based code editor for AL
var editor;

// Initialize the editor when the control add-in is ready
document.addEventListener('DOMContentLoaded', function () {
    // Set body styles for full height
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.body.style.height = '100%';
    document.body.style.width = '100%';
    document.body.style.overflow = 'hidden';
    
    // Create a container div for the editor
    var container = document.createElement('div');
    container.style.height = '100%';
    container.style.width = '100%';
    container.style.position = 'absolute';
    container.style.top = '0';
    container.style.left = '0';
    container.style.right = '0';
    container.style.bottom = '0';
    container.style.overflow = 'hidden';
    document.body.appendChild(container);

    // Initialize CodeMirror editor
    editor = CodeMirror(container, {
        lineNumbers: true,
        mode: 'javascript',
        theme: 'dracula',
        readOnly: false,
        lineWrapping: true,
        indentUnit: 2,
        tabSize: 2,
        indentWithTabs: false,
        autofocus: true,
        matchBrackets: true,
        autoCloseBrackets: true,
        foldGutter: true,
        gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter'],
        extraKeys: {
            'Ctrl-S': function(cm) {
                // Save functionality - will be handled by AL
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ContentChanged', [cm.getValue()]);
            }
        }
    });

    // Listen for content changes
    editor.on('change', function() {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ContentChanged', [editor.getValue()]);
    });

    // Listen for focus events to ensure proper keyboard handling
    editor.on('focus', function() {
        editor.refresh();
    });

    // Notify AL that the control is ready
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', []);
});

// Procedure to set content from AL
function SetContent(content) {
    if (editor) {
        editor.setValue(content || '');
        editor.refresh();
    }
}

// Procedure to get content for AL - triggers event instead of returning
function GetContent() {
    if (editor) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ContentChanged', [editor.getValue()]);
    }
}
