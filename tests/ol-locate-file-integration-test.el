;;; ol-locate-file-integration-test.el --- Integration tests for ol-locate-file -*- lexical-binding: t -*-

;; Copyright (C) 2026  Free Software Foundation, Inc.

;; Author: p-snow <public@p-snow.org>

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Integration tests for ol-locate-file that exercise the actual
;; locate command inside a Guix container with mlocate/plocate.
;;
;; Test scenarios are organized by package feature (follow, export,
;; complete, store) rather than by individual function.
;;
;; These tests require:
;;   1. A locate database built by tests/integration-test.sh
;;   2. The OC_LOCATE_TEST_DB environment variable pointing to it
;;
;; Run via: make integration-test

;;; Code:

(require 'ert)
(require 'ol-locate-file)
(eval-when-compile (require 'cl-lib))

;;; Test environment setup

(defvar org-locate-file-test--db-path
  (getenv "OC_LOCATE_TEST_DB")
  "Path to the locate database for integration tests.
Set by the integration-test.sh script before launching Emacs.")

(defun org-locate-file-test--with-test-db (fn)
  "Call FN with locate configured to use the integration test DB.
Binds `org-locate-file-locate-args' so that the locate command
uses `-d' to point at `org-locate-file-test--db-path'."
  (let ((org-locate-file-locate-args
         (list "locate" "-d" org-locate-file-test--db-path)))
    (funcall fn)))

(defmacro org-locate-file-test--skip-unless-db ()
  "Skip test when the integration test DB is not configured."
  `(skip-unless org-locate-file-test--db-path))

;;; Test helpers

(defmacro org-locate-file-test--capture-open (&rest body)
  "Execute BODY with `org-link-open-as-file' intercepted.
Returns the (path in-emacs) list that would have been passed to
`org-link-open-as-file'.  If `user-error' is signaled, returns
(:user-error ERROR-DATA) instead."
  (declare (indent 0))
  `(let ((captured nil))
     (cl-letf (((symbol-function 'org-link-open-as-file)
                (lambda (path &optional in-emacs)
                  (setq captured (list path in-emacs))
                  nil)))
       (condition-case err
           (progn ,@body)
         (user-error (setq captured (cons :user-error err))))
       captured)))

(defmacro org-locate-file-test--follow-captured (path arg)
  "Capture the `org-link-open-as-file' call when following PATH
with prefix ARG via `org-locate-file--follow'.
Returns (resolved-path in-emacs) or (:user-error . ERROR)."
  `(org-locate-file-test--capture-open
    (org-locate-file--follow ,path ,arg)))

;;; Follow handler (integration)

;; The follow handler resolves a locate search string to a file
;; path, then delegates to `org-link-open-as-file' with the
;; resolved path and an in-emacs flag.  These tests intercept
;; `org-link-open-as-file' to verify the resolved path and flag
;; without actually opening a file in batch mode.

;;;; Normal cases - single match (unique basename)

;;;;; Unique basename resolves to absolute path without search option
(ert-deftest org-locate-file-test/integration/follow/unique-basename ()
  "Following `main.c' (unique in the DB) resolves to an absolute
path ending in `main.c' and opens with `in-emacs' set to nil."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--follow-captured "main.c" nil)))
       (should (string-suffix-p "main.c" (car result)))
       (should (file-name-absolute-p (car result)))
       (should (null (cadr result)))))))

;;;;; Link with line-number search option preserves the option
(ert-deftest org-locate-file-test/integration/follow/search-option ()
  "Following `main.c::10' resolves to an absolute path that
includes the `::10' search option suffix."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--follow-captured "main.c::10" nil)))
       (should (string-suffix-p "main.c::10" (car result)))))))

;;;;; File in nested subdirectory resolves correctly
(ert-deftest org-locate-file-test/integration/follow/nested-path ()
  "Following `module.el' (unique, in src/sub/) resolves to an
absolute path ending in `src/sub/module.el'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--follow-captured "module.el" nil)))
       (should (string-suffix-p "src/sub/module.el" (car result)))))))

;;;; Normal cases - link variants (lfile+emacs / lfile+sys)

;;;;; lfile+emacs variant: in-emacs flag is 'emacs
(ert-deftest org-locate-file-test/integration/follow/emacs-variant ()
  "When following via `org-locate-file--follow-emacs', the
`in-emacs' argument to `org-link-open-as-file' is `emacs'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--capture-open
                      (org-locate-file--follow-emacs "main.c" nil))))
       (should (eq (cadr result) 'emacs))))))

;;;;; lfile+sys variant: in-emacs flag is 'system
(ert-deftest org-locate-file-test/integration/follow/sys-variant ()
  "When following via `org-locate-file--follow-sys', the
`in-emacs' argument to `org-link-open-as-file' is `system'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--capture-open
                      (org-locate-file--follow-sys "main.c" nil))))
       (should (eq (cadr result) 'system))))))

;;;; Normal cases - multiple matches (auto resolution)

;;;;; Auto picks first locate result without prompting
(ert-deftest org-locate-file-test/integration/follow/multiple-auto ()
  "When `org-locate-file-resolve-method' is `auto' and multiple
files match (`README' matches root README and doc/README), the
first locate result is used without prompting."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((org-locate-file-resolve-method 'auto)
            (result (org-locate-file-test--follow-captured "README" nil))
            (path (car result)))
       (should (stringp path))
       (should (string-suffix-p "README" path))))))

;;;; Normal cases - multiple matches (recent resolution)

;;;;; Recent picks the most recently modified file
(ert-deftest org-locate-file-test/integration/follow/multiple-recent ()
  "When `org-locate-file-resolve-method' is `recent' and `.rst'
matches both `alpha.rst' (touched 2000) and `beta.rst' (touched
2025), `beta.rst' (the newer file) is selected."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((org-locate-file-resolve-method 'recent)
            (result (org-locate-file-test--follow-captured ".rst" nil))
            (path (car result)))
       (should (string-suffix-p "beta.rst" path))))))

;;;; Normal cases - multiple matches (custom function)

;;;;; Custom function returning an arbitrary path passes it through
(ert-deftest org-locate-file-test/integration/follow/custom-arbitrary-path ()
  "A custom resolve function that returns a string path causes
that path to be passed to `org-link-open-as-file' as-is,
regardless of whether it exists in the locate candidates."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((my-picker (lambda (_candidates) "arbitrary/path.txt"))
            (org-locate-file-resolve-method my-picker)
            (result (org-locate-file-test--follow-captured "report.txt" nil))
            (path (car result)))
       (should (equal path "arbitrary/path.txt"))))))

