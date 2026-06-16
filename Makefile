EMACS ?= emacs
BATCH  = $(EMACS) -Q --batch

LOAD_PATH = -L .
UNIT_TEST_FILES = tests/ol-locate-file-unit-test.el
TEST_HELPER     = tests/ol-locate-file-test.el

# Collect all test files for future expansion (unit + integration)
ALL_TEST_FILES = $(UNIT_TEST_FILES)

# ERT runner with testcover instrumentation for coverage
define run-ert
	$(BATCH) $(LOAD_PATH) \
		--eval "(require 'testcover)" \
		--eval "(testcover-start \"ol-locate-file.el\")" \
		-l $(TEST_HELPER) \
		-l $(1) \
		--eval "(let* ((stats (ert-run-tests-batch)) \
		                (nfailed (aref stats 10))) \
		            (org-locate-file-test--coverage-report) \
		            (kill-emacs (if (> nfailed 0) 1 0)))"
endef

.PHONY: unit-test test clean

unit-test:
	$(call run-ert,$(UNIT_TEST_FILES))

# Run all tests (unit + integration in the future)
test: unit-test

clean:
	rm -f *.elc tests/*.elc