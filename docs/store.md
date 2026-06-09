# Store Handler: `ol-locate-file-store-link`

The store handler is called when the user invokes `org-store-link`
(typically `C-c l`).  It determines whether an `lfile:` link is
stored for the current file or buffer.

## Customization: `ol-locate-file-store-link-p`

This boolean option (default: `t`) controls whether the store
handler produces an `lfile:` link.

| Value | Behavior |
|-------|----------|
| `t` (default) | `org-store-link` stores an `lfile:` link for the current file |
| `nil` | `ol-locate-file-store-link` does nothing, allowing the default `file:` link handler to operate normally |

Users who prefer `file:` links for storing but still want `lfile:`
links in existing Org documents can set this to `nil`:

```elisp
(setq ol-locate-file-store-link-p nil)
```

## Store Behavior (when the flag is non-nil)

1. **File-visiting buffer**: Calls `org-link--file-link-to-here` to
   obtain the file path and any search option (line number, Org
   heading `#name`, or `*target`).  Extracts the basename and stores
   an `lfile:` link.  The description comes from
   `org-link--file-link-to-here` (e.g., an Org heading text).

2. **Dired mode**: Uses `dired-get-filename` to get the file at
   point, extracts the basename, and stores an `lfile:` link with
   no description.

3. **Other buffers**: Does nothing (returns nil), which lets Org's
   built-in store handlers work as usual.

## Link Format

The stored link uses only the basename of the file (via
`file-name-nondirectory`), so it looks like `lfile:emacsclient`
instead of `lfile:/usr/bin/emacsclient`.  The basename is resolved
at follow-time via the locate database (see `ol-locate-file--resolve`).

When in a file-visiting buffer, the link may include a search option
suffix such as `lfile:foo.el::10` (line number) or
`lfile:foo.el::#heading` (Org heading), handled by
`org-link--file-link-to-here`.

## Link Properties

When storing, the handler sets these properties via
`org-link-store-props`:

- `:type` — `ol-locate-file-link-type` (default: `"lfile"`)
- `:link` — The `lfile:` URI (e.g. `"lfile:emacsclient"` or
  `"lfile:foo.el::10"`)
- `:description` — For file-visiting buffers, the description from
  `org-link--file-link-to-here` (e.g. an Org heading).  For dired
  buffers, `nil` (no description).

## Registration

The store handler is registered for all three link variants
(`lfile`, `lfile+emacs`, `lfile+sys`) via `org-link-set-parameters`
in `ol-locate-file--register-link-parameters`.
