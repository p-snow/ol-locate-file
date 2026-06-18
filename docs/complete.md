# Complete Handler: `org-locate-file-complete-link`

When the user invokes `org-insert-link` (typically `C-c C-l`) and
selects the `lfile:` link type (or whatever
`org-locate-file-link-type` is set to), the complete handler is
called to allow the user to choose a link target.

## Behavior

1. A single `completing-read` session opens in the minibuffer.

2. As the user types, each keystroke triggers a fresh locate query
   via `completion-table-dynamic`.  The locate database is queried
   with whatever substring the user has entered so far, and the
   matching files are presented as completion candidates.

3. Completion candidates are **absolute file paths** from the locate
   database (e.g. `/usr/bin/emacsclient`).  The user selects one,
   then `org-locate-file--shortest-unique-suffix` computes the
   shortest unique suffix for use as the link path:
   - When the basename is already unique, the stored link uses just
     the basename (e.g. `lfile:emacsclient`).
   - When multiple files share the same basename, parent directory
     components are prepended until the suffix is unique
     (e.g. `lfile:bin/emacsclient`).
   - When the selected path is not found in the locate database at
     all, the bare basename is used as a fallback (via
     `file-name-nondirectory`).

4. If the locate query returns no results for the current input,
   completion yields nil (no candidates shown).  The user's raw
   input string is then used as the selected choice, and the bare
   basename of that input is inserted.

5. The history variable `org-locate-file--history` stores previously
   selected basenames for easy recall.

## Example

```
# User types "emacs" in the completing-read prompt.
# Locate returns: ["/usr/bin/emacsclient", "/usr/bin/emacs"]
# Candidates shown: "/usr/bin/emacsclient", "/usr/bin/emacs"
# User selects "/usr/bin/emacsclient".
# shortest-unique-suffix returns "emacsclient" (unique).
# Inserted link: [[lfile:emacsclient]]
```

## Design Notes

- The `:complete` handler is registered via `org-link-set-parameters`
  in `org-locate-file--register-link-parameters`.
- The dynamic table is constructed with `completion-table-dynamic`,
  which calls `org-locate-file--run-locate` on each completion
  request with the current minibuffer input.
- Full paths are used as completion candidates so the user can
  distinguish files with the same basename during selection.
- The link itself uses the shortest unique suffix (computed by
  `org-locate-file--shortest-unique-suffix`) so that the stored
  link is concise and remains resolvable at follow-time as long
  as the suffix remains unique in the locate database.
- When the selected path is a directory, children of that directory
  are excluded from locate results during suffix computation, so
  that files inside the target directory do not inflate the
  candidate count.