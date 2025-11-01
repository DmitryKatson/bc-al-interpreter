// SplitLayoutAddin.js - Split layout container with two CodeMirror editors
var codeEditor;
var outputEditor;

// Initialize the split layout when the control add-in is ready
document.addEventListener('DOMContentLoaded', function () {
    // Set body styles to fill the add-in container (no viewport locking)
    document.documentElement.style.height = '100%';
    document.documentElement.style.width = '100%';
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.body.style.height = '100%';
    document.body.style.width = '100%';
    document.body.style.overflow = 'hidden';
    document.body.style.display = 'flex';
    document.body.style.flexDirection = 'row';
    
    // Create main container
    var mainContainer = document.createElement('div');
    mainContainer.style.height = '100%';
    mainContainer.style.width = '100%';
    mainContainer.style.display = 'flex';
    mainContainer.style.flexDirection = 'row';
    mainContainer.style.gap = '0px';
    mainContainer.style.border = '1px solid #ddd';
    mainContainer.style.position = 'absolute';
    mainContainer.style.top = '0';
    mainContainer.style.left = '0';
    mainContainer.style.right = '0';
    mainContainer.style.bottom = '0';
    document.body.appendChild(mainContainer);

    // Create left panel for code editor
    var leftPanel = document.createElement('div');
    leftPanel.style.flex = '1';
    leftPanel.style.height = '100%';
    leftPanel.style.minWidth = '300px';
    leftPanel.style.display = 'flex';
    leftPanel.style.flexDirection = 'column';
    mainContainer.appendChild(leftPanel);

    // Add code editor label
    var codeLabel = document.createElement('div');
    codeLabel.textContent = 'AL Code';
    codeLabel.style.padding = '8px';
    codeLabel.style.backgroundColor = '#2d2d2d';
    codeLabel.style.color = '#f8f8f2';
    codeLabel.style.fontWeight = 'bold';
    codeLabel.style.fontSize = '14px';
    codeLabel.style.borderBottom = '1px solid #444';
    leftPanel.appendChild(codeLabel);

    // Create code editor container
    var codeContainer = document.createElement('div');
    codeContainer.style.flex = '1';
    codeContainer.style.height = 'calc(100% - 30px)';
    codeContainer.style.overflow = 'hidden';
    leftPanel.appendChild(codeContainer);

    // Initialize code editor
    codeEditor = CodeMirror(codeContainer, {
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
        viewportMargin: Infinity,
        extraKeys: {
            'Ctrl-S': function(cm) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CodeContentChanged', [cm.getValue()]);
            }
        }
    });
    
    // Force the editor to fill the container
    codeEditor.setSize('100%', '100%');

    // Listen for code content changes
    codeEditor.on('change', function() {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CodeContentChanged', [codeEditor.getValue()]);
    });

    // Create right panel for output console
    var rightPanel = document.createElement('div');
    rightPanel.style.flex = '1';
    rightPanel.style.height = '100%';
    rightPanel.style.minWidth = '300px';
    rightPanel.style.display = 'flex';
    rightPanel.style.flexDirection = 'column';
    rightPanel.style.backgroundColor = '#ffffff';
    rightPanel.style.borderLeft = '1px solid #ddd';
    mainContainer.appendChild(rightPanel);

    // Add output console label
    var outputLabel = document.createElement('div');
    outputLabel.textContent = 'Execution Output';
    outputLabel.style.padding = '8px';
    outputLabel.style.backgroundColor = '#f8f8f8';
    outputLabel.style.color = '#333333';
    outputLabel.style.fontWeight = 'bold';
    outputLabel.style.fontSize = '14px';
    outputLabel.style.borderBottom = '1px solid #ddd';
    rightPanel.appendChild(outputLabel);

    // Create output editor container
    var outputContainer = document.createElement('div');
    outputContainer.style.flex = '1';
    outputContainer.style.height = 'calc(100% - 30px)';
    outputContainer.style.overflow = 'hidden';
    outputContainer.style.backgroundColor = '#ffffff';
    rightPanel.appendChild(outputContainer);

    // Initialize output editor in read-only mode with light theme
    outputEditor = CodeMirror(outputContainer, {
        lineNumbers: true,
        mode: 'javascript',
        theme: 'default', // Light theme instead of dracula
        readOnly: 'nocursor',
        lineWrapping: true,
        indentUnit: 2,
        tabSize: 2,
        indentWithTabs: false,
        matchBrackets: true,
        autoCloseBrackets: true,
        foldGutter: true,
        gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter'],
        viewportMargin: Infinity
    });
    
    // Force the editor to fill the container
    outputEditor.setSize('100%', '100%');

    // Listen for focus events to ensure proper keyboard handling
    codeEditor.on('focus', function() {
        codeEditor.refresh();
    });

    // Ensure editors are properly sized and refreshed
    setTimeout(function() {
        if (codeEditor) {
            codeEditor.refresh();
            codeEditor.setSize('100%', '100%');
        }
        if (outputEditor) {
            outputEditor.refresh();
            outputEditor.setSize('100%', '100%');
        }
    }, 100);

    // Notify AL that the control is ready
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', []);
});

// AL callable functions
function SetCodeContent(content) {
    if (codeEditor) {
        codeEditor.setValue(content || '');
        codeEditor.setSize('100%', '100%');
        codeEditor.refresh();
    }
}

function SetOutputContent(content) {
    if (outputEditor) {
        outputEditor.setValue(content || '');
        outputEditor.setSize('100%', '100%');
        outputEditor.refresh();
    }
}

function ClearOutput() {
    if (outputEditor) {
        outputEditor.setValue('');
        outputEditor.setSize('100%', '100%');
        outputEditor.refresh();
    }
}
