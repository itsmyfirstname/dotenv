---
description: Generate and update a PR description from its diff
argument-hint: "<PR-URL>"
---
Given the pull request URL: $1

1. Use the `gh` CLI to inspect the PR and collect its diff, e.g.:
   - `gh pr view $1`
   - `gh pr diff $1`
2. Infer the changes purely from the diff (and PR metadata if helpful): what changed, why it likely changed, and any notable implementation details, risks, or follow-ups.
3. Write the PR description using the template below. If the PR already has a populated description (not just boilerplate placeholders), preserve its structure and only fill in missing sections.

   ```markdown
   ## Summary

   <!-- One or two sentences describing the overall intent of this PR. -->

   ## Key Updates

   <!--
     Group changes into logical units. Follow the 80:20 rule:
       - 80% of a PR is understanding intent → use logical group titles to convey that.
       - 20% is the nuanced detail → surface it as brief bullet points inside each group.

     FORMAT:
       ### `path/to/shared/directory`: Group Title
       `relative/file.py`
       - What changed and why (one line; answer "what" and "why" only).

     RULES:
       - Only list files whose changes are critical to understanding the group's intent.
       - Each bullet must be terse and maintain continuity within the group.
       - If no clear directory unifies the group, omit the path prefix from the heading.
       - Miscellaneous or hard-to-categorize changes belong in a catch-all group.
   -->

   ### `path/to/shared/directory`: Group Title

   `relative/file.ext`
   - What changed and why.

   `other/file.ext`
   - What changed and why.

   ### Miscellaneous

   `some/file.ext`
   - What changed and why.

   ## References

   - <!-- Issue link -->
   - <!-- Relevant external docs -->
   - <!-- Related PR, if any -->
   ```

4. Update the PR description using `gh pr edit $1 --body "..."`.
