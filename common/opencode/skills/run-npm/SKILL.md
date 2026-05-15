---
name: npm-runner
description: Police npm server run executions
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: npm
---

## What I do
You run npm commands, knowing they may linger. When running npm, the command may hang. Be sure to poll the output to ensure the process isnt hanging, and validate the command has reached a steady enough state to be considered complete.

## When to use me
for example, when running commands like:
- npm run dev
- npm run

