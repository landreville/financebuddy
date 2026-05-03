# Git-Safe File Deletion Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an OpenCode plugin that intercepts `rm` commands and validates files can be recovered from git before allowing deletion.

**Architecture:** Uses `permission.ask` hook to intercept bash permission requests for `rm` commands. Files with git history are auto-allowed; files without history or outside workspace trigger permission prompts.

**Tech Stack:** Node.js built-in test runner, JavaScript, git commands, OpenCode plugin API

---

### Task 1: Extract Shared Path Utility

**Files:**
- Create: `/home/jason/.config/opencode/plugins/path-utils.js`
- Modify: `/home/jason/.config/opencode/plugins/git-c-allow.js` (to import from shared)

- [ ] **Step 1: Create path-utils.js with isPathWithinBase**

```javascript
import { resolve } from "path"

/**
 * Returns true if resolvedPath equals resolvedBase or is a direct subdirectory of it.
 * Both arguments must already be canonicalised with path.resolve.
 */
export function isPathWithinBase(resolvedPath, resolvedBase) {
  return resolvedPath === resolvedBase || resolvedPath.startsWith(resolvedBase + "/")
}
```

- [ ] **Step 2: Run existing tests to verify current behavior**

```bash
node --test /home/jason/.config/opencode/plugins/git-c-allow.test.js
```
Expected: All 9 tests pass

- [ ] **Step 3: Update git-c-allow.js to import isPathWithinBase**

Replace the local `isPathWithinBase` function in `git-c-allow.js` with an import:

```javascript
import { resolve } from "path"
import { isPathWithinBase } from "./path-utils.js"

// ... rest of file stays the same, but remove the local isPathWithinBase function
```

Remove lines 54-57 (the local `isPathWithinBase` function) since it's now imported.

- [ ] **Step 4: Run tests again to verify refactor didn't break anything**

```bash
node --test /home/jason/.config/opencode/plugins/git-c-allow.test.js
```
Expected: All 9 tests pass

- [ ] **Step 5: Add tests for path-utils.js**

Create test file for the shared utility:

```javascript
// ~/.config/opencode/plugins/path-utils.test.js
import { test } from "node:test"
import assert from "node:assert/strict"
import { isPathWithinBase } from "./path-utils.js"

test("isPathWithinBase returns true when path equals base", () => {
  assert.strictEqual(isPathWithinBase("/home/jason/workspace", "/home/jason/workspace"), true)
})

test("isPathWithinBase returns true when path is a subdirectory", () => {
  assert.strictEqual(isPathWithinBase("/home/jason/workspace/myapp", "/home/jason/workspace"), true)
})

test("isPathWithinBase returns false when path is outside base", () => {
  assert.strictEqual(isPathWithinBase("/tmp/evil", "/home/jason/workspace"), false)
})

test("isPathWithinBase returns false for prefix-only match", () => {
  assert.strictEqual(isPathWithinBase("/home/jason/workspace2", "/home/jason/workspace"), false)
})
```

- [ ] **Step 6: Run path-utils tests**

```bash
node --test /home/jason/.config/opencode/plugins/path-utils.test.js
```
Expected: All 4 tests pass

- [ ] **Step 7: Commit**

```bash
git add plugins/path-utils.js plugins/path-utils.test.js plugins/git-c-allow.js
git commit -m "refactor: extract shared isPathWithinBase utility to path-utils.js"
```

---

### Task 2: Create RM Command Parser

**Files:**
- Create: `/home/jason/.config/opencode/plugins/rm-parser.js`
- Create: `/home/jason/.config/opencode/plugins/rm-parser.test.js`

- [ ] **Step 1: Write tests first for parseRmCommand**

