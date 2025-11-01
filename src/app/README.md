# Interactive AL Code Runner for Business Central

## Overview

This extension enables Business Central users to write and execute AL code directly within the platform. The system provides a comprehensive AL interpreter that supports variables, expressions, conditionals, loops, record operations, and built-in functions.

Users can simply write AL code and execute it immediately without compilation or deployment, making it perfect for quick prototyping, data analysis, and ad-hoc reporting.

## Key Features

- Write and execute AL code directly in Business Central
- Comprehensive AL interpreter supporting most language features
- Interactive code editor with real-time execution
- Built-in demo scripts for learning (auto-loaded on installation)
- Save and organize your scripts for reuse
- Public/private script sharing capabilities
- No compilation or deployment required

## Setup Requirements

- Business Central 2024 Wave 2/v27.0+
- Administrator permissions to install extensions
- Visual Studio Code with AL Language extension (for development)

## Quick Setup

1. **Install Extension**: Deploy the extension to your Business Central environment
2. **Open Code Runner**: Search for "Interactive Code Runner" in Business Central
3. **Load Demos**: Demo scripts are automatically loaded on first use
4. **Start Coding**: Write your first AL script and click "Run"

## Using the Extension

1. Open "Interactive Code Runner" page
2. Write your AL code in the editor
3. Click "Run" to execute
4. View results in the output console
5. Save useful scripts for later use

## Demo Scripts

The extension includes 7 progressive demo scripts that teach AL programming from zero to hero:

### 1. Welcome & Basics
Learn variable declarations, assignments, and basic operations.

### 2. Working with Data
Master record operations, FindSet(), and field access.

### 3. Filtering & Conditions
Understand SetRange(), if/then/else logic, and data filtering.

### 4. Loops & Iteration
Master repeat/until loops, counters, and control flow.

### 5. Built-in Functions
Learn string, date, math, and formatting functions.

### 6. Real Analysis
Apply everything to complete business data analysis.

### 7. Advanced Patterns
Master complex business logic and multi-table operations.

## Example Questions

- "Show me all customers with high balances"
- "Analyze inventory levels and identify low stock items"
- "Calculate total sales by customer for this month"
- "Find the top 10 selling items"
- "Generate a report of overdue invoices"

## Example Code

### Basic Customer Query
```al
Cust: Record Customer;
Counter: Integer;

Counter := 0;
if Cust.FindSet() then begin
  repeat
    Counter := Counter + 1;
    Message('Customer ' + Format(Counter) + ': ' + Cust.Name);
  until Cust.Next() = 0;
end;

Message('Total customers: ' + Format(Counter));
```

### Inventory Analysis
```al
Item: Record Item;
LowStock: Integer;

LowStock := 0;
Item.SetRange('Type', 'Inventory');
if Item.FindSet() then begin
  repeat
    if Item.Inventory < 10 then begin
      LowStock := LowStock + 1;
      Message('Low stock: ' + Item.'No.' + ' - ' + Item.Description);
    end;
  until Item.Next() = 0;
end;

Message('Items below reorder point: ' + Format(LowStock));
```

### Sales Analysis
```al
SalesHeader: Record "Sales Header";
TotalSales: Decimal;

TotalSales := 0;
SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
if SalesHeader.FindSet() then begin
  repeat
    TotalSales := TotalSales + SalesHeader."Amount Including VAT";
  until SalesHeader.Next() = 0;
end;

Message('Total sales: ' + Format(TotalSales));
```

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

## Adding Custom Instructions

You can customize the interpreter's behavior by extending the codeunit with additional functions or modifying the built-in function set.

### Method 1: Extend Built-in Functions

Add new cases to the `CallBuiltInFunction()` procedure in the Program Executor codeunit:

```al
case FunctionName of
    'MyCustomFunction':
        // Your custom function logic
        Result := 'Custom result';
    // ... existing cases
end;
```

### Method 2: Add New Statement Types

Extend the `ParseStatement()` procedure to support new statement types:

```al
case TokenType of
    'MY_KEYWORD':
        ParseMyCustomStatement();
    // ... existing cases
end;
```

## Technical Notes

- **Secure execution**: All code runs within Business Central's security model
- **Data privacy**: No business data sent to external services
- **Performance**: Optimized for typical data analysis scenarios
- **Limitations**: Some advanced AL features not supported (see below)

## Current Limitations

- No while or for loops (only repeat/until)
- No case/of statements
- No procedure definitions
- No local procedure calls
- No arrays or complex data structures
- Maximum 100 variables per script
- Maximum 10,000 loop iterations
- Single global scope only
- No error handling (try/catch)
- No file I/O operations

## Troubleshooting

### "Table not found" Error
- Verify table name spelling
- Table must exist in your Business Central environment
- Use exact table names from Business Central

### "Field not found" Error
- Check field name spelling
- Field must exist on the table
- Use single quotes for field names with special characters

### "Variable not found" Error
- Declare the variable before using it
- Check variable name spelling (case-sensitive)

### "Loop exceeded maximum iterations" Error
- Check loop condition - ensure it will eventually become true
- Maximum iterations is 10,000 by default

## Performance Tips

- Filter records before iteration using SetRange() or SetFilter()
- Use counters instead of displaying every record in loops
- Test with small datasets first
- Avoid nested loops when possible
- Consider using CalcFields() for calculated fields

## Security Notes

⚠️ **Important Security Considerations:**

- Only grant access to trusted administrators
- Scripts execute with the user's permissions
- Can modify database records if write operations are used
- No sandboxing - scripts have full AL capabilities
- Review all scripts before execution
- Use "Is Public" flag carefully

## Support

For help, questions, or contributions, please refer to the project documentation or contact the development team.

## Version History

### Version 1.0.0.0
- Initial release with comprehensive AL interpreter
- Support for variables, expressions, conditionals, loops
- Record operations and built-in functions
- Interactive code editor with real-time execution
- Demo scripts for learning
- Public/private script sharing

---

*Powered by Business Central and AL Language*