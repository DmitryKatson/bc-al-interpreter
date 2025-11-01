# Interactive AL Code Runner

This repository hosts a Business Central extension that interprets AL snippets at runtime—ideal for troubleshooting, demos, and exploratory data work without publishing new codeunits. Development and CI are orchestrated through AL-Go for GitHub.

## Where to Start

- Application details, supported syntax, and usage examples live in `src/app/README.md`.
- Test strategy, coverage notes, and execution guidance are documented in `src/test/README.md`.

## Development Environment

- Run `.AL-Go/localDevEnv.ps1` for a Docker sandbox or `.AL-Go/cloudDevEnv.ps1` for SaaS setup.
- Visual Studio Code with the AL Language extension remains the recommended IDE.

## Project Layout

```
bc-al-interpreter/
├── .AL-Go/          # AL-Go pipeline scripts
├── src/
│   ├── app/        # Extension source
│   └── test/       # Automated tests
└── README.md       # Repository overview (this file)
```

Questions about extending AL-Go? Review the upstream guidance at https://aka.ms/AL-Go.
