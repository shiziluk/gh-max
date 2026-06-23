# Debug Session: currency-color-loading-issues

## Session ID
`currency-color-loading-issues`

## Start Time
2026-06-23

## Problem Summary
5 issues persist after multiple fix attempts:
1. Chart page currency symbol error (jinshi showing $ instead of ¥)
2. Home page data source switch bar color mismatch
3. History page "no market records"
4. Jinshi data source loading very slow
5. Home page jinshi currency symbol showing $ instead of ¥

## Hypotheses

### H1: Build Cache Issue
- Files are being modified but build cache prevents changes from taking effect
- **Evidence Point**: Check if flutter clean fully clears build artifacts

### H2: File Sync Issue  
- Source files in temp build directory differ from main project directory
- **Evidence Point**: Compare file timestamps and content between directories

### H3: Theme Inheritance Issue
- Container color not properly inheriting from AppBar theme
- **Evidence Point**: Add debug logging to verify Container color at runtime

### H4: Data Source Parameter Issue
- API calls not passing correct source parameter
- **Evidence Point**: Check actual API request URL being generated

### H5: Widget State Not Updating
- setState() not being called or UI not rebuilding
- **Evidence Point**: Add logging to verify state changes

## Status: [OPEN]

## Investigation Plan
1. First verify file sync between directories
2. Add instrumentation to key widgets
3. Collect runtime evidence
4. Implement minimal fix based on evidence
