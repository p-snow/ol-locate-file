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
       │   │   │
       │   └── call-process("locate" ... "emacsclient")
       │       → ("/usr/bin/emacsclient", "/usr/bin/emacs", "/tmp/packages", ...)
       │
       ├── Filter results with string-suffix-p("emacsclient"):
       │   "/usr/bin/emacsclient" ─── ✓ (ends with "emacsclient")
       │   "/usr/bin/emacs"       ─── ✗ (ends with "emacs", not "emacsclient")
       │   "/tmp/packages"        ─── ✗
       │   → ("/usr/bin/emacsclient")
       │
       ├── Single result → return "/usr/bin/emacsclient"
       │
       └── Multiple results (context = follow):
            ├── org-locate-file-resolve-method = auto  → first result
            ├── org-locate-file-resolve-method = recent → most recent mtime
            ├── org-locate-file-resolve-method = ask   → completing-read
            └── org-locate-file-resolve-method = fn    → (funcall fn candidates)
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
- `org-locate-file-resolve-method` controls how candidates are selected
  when multiple files match.  See that variable's docstring for details.
  Follow uses the `follow` context (default: `ask`), export uses
  the `export` context (default: `auto`).
- Results are filtered with `string-suffix-p` against the search
  string to exclude paths where the search string appears only as a
  middle substring (e.g. "packages" matching "packages/child" or
  "foo.el" matching "foo.elc").  When no result survives the filter,
  the raw locate results are used as a fallback.
- When the link was stored via `org-locate-file-store-link` or
  `org-locate-file-complete-link`, the stored suffix is the output
  of `org-locate-file--shortest-unique-suffix`, which excludes
  children of directory targets from locate results during
  computation.