```javascript
// ~/.config/opencode/plugins/rm-parser.test.js
import { test } from "node:test"
import assert from "node:assert/strict"
import { parseRmCommand } from "./rm-parser.js"

test("parseRmCommand returns null for non-rm commands", () => {
  assert.strictEqual(parseRmCommand("ls -la"), null)
  assert.strictEqual(parseRmCommand("echo hello"), null)
  assert.strictEqual(parseRmCommand("git status"), null)
})

test("parseRmCommand returns null for commands containing 'rm' but not starting with it", () => {
  assert.strictEqual(parseRmCommand("mkdir test"), null)
  assert.strictEqual(parseRmCommand("arm file"), null)
})

test("parseRmCommand extracts files from basic rm command", () => {
  const result = parseRmCommand("rm file.txt")
  assert.deepStrictEqual(result, {
    flags: [],
    files: ["file.txt"]
  })
})

test("parseRmCommand extracts files from rm with -f flag", () => {
  const result = parseRmCommand("rm -f file.txt")
  assert.deepStrictEqual(result, {
    flags: ["f"],
    files: ["file.txt"]
  })
})

test("parseRmCommand extracts files from rm with multiple flags", () => {
  const result = parseRmCommand("rm -rf dir/")
  assert.deepStrictEqual(result, {
    flags: ["r", "f"],
    files: ["dir/"]
  })
})

test("parseRmCommand extracts multiple files", () => {
  const result = parseRmCommand("rm file1.txt file2.txt")
  assert.deepStrictEqual(result, {
    flags: [],
    files: ["file1.txt", "file2.txt"]
  })
})

test("parseRmCommand returns null for rm without files", () => {
  assert.strictEqual(parseRmCommand("rm"), null)
  assert.strictEqual(parseRmCommand("rm -f"), null)
})

test("parseRmCommand handles quoted filenames", () => {
  const result = parseRmCommand("rm \"file with spaces.txt\"")
  assert.deepStrictEqual(result, {
    flags: [],
    files: ["file with spaces.txt"]
  })
})

test("parseRmCommand handles -- end of flags", () => {
  const result = parseRmCommand("rm -- -file.txt")
  assert.deepStrictEqual(result, {
    flags: [],
    files: ["-file.txt"]
  })
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
node --test /home/jason/.config/opencode/plugins/rm-parser.test.js
```
Expected: Tests fail with "parseRmCommand is not a function"

- [ ] **Step 3: Implement parseRmCommand**

```javascript
// ~/.config/opencode/plugins/rm-parser.js

/**
 * Parses an rm command string to extract flags and file paths.
 * Returns { flags: string[], files: string[] } or null if not an rm command.
 */
export function parseRmCommand(command) {
  const trimmed = command.trim()
  
  // Match rm command at start (with optional path prefix)
  const match = trimmed.match(/^(?:.*\/)?rm\s+(.+)$/)
  if (!match) return null
  
  const rest = match[1]
  const flags = []
  const files = []
  let pastDoubleDash = false
  
  // Simple tokenizer that handles quotes
  const tokens = tokenize(rest)
  
  for (const token of tokens) {
    if (pastDoubleDash) {
      files.push(token)
      continue
    }
    
    if (token === "--") {
      pastDoubleDash = true
      continue
    }
    
    if (token.startsWith("-") && token.length > 1) {
      // Extract flag characters (e.g., "-rf" -> ["r", "f"])
      const flagChars = token.slice(token.startsWith("--") ? 2 : 1)
      if (flagChars) {
        if (token.startsWith("--")) {
          flags.push(token.slice(2))
        } else {
          flags.push(...flagChars)
        }
      }
    } else {
      files.push(token)
    }
  }
  
  // Must have at least one file to be a valid rm command
  if (files.length === 0) return null
  
  return { flags, files }
}

/**
 * Simple tokenizer that handles quoted strings
 */
function tokenize(input) {
  const tokens = []
  let current = ""
  let inQuote = false
  let quoteChar = ""
  
  for (let i = 0; i < input.length; i++) {
    const char = input[i]
    
    if (inQuote) {
      if (char === quoteChar) {
        inQuote = false
      } else {
        current += char
      }
      continue
    }
    
    if (char === '"' || char === "'") {
      inQuote = true
      quoteChar = char
      continue
    }
    
    if (char === " ") {
      if (current) {
        tokens.push(current)
        current = ""
      }
      continue
    }
    
    current += char
  }
  
  if (current) {
    tokens.push(current)
  }
  
  return tokens
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
node --test /home/jason/.config/opencode/plugins/rm-parser.test.js
```
Expected: All 9 tests pass

