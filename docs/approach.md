# Approach: Why `org-link-set-parameters` Instead of `org-link-abbrev-alist`

`ol-locate-file` registers the `lfile:` link type exclusively via
`org-link-set-parameters`.  An alternative approach would be to
define `lfile` as an abbreviation of the built-in `file:` link type
using `org-link-abbrev-alist` combined with a custom expansion
function that transforms a search string into a full path (via
`locate`).  This section documents why that alternative was
rejected.

## Advantages of the `org-link-abbrev-alist` Approach

- Reuses all `file:` link processing (follow, export, etc.)
  automatically, minimizing code and reducing the chance of bugs.
- Simpler implementation: a single abbreviation entry plus an
  expansion function is enough.

## Why It Was Rejected

The critical problem is **follow handler priority**.  When
`org-link-abbrev-alist` expands an abbreviated link, Org replaces
the abbreviation with the expansion result and then dispatches the
resulting link type's follow handler.  This means the `file:` link
type's follow handler runs unconditionally and there is no hook
point to inject custom behavior.

`lfile:` links, however, need a custom follow handler because
`locate` can (and often does) return multiple matching files.  The
follow handler must prompt the user to select which file to open
before delegating to `org-link-open-as-file`.  This behavior
cannot be achieved if the `file:` link type's follow handler takes
over.

Using `org-link-abbrev-alist` would also make it impossible to
register the variant link types (`lfile+emacs:`, `lfile+sys:`) that
force a specific opening method, since those rely on dedicated
follow handlers registered via `org-link-set-parameters`.

For these reasons, `ol-locate-file` uses `org-link-set-parameters`
to register all link handlers explicitly, even though it requires
more code than the abbreviation approach.
