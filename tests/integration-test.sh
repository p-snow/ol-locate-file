#!/bin/bash
# Integration test runner for ol-locate-file.
# Runs inside a guix shell --container with mlocate and emacs.
set -eu

TEST_DIR=$(mktemp -d)
DB_PATH="$TEST_DIR/locate.db"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Create test files -- organized by scenario:

# Single-match files (unique basename, no collision in DB)
echo "int main(void) { return 0; }" > "$TEST_DIR/main.c"
mkdir -p "$TEST_DIR/src/sub"
echo "module code" > "$TEST_DIR/src/sub/module.el"

# Multi-match by same basename
echo "root readme" > "$TEST_DIR/README"
mkdir -p "$TEST_DIR/doc"
echo "doc readme" > "$TEST_DIR/doc/README"

# Multi-match by same filename across directories
mkdir -p "$TEST_DIR/collision" "$TEST_DIR/other"
echo "collision report" > "$TEST_DIR/collision/report.txt"
echo "other report" > "$TEST_DIR/other/report.txt"

# Files for recent-method test (different timestamps).
# alpha.rst comes first alphabetically but is older;
# beta.rst comes second but is newer -- this distinguishes auto from recent.
mkdir -p "$TEST_DIR/tsdir"
echo "old content" > "$TEST_DIR/tsdir/alpha.rst"
touch -t 200001010000 "$TEST_DIR/tsdir/alpha.rst"
echo "new content" > "$TEST_DIR/tsdir/beta.rst"
touch -t 202506010000 "$TEST_DIR/tsdir/beta.rst"

# Make sure doc/guide.txt still exists (referenced by some tests)
echo "# old documentation" > "$TEST_DIR/doc/guide.txt"

# Large DB performance test files: generate ~5000 files in a subdirectory.
# These files are used by the large DB performance tests to verify that
# locate remains responsive with many indexed files.
PERF_DIR="$TEST_DIR/perf"
mkdir -p "$PERF_DIR"
for i in $(seq 1 5000); do
    printf "performance test file %04d\n" "$i" > "$PERF_DIR/file_$(printf '%04d' "$i").dat"
done

# Build locate database for the test directory.
# -l 0 disables security checks so all files are indexed regardless of
# permissions, which is necessary inside the container.
updatedb -l 0 -o "$DB_PATH" -U "$TEST_DIR"

# Run integration tests via Emacs batch
OC_LOCATE_TEST_DB="$DB_PATH" \
OC_LOCATE_TEST_DIR="$TEST_DIR" \
emacs -Q --batch -L . \
  -l tests/ol-locate-file-test.el \
  -l tests/ol-locate-file-integration-test.el \
  --eval "(let* ((stats (ert-run-tests-batch)) \
                 (nfailed (aref stats 10))) \
             (kill-emacs (if (> nfailed 0) 1 0)))"
