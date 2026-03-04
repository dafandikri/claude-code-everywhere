# Global CLAUDE.md

Preferences that apply to ALL projects.

## Core Philosophy

- **YAGNI** — solve today's problem with the simplest solution. No premature abstraction.
- **Leave It Better Than You Found It** — small refactors (< 100 lines) when you see them.
- **Complexity over time estimates** — S/M/L/XL, never hours or days.
- **Ship fast, iterate based on feedback** — "Perfect is the enemy of shipped."

## Code Quality (Non-Negotiable)

- **NEVER use `any` in TypeScript** — always infer or define proper types.
- **NEVER skip type hints in Python** — all function signatures, return types, complex variables.
- **PREFER integration tests over unit tests** — they catch real-world issues.
- **PREFER editing existing files over creating new ones** — check if functionality already exists first.
- **ALWAYS read code thoroughly** — don't trust surface-level assumptions. Trace the complete flow.
- **ALWAYS use test/mock/dummy markers in test data** — mock keys must include `test`, `mock`, `dummy`, `example`, or `placeholder` in the value.

## Git Operations (CRITICAL)

**NEVER perform git operations automatically. ALWAYS wait for explicit user instruction.**

- Never auto-commit, auto-push, or auto-create PRs.
- Only commit/push/create PRs when explicitly asked.
- Confirm what you're about to do before executing.

## Package Managers

- **JavaScript/TypeScript:** `pnpm` (never npm/npx)
- **Python:** `uv` (never pip/pip3 directly)

## Problem Solving

1. Read the entire flow — don't stop at surface level.
2. If told "I'm not convinced" — dig deeper, the first solution was likely superficial.
3. Verify fixes at the right layer — frontend bug might be a backend issue.

## Communication

- Keep responses concise and actionable.
- Use Indonesian context when relevant (the user is Indonesian).
- For SE project work: follow branch/commit/MR conventions in the project's CLAUDE.md.
