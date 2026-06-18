# Backend Support Boundaries

This document clarifies the level of support for non-default backends
beyond `locate`/`plocate`, and defines the boundary between what the
package guarantees and what falls to the user.

## Supported backends

| Backend  | Support level | Maintained by |
|----------|---------------|---------------|
| `locate` | First-class   | Package       |
| `plocate`| First-class   | Package       |
| `find`   | Best-effort   | User          |
| `fd`     | Best-effort   | User          |

### First-class: `locate` / `plocate`

These are the default and recommended backends.  The package's store,
complete, and follow handlers are designed and tested exclusively
against `locate`'s behavior: the search string is matched as a
substring against the full file path in the locate database.

The package relies on Emacs' built-in `locat-make-command-line` to
construct the command line, which handles any backend that is
command-compatible with GNU `locate` (e.g. `plocate`).

- The integration test suite includes 30+ tests against `locate`.
- Behavior is deterministic: the package owns any bugs with this
  backend.

### Best-effort: `find`

`find` is a reasonable fallback for systems without a locate database.
However, the package assumes a **substring search against the full
file path** -- the same semantics as `locate`.  To achieve this with
`find`, use `-path` (not `-name`):

**Recommended `find` configuration:**

```elisp
(setq org-locate-file-locate-args
      (lambda (pattern)
        `("find" "/" "-path" ,(format "*%s*" pattern) "-type" "f")))
```

`-path` matches the glob pattern against the entire path, which is
essential when the search string contains partial path components
(e.g. `bin/emacsclient`).  `-name` matches only the basename and will
fail for such patterns.

Known limitations:

- `find` traverses the filesystem live on every query, making it
  slower than `locate` on large directory trees.
- No database: results reflect the current filesystem state, not a
  snapshot.
- The `-path` predicate uses its own glob syntax (`*`, `?`, `[]`).
  Patterns with regex metacharacters may need escaping.
- The integration test suite includes 5 basic smoke tests for `find`
  (follow, store, complete, no-match). These tests run inside a Guix
  container and are not exhaustive.

### Best-effort: `fd`

`fd` is a modern alternative with sensible defaults.  The recommended
configuration uses `--fixed-strings` for substring matching against
the full path, matching `locate`'s semantics:

**Recommended `fd` configuration:**

```elisp
(setq org-locate-file-locate-args
      (lambda (pattern)
         `("fd" "--hidden" "--absolute-path" "--full-path" "--fixed-strings"
           ,pattern ,(getenv "HOME"))))
```

`--full-path` instructs fd to match against the full file path (not
just the filename).  `--fixed-strings` treats the pattern as a literal
substring, so no regex or glob escaping is needed.  `--absolute-path`
is required because the package expects absolute paths (as `locate`
returns).

Known limitations:

- `--full-path` combined with `--glob` does NOT work for substring
  matching because `*` in glob mode does not match `/` in fd.
  Always use `--fixed-strings` with `--full-path`.
- `fd` uses smart case by default (case-insensitive when the pattern
  is all lowercase; case-sensitive when it contains uppercase).  This
  differs from `locate`'s default behavior.  Add `--case-sensitive`
  or `--ignore-case` if you need explicit control.
- `fd` respects `.gitignore` by default.  Use `--no-ignore` if you
  want to include ignored files.
- The integration test suite includes 5 basic smoke tests for `fd`
  (follow, store, complete, no-match). These run inside a Guix
  container and are not exhaustive.
- Requires fd 8.0+ (for `--full-path` support) and Emacs 30.1+.

## Responsibility boundary

The package guarantees correct behavior with the `locate` (or
`plocate`) backend when `org-locate-file-locate-args` is left at its
default (nil).  For `find`, `fd`, or any other alternative backend,
the user is responsible for:

1. **Correct command configuration**: Providing a valid
   `org-locate-file-locate-args` that accepts a search string and
   returns results as lines of absolute file paths on stdout.
2. **Semantic compatibility**: Ensuring that the command matches the
   search string as a substring against the full file path (or
   provides equivalent semantics for the user's use case).
3. **Performance**: Live filesystem traversal may be slower for large
   trees; the package's `org-locate-file-max-results` limit still
   applies but does not accelerate the command itself.
4. **Character escaping**: The search string is passed as a literal
   argument to `call-process`, which means shell metacharacters are
   not interpreted.  However, the command's own argument parsing
   (e.g. `find -path` glob syntax) may interpret special characters
   in the pattern.

## Why not first-class support for find/fd?

The package's core logic (`org-locate-file--shortest-unique-suffix`,
`org-locate-file--store-link`, etc.) is designed around locate's
behavior: the query returns ALL matches for a substring in a single
call, and the package filters/sorts them in memory.  Alternate
backends that deviate from this contract (e.g. returning results in a
different format, having different matching semantics, requiring
multiple queries) would need special-casing in the core code.  Rather
than adding backend-specific branches to every function, the package
provides a generic command-building hook (`org-locate-file-locate-args`)
that lets users plug in any command, with the understanding that the
responsibility for semantic compatibility rests with the user.

## Testing

- Unit tests mock `org-locate-file--run-locate` and test the core
  logic independently of any backend.
- Integration tests run against the real `locate` command (mlocate in
  the Guix container) as the gold standard.
- Smoke tests for `find` and `fd` are included as a sanity check, but
  failures in these tests indicate either a missing binary in the test
  environment or a misconfiguration in the specific test case, not
  necessarily a bug in `ol-locate-file.el` itself.  The smoke tests
  are intended to catch regressions in the command-building path, not
  to guarantee backend compatibility.