- [ ] **Step 5: Commit**

```bash
git add plugins/rm-parser.js plugins/rm-parser.test.js
git commit -m "feat: add rm command parser with flag and file extraction"
```

---

### Task 3: Create Git History Checker

**Files:**
- Create: `/home/jason/.config/opencode/plugins/git-history.js`
- Create: `/home/jason/.config/opencode/plugins/git-history.test.js`

- [ ] **Step 1: Write tests first for hasGitHistory**

```javascript
// ~/.config/opencode/plugins/git-history.test.js
import { test } from "node:test"
import assert from "node:assert/strict"
import { hasGitHistory } from "./git-history.js"

// Note: These tests require a real git repository to run
// They will be tested in the integration test environment

test("hasGitHistory function is exported", () => {
  assert.ok(typeof hasGitHistory === "function")
})
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
node --test /home/jason/.config/opencode/plugins/git-history.test.js
```
Expected: 1 test passes (function exists)

- [ ] **Step 3: Implement hasGitHistory**

```javascript
// ~/.config/opencode/plugins/git-history.js
import { execSync } from "child_process"
import { dirname, resolve } from "path"

/**
 * Checks if a file has git history in the current branch.
 * Returns true if the file exists in git history, false otherwise.
 * 
 * @param {string} filePath - Absolute path to the file
 * @param {string} [cwd] - Working directory for git commands (optional)
 * @returns {boolean}
 */
export function hasGitHistory(filePath, cwd) {
  try {
    // Use git log to check if file has any history
    const result = execSync(`git log --oneline -- "${filePath}"`, {
      cwd: cwd || dirname(filePath),
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 5000
    })
    
    // If git log returns any output, file has history
    return result.toString().trim().length > 0
  } catch (error) {
    // git log returns non-zero exit code if file not found in history
    return false
  }
}

/**
 * Checks if a file is currently tracked by git.
 * Returns true if file is tracked, false otherwise.
 * 
 * @param {string} filePath - Absolute path to the file
 * @param {string} [cwd] - Working directory for git commands (optional)
 * @returns {boolean}
 */
export function isTrackedByGit(filePath, cwd) {
  try {
    const result = execSync(`git ls-files --error-unmatch -- "${filePath}"`, {
      cwd: cwd || dirname(filePath),
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 5000
    })
    
    return result.toString().trim().length > 0
  } catch (error) {
    return false
  }
}
```

- [ ] **Step 4: Run tests again**

```bash
node --test /home/jason/.config/opencode/plugins/git-history.test.js
```
Expected: 1 test passes

- [ ] **Step 5: Commit**

```bash
git add plugins/git-history.js plugins/git-history.test.js
git commit -m "feat: add git history checker utility functions"
```

---

### Task 4: Build Main Plugin with permission.ask Hook

**Files:**
- Create: `/home/jason/.config/opencode/plugins/git-rm-safety.js`

- [ ] **Step 1: Write the main plugin**

