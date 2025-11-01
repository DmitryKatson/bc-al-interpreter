// OutputConsoleAddin.js - Read-only CodeMirror console for output display
var outputEditor;
var copyButton;

function ensureStyles() {
  if (document.getElementById('output-console-styles')) {
    return;
  }

  var style = document.createElement('style');
  style.id = 'output-console-styles';
  style.type = 'text/css';
  style.textContent = '' +
    '.output-console-root { position:absolute; top:0; left:0; right:0; bottom:0; display:flex; flex-direction:column; background-color:#282a36; }' +
    '.output-console-toolbar { position:relative; display:flex; justify-content:flex-end; align-items:center; gap:8px; padding:8px; flex:0 0 auto; pointer-events:none; }' +
    '.output-console-editor { flex:1 1 auto; position:relative; }' +
    '.output-console-copy-button { pointer-events:auto; width:32px; height:32px; border-radius:6px; border:1px solid rgba(255,255,255,0.25); background:rgba(255,255,255,0.06); cursor:pointer; position:relative; transition:background 0.15s ease, border-color 0.15s ease; }' +
    '.output-console-copy-button::before, .output-console-copy-button::after { content:""; position:absolute; box-sizing:border-box; border-radius:2px; border:2px solid #f8f8f2; width:14px; height:16px; top:50%; left:50%; transform:translate(-50%, -55%); }' +
    '.output-console-copy-button::after { border-top-color:transparent; border-left-color:transparent; top:calc(50% + 4px); left:calc(50% + 4px); opacity:0.9; }' +
    '.output-console-copy-button:hover { background:rgba(255,255,255,0.12); border-color:rgba(255,255,255,0.4); }' +
    '.output-console-copy-button:focus { outline:2px solid #8be9fd; outline-offset:2px; }' +
    '.output-console-copy-button.copied { background:rgba(80,250,123,0.2); border-color:rgba(80,250,123,0.6); }' +
    '.output-console-copy-button.copied::before, .output-console-copy-button.copied::after { border-color:#50fa7b; }' +
    '.output-console-copy-button.copy-error { background:rgba(255,85,85,0.18); border-color:rgba(255,85,85,0.6); }' +
    '.output-console-copy-button.copy-error::before, .output-console-copy-button.copy-error::after { border-color:#ff5555; }';

  document.head.appendChild(style);
}

function handleCopyRequest() {
  if (!outputEditor) {
    indicateCopyResult(false);
    return;
  }

  var content = outputEditor.getValue();

  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(content).then(function () {
      indicateCopyResult(true);
    }).catch(function () {
      legacyCopy(content);
    });
  } else {
    legacyCopy(content);
  }
}

function legacyCopy(content) {
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

  indicateCopyResult(succeeded);
}

function indicateCopyResult(succeeded) {
  if (!copyButton) {
    return;
  }

  copyButton.classList.remove('copied');
  copyButton.classList.remove('copy-error');

  var className = succeeded ? 'copied' : 'copy-error';
  copyButton.classList.add(className);

  setTimeout(function () {
    copyButton.classList.remove(className);
  }, 1200);
}

// Initialize the output editor when the control add-in is ready
document.addEventListener('DOMContentLoaded', function () {
    ensureStyles();

    // Set body styles for full height
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.body.style.height = '100%';
    document.body.style.width = '100%';
    document.body.style.overflow = 'hidden';
    
    // Create root container for editor and toolbar
    var root = document.createElement('div');
    root.className = 'output-console-root';
    document.body.appendChild(root);

    var toolbar = document.createElement('div');
    toolbar.className = 'output-console-toolbar';
    root.appendChild(toolbar);

    copyButton = document.createElement('button');
    copyButton.type = 'button';
    copyButton.className = 'output-console-copy-button';
    copyButton.title = 'Copy output';
    copyButton.setAttribute('aria-label', 'Copy output');
    copyButton.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopPropagation();
        handleCopyRequest();
    });
    toolbar.appendChild(copyButton);

    var editorContainer = document.createElement('div');
    editorContainer.className = 'output-console-editor';
    root.appendChild(editorContainer);

    // Initialize CodeMirror editor in read-only mode
    outputEditor = CodeMirror(editorContainer, {
        lineNumbers: true,
        mode: 'javascript',
        theme: 'dracula',
        readOnly: true,
        lineWrapping: true,
        indentUnit: 2,
        tabSize: 2,
        indentWithTabs: false,
        matchBrackets: false,
        autoCloseBrackets: false,
        foldGutter: false,
        gutters: ['CodeMirror-linenumbers'],
        scrollbarStyle: 'overlay',
        cursorBlinkRate: -1,
        // Console-like styling
        styleActiveLine: false,
        highlightSelectionMatches: false
    });

    outputEditor.setSize('100%', '100%');

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
