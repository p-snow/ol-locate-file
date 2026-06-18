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
(require 'ox)
(eval-when-compile (require 'cl-lib))

;;; Test environment setup

(defvar org-locate-file-test--db-path
  (getenv "OC_LOCATE_TEST_DB")
  "Path to the locate database for integration tests.
Set by the integration-test.sh script before launching Emacs.")

(defvar org-locate-file-test--dir-path
  (getenv "OC_LOCATE_TEST_DIR")
  "Path to the test data directory for integration tests.
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

(defmacro org-locate-file-test--skip-unless-dir ()
  "Skip test when the integration test directory is not configured."
  `(skip-unless org-locate-file-test--dir-path))

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

(defmacro org-locate-file-test--capture-export (&rest body)
  "Execute BODY with `org-export-data-with-backend' intercepted.
Returns the (link-element backend info) that would have been passed.
If `user-error' is signaled, returns (:user-error ERROR-DATA)."
  (declare (indent 0))
  `(let ((captured nil))
     (cl-letf (((symbol-function 'org-export-data-with-backend)
                (lambda (data backend info)
                  (setq captured (list data backend info))
                  ;; Return something plausible for the export output
                  (let* ((props (nth 1 data))
                         (type (plist-get props :type))
                         (path (plist-get props :path)))
                    (format "[[%s:%s]]" type path)))))
       (condition-case err
           (progn ,@body)
         (user-error (setq captured (cons :user-error err))))
       captured)))

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

;;; Export handler (integration)

;; The export handler resolves a locate search string to a file
;; path, wraps it in a `file:' link element, and passes it to
;; `org-export-data-with-backend'.  These tests intercept
;; `org-export-data-with-backend' to verify the constructed link
;; element without running a full export pipeline.

;;;; Normal cases - unique match

;;;;; Path resolves and exports as file: link
(ert-deftest org-locate-file-test/integration/export/unique-basename ()
  "Exporting `main.c' (unique in the DB) resolves to an absolute
path and wraps it in a `file:' link element."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((captured (org-locate-file-test--capture-export
                       (org-locate-file--export "main.c" nil
                                                'test-backend nil)))
            (data (car captured))
            (props (nth 1 data)))
       (should (eq (car data) 'link))
       (should (equal (plist-get props :type) "file"))
       (should (string-suffix-p "main.c" (plist-get props :path)))))))

;;;;; Path with search option preserves the option in export
(ert-deftest org-locate-file-test/integration/export/search-option ()
  "Exporting `main.c::10' preserves the `::10' search option in
the exported file: link path."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((result (org-locate-file-test--capture-export
                     (org-locate-file--export "main.c::10" nil 'test-backend nil)))
            (link (car result))
            (path (plist-get (nth 1 link) :path)))
       (should (string-suffix-p "main.c::10" path))))))

;;;;; Description is included in exported output
(ert-deftest org-locate-file-test/integration/export/with-description ()
  "Exporting `main.c' with a non-nil description includes the
description in the constructed link element."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((desc "Main source file")
            (captured (org-locate-file-test--capture-export
                       (org-locate-file--export "main.c" desc
                                                'test-backend nil)))
            (data (car captured))
            (props (nth 1 data)))
       (should (equal (plist-get props :type) "file"))
       (should (string-suffix-p "main.c" (plist-get props :path)))))))

;;;; Abnormal cases

;;;;; Non-existent path returns fallback file URI
(ert-deftest org-locate-file-test/integration/export/no-match ()
  "Exporting a non-existent search string catches the
`user-error' internally and returns `org-export-file-uri' of the
original path as a fallback.  The captured list remains nil because
`org-export-data-with-backend' was never reached."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((captured (org-locate-file-test--capture-export
                       (org-locate-file--export "NONEXISTENT_FILE_XYZ" nil
                                                'test-backend nil))))
       ;; user-error is caught internally; no export data captured
       (should (null (car captured)))))))

;;;; Context-specific resolution

;;;;; Export context uses auto resolution by default
(ert-deftest org-locate-file-test/integration/export/context-auto ()
  "When `org-locate-file-resolve-method' has export=auto, a
multiple-match search string resolves to the first locate result
without prompting."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((org-locate-file-resolve-method '((follow ask) (export auto)))
            (result (org-locate-file-test--capture-export
                     (org-locate-file--export "README" nil 'test-backend nil)))
            (link (car result))
            (path (plist-get (nth 1 link) :path)))
       (should (stringp path))
       (should (string-suffix-p "README" path))))))

;;; Complete handler (integration)