```javascript
// ~/.config/opencode/plugins/git-rm-safety.js
import { resolve } from "path"
import { parseRmCommand } from "./rm-parser.js"
import { hasGitHistory } from "./git-history.js"
import { isPathWithinBase } from "./path-utils.js"

export const GitRmSafety = async ({ $, worktree, directory }) => {
  const base = resolve(worktree || directory)
  
  return {
    "permission.ask": async (input, output) => {
      try {
        // Only handle bash commands
        if (input.type !== "bash") return
        
        // Get the command string
        const raw = Array.isArray(input.pattern) ? input.pattern[0] : input.pattern
        if (!raw) return
        
        // Parse the rm command
        const parsed = parseRmCommand(raw)
        if (!parsed) return
        
        // Check each file in the rm command
        const concerns = []
        
        for (const file of parsed.files) {
          const absolutePath = resolve(base, file)
          
          // Check if file is within workspace
          if (!isPathWithinBase(absolutePath, base)) {
            concerns.push(`${file} (outside workspace)`)
            continue
          }
          
          // Check if file has git history
          if (!hasGitHistory(absolutePath, base)) {
            concerns.push(`${file} (untracked)`)
          }
        }
        
        // If any files have concerns, let the default permission behavior handle it
        // (don't set output.status, so it stays as "ask")
        if (concerns.length > 0) return
        
        // All files have git history - auto-allow
        output.status = "allow"
        
      } catch (err) {
        console.error("[git-rm-safety] permission.ask error:", err)
      }
    }
  }
}
```

- [ ] **Step 2: Verify plugin loads without errors**

```bash
node -e "import('./plugins/git-rm-safety.js').then(() => console.log('Plugin loads OK'))"
```
Expected: "Plugin loads OK"

- [ ] **Step 3: Commit**

```bash
git add plugins/git-rm-safety.js
git commit -m "feat: add git-rm-safety plugin with permission.ask hook"
```

---

### Task 5: Comprehensive Integration Tests

**Files:**
- Create: `/home/jason/.config/opencode/plugins/git-rm-safety.test.js`
- Create: `/home/jason/.config/opencode/plugins/test-helpers.js`

- [ ] **Step 1: Create test helpers for git repository setup**

```javascript
// ~/.config/opencode/plugins/test-helpers.js
import { execSync } from "child_process"
import { mkdtempSync, writeFileSync, mkdirSync, rmSync, existsSync } from "fs"
import { tmpdir } from "os"
import { join } from "path"

/**
 * Creates a temporary git repository for testing
 * @returns {Object} { dir, cleanup } - Directory path and cleanup function
 */
export function createTestRepo() {
  const dir = mkdtempSync(join(tmpdir(), "git-rm-test-"))
  
  // Initialize git repo
  execSync("git init", { cwd: dir })
  execSync("git config user.email 'test@test.com'", { cwd: dir })
  execSync("git config user.name 'Test'", { cwd: dir })
  
  return {
    dir,
    cleanup: () => {
      try {
        rmSync(dir, { recursive: true, force: true })
      } catch {}
    }
  }
}

/**
 * Commits a file to the test repository
 */
export function commitFile(dir, filename, content = "test content") {
  const filepath = join(dir, filename)
  const filedir = dirname(filepath)
  
  if (filedir !== dir) {
    mkdirSync(filedir, { recursive: true })
  }
  
  writeFileSync(filepath, content)
  execSync(`git add "${filename}"`, { cwd: dir })
  execSync(`git commit -m "add ${filename}"`, { cwd: dir })
  
  return filepath
}

/**
 * Creates an untracked file
 */
export function createUntrackedFile(dir, filename, content = "untracked") {
  const filepath = join(dir, filename)
  writeFileSync(filepath, content)
  return filepath
}
```

- [ ] **Step 2: Write integration tests**

