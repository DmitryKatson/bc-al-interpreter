// SplitLayoutAddin.js - Split layout container with two CodeMirror editors
var codeEditor;
var outputEditor;
var outputCopyButton;
var outputCopyTimer;

function ensureSplitLayoutStyles() {
    if (document.getElementById('split-layout-styles')) {
        return;
    }

    var style = document.createElement('style');
    style.id = 'split-layout-styles';
    style.type = 'text/css';
    style.textContent = '' +
        '.split-layout-output-label { display:flex; justify-content:space-between; align-items:center; gap:8px; }' +
        '.split-layout-output-actions { display:flex; align-items:center; gap:8px; }' +
        '.split-layout-copy-button { width:28px; height:28px; border-radius:6px; border:1px solid rgba(51,51,51,0.25); background:rgba(51,51,51,0.08); cursor:pointer; position:relative; transition:background 0.15s ease, border-color 0.15s ease; }' +
        '.split-layout-copy-button::before, .split-layout-copy-button::after { content:""; position:absolute; box-sizing:border-box; border-radius:2px; border:2px solid #333333; width:12px; height:14px; top:50%; left:50%; transform:translate(-50%, -55%); }' +
        '.split-layout-copy-button::after { border-top-color:transparent; border-left-color:transparent; top:calc(50% + 3px); left:calc(50% + 3px); opacity:0.9; }' +
        '.split-layout-copy-button:hover { background:rgba(51,51,51,0.16); border-color:rgba(51,51,51,0.4); }' +
        '.split-layout-copy-button:focus { outline:2px solid #2680eb; outline-offset:2px; }' +
        '.split-layout-copy-button.copied { background:rgba(46,160,67,0.18); border-color:rgba(46,160,67,0.6); }' +
        '.split-layout-copy-button.copied::before, .split-layout-copy-button.copied::after { border-color:#2ea043; }' +
        '.split-layout-copy-button.copy-error { background:rgba(206,56,75,0.18); border-color:rgba(206,56,75,0.6); }' +
        '.split-layout-copy-button.copy-error::before, .split-layout-copy-button.copy-error::after { border-color:#ce384b; }';

    document.head.appendChild(style);
}

function indicateOutputCopyResult(succeeded) {
    if (!outputCopyButton) {
        return;
    }

    if (outputCopyTimer) {
        clearTimeout(outputCopyTimer);
    }

    outputCopyButton.classList.remove('copied');
    outputCopyButton.classList.remove('copy-error');

    var className = succeeded ? 'copied' : 'copy-error';
    outputCopyButton.classList.add(className);

    outputCopyTimer = setTimeout(function () {
        outputCopyButton.classList.remove(className);
    }, 1200);
}

function copySplitLayoutOutput() {
    if (!outputEditor) {
        indicateOutputCopyResult(false);
        return;
    }

    var content = outputEditor.getValue();

    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(content).then(function () {
            indicateOutputCopyResult(true);
        }).catch(function () {
            legacyCopySplitLayoutOutput(content);
        });
    } else {
        legacyCopySplitLayoutOutput(content);
    }
}

function legacyCopySplitLayoutOutput(content) {
    var textarea = document.createElement('textarea');
    textarea.value = content;
    textarea.setAttribute('readonly', '');
    textarea.style.position = 'absolute';
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.select();

    var succeeded = false;

    try {
        succeeded = document.execCommand('copy');
    } catch (error) {
        succeeded = false;
    }

    document.body.removeChild(textarea);

    indicateOutputCopyResult(succeeded);
}

// Initialize the split layout when the control add-in is ready
document.addEventListener('DOMContentLoaded', function () {
    ensureSplitLayoutStyles();

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
    outputLabel.className = 'split-layout-output-label';
    outputLabel.style.padding = '8px';
    outputLabel.style.backgroundColor = '#f8f8f8';
    outputLabel.style.color = '#333333';
    outputLabel.style.fontWeight = 'bold';
    outputLabel.style.fontSize = '14px';
    outputLabel.style.borderBottom = '1px solid #ddd';
    var outputLabelText = document.createElement('span');
    outputLabelText.textContent = 'Execution Output';
    outputLabel.appendChild(outputLabelText);

    var outputLabelActions = document.createElement('div');
    outputLabelActions.className = 'split-layout-output-actions';
    outputLabel.appendChild(outputLabelActions);

    outputCopyButton = document.createElement('button');
    outputCopyButton.type = 'button';
    outputCopyButton.className = 'split-layout-copy-button';
    outputCopyButton.title = 'Copy output';
    outputCopyButton.setAttribute('aria-label', 'Copy output');
    outputCopyButton.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopPropagation();
        copySplitLayoutOutput();
    });
    outputLabelActions.appendChild(outputCopyButton);

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
        readOnly: true,
        lineWrapping: true,
        indentUnit: 2,
        tabSize: 2,
        indentWithTabs: false,
        matchBrackets: true,
        autoCloseBrackets: true,
        foldGutter: true,
        gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter'],
        viewportMargin: Infinity,
        cursorBlinkRate: -1
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
        var scrollInfo = outputEditor.getScrollInfo();
        outputEditor.scrollTo(null, scrollInfo.height);
    }
}

function ClearOutput() {
    if (outputEditor) {
        outputEditor.setValue('');
        outputEditor.setSize('100%', '100%');
        outputEditor.refresh();
        outputEditor.scrollTo(null, 0);
    }
}