;; The complete handler calls `completing-read' with a dynamic
;; completion table backed by locate.  These tests mock
;; `completing-read' to verify the return value construction.

;;;; Normal cases

;;;;; Returns lfile:path when completing-read returns a path
(ert-deftest org-locate-file-test/integration/complete/returns-link ()
  "When `completing-read' returns a file path,
`org-locate-file-complete-link' returns a string of the form
`lfile:BASENAME'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (cl-letf (((symbol-function 'completing-read)
                (lambda (&rest _) "/some/path/main.c")))
       (let ((result (org-locate-file-complete-link nil)))
         (should (stringp result))
         (should (string-match-p "\\`lfile:" result))
         (should (string-suffix-p "main.c" result)))))))

;;;;; Returns type: prefix when completing-read returns empty string
(ert-deftest org-locate-file-test/integration/complete/empty-choice ()
  "When `completing-read' returns an empty string,
`org-locate-file-complete-link' returns just the type prefix with
colon (e.g. `lfile:')."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (cl-letf (((symbol-function 'completing-read)
                (lambda (&rest _) "")))
       (let ((result (org-locate-file-complete-link nil)))
         (should (stringp result))
         (should (equal result "lfile:")))))))

;;; Store handler (integration)

;; The store handler stores an lfile: link for the current buffer's
;; file.  These tests mock `org-locate-file--shortest-unique-suffix'
;; (which needs locate) and use a temp buffer visiting a real file.

;;;; Store-link-p nil

;;;;; When store-link-p is nil, returns nil
(ert-deftest org-locate-file-test/integration/store/disabled ()
  "When `org-locate-file-store-link-p' is nil,
`org-locate-file-store-link' returns nil, allowing the default
file: link handler to operate."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((org-locate-file-store-link-p nil))
       (should (null (org-locate-file-store-link)))))))

;;;; Store with mocked suffix

;;;;; Store link returns link props when suffix found
(ert-deftest org-locate-file-test/integration/store/with-suffix ()
  "When `org-locate-file--shortest-unique-suffix' returns a suffix
string, `org-locate-file-store-link' stores link properties via
`org-link-store-props'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((captured-props nil)
            (temp-file (make-temp-file "ol-locate-store-test-")))
       (unwind-protect
           (progn
             (with-current-buffer (find-file-noselect temp-file)
               (cl-letf (((symbol-function 'org-link-store-props)
                          (lambda (&rest props)
                            (setq captured-props props))))
                 (cl-letf (((symbol-function
                             'org-locate-file--shortest-unique-suffix)
                            (lambda (_file-path) "temp-file-suffix.el")))
                   (cl-letf (((symbol-function 'org-link--file-link-to-here)
                              (lambda () (cons (concat "file:" temp-file) nil))))
                     (org-locate-file-store-link)))))
             (should (consp captured-props))
             (should (plist-get captured-props :type))
             (should (string-match-p "\\`lfile:" (plist-get captured-props :link))))
         (and (get-file-buffer temp-file)
              (kill-buffer (get-file-buffer temp-file)))
         (delete-file temp-file))))))

;;;;; Store link returns nil when suffix is nil
(ert-deftest org-locate-file-test/integration/store/suffix-nil ()
  "When `org-locate-file--shortest-unique-suffix' returns nil,
`org-locate-file-store-link' stores no link properties and returns
nil."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((captured-props nil)
            (temp-file (make-temp-file "ol-locate-store-test-")))
       (unwind-protect
           (with-current-buffer (find-file-noselect temp-file)
             (cl-letf (((symbol-function 'org-link-store-props)
                        (lambda (&rest props)
                          (setq captured-props props))))
               (cl-letf (((symbol-function
                           'org-locate-file--shortest-unique-suffix)
                          (lambda (_file-path) nil)))
                 (cl-letf (((symbol-function 'org-link--file-link-to-here)
                            (lambda () (cons (concat "file:" temp-file) nil))))
                   (let ((result (org-locate-file-store-link)))
                     (should (null captured-props))
                     (should (null result)))))))
         (and (get-file-buffer temp-file)
              (kill-buffer (get-file-buffer temp-file)))
         (delete-file temp-file))))))

;;; Locate backend variants (integration)

;; These tests verify that `org-locate-file-locate-args' works with
;; different locate-compatible binaries.  The Guix container
;; provides mlocate which is the default.

;;;; mlocate backend

;;;;; Default mlocate backend resolves correctly
(ert-deftest org-locate-file-test/integration/backend/mlocate-default ()
  "The default locate backend (mlocate in the Guix container)
resolves a unique basename correctly when using `-d' to point at
the test DB."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((result (org-locate-file-test--follow-captured "main.c" nil)))
       (should (string-suffix-p "main.c" (car result)))
       (should (file-name-absolute-p (car result)))))))

;;;;; Custom locate-args list works correctly
(ert-deftest org-locate-file-test/integration/backend/custom-args-list ()
  "Setting `org-locate-file-locate-args' to a list of arguments
works the same as the default, because the underlying command and
DB path are equivalent."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((org-locate-file-locate-args
             (list "locate" "-d" org-locate-file-test--db-path))
            (result (org-locate-file-test--follow-captured "module.el" nil)))
       (should (string-suffix-p "src/sub/module.el" (car result)))))))

