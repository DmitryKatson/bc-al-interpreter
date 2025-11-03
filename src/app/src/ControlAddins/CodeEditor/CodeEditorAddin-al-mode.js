(function (mod) {
  if (typeof exports == 'object' && typeof module == 'object') {
    mod(require('codemirror'));
  } else if (typeof define == 'function' && define.amd) {
    define(['codemirror'], mod);
  } else {
    mod(CodeMirror);
  }
})(function (CodeMirror) {
  'use strict';

  function words(str) {
    var obj = Object.create(null);
    str.split(' ').forEach(function (word) {
      if (word) {
        obj[word.toLowerCase()] = true;
      }
    });
    return obj;
  }

  var keywords = words(
    'procedure trigger interface codeunit page report query xmlport requestpage enum ' +
      'var local begin end exit if then else elsif repeat until while do case of for to downto ' +
      'with try tryfunction catch finally break continue event and or not xor mod div in temporary ' +
      'label bind extend implements action group layout area dataset column control value dataitem ' +
      'pageextension tableextension reportextension xmlportextension enumextension requestpageextension '
  );

  var dataTypes = words(
    'record page codeunit report query xmlport text code decimal integer boolean bigint option enum ' +
      'guid char array list dictionary listof jsonobject jsonarray jsontoken jsonvalue ' +
      'date time datetime duration errorinfo variant filter recordref fieldref pageid biginteger ' +
      'moduleid fieldclass instream outstream binary number blob media medialink label ' +
      'actionref partref controladdinref interface reference stream dotnet'
  );

  var atomWords = words('true false yes no null undefined');

  function tokenString(stream) {
    var ch;
    while ((ch = stream.next()) != null) {
      if (ch === "'" && stream.peek() === "'") {
        stream.next();
        continue;
      }
      if (ch === "'") {
        break;
      }
    }
    return 'string';
  }

  function tokenQuotedIdentifier(stream) {
    var ch;
    while ((ch = stream.next()) != null) {
      if (ch === '"' && stream.peek() === '"') {
        stream.next();
        continue;
      }
      if (ch === '"') {
        break;
      }
    }
    return 'string-2';
  }

  function tokenComment(stream, state) {
    var ch;
    while ((ch = stream.next()) != null) {
      if (ch === '{') {
        state.commentDepth += 1;
      } else if (ch === '}') {
        state.commentDepth -= 1;
        if (state.commentDepth <= 0) {
          state.commentDepth = 0;
          break;
        }
      }
    }
    return 'comment';
  }

  function tokenNumber(stream) {
    stream.eatWhile(/[0-9]/);
    if (stream.peek() === '.') {
      stream.next();
      stream.eatWhile(/[0-9]/);
    }
    if (/e/i.test(stream.peek())) {
      stream.next();
      stream.eatWhile(/[\+\-0-9]/);
    }
    return 'number';
  }

  function tokenBase(stream, state) {
    if (stream.eatSpace()) {
      return null;
    }

    var ch = stream.next();

    if (ch === '/' && stream.eat('/')) {
      stream.skipToEnd();
      return 'comment';
    }

    if (ch === '{') {
      state.commentDepth = 1;
      return tokenComment(stream, state);
    }

    if (ch === "'") {
      return tokenString(stream);
    }

    if (ch === '"') {
      return tokenQuotedIdentifier(stream);
    }

    if (/[0-9]/.test(ch)) {
      stream.backUp(1);
      return tokenNumber(stream);
    }

    if (/[A-Za-z_]/.test(ch)) {
      stream.eatWhile(/[A-Za-z0-9_]/);
      var cur = stream.current().toLowerCase();

      if (keywords[cur]) {
        return 'keyword';
      }

      if (dataTypes[cur]) {
        return 'variable-2';
      }

      if (atomWords[cur]) {
        return 'atom';
      }

      if (stream.match(/\s*\(/, false)) {
        return 'def';
      }

      return 'variable';
    }

    if ('+-*/=<>&|:.(),;[]'.indexOf(ch) >= 0) {
      return 'operator';
    }

    return null;
  }

  CodeMirror.defineMode('al', function () {
    return {
      startState: function () {
        return {
          commentDepth: 0
        };
      },
      token: function (stream, state) {
        if (state.commentDepth > 0) {
          return tokenComment(stream, state);
        }
        return tokenBase(stream, state);
      },
      blockCommentStart: '{',
      blockCommentEnd: '}',
      lineComment: '//',
      fold: 'brace'
    };
  });

  CodeMirror.defineMIME('text/al', 'al');
});

