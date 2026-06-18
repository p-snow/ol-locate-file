# Store Handler: `org-locate-file-store-link`

The store handler is called when the user invokes `org-store-link`
(typically `C-c l`).  It determines whether an `lfile:` link is
stored for the current file or buffer.

## Customization: `org-locate-file-store-link-p`

This boolean option (default: `t`) controls whether the store
handler produces an `lfile:` link.

| Value | Behavior |
|-------|----------|
| `t` (default) | `org-store-link` stores an `lfile:` link for the current file |
| `nil` | `org-locate-file-store-link` does nothing, allowing the default `file:` link handler to operate normally |

Users who prefer `file:` links for storing but still want `lfile:`
links in existing Org documents can set this to `nil`:

```elisp
(setq org-locate-file-store-link-p nil)
```

## Store Behavior (when the flag is non-nil)

Before storing a link, the handler verifies that the file exists
in the locate database by running locate with the file's basename.
If the file is not found, no `lfile:` link is stored (returns nil).

1. **File-visiting buffer**: Calls `org-link--file-link-to-here` to
   obtain the file path and any search option (line number, Org
   heading `#name`, or `*target`).  If the file is found in the
   locate database, stores an `lfile:` link using the shortest unique
   path suffix (see "Link Suffix Disambiguation" below).  The
   description comes from `org-link--file-link-to-here` (e.g., an
   Org heading text).

2. **Dired mode**: Uses `dired-get-filename` to get the file at
   point.  If the file is found in the locate database, stores an
   `lfile:` link using the shortest unique path suffix, with no
   description.

3. **Other buffers**: Does nothing (returns nil), which lets Org's
   built-in store handlers work as usual.

## Link Suffix Disambiguation

Instead of always using the bare basename, the handler computes the
**shortest unique suffix** of the file path among all files in the
locate database that share the same basename.

- When the basename is already unique, the stored link uses just the
  basename (e.g. `lfile:emacsclient`).
- When multiple files share the same basename, parent directory
  components are prepended one by one until the suffix is unique
  (e.g. `lfile:bin/emacsclient` or `lfile:local/bin/emacsclient`).

This ensures that following the stored link resolves to the correct
file without ambiguity, even when the same filename appears in
multiple locations.

When the target path is a directory, files and subtrees inside that
directory are excluded from locate results during suffix computation.
These children are subordinate candidates -- they share the target's
basename as a path prefix, not as a filename component -- and should
not inflate the candidate count or prevent the directory itself from
being identified by its basename alone.

## Link Format

The stored link uses the shortest unique path suffix, so it looks
like `lfile:emacsclient` (when unique) or `lfile:bin/emacsclient`
(when disambiguation is needed).  The suffix is resolved at
follow-time via the locate database (see `org-locate-file--resolve`
and `org-locate-file--shortest-unique-suffix`).

When in a file-visiting buffer, the link may include a search option
suffix such as `lfile:foo.el::10` (line number) or
`lfile:foo.el::#heading` (Org heading), handled by
`org-link--file-link-to-here`.

## Link Properties

When storing, the handler sets these properties via
`org-link-store-props`:

- `:type` — `org-locate-file-link-type` (default: `"lfile"`)
- `:link` — The `lfile:` URI (e.g. `"lfile:emacsclient"`,
  `"lfile:bin/emacsclient"`, or `"lfile:foo.el::10"`)
- `:description` — For file-visiting buffers, the description from
  `org-link--file-link-to-here` (e.g. an Org heading).  For dired
  buffers, `nil` (no description).

## Registration

The store handler is registered for all three link variants
(`lfile`, `lfile+emacs`, `lfile+sys`) via `org-link-set-parameters`
in `org-locate-file--register-link-parameters`.