;;; find backend (integration)

;; The `find' command can serve as a locate replacement for users
;; who do not have mlocate/plocate installed.  These tests
;; configure `org-locate-file-locate-args' to use `find' with the
;; test directory as the search root.

;;;; Normal cases

;;;;; find with -name finds files by exact basename
(ert-deftest org-locate-file-test/integration/find/exact-name ()
  "Using `find TEST_DIR -name' as the locate replacement resolves
a unique basename to its full path.  Note: find -name uses glob
pattern matching, not substring matching like locate."
  (org-locate-file-test--skip-unless-dir)
  (let ((org-locate-file-locate-args
         (list "find" org-locate-file-test--dir-path "-name"))
        (org-locate-file-max-results nil))
    (let ((result (org-locate-file-test--follow-captured "main.c" nil)))
      (should (string-suffix-p "main.c" (car result)))
      (should (file-name-absolute-p (car result))))))

;;;;; find resolves nested path correctly
(ert-deftest org-locate-file-test/integration/find/nested-path ()
  "Using `find' with the test directory resolves a file in a
nested subdirectory by its exact basename."
  (org-locate-file-test--skip-unless-dir)
  (let ((org-locate-file-locate-args
         (list "find" org-locate-file-test--dir-path "-name"))
        (org-locate-file-max-results nil))
    (let ((result (org-locate-file-test--follow-captured "module.el" nil)))
      (should (string-suffix-p "src/sub/module.el" (car result))))))

;;;;; find with no match signals user-error
(ert-deftest org-locate-file-test/integration/find/no-match ()
  "Using `find' with a non-existent filename signals `user-error'."
  (org-locate-file-test--skip-unless-dir)
  (let ((org-locate-file-locate-args
         (list "find" org-locate-file-test--dir-path "-name"))
        (org-locate-file-max-results nil))
    (let ((result (org-locate-file-test--follow-captured "NONEXISTENT" nil)))
      (should (eq (car result) :user-error)))))

;;; Org-mode simulated environment (integration)

;; These tests create a real org-mode buffer, insert an lfile link,
;; and exercise org-mode's link infrastructure end-to-end to verify
;; that the `org-link-set-parameters' registration works.

;;;; Normal cases

;;;;; Org link face is applied to lfile: links
(ert-deftest org-locate-file-test/integration/org-mode/link-face ()
  "An `lfile:main.c' link in an org-mode buffer has the `org-link'
face property applied by font-lock."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (with-temp-buffer
       (org-mode)
       (insert "[[lfile:main.c][test link]]")
       (font-lock-ensure)
       (goto-char (point-min))
       (let ((found-org-link-face nil))
         (while (and (not found-org-link-face)
                     (< (point) (point-max)))
           (let ((face (get-text-property (point) 'face)))
             (when (or (eq face 'org-link)
                       (and (listp face) (memq 'org-link face)))
               (setq found-org-link-face t)))
           (forward-char 1))
         (should found-org-link-face))))))

;;;;; org-open-at-point dispatches to follow handler
(ert-deftest org-locate-file-test/integration/org-mode/open-at-point ()
  "Calling `org-open-at-point' on an lfile: link dispatches to the
follow handler, which resolves the path and calls
`org-link-open-as-file'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (with-temp-buffer
       (org-mode)
       (insert "[[lfile:main.c][test link]]")
       (goto-char (+ (point-min) 2))
       (org-locate-file-test--capture-open
        (org-open-at-point nil))))))

;;;;; org-open-at-point with lfile+emacs variant
(ert-deftest org-locate-file-test/integration/org-mode/open-at-point-emacs ()
  "Calling `org-open-at-point' on an lfile+emacs: link dispatches
to the emacs variant which sets in-emacs to `emacs'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (with-temp-buffer
       (org-mode)
       (insert "[[lfile+emacs:main.c][test link]]")
       (goto-char (+ (point-min) 2))
       (let ((result
              (org-locate-file-test--capture-open
               (org-open-at-point nil))))
         (should (eq (cadr result) 'emacs)))))))

;; Large DB performance tests (integration)

;; These tests verify that locate remains responsive when the
;; database contains many files.  The test setup script generates
;; ~5000 files in a `perf/' subdirectory.

;;;; Performance timing

;;;;; Unique file among many resolves within timeout
(ert-deftest org-locate-file-test/integration/perf/resolve-timing ()
  "Searching for a unique file among ~5000 generated files
resolves within 5 seconds."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((start-time (float-time)))
       (should (string-suffix-p
                "file_2500.dat"
                (car (org-locate-file-test--follow-captured
                      "file_2500.dat" nil))))
       (should (< (- (float-time) start-time) 5.0))))))

;;;;; Search among many files with substring match completes quickly
(ert-deftest org-locate-file-test/integration/perf/substring-match ()
  "Searching for a common substring that matches many files in a
large DB completes within 10 seconds."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let ((start-time (float-time))
           (org-locate-file-max-results 100)
           (org-locate-file-resolve-method 'auto))
       ;; ".dat" matches all 5000 perf files but we limit to 100
       (let ((result (org-locate-file-test--follow-captured ".dat" nil)))
         (should (stringp (car result)))
         (should (< (- (float-time) start-time) 10.0)))))))