```javascript
// ~/.config/opencode/plugins/git-rm-safety.test.js
import { test, describe } from "node:test"
import assert from "node:assert/strict"
import { createTestRepo, commitFile, createUntrackedFile } from "./test-helpers.js"
import { parseRmCommand } from "./rm-parser.js"
import { hasGitHistory } from "./git-history.js"
import { isPathWithinBase } from "./path-utils.js"

describe("GitRmSafety Integration Tests", () => {
  test("tracked file should have git history", () => {
    const { dir, cleanup } = createTestRepo()
    try {
      const filepath = commitFile(dir, "tracked.txt")
      assert.ok(hasGitHistory(filepath, dir))
    } finally {
      cleanup()
    }
  })

  test("untracked file should not have git history", () => {
    const { dir, cleanup } = createTestRepo()
    try {
      const filepath = createUntrackedFile(dir, "untracked.txt")
      assert.ok(!hasGitHistory(filepath, dir))
    } finally {
      cleanup()
    }
  })

  test("deleted file should still have git history", () => {
    const { dir, cleanup } = createTestRepo()
    try {
      const filepath = commitFile(dir, "to-delete.txt")
      rmSync(filepath)
      assert.ok(hasGitHistory(filepath, dir))
    } finally {
      cleanup()
    }
  })

  test("file in subdirectory should have git history", () => {
    const { dir, cleanup } = createTestRepo()
    try {
      const filepath = commitFile(dir, "subdir/nested.txt")
      assert.ok(hasGitHistory(filepath, dir))
    } finally {
      cleanup()
    }
  })

  test("path within base should be allowed", () => {
    assert.ok(isPathWithinBase("/workspace/project", "/workspace"))
    assert.ok(!isPathWithinBase("/tmp/outside", "/workspace"))
  })

  test("rm parser should handle real-world commands", () => {
    const cmd = "rm -rf build/ dist/ *.log"
    const result = parseRmCommand(cmd)
    
    assert.ok(result)
    assert.ok(result.flags.includes("r"))
    assert.ok(result.flags.includes("f"))
    assert.strictEqual(result.files.length, 3)
  })
})
```

- [ ] **Step 3: Run integration tests**

```bash
node --test /home/jason/.config/opencode/plugins/git-rm-safety.test.js
```
Expected: All 6 tests pass

- [ ] **Step 4: Run all plugin tests together**

```bash
node --test /home/jason/.config/opencode/plugins/*.test.js
```
Expected: All tests pass (9 from git-c-allow + 4 from path-utils + 9 from rm-parser + 1 from git-history + 6 from git-rm-safety = 29 total)

- [ ] **Step 5: Commit**

```bash
git add plugins/test-helpers.js plugins/git-rm-safety.test.js
git commit -m "test: add comprehensive integration tests for git-rm-safety"
```

---

### Task 6: Final Verification and Documentation

**Files:**
- No new files created
- Verify: All existing tests pass
- Verify: Plugin loads correctly in OpenCode

- [ ] **Step 1: Run all tests one final time**

```bash
node --test /home/jason/.config/opencode/plugins/*.test.js
```
Expected: All 29 tests pass

- [ ] **Step 2: Verify plugin export format**

```bash
node -e "import('./plugins/git-rm-safety.js').then(m => console.log('Exports:', Object.keys(m)))"
```
Expected: Shows "GitRmSafety" export

- [ ] **Step 3: Verify plugin can be instantiated**

```bash
node -e "
import { GitRmSafety } from './plugins/git-rm-safety.js'
const plugin = await GitRmSafety({ 
  worktree: '/tmp', 
  directory: '/tmp' 
})
console.log('Hooks:', Object.keys(plugin))
"
```
Expected: Shows "permission.ask" hook

- [ ] **Step 4: Commit final state**

```bash
git status
git add -A
git commit -m "chore: verify git-rm-safety plugin integration"
```

---

## File Summary

| File | Purpose |
|------|---------|
| `plugins/path-utils.js` | Shared path comparison utility |
| `plugins/path-utils.test.js` | Tests for path utilities |
| `plugins/rm-parser.js` | RM command parser |
| `plugins/rm-parser.test.js` | Tests for RM parser |
| `plugins/git-history.js` | Git history checker |
| `plugins/git-history.test.js` | Tests for git history (basic) |
| `plugins/git-rm-safety.js` | Main plugin with permission hook |
| `plugins/git-rm-safety.test.js` | Integration tests |
| `plugins/test-helpers.js` | Test utilities for git repos |
| `plugins/git-c-allow.js` | Modified to use shared path-utils |

## Total Test Count

- **29 tests** across all test files
- All tests use Node.js built-in test runner (`node:test`)
- Tests are self-contained and create temporary git repos for isolation
