// OutputConsoleAddin.js - Read-only CodeMirror console for output display
var outputEditor;

// Initialize the output editor when the control add-in is ready
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
    container.style.backgroundColor = '#282a36'; // Dracula background
    document.body.appendChild(container);

    // Initialize CodeMirror editor in read-only mode
    outputEditor = CodeMirror(container, {
        lineNumbers: true,
        mode: 'javascript',
        theme: 'dracula',
        readOnly: 'nocursor', // Completely disable editing
        lineWrapping: true,
        indentUnit: 2,
        tabSize: 2,
        indentWithTabs: false,
        matchBrackets: false,
        autoCloseBrackets: false,
        foldGutter: false,
        gutters: ['CodeMirror-linenumbers'],
        scrollbarStyle: 'overlay',
        cursorBlinkRate: 0, // No cursor blinking
        // Console-like styling
        styleActiveLine: false,
        highlightSelectionMatches: false
    });

    // Set initial content
    outputEditor.setValue('Execution output will appear here...');
    
    // Notify AL that the control is ready
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', []);
});

// Procedure to set content from AL
function SetContent(content) {
    if (outputEditor) {
        outputEditor.setValue(content || '');
        // Scroll to bottom to show latest output
        outputEditor.scrollTo(null, outputEditor.getScrollInfo().height);
        outputEditor.refresh();
    }
}
