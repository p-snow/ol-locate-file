# Complete Handler: `ol-locate-file-complete-link`

When the user invokes `org-insert-link` (typically `C-c C-l`) and
selects the `lfile:` link type (or whatever
`ol-locate-file-link-type` is set to), the complete handler is
called to allow the user to choose a link target.

## Behavior

1. A single `completing-read` session opens in the minibuffer.

2. As the user types, each keystroke triggers a fresh locate query
   via `completion-table-dynamic`.  The locate database is queried
   with whatever substring the user has entered so far, and the
   matching files are presented as completion candidates.

3. Completion candidates are the **basenames** of matching files
   (via `file-name-nondirectory`), not the full absolute paths.
   This means:
   - The inserted link looks like `lfile:emacsclient` instead of
     `lfile:/usr/bin/emacsclient`.
   - The link is resolved again at follow-time via the locate
     database, so it remains valid even if the file moves (as long
     as the locate database is updated).

4. If the locate query returns no results for the current input,
   the user's raw input is used as-is.  This allows typing a path
   that is not in the locate database.

5. The history variable `ol-locate-file--history` stores previously
   selected basenames for easy recall.

## Example

```
# User types "emacs" in the completing-read prompt.
# Locate returns: ["/usr/bin/emacsclient", "/usr/bin/emacs"]
# Candidates shown: "emacsclient", "emacs"
# User selects "emacsclient".
# Inserted link: [[lfile:emacsclient]]
```

## Design Notes

- The `:complete` handler is registered via `org-link-set-parameters`
  in `ol-locate-file--register-link-parameters`.
- The dynamic table is constructed with `completion-table-dynamic`,
  which calls `ol-locate-file--run-locate` on each completion
  request with the current minibuffer input.
- Only basenames are used so that links are concise and remain
  resolvable at follow-time regardless of the file's absolute path.