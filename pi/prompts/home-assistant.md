---
description: Handle a Home Assistant request via the home-assistant MCP server
argument-hint: "[request]"
---
Handle this Home Assistant request using ONLY the `mcp__home_assistant__*` tools:

${@:-<the user's request, if not already stated>}

Work through these steps in order.

## 1. Clarify

Read the existing state (entities, devices, automations) first — read-only calls
need no approval. If anything is ambiguous (which entity, which area, whether a
rename should also change the entity_id, etc.), batch all clarifying questions
into one message. Do not act until the request is clear.

## 2. Plan

List every tool call you intend to make, in order, before making any mutating
one. For each call, state the tool, its key arguments, and what changes it makes.
This planning is where MCP limitations must be caught: if an action cannot be
expressed as a home-assistant MCP tool (e.g. deleting a device, creating a
helper, editing YAML), stop and report the gap as a bug or a feature request
for the home-assistant MCP server, whichever fits the context. Do not reach for
bash, file edits, or other MCP servers to cover the gap.

## 3. Present

Show the complete plan — every MCP tool call and its effect — and ask the user
to approve, reject, or tweak it. Repeat until approved.

## 4. Execute

Run the approved plan in order. Use `dry_run: true` where the tool supports it
to preview mutating registry changes. After execution, verify the resulting
state with read-only calls and report what changed.