;;; Store-follow round-trip (integration)

;; These tests verify the full round-trip: store an lfile link via
;; `org-locate-file-store-link' (from a file-visiting buffer), then
;; follow it via `org-locate-file--follow', checking that the
;; resolved path matches the original file.

;;;; Normal cases - unique basename

;;;;; Store then follow resolves to original file
(ert-deftest org-locate-file-test/integration/store-follow/unique-basename ()
  "Store an lfile link for `guide.txt' (unique basename in doc/),
then follow it and verify the resolved path correctly points to
a file ending in `guide.txt'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--skip-unless-dir)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((test-file (expand-file-name "doc/guide.txt"
                                         org-locate-file-test--dir-path))
            (captured-link nil))
       (with-current-buffer (find-file-noselect test-file)
         (cl-letf (((symbol-function 'org-link--file-link-to-here)
                    (lambda () (cons (concat "file:" test-file) nil)))
                   ((symbol-function 'org-link-store-props)
                    (lambda (&rest props)
                      (setq captured-link (plist-get props :link)))))
           (org-locate-file-store-link))
         (kill-buffer (current-buffer)))
       (should (stringp captured-link))
       (should (string-prefix-p "lfile:" captured-link))
       (let ((suffix (substring captured-link (length "lfile:"))))
         (should (> (length suffix) 0))
         (let ((result (org-locate-file-test--follow-captured suffix nil)))
           (should (string-suffix-p "guide.txt" (car result)))
           (should (file-name-absolute-p (car result)))))))))

;;;;; Store then follow resolves with disambiguated suffix
(ert-deftest org-locate-file-test/integration/store-follow/disambiguated-suffix ()
  "Store an lfile link for `collision/report.txt' (basename shared
with other/report.txt), then follow it and verify the resolved
path ends with `collision/report.txt'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--skip-unless-dir)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((test-file (expand-file-name "collision/report.txt"
                                         org-locate-file-test--dir-path))
            (captured-link nil))
       (with-current-buffer (find-file-noselect test-file)
         (cl-letf (((symbol-function 'org-link--file-link-to-here)
                    (lambda () (cons (concat "file:" test-file) nil)))
                   ((symbol-function 'org-link-store-props)
                    (lambda (&rest props)
                      (setq captured-link (plist-get props :link)))))
           (org-locate-file-store-link))
         (kill-buffer (current-buffer)))
       (should (stringp captured-link))
       (should (string-prefix-p "lfile:" captured-link))
       (let ((suffix (substring captured-link (length "lfile:"))))
         (should (string-match-p "collision/report\\.txt\\'" suffix))
         (let ((result (org-locate-file-test--follow-captured suffix nil)))
           (should (string-suffix-p "collision/report.txt" (car result)))
           (should (file-name-absolute-p (car result)))))))))

;;; Complete-follow round-trip (integration)

;; These tests verify the full round-trip: complete an lfile link
;; via `org-locate-file-complete-link' (mocking completing-read),
;; then follow it via `org-locate-file--follow'.

;;;; Normal cases

;;;;; Complete then follow resolves to original file (unique)
(ert-deftest org-locate-file-test/integration/complete-follow/unique-basename ()
  "Complete a link by selecting `guide.txt' (unique), then follow