;;;;; Custom function receives candidates and can pick among them
(ert-deftest org-locate-file-test/integration/follow/custom-picks-candidate ()
  "A custom resolve function that selects one of the candidates
by its suffix correctly opens that file."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((my-picker (lambda (candidates)
                         (cl-find-if
                          (lambda (p) (string-suffix-p "other/report.txt" p))
                          candidates)))
            (org-locate-file-resolve-method my-picker)
            (result (org-locate-file-test--follow-captured "report.txt" nil))
            (path (car result)))
       (should (string-suffix-p "other/report.txt" path))))))

;;;; Normal cases - multiple matches (ask resolution)

;;;;; Ask with completing-read picks the user's choice
(ert-deftest org-locate-file-test/integration/follow/ask-selects-choice ()
  "When `org-locate-file-resolve-method' is `ask' and `report.txt'
matches two files, `completing-read' is called; mocking it to
return `other/report.txt' causes that file to open."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((org-locate-file-resolve-method 'ask)
            (result
             (org-locate-file-test--capture-open
               (cl-letf (((symbol-function 'completing-read)
                          (lambda (&rest _) "other/report.txt")))
                 (org-locate-file--follow "report.txt" nil))))
            (path (car result)))
       (should (string-suffix-p "other/report.txt" path))))))

;;;; Abnormal cases

;;;;; Non-existent search string signals user-error
(ert-deftest org-locate-file-test/integration/follow/no-match ()
  "Following a string that matches nothing in the locate database
signals `user-error'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--follow-captured
                    "NONEXISTENT_FILE_XYZ" nil)))
       (should (eq (car result) :user-error))))))

;;;;; Empty search string signals user-error
(ert-deftest org-locate-file-test/integration/follow/empty-string ()
  "Following an empty string signals `user-error'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--follow-captured "" nil)))
       (should (eq (car result) :user-error))))))

;;;;; Ask with empty completing-read selection signals user-error
(ert-deftest org-locate-file-test/integration/follow/ask-cancelled ()
  "When `org-locate-file-resolve-method' is `ask' and the user
cancels by returning an empty string, `user-error' is signaled."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((org-locate-file-resolve-method 'ask)
            (result
             (org-locate-file-test--capture-open
               (cl-letf (((symbol-function 'completing-read)
                          (lambda (&rest _) "")))
                 (org-locate-file--follow "report.txt" nil)))))
       (should (eq (car result) :user-error))))))

;;; Export handler (integration)  -- placeholder
;;; Complete handler (integration) -- placeholder
;;; Store handler (integration) -- placeholder

(provide 'ol-locate-file-integration-test)

;;; ol-locate-file-integration-test.el ends here
