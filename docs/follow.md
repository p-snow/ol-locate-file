# Follow Handlers

The follow handlers are called when the user opens an `lfile:` link
(via `org-open-at-point`, typically `C-c C-o`).  There are three
variants, each registered via `org-link-set-parameters`.

## Variants

| Link Type       | Follow Function              | Effect |
|-----------------|------------------------------|--------|
| `lfile:PATH`    | `ol-locate-file--follow`     | Opens resolved file using `org-file-apps` |
| `lfile+emacs:PATH` | `ol-locate-file--follow-emacs` | Always opens in Emacs |
| `lfile+sys:PATH`   | `ol-locate-file--follow-sys`   | Always opens with system application |

## Resolution Flow

```
User opens [[lfile:emacsclient::10]]
       │
       ▼
ol-locate-file--follow("emacsclient::10", nil)
       │
       ▼
ol-locate-file--follow-impl("emacsclient::10", nil)
       │
       ├── Extracts search option: "10"
       ├── Extracts search string: "emacsclient"
       │
       ▼
ol-locate-file--resolve("emacsclient")
       │
       ├── ol-locate-file--run-locate("emacsclient")
       │   │
       │   ├── ol-locate-file--build-command("emacsclient")
       │   │   └── locate-make-command-line("emacsclient")
       │   │       → ("locate" "--regex" "emacsclient")
       │   │
       │   └── call-process("locate" ... "--regex" "emacsclient")
       │       → ("/usr/bin/emacsclient", "/usr/bin/emacs", ...)
       │
       ├── Single result → return "/usr/bin/emacsclient"
       └── Multiple results → completing-read → user selects one
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