and verify it resolves to a path ending in `guide.txt'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--skip-unless-dir)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((test-file (expand-file-name "doc/guide.txt"
                                         org-locate-file-test--dir-path))
            (link-string
             (cl-letf (((symbol-function 'completing-read)
                        (lambda (&rest _) test-file)))
               (org-locate-file-complete-link nil))))
       (should (stringp link-string))
       (should (string-prefix-p "lfile:" link-string))
       (let ((suffix (substring link-string (length "lfile:"))))
         (should (string-match-p "\\`guide\\.txt\\'" suffix))
         (let ((result (org-locate-file-test--follow-captured suffix nil)))
           (should (string-suffix-p "guide.txt" (car result)))
           (should (file-name-absolute-p (car result)))))))))

;;;;; Complete then follow resolves with disambiguated suffix
(ert-deftest org-locate-file-test/integration/complete-follow/disambiguated-suffix ()
  "Complete a link by selecting `collision/report.txt', then
follow and verify it resolves to a path ending in
`collision/report.txt'."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--skip-unless-dir)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((test-file (expand-file-name "collision/report.txt"
                                         org-locate-file-test--dir-path))
            (link-string
             (cl-letf (((symbol-function 'completing-read)
                        (lambda (&rest _) test-file)))
               (org-locate-file-complete-link nil))))
       (should (stringp link-string))
       (should (string-prefix-p "lfile:" link-string))
       (let ((suffix (substring link-string (length "lfile:"))))
         (should (string-match-p "collision/report\\.txt\\'" suffix))
         (let ((result (org-locate-file-test--follow-captured suffix nil)))
           (should (string-suffix-p "collision/report.txt" (car result)))
           (should (file-name-absolute-p (car result)))))))))

;;; Move-follow scenario (integration)

;; These tests verify what happens when a file is moved after a
;; link is stored, the locate database is rebuilt, and the link is
;; then followed.  The link should resolve to the new location
;; because the stored suffix (basename) still matches via locate
;; and the suffix-p filter.

;;;; Normal cases

;;;;; File moved within test dir resolves to new location
(ert-deftest org-locate-file-test/integration/move-follow/unique-file-moved ()
  "Store a link for `guide.txt', move it to `moved/guide.txt',
rebuild the locate DB, then follow the link and verify it resolves
to the new location.  The suffix `guide.txt' remains valid because
the basename is unchanged.

After the test, restore the original file and DB to avoid
affecting subsequent tests."
  (org-locate-file-test--skip-unless-db)
  (org-locate-file-test--skip-unless-dir)
  (org-locate-file-test--with-test-db
   (lambda ()
     (let* ((dir org-locate-file-test--dir-path)
            (db org-locate-file-test--db-path)
            (old-path (expand-file-name "doc/guide.txt" dir))
            (new-dir (expand-file-name "moved" dir))
            (new-path (expand-file-name "guide.txt" new-dir))
            (captured-link nil))
       (unwind-protect
           (progn
             ;; Store a link to the original file
             (with-current-buffer (find-file-noselect old-path)
               (cl-letf (((symbol-function 'org-link--file-link-to-here)
                          (lambda ()
                            (cons (concat "file:" old-path) nil)))
                         ((symbol-function 'org-link-store-props)
                          (lambda (&rest props)
                            (setq captured-link (plist-get props :link)))))
                 (org-locate-file-store-link))
               (kill-buffer (current-buffer)))
             (should (stringp captured-link))
             (should (string-prefix-p "lfile:" captured-link))
             ;; Move the file within the test directory
             (make-directory new-dir t)
             (rename-file old-path new-path)
             (should (file-exists-p new-path))
             (should (not (file-exists-p old-path)))
             ;; Rebuild the locate database
             (let ((exit-code (call-process "updatedb" nil nil nil
                                            "-l" "0"
                                            "-o" db
                                            "-U" dir)))
               (should (zerop exit-code)))
             ;; Follow the stored link -- should resolve to the new location
             (let* ((suffix (substring captured-link (length "lfile:")))
                    (result (org-locate-file-test--follow-captured
                             suffix nil)))
               (should (string-suffix-p "guide.txt" (car result)))
               (should (file-name-absolute-p (car result)))
               ;; The resolved path should be the NEW location, not the old one
               (should (string-prefix-p (file-name-as-directory new-dir)
                                        (car result)))))
         ;; Cleanup: restore original state
         (rename-file new-path old-path t)
         (ignore-errors (delete-directory new-dir))
         (call-process "updatedb" nil nil nil
                       "-l" "0" "-o" db "-U" dir))))))

(provide 'ol-locate-file-integration-test)

;;; ol-locate-file-integration-test.el ends here
