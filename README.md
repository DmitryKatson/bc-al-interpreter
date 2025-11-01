# Interactive AL Code Runner for Business Central

This repository contains the Interactive AL Code Runner extension for Microsoft Dynamics 365 Business Central, managed using AL-Go.

## Overview

This extension enables Business Central users to write and execute AL code directly within the platform. The system provides a comprehensive AL interpreter that supports variables, expressions, conditionals, loops, record operations, and built-in functions.

Users can simply write AL code and execute it immediately without compilation or deployment, making it perfect for quick prototyping, data analysis, and ad-hoc reporting.

## Project Structure

```
bc-al-interpreter/
├── .AL-Go/              # AL-Go configuration and scripts
├── src/
│   ├── app/            # Application source code
│   └── test/           # Test codeunits and test files
├── README.md           # This file
└── al-code-interpreter.code-workspace  # VS Code workspace
```

## Setup

This project uses AL-Go for development and deployment. Please go to https://aka.ms/AL-Go to learn more.

### Development Environment Setup

1. **Local Development**: Run `.AL-Go/localDevEnv.ps1` to create a local Docker-based development environment
2. **Cloud Development**: Run `.AL-Go/cloudDevEnv.ps1` to create a cloud-based SaaS sandbox environment

## Key Features

- Write and execute AL code directly in Business Central
- Comprehensive AL interpreter supporting most language features
- Interactive code editor with real-time execution
- Built-in demo scripts for learning (auto-loaded on installation)
- Save and organize your scripts for reuse
- Public/private script sharing capabilities
- No compilation or deployment required

## Supported AL Features

### Data Types
- Integer, Text, Boolean, Decimal, Date, DateTime
- Code, Char, BigText, GUID, Option, Duration, Blob
- Record (for table access)

### Operators
- Arithmetic: `+`, `-`, `*`, `/`, `div`, `mod`
- Comparison: `=`, `<>`, `<`, `>`, `<=`, `>=`
- Logical: `and`, `or`, `not`
- Assignment: `:=`

### Control Structures
- if/then/else statements with nesting
- repeat/until loops
- begin/end blocks for statement grouping

### Record Operations
- FindFirst(), FindLast(), FindSet()
- Next() for iteration
- SetRange(), SetFilter() for filtering
- Field access and modification
- CalcFields() for calculated fields

### Built-in Functions
- Message() for output
- String: StrLen(), UpperCase(), LowerCase(), CopyStr()
- Math: Round(), Abs()
- Date: Today(), Time(), CurrentDateTime()
- System: UserId(), CompanyName(), Format()

## Requirements

- Business Central 2024 Wave 2/v27.0+
- Administrator permissions to install extensions
- Visual Studio Code with AL Language extension (for development)

## Contributing

Please read [this](https://github.com/microsoft/AL-Go/blob/main/Scenarios/Contribute.md) description on how to contribute to AL-Go for GitHub.
