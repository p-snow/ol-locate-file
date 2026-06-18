# Children Exclusion in `shortest-unique-suffix`

## Problem

When `org-locate-file--shortest-unique-suffix` is called with a
directory path (e.g., `/home/user/proj/packages`), `locate` returns
all files inside that directory (e.g., `packages/file1.txt`,
`packages/subdir/file2.el`) in addition to the directory itself.
These child entries inflate the candidate count, causing the
function to fail the `member` check (which looks for the exact
target path in the filtered results) and return nil, or to require
more directory components than necessary during the incremental
prepend loop.

## Solution

Add a children-exclusion filter to `shortest-unique-suffix` that
removes paths starting with `normalized/` (where `normalized` is
the target path after `directory-file-name`) from both the initial
locate results and the results obtained during the loop.

### Implementation

- A `children-prefix` is computed as `(concat normalized "/")`.
- Before processing results, paths satisfying
  `(string-prefix-p children-prefix r)` are removed via
  `cl-remove-if`.
- This filter is applied in two places:
  1. Initial locate results (before the `member` check and
     `suffix-filtered` computation).
  2. Loop iterate results (before `suffix-filtered` computation).
- Children are subordinate candidates, not competing candidates;
  excluding them ensures the target directory's suffix is computed
  correctly.
- The target path itself does NOT start with `children-prefix`
  (since `children-prefix = target + "/"`), so it always survives
  the filter.

### Files changed

- `ol-locate-file.el`: lines 482-487 (initial results), 511-515
  (loop results).
- `tests/ol-locate-file-unit-test.el`: added
  `dir-with-children` test.

### Test

Unit test `dir-with-children`:
- Target: `/home/user/proj/packages` (directory).
- locate results for "packages": target + child files + unrelated
  `/usr/share/packages`.
- Children are excluded; suffix `"proj/packages"` is returned.
