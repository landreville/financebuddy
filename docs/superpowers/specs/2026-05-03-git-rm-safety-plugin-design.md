# Git-Safe File Deletion Plugin Design

**Date:** 2026-05-03
**Status:** Proposed

## Overview

A plugin that intercepts `rm` commands and validates deletions are safe by ensuring files can be recovered from git version control.

## Architecture

### Hook Strategy
- Use `tool.execute.before` hook to intercept bash commands before execution
- Only intercept literal `rm` commands (not aliases or other variants)

### Decision Flow

```
rm command detected
    ↓
For each file path in command:
    ↓
Is file within workspace?
    ├── No → ASK PERMISSION
    └── Yes →
        ↓
Does file have git history?
    ├── Yes → ALLOW
    └── No → ASK PERMISSION
```

### Git Verification

Commands used:
- `git log [path]` - Check if file has history in current branch
- `git rev-parse --show-toplevel` - Find git repository root
- `git ls-files [path]` - Check if file is currently tracked

## Implementation Details

### Plugin Structure

**Main Plugin (`git-rm-safety.js`):**
- Intercepts bash commands matching `/^rm\s+/` pattern
- Parses command to extract file paths and flags (-r, -f, -v, etc.)
- Validates each file path:
  1. Resolve relative to absolute paths
  2. Check if within workspace directory
  3. Check git repository status for each file
  4. Determine permission action

**Decision Outcomes:**
- `ALLOW` - All files have git history in current branch
- `ASK_PERMISSION` - Any file has concerns (untracked, directory, outside workspace, no git history)

### Permission Prompts

When asking permission, show concise information:
```
Delete files:
  - path/to/file1.txt (untracked)
  - path/to/file2.txt (no git history)
```

### Error Messages

When blocking (shouldn't happen with current design, but defensive):
```
Cannot delete: path/to/file.txt - reason
```

## Test Strategy

### Test Cases

1. **Tracked file deletion** → ALLOW
2. **Untracked file deletion** → ASK PERMISSION  
3. **Directory deletion** → ASK PERMISSION
4. **File outside workspace** → ASK PERMISSION
5. **File without git history** → ASK PERMISSION
6. **Multiple files (mixed)** → ASK PERMISSION (if any have concerns)
7. **Relative paths** → Correctly resolved
8. **Absolute paths** → Correctly validated
9. **rm without arguments** → Pass through (no files to check)
10. **rm with only flags** → Pass through

### Test Environment

Test against various git states:
- Clean repository with committed files
- Repository with staged changes
- Repository with unstaged changes
- Repository with untracked files
- Bare git repository (no working tree)

## Edge Cases

- Symlinks: Follow the same logic as regular files
- Non-existent files: Git check will fail, ask permission
- Special files (devices, sockets): Ask permission
- Multiple `-` flags: Parse correctly
- Quoted paths: Extract correctly from command
- Wildcards/glob patterns: Expand before checking

## Success Criteria

- All rm commands within workspace with git history are allowed automatically
- Files without git history require explicit permission
- Clear, concise permission prompts
- Comprehensive test coverage
- No false positives (safe files blocked) or false negatives (unsafe files allowed)
