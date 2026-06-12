# Follow Handlers

The follow handlers are called when the user opens an `lfile:` link
(via `org-open-at-point`, typically `C-c C-o`).  There are three
variants, each registered via `org-link-set-parameters`.

## Variants

| Link Type       | Follow Function              | Effect |
|-----------------|------------------------------|--------|
| `lfile:PATH`    | `org-locate-file--follow`     | Opens resolved file using `org-file-apps` |
| `lfile+emacs:PATH` | `org-locate-file--follow-emacs` | Always opens in Emacs |
| `lfile+sys:PATH`   | `org-locate-file--follow-sys`   | Always opens with system application |

## Resolution Flow

```
User opens [[lfile:emacsclient::10]]
       │
       ▼
org-locate-file--follow("emacsclient::10", nil)
       │
       ▼
org-locate-file--follow-impl("emacsclient::10", nil)
       │
       ├── Extracts search option: "10"
       ├── Extracts search string: "emacsclient"
       │
       ▼
org-locate-file--resolve("emacsclient")
       │
       ├── org-locate-file--run-locate("emacsclient")
│   │
        │   ├── org-locate-file--build-command("emacsclient")
        │   │   ├── Uses org-locate-file-locate-args:
        │   │   │   • nil         → locate-make-command-line
        │   │   │   • string      → split prefix + ("emacsclient")
        │   │   │   • list        → append ("emacsclient")
        │   │   │   • function    → (funcall fn "emacsclient")
        │   │   │       → ("locate" "--regex" "emacsclient")
        │   │
        │   └── call-process("locate" ... "--regex" "emacsclient")
       │       → ("/usr/bin/emacsclient", "/usr/bin/emacs", ...)
       │
       ├── Single result → return "/usr/bin/emacsclient"
       └── Multiple results:
            ├── org-locate-file-follow-auto = nil  → completing-read
            ├── org-locate-file-follow-auto = t    → first result
            ├── org-locate-file-follow-auto = 'recent → most recent mtime
            └── org-locate-file-follow-auto = fn   → (funcall fn candidates)
       │
       ▼
org-link-open-as-file("/usr/bin/emacsclient::10", nil)
  → Opens file and jumps to line 10
```

## Design Notes

- The three variants (`lfile`, `lfile+emacs`, `lfile+sys`) mirror the
  standard `file`, `file+emacs`, and `file+sys` link types.  After
  resolving the path via locate, they all delegate to
  `org-link-open-as-file` with the appropriate `in-emacs` argument.
- PATH may include a search-option suffix (`::line`, `::#heading`,
  `::*target`) which is preserved through the resolution and passed
  to `org-link-open-as-file`.
- Because there is no `org-link-abbrev-alist` expansion, Org never
  rewrites the link text at parse time.  The link is always displayed
  as the original `lfile:` form, and resolution happens only at
  follow-time via the `:follow` handler.
- Each variant is registered as a separate link type (not as a
  parameter on a single type), which is required for Org to dispatch
  the correct follow function based on the link prefix.
- `org-locate-file-follow-auto` controls automatic candidate selection
  when multiple files match.  See the docstring of that variable for
  details on the possible values.