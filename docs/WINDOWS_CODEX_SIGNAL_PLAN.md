# Windows Codex Signal Light Plan

## Goal

Make `vibecoding-signal-light` work reliably on Windows for a user who primarily uses Codex through the VS Code extension.

The target outcome is:

- Codex state changes automatically drive the physical signal light
- Windows usage is smooth enough for daily use
- The solution is stable, understandable, and low-maintenance

## What We Tried

### 1. Read the repository and verify the current architecture

We reviewed:

- `README.md`
- `signal_light/cli.py`
- `signal_light/codex_hook.py`
- `signal_light/runtime.py`
- `signal_light/hardware.py`

We confirmed the project is structured around:

- Python CLI entrypoints
- hook adapters for Codex and Claude Code
- MCP2221A hardware control
- a small shared lamp language

### 2. Add Windows compatibility to the repo

We added or adjusted:

- PowerShell wrapper scripts for Windows
- bash wrapper script Python selection logic for Windows / Git Bash
- README Windows usage notes

Working results:

- `python -m signal_light ...` worked on Windows
- PowerShell wrappers worked
- Git Bash wrappers worked after Python resolution fixes
- dry-run mode worked

### 3. Try the Codex hooks route

We tried:

- `~/.codex/hooks.json`
- enabling `features.hooks = true` in `~/.codex/config.toml`
- generating a structured `config.toml` candidate with hook definitions

Observed results:

- scripts themselves were callable
- dry-run hook logic worked
- but the VS Code extension did not reliably trigger those hooks
- one structured config attempt interfered with the login/startup experience, so it was reverted

### 4. Investigate the VS Code Codex extension

We inspected the installed extension:

- `openai.chatgpt-26.519.32039-win32-x64`

We confirmed:

- it contains an internal `codex.exe`
- it uses an app-server style runtime
- it internally knows about `codex/event/...` events
- it does not clearly expose a simple public external hook interface at the plugin level

### 5. Export and inspect Codex app-server schemas

We generated schema output from the bundled `codex.exe` to inspect:

- hook concepts
- event names
- config structures
- app-server protocol shape

Important findings:

- hooks are real runtime concepts
- hook events include:
  - `preToolUse`
  - `permissionRequest`
  - `postToolUse`
  - `sessionStart`
  - `userPromptSubmit`
  - `stop`
- the runtime supports `commandWindows`
- hook configuration appears to belong to `config.toml`-style config, not just `hooks.json`

The exported schema directory was later deleted from the repo to avoid clutter.

### 6. Try a log-watcher fallback

We temporarily built a log watcher that listened to VS Code `Codex.log` and mapped log lines to lamp states.

This was later removed from the repo because:

- the logs were noisy
- `thread-stream-state-changed` produced too many false positives
- the logs did not reliably expose the ideal `codex/event/...` text we wanted
- the result was not robust enough for long-term use

## Current Results

### Confirmed working

- The repo can run on Windows
- PowerShell wrappers are working
- Git Bash wrappers are working
- dry-run signal playback is working
- the project itself is not blocked by Windows

### Confirmed not yet solved

- Automatic state-sync from the VS Code Codex extension to the lamp is not solved
- `~/.codex/hooks.json` is not enough in the current plugin-driven setup
- simply enabling `features.hooks = true` in the main user config is not enough
- log-watching is not a good long-term answer for this setup

## Key Problems Found

### 1. The VS Code extension is not a transparent hook surface

The user works through the VS Code extension, not through a clean standalone Codex CLI workflow.

That means:

- plugin behavior and runtime behavior are partially hidden
- config source is not obvious
- local hooks are harder to validate

### 2. Sandbox changes the runtime environment

The user intentionally runs Codex in a sandboxed setup for safety.

A `doctor` run on the bundled `codex.exe` showed:

- `CODEX_HOME = C:\Users\CodexSandboxOffline\.codex`

But that sandbox directory did not contain a normal full config setup like:

- `config.toml`
- `hooks.json`
- `auth.json`

This suggests:

- the effective runtime config source may be more complex than a single visible `.codex` directory
- some configuration may be injected or managed indirectly by the extension/runtime

### 3. The visible logs are not the clean state source we want

In the actual `Codex.log`, the stable visible output was mostly:

- `thread-stream-state-changed`
- background network/plugin messages

What we wanted was:

- direct `codex/event/task_started`
- direct `codex/event/task_complete`
- direct `codex/event/exec_approval_request`
- direct `codex/event/error`

But those were not reliably present as log lines in the current VS Code workflow.

## Why The Log Watcher Was Removed

The watcher was removed because it did not meet the reliability bar.

Specifically:

- background plugin noise caused ambiguity
- false positives were hard to eliminate without also losing useful signal
- a pure `codex/event/...` watcher would be ideal, but the current visible log output does not reliably provide that event stream

This made the approach too fragile.

## Where We Are Now

The repository currently contains only the Windows compatibility improvements and the original project logic.

The log-watcher prototype and schema dump have been removed.

What remains in git status are the Windows compatibility changes:

- `README.md`
- `scripts/signal-light`
- `scripts/codex-signal-hook`
- `scripts/claude-code-signal-hook`
- `scripts/signal-light.ps1`
- `scripts/codex-signal-hook.ps1`
- `scripts/claude-code-signal-hook.ps1`
- `signal_light/agent_signals.py`
- `signal_light/cli.py`

## Recommended Next Step

Move to a true standalone Codex CLI workflow instead of continuing to fight the VS Code extension internals.

Why:

- hooks are much more likely to be controllable
- config ownership is clearer
- state propagation is easier to reason about
- the signal light integration becomes a normal Codex hook problem again

## Open Questions

These questions remain unresolved:

1. If the user keeps using only the VS Code extension, can a stable automatic hook path be found without reverse-engineering the extension internals?
2. If the user installs or adopts a standalone Codex CLI, will that CLI become the real daily entrypoint?
3. If thread content syncs across surfaces, will runtime hook execution also sync, or only conversation content?

## Decision Record

Current recommendation:

- do not continue the removed log-watcher route
- do not continue directly modifying the live VS Code plugin-driven config blindly
- prefer a standalone CLI-based solution for the next phase

## Practical Summary

What is done:

- Windows project compatibility work
- hook-path investigation
- extension/runtime investigation
- schema/protocol investigation
- log-watcher exploration and removal

What is not done:

- stable automatic lamp sync for the current VS Code extension workflow

What likely comes next:

- evaluate or install a standalone Codex CLI
- re-test hook-based signal light integration there
