;;; ol-locate-file-unit-test.el --- Unit tests for ol-locate-file -*- lexical-binding: t -*-

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

;; Unit tests for ol-locate-file.  These tests use ad-hoc test data
;; and mock functions where needed -- no external files required.
;;
;; Outline hierarchy:
;;   ;;;   Category (function-level grouping)
;;   ;;;;  Scenario category
;;   ;;;;; Scenario description (one line)

;;; Code:

(require 'ert)
(require 'ol-locate-file)

;;; org-locate-file--resolve-method

;; Tests for `org-locate-file--resolve-method', which returns the
;; effective resolution method for a given context.  This is a pure
;; function with no side effects, making it ideal for unit testing.

;;;; Flat value resolution

;;;;; Flat value `auto' returns `auto' regardless of context
(ert-deftest org-locate-file-test/resolve-method/flat-auto ()
  "`org-locate-file--resolve-method' returns `auto' when
`org-locate-file-resolve-method' is set to the symbol `auto',
for both `follow' and `export' contexts."
  (let ((org-locate-file-resolve-method 'auto))
    (should (eq (org-locate-file--resolve-method 'follow) 'auto))
    (should (eq (org-locate-file--resolve-method 'export) 'auto))
    (should (eq (org-locate-file--resolve-method) 'auto))))

;;;;; Flat value `ask' returns `ask' regardless of context
(ert-deftest org-locate-file-test/resolve-method/flat-ask ()
  "`org-locate-file--resolve-method' returns `ask' when
`org-locate-file-resolve-method' is set to the symbol `ask',
for both `follow' and `export' contexts."
  (let ((org-locate-file-resolve-method 'ask))
    (should (eq (org-locate-file--resolve-method 'follow) 'ask))
    (should (eq (org-locate-file--resolve-method 'export) 'ask))))

;;;;; Flat value `recent' returns `recent' regardless of context
(ert-deftest org-locate-file-test/resolve-method/flat-recent ()
  "`org-locate-file--resolve-method' returns `recent' when
`org-locate-file-resolve-method' is set to the symbol `recent',
for both `follow' and `export' contexts."
  (let ((org-locate-file-resolve-method 'recent))
    (should (eq (org-locate-file--resolve-method 'follow) 'recent))
    (should (eq (org-locate-file--resolve-method 'export) 'recent))))

;;;; Alist resolution

;;;;; Alist with `follow' entry returns the associated method
(ert-deftest org-locate-file-test/resolve-method/alist-follow ()
  "When `org-locate-file-resolve-method' is an alist with a
`follow' entry, `org-locate-file--resolve-method' with context
`follow' returns the method specified in that entry."
  (let ((org-locate-file-resolve-method '((follow ask) (export auto))))
    (should (eq (org-locate-file--resolve-method 'follow) 'ask))))

;;;;; Alist with `export' entry returns the associated method
(ert-deftest org-locate-file-test/resolve-method/alist-export ()
  "When `org-locate-file-resolve-method' is an alist with an
`export' entry, `org-locate-file--resolve-method' with context
`export' returns the method specified in that entry."
  (let ((org-locate-file-resolve-method '((follow ask) (export recent))))
    (should (eq (org-locate-file--resolve-method 'export) 'recent))))

;;;;; Alist without context entry falls back to `auto'
(ert-deftest org-locate-file-test/resolve-method/alist-missing-context ()
  "When `org-locate-file-resolve-method' is an alist but has no
entry for the requested context, `org-locate-file--resolve-method'
falls back to `auto'."
  (let ((org-locate-file-resolve-method '((follow ask))))
    (should (eq (org-locate-file--resolve-method 'export) 'auto))))

;;;;; Alist with nil context defaults to `follow'
(ert-deftest org-locate-file-test/resolve-method/alist-nil-context ()
  "When `org-locate-file-resolve-method' is an alist and CONTEXT
is nil, `org-locate-file--resolve-method' defaults to looking up
the `follow' entry."
  (let ((org-locate-file-resolve-method '((follow recent) (export auto))))
    (should (eq (org-locate-file--resolve-method) 'recent))))

;;;; Custom function resolution

;;;;; Flat custom function returns the function itself
(ert-deftest org-locate-file-test/resolve-method/flat-function ()
  "When `org-locate-file-resolve-method' is a function,
`org-locate-file--resolve-method' returns that function directly."
  (let* ((my-fn (lambda (candidates) (car candidates)))
         (org-locate-file-resolve-method my-fn))
    (should (eq (org-locate-file--resolve-method 'follow) my-fn))
    (should (eq (org-locate-file--resolve-method 'export) my-fn))))

;;;;; Alist with function method returns the function
(ert-deftest org-locate-file-test/resolve-method/alist-function ()
  "When `org-locate-file-resolve-method' is an alist and the
method for a context is a function,
`org-locate-file--resolve-method' returns that function."
  (let* ((my-fn (lambda (candidates) (car candidates)))
         (org-locate-file-resolve-method `((follow ,my-fn))))
    (should (eq (org-locate-file--resolve-method 'follow) my-fn))))

;;;; Edge cases

;;;;; Unrecognized flat value falls back to `auto'
(ert-deftest org-locate-file-test/resolve-method/unrecognized-flat ()
  "When `org-locate-file-resolve-method' is set to an unrecognized
symbol (e.g. `invalid), `org-locate-file--resolve-method' falls
back to `auto'."
  (let ((org-locate-file-resolve-method 'invalid))
    (should (eq (org-locate-file--resolve-method 'follow) 'auto))))

;;;;; Unrecognized alist method falls back to `auto'
(ert-deftest org-locate-file-test/resolve-method/unrecognized-alist-method ()
  "When `org-locate-file-resolve-method' is an alist and the
method value is an unrecognized symbol,
`org-locate-file--resolve-method' falls back to `auto'."
  (let ((org-locate-file-resolve-method '((follow invalid))))
    (should (eq (org-locate-file--resolve-method 'follow) 'auto))))

;;; org-locate-file--build-command

;;;; Nil delegates to locate-make-command-line
(ert-deftest org-locate-file-test/build-command/nil-delegates ()
  "When `org-locate-file-locate-args' is nil,
`org-locate-file--build-command' calls `locate-make-command-line'
and prepends the resolved locate executable path."
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_cmd) "/fake/locate"))
            ((symbol-function 'locate-make-command-line)
             (lambda (s) (list "locate" s))))
    (let ((org-locate-file-locate-args nil))
      (should (equal (org-locate-file--build-command "foo")
                     '("/fake/locate" "foo"))))))

;;;; String value splits and appends search-string
(ert-deftest org-locate-file-test/build-command/string-value ()
  "When `org-locate-file-locate-args' is a string, it is split
into command and arguments, and SEARCH-STRING is appended."
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_cmd) "/fake/locate")))
    (let ((org-locate-file-locate-args "locate --ignore-case"))
      (should (equal (org-locate-file--build-command "foo")
                     '("/fake/locate" "--ignore-case" "foo"))))))

;;;; List value appends search-string
(ert-deftest org-locate-file-test/build-command/list-value ()
  "When `org-locate-file-locate-args' is a list of strings,
SEARCH-STRING is appended as the last element."
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_cmd) "/fake/locate")))
    (let ((org-locate-file-locate-args '("locate" "--ignore-case")))
      (should (equal (org-locate-file--build-command "foo")
                     '("/fake/locate" "--ignore-case" "foo"))))))

;;;; Function returning string splits result
(ert-deftest org-locate-file-test/build-command/fn-returns-string ()
  "When `org-locate-file-locate-args' is a function that returns
a string, the result is split via `split-string-and-unquote'."
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_cmd) "/fake/locate")))
    (let ((org-locate-file-locate-args
           (lambda (s) (format "locate -d /db %s" s))))
      (should (equal (org-locate-file--build-command "foo")
                     '("/fake/locate" "-d" "/db" "foo"))))))

;;;; Function returning list used directly
(ert-deftest org-locate-file-test/build-command/fn-returns-list ()
  "When `org-locate-file-locate-args' is a function that returns
a list, the list is used directly as the command line."
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_cmd) "/fake/locate")))
    (let ((org-locate-file-locate-args
           (lambda (s) (list "locate" "-d" "/db" s))))
      (should (equal (org-locate-file--build-command "foo")
                     '("/fake/locate" "-d" "/db" "foo"))))))

;;;; Executable-find failure signals user-error
(ert-deftest org-locate-file-test/build-command/no-executable ()
  "When `executable-find' returns nil for the locate command,
`org-locate-file--build-command' signals a `user-error'."
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_cmd) nil))
            ((symbol-function 'locate-make-command-line)
             (lambda (s) (list "locate" s))))
    (let ((org-locate-file-locate-args nil))
      (should-error (org-locate-file--build-command "foo")))))

;;;; Invalid value type signals user-error
(ert-deftest org-locate-file-test/build-command/invalid-type ()
  "When `org-locate-file-locate-args' is an unsupported type
(e.g. an integer), `org-locate-file--build-command' signals a
`user-error'."
  (let ((org-locate-file-locate-args 42))
    (should-error (org-locate-file--build-command "foo")
                  :type 'user-error)))

;;; org-locate-file--pick-recent

;;;;; Pick newer file from two
(ert-deftest org-locate-file-test/pick-recent/two-files ()
  "Given two temp files with different modification times,
`org-locate-file--pick-recent' returns the newer one."
  (let* ((old-file (make-temp-file "ol-locate-old-"))
         (new-file (make-temp-file "ol-locate-new-")))
    (unwind-protect
        (progn
          (set-file-times old-file (encode-time 0 0 0 1 1 2020))
          (set-file-times new-file (encode-time 0 0 0 1 1 2024))
          (should (equal (org-locate-file--pick-recent
                          (list old-file new-file))
                         new-file)))
      (ignore-errors (delete-file old-file))
      (ignore-errors (delete-file new-file)))))

;;;;; Pick newest from three files
(ert-deftest org-locate-file-test/pick-recent/three-files ()
  "Given three temp files, `org-locate-file--pick-recent' returns
the most recently modified one."
  (let* ((old-file (make-temp-file "ol-locate-old-"))
         (mid-file (make-temp-file "ol-locate-mid-"))
         (new-file (make-temp-file "ol-locate-new-")))
    (unwind-protect
        (progn
          (set-file-times old-file (encode-time 0 0 0 1 1 2020))
          (set-file-times mid-file (encode-time 0 0 0 6 1 2022))
          (set-file-times new-file (encode-time 0 0 0 1 1 2024))
          (should (equal (org-locate-file--pick-recent
                          (list old-file mid-file new-file))
                         new-file)))
      (ignore-errors (delete-file old-file))
      (ignore-errors (delete-file mid-file))
      (ignore-errors (delete-file new-file)))))

;;;;; Fallback to first when file-attributes returns nil
(ert-deftest org-locate-file-test/pick-recent/fallback-nil-attrs ()
  "When all `file-attributes' calls return nil,
`org-locate-file--pick-recent' falls back to the first candidate."
  (let* ((a "/nonexistent/a")
         (b "/nonexistent/b"))
    (should (equal (org-locate-file--pick-recent (list a b)) a))))

;;;;; Single file returns that file
(ert-deftest org-locate-file-test/pick-recent/single-file ()
  "Given a single candidate, `org-locate-file--pick-recent'
returns it directly."
  (let* ((f (make-temp-file "ol-locate-single-")))
    (unwind-protect
        (should (equal (org-locate-file--pick-recent (list f)) f))
      (ignore-errors (delete-file f)))))

;;;;; Equal timestamps returns first candidate
(ert-deftest org-locate-file-test/pick-recent/equal-timestamps ()
  "When two files have the same modification time,
`org-locate-file--pick-recent' returns the first candidate."
  (let* ((a (make-temp-file "ol-locate-eq-a-"))
         (b (make-temp-file "ol-locate-eq-b-"))
         (same-time (encode-time 0 0 12 15 6 2025)))
    (unwind-protect
        (progn
          (set-file-times a same-time)
          (set-file-times b same-time)
          (should (equal (org-locate-file--pick-recent (list a b)) a)))
      (ignore-errors (delete-file a))
      (ignore-errors (delete-file b)))))

;;; org-locate-file--resolve

;;;;; Single candidate returns it directly (auto method)
(ert-deftest org-locate-file-test/resolve/single-candidate-auto ()
  "When only one candidate matches, return it directly regardless
of the resolve method being `auto'."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacs"))))
    (let ((org-locate-file-resolve-method 'auto))
      (should (equal (org-locate-file--resolve "emacs" 'follow)
                     "/usr/bin/emacs")))))

;;;;; Single candidate returns it directly (ask method)
(ert-deftest org-locate-file-test/resolve/single-candidate-ask ()
  "When only one candidate matches, return it directly even when
the resolve method is `ask' (no prompting needed)."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacs"))))
    (let ((org-locate-file-resolve-method 'ask))
      (should (equal (org-locate-file--resolve "emacs" 'follow)
                     "/usr/bin/emacs")))))

;;;;; Multiple candidates with auto picks first
(ert-deftest org-locate-file-test/resolve/multi-auto-picks-first ()
  "When multiple candidates match and method is `auto', return the
first candidate."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacs" "/bin/emacs"))))
    (let ((org-locate-file-resolve-method 'auto))
      (should (equal (org-locate-file--resolve "emacs" 'follow)
                     "/usr/bin/emacs")))))

;;;;; Multiple candidates with recent method
(ert-deftest org-locate-file-test/resolve/multi-recent ()
  "When multiple candidates match and method is `recent', delegate
to `org-locate-file--pick-recent'."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacs" "/bin/emacs")))
            ((symbol-function 'org-locate-file--pick-recent)
             (lambda (candidates) (cadr candidates))))
    (let ((org-locate-file-resolve-method 'recent))
      (should (equal (org-locate-file--resolve "emacs" 'follow)
                     "/bin/emacs")))))

;;;;; Multiple candidates with custom function
(ert-deftest org-locate-file-test/resolve/multi-custom-function ()
  "When multiple candidates match and method is a function, call
it with the candidates list and return its result."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacs" "/bin/emacs"))))
    (let* ((my-fn (lambda (candidates) (car (last candidates))))
           (org-locate-file-resolve-method my-fn))
      (should (equal (org-locate-file--resolve "emacs" 'follow)
                     "/bin/emacs")))))

;;;;; Multiple candidates with ask prompts user
(ert-deftest org-locate-file-test/resolve/multi-ask-prompts ()
  "When multiple candidates match and method is `ask', prompt via
`completing-read' and return the user's choice."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacs" "/bin/emacs")))
            ((symbol-function 'completing-read)
             (lambda (&rest _) "/usr/bin/emacs")))
    (let ((org-locate-file-resolve-method 'ask))
      (should (equal (org-locate-file--resolve "emacs" 'follow)
                     "/usr/bin/emacs")))))

;;;;; Substring-only matches are filtered out by string-suffix-p
(ert-deftest org-locate-file-test/resolve/substring-filtered ()
  "When locate returns paths where SEARCH-STRING appears only as
a substring (e.g. \"packages\" matching \"packages/child\" or
\"foo.el\" matching \"foo.elc\"), those are filtered out by
`string-suffix-p' and only exact suffix matches remain."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s)
               (list "/home/user/proj/packages"
                     "/home/user/proj/packages/child"))))
    (should (equal (org-locate-file--resolve "packages")
                   "/home/user/proj/packages"))))

;;;;; Empty filtered list falls back to raw candidates
(ert-deftest org-locate-file-test/resolve/empty-filter-fallback ()
  "When no candidate ends with SEARCH-STRING, the raw locate
results are used as fallback."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s)
               (list "/path/to/foo.elc" "/other/bar.elc"))))
    (let ((org-locate-file-resolve-method 'auto))
      (should (equal (org-locate-file--resolve "elc")
                     "/path/to/foo.elc")))))

;;; org-locate-file--shortest-unique-suffix

;;;;; Single file match returns basename
(ert-deftest org-locate-file-test/shortest-unique-suffix/single-match ()
  "When the locate database has exactly one result matching the
basename, return just the basename."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (list "/usr/bin/emacsclient"))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/usr/bin/emacsclient")
                   "emacsclient"))))

;;;;; Directory path with trailing slash normalizes correctly
(ert-deftest org-locate-file-test/shortest-unique-suffix/dir-trailing-slash ()
  "A directory path ending in \"/\" (as returned by
`dired-get-filename' for directories) is normalized by
`directory-file-name', producing the correct basename."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "lib")
                 (list "/home/user/project/src/lib"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/home/user/project/src/lib/")
                   "lib"))))

;;;;; Directory with trailing slash and disambiguation
(ert-deftest org-locate-file-test/shortest-unique-suffix/dir-trailing-slash-disambig ()
  "A directory path with trailing slash needing disambiguation
works correctly: the trailing slash is stripped, the basename is
found, and directory components are prepended as needed."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "lib")
                 (list "/home/user/project/src/lib"
                       "/home/user/other/src/lib"))
                ((equal s "src/lib")
                 (list "/home/user/project/src/lib"
                       "/home/user/other/src/lib"))
                ((equal s "project/src/lib")
                 (list "/home/user/project/src/lib"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/home/user/project/src/lib/")
                   "project/src/lib"))))

;;;;; Unique suffix after one directory level
(ert-deftest org-locate-file-test/shortest-unique-suffix/one-dir-level ()
  "When multiple files share a basename and one directory level
is enough to disambiguate via locate, return that two-component suffix."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "emacsclient")
                 (list "/usr/bin/emacsclient"
                       "/usr/local/bin/emacsclient"))
                ((equal s "bin/emacsclient")
                 (list "/usr/bin/emacsclient"
                       "/usr/local/bin/emacsclient"))
                ((equal s "usr/bin/emacsclient")
                 (list "/usr/bin/emacsclient"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/usr/bin/emacsclient")
                   "usr/bin/emacsclient"))))

;;;;; Unique suffix after multiple directory levels
(ert-deftest org-locate-file-test/shortest-unique-suffix/multi-dir-level ()
  "When one directory level is insufficient, keep prepending until
the suffix is unique via locate."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "main.el")
                 (list "/home/user/proj/src/main.el"
                       "/home/user/other/src/main.el"))
                ((equal s "src/main.el")
                 (list "/home/user/proj/src/main.el"
                       "/home/user/other/src/main.el"))
                ((equal s "proj/src/main.el")
                 (list "/home/user/proj/src/main.el"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/home/user/proj/src/main.el")
                   "proj/src/main.el"))))

;;;;; Unique suffix disambiguates same-directory files by extension
(ert-deftest org-locate-file-test/shortest-unique-suffix/same-dir-ext ()
  "When two files with the same basename stem exist in the same
directory (e.g. foo.el and foo.elc), `string-suffix-p' filtering
disambiguates by the full basename including extension, so the
basename alone suffices."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "foo.el")
                 (list "/home/user/project/src/foo.el"
                       "/home/user/project/src/foo.elc"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/home/user/project/src/foo.el")
                   "foo.el"))))

;;;;; Extension filtering then directory prepending as needed
(ert-deftest org-locate-file-test/shortest-unique-suffix/ext-then-dir ()
  "When extension filtering alone is insufficient (same-named files
in different directories), directory prepending further
disambiguates."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "foo.el")
                 (list "/home/user/proj/src/foo.el"
                       "/home/user/proj/src/foo.elc"
                       "/home/user/other/src/foo.el"))
                ((equal s "src/foo.el")
                 (list "/home/user/proj/src/foo.el"
                       "/home/user/other/src/foo.el"))
                ((equal s "proj/src/foo.el")
                 (list "/home/user/proj/src/foo.el"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/home/user/proj/src/foo.el")
                   "proj/src/foo.el"))))

;;;;; File not found in results returns nil
(ert-deftest org-locate-file-test/shortest-unique-suffix/not-in-results ()
  "When FILE-PATH is not among the locate results, return nil."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s)
               (list "/usr/bin/emacs" "/bin/emacs"))))
    (should (null (org-locate-file--shortest-unique-suffix
                   "/usr/bin/nano")))))

;;;;; File not in locate database (user-error) returns nil
(ert-deftest org-locate-file-test/shortest-unique-suffix/not-in-db ()
  "When `org-locate-file--run-locate' signals `user-error', the
condition-case handler returns nil."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s) (user-error "No matches"))))
    (should (null (org-locate-file--shortest-unique-suffix
                    "/usr/bin/emacsclient")))))

;;;;; Directory with children excludes those children
(ert-deftest org-locate-file-test/shortest-unique-suffix/dir-with-children ()
  "When the target is a directory that contains files, those
children paths are excluded from locate results so they don't
inflate the candidate count.  The suffix uses directory components
as needed when other unrelated paths match."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "packages")
                 (list "/home/user/proj/packages"
                       "/home/user/proj/packages/file1.txt"
                       "/home/user/proj/packages/subdir/file2.el"
                       "/usr/share/packages"))
                ((equal s "proj/packages")
                 (list "/home/user/proj/packages"))
                (t nil)))))
    (should (equal (org-locate-file--shortest-unique-suffix
                    "/home/user/proj/packages")
                   "proj/packages"))))

;;; org-locate-file--follow-impl

;;;;; Plain path resolves and opens via org-link-open-as-file
(ert-deftest org-locate-file-test/follow-impl/plain-path ()
  "A plain path (no search option) resolves via locate and opens
via `org-link-open-as-file' with IN-EMACS nil."
  (cl-letf (((symbol-function 'org-locate-file--resolve)
             (lambda (_s _ctx) "/real/path/emacsclient"))
            ((symbol-function 'org-link-open-as-file)
             (lambda (path in-emacs)
               (list 'opened path in-emacs))))
    (should (equal (org-locate-file--follow-impl
                    "emacsclient" nil)
                   '(opened "/real/path/emacsclient" nil)))))

;;;;; Path with linenum option preserves it
(ert-deftest org-locate-file-test/follow-impl/linenum-option ()
  "A path with ::linenum suffix preserves the option on the
resolved path."
  (cl-letf (((symbol-function 'org-locate-file--resolve)
             (lambda (_s _ctx) "/real/path/emacsclient"))
            ((symbol-function 'org-link-open-as-file)
             (lambda (path in-emacs)
               (list 'opened path in-emacs))))
    (should (equal (org-locate-file--follow-impl
                    "emacsclient::42" nil)
                   '(opened "/real/path/emacsclient::42" nil)))))

;;;;; Path with heading option preserves it
(ert-deftest org-locate-file-test/follow-impl/heading-option ()
  "A path with ::*Heading suffix preserves the heading option on
the resolved path."
  (cl-letf (((symbol-function 'org-locate-file--resolve)
             (lambda (_s _ctx) "/real/path/notes"))
            ((symbol-function 'org-link-open-as-file)
             (lambda (path in-emacs)
               (list 'opened path in-emacs))))
    (should (equal (org-locate-file--follow-impl
                    "notes::*SectionOne" nil)
                   '(opened "/real/path/notes::*SectionOne" nil)))))

;;;;; IN-EMACS nil is passed through
(ert-deftest org-locate-file-test/follow-impl/in-emacs-nil ()
  "When IN-EMACS is nil, it is passed directly to
`org-link-open-as-file'."
  (cl-letf (((symbol-function 'org-locate-file--resolve)
             (lambda (_s _ctx) "/real/path/emacsclient"))
            ((symbol-function 'org-link-open-as-file)
             (lambda (path in-emacs)
               (list 'opened path in-emacs))))
    (should (equal (org-locate-file--follow-impl "emacsclient" nil)
                   '(opened "/real/path/emacsclient" nil)))))

;;;;; IN-EMACS 'emacs is passed through
(ert-deftest org-locate-file-test/follow-impl/in-emacs-emacs ()
  "When IN-EMACS is `emacs', it is passed directly to
`org-link-open-as-file'."
  (cl-letf (((symbol-function 'org-locate-file--resolve)
             (lambda (_s _ctx) "/real/path/emacsclient"))
            ((symbol-function 'org-link-open-as-file)
             (lambda (path in-emacs)
               (list 'opened path in-emacs))))
    (should (equal (org-locate-file--follow-impl "emacsclient" 'emacs)
                   '(opened "/real/path/emacsclient" emacs)))))

;;; org-locate-file-complete-link

;; Tests for `org-locate-file-complete-link', which provides
;; minibuffer completion backed by locate and returns a link string
;; of the form TYPE:SUFFIX.  The suffix is the shortest unique
;; suffix via `org-locate-file--shortest-unique-suffix'.

;;;;; Unique basename returns lfile:BASENAME
(ert-deftest org-locate-file-test/complete/unique-basename ()
  "When completing-read returns a path whose basename is unique in
the locate DB, the link uses just the basename."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (if (equal s "emacsclient")
                   (list "/usr/bin/emacsclient")
                 nil)))
            ((symbol-function 'completing-read)
             (lambda (&rest _) "/usr/bin/emacsclient")))
    (should (equal (org-locate-file-complete-link nil)
                   "lfile:emacsclient"))))

;;;;; Disambiguation produces directory-qualified suffix
(ert-deftest org-locate-file-test/complete/disambiguated-suffix ()
  "When the basename alone would match multiple files, the link
includes directory components for disambiguation."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (cond
                ((equal s "emacsclient")
                 (list "/usr/bin/emacsclient"
                       "/usr/local/bin/emacsclient"))
                ((equal s "bin/emacsclient")
                 (list "/usr/bin/emacsclient"
                       "/usr/local/bin/emacsclient"))
                ((equal s "usr/bin/emacsclient")
                 (list "/usr/bin/emacsclient"))
                (t nil))))
            ((symbol-function 'completing-read)
             (lambda (&rest _) "/usr/bin/emacsclient")))
    (should (equal (org-locate-file-complete-link nil)
                   "lfile:usr/bin/emacsclient"))))

;;;;; Empty choice returns type: prefix
(ert-deftest org-locate-file-test/complete/empty-choice ()
  "When completing-read returns an empty string, return just the
type prefix with colon (e.g. `lfile:')."
  (cl-letf (((symbol-function 'completing-read)
             (lambda (&rest _) "")))
    (should (equal (org-locate-file-complete-link nil) "lfile:"))))

;;;;; Directory path with trailing slash is normalized
(ert-deftest org-locate-file-test/complete/dir-trailing-slash ()
  "A directory path ending in \"/\" (as coming from locate results)
is normalized so the link uses the corrected basename."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (s)
               (if (equal s "lib")
                   (list "/home/user/project/src/lib")
                 nil)))
            ((symbol-function 'completing-read)
             (lambda (&rest _) "/home/user/project/src/lib/")))
    (should (equal (org-locate-file-complete-link nil)
                   "lfile:lib"))))

;;;;; File not in DB falls back to file-name-nondirectory
(ert-deftest org-locate-file-test/complete/fallback-basename ()
  "When `shortest-unique-suffix' returns nil (e.g. the file is in
the locate output but not matched by member-check), fall back to
`file-name-nondirectory'."
  (cl-letf (((symbol-function 'org-locate-file--run-locate)
             (lambda (_s)
               ;; shortest-unique-suffix: member check fails
               ;; because the real file is not in the results.
               (list "/other/path/file.dat")))
            ((symbol-function 'completing-read)
             (lambda (&rest _) "/some/path/file.dat")))
    (should (equal (org-locate-file-complete-link nil)
                   "lfile:file.dat"))))

;;; org-locate-file-store-link

;; Tests for `org-locate-file-store-link', which captures the
;; current buffer's file (or dired selection) and stores an lfile:
;; link via `org-link-store-props'.  These tests mock the buffer
;; environment and verify the stored properties.

;;;;; Dired mode: unique basename stores lfile:BASENAME
(ert-deftest org-locate-file-test/store/dired-unique-basename ()
  "In Dired mode with a file that has a unique basename, store an
lfile: link using just the basename."
  (let* ((captured-props nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (mode) (eq mode 'dired-mode)))
              ((symbol-function 'dired-get-filename)
               (lambda (&rest _) "/usr/bin/emacsclient"))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (s)
                 (if (equal s "emacsclient")
                     (list "/usr/bin/emacsclient")
                   nil))))
      (org-locate-file-store-link)
      (should (consp captured-props))
      (should (equal (plist-get captured-props :type) "lfile"))
      (should (equal (plist-get captured-props :link)
                     "lfile:emacsclient"))
      (should (null (plist-get captured-props :description))))))

;;;;; Dired mode: disambiguated suffix includes directory
(ert-deftest org-locate-file-test/store/dired-disambiguated ()
  "In Dired mode when the basename alone is ambiguous, store a
link with directory components."
  (let* ((captured-props nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (mode) (eq mode 'dired-mode)))
              ((symbol-function 'dired-get-filename)
               (lambda (&rest _) "/usr/bin/emacsclient"))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (s)
                 (cond
                  ((equal s "emacsclient")
                   (list "/usr/bin/emacsclient"
                         "/usr/local/bin/emacsclient"))
                  ((equal s "bin/emacsclient")
                   (list "/usr/bin/emacsclient"
                         "/usr/local/bin/emacsclient"))
                  ((equal s "usr/bin/emacsclient")
                   (list "/usr/bin/emacsclient"))
                  (t nil)))))
      (org-locate-file-store-link)
      (should (equal (plist-get captured-props :link)
                     "lfile:usr/bin/emacsclient")))))

;;;;; Dired mode: directory path with trailing slash
(ert-deftest org-locate-file-test/store/dired-directory ()
  "In Dired mode with point on a directory, store an lfile: link
using the normalized directory basename."
  (let* ((captured-props nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (mode) (eq mode 'dired-mode)))
              ((symbol-function 'dired-get-filename)
               (lambda (&rest _) "/home/user/project/src/lib/"))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (s)
                 (if (equal s "lib")
                     (list "/home/user/project/src/lib")
                   nil))))
      (org-locate-file-store-link)
      (should (equal (plist-get captured-props :link)
                     "lfile:lib")))))

;;;;; Dired mode: suffix nil returns nil, no props stored
(ert-deftest org-locate-file-test/store/dired-suffix-nil ()
  "In Dired mode when `shortest-unique-suffix' returns nil, no
link properties are stored and the function returns nil."
  (let* ((captured-props nil)
         (result nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (mode) (eq mode 'dired-mode)))
              ((symbol-function 'dired-get-filename)
               (lambda (&rest _) "/usr/bin/emacsclient"))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (s)
                 (if (equal s "emacsclient")
                     (list "/other/bin/emacsclient")
                   nil))))
      (setq result (org-locate-file-store-link))
      (should (null captured-props))
      (should (null result)))))

;;;;; File-visiting buffer: stores link with description
(ert-deftest org-locate-file-test/store/file-visiting-buffer ()
  "In a file-visiting buffer, store an lfile: link using the
shortest unique suffix and the description from
`org-link--file-link-to-here'."
  (let* ((captured-props nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (_mode) nil))
              ((symbol-function 'buffer-base-buffer)
               (lambda () nil))
              ((symbol-function 'org-link--file-link-to-here)
               (lambda ()
                 (cons "file:/usr/bin/emacsclient" "Emacs client")))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (s)
                 (if (equal s "emacsclient")
                     (list "/usr/bin/emacsclient")
                   nil))))
      (let ((buffer-file-name "/usr/bin/emacsclient"))
        (org-locate-file-store-link))
      (should (equal (plist-get captured-props :type) "lfile"))
      (should (equal (plist-get captured-props :link)
                     "lfile:emacsclient"))
      (should (equal (plist-get captured-props :description)
                     "Emacs client")))))

;;;;; File-visiting buffer: preserves search option (::linenum)
(ert-deftest org-locate-file-test/store/file-with-search-option ()
  "In a file-visiting buffer with a search option (line number),
the link preserves the ::option suffix."
  (let* ((captured-props nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (_mode) nil))
              ((symbol-function 'buffer-base-buffer)
               (lambda () nil))
              ((symbol-function 'org-link--file-link-to-here)
               (lambda ()
                 (cons "file:/usr/bin/emacsclient::42" nil)))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (s)
                 (if (equal s "emacsclient")
                     (list "/usr/bin/emacsclient")
                   nil))))
      (let ((buffer-file-name "/usr/bin/emacsclient"))
        (org-locate-file-store-link))
      (should (equal (plist-get captured-props :link)
                     "lfile:emacsclient::42")))))

;;;;; File-visiting buffer: suffix nil returns nil
(ert-deftest org-locate-file-test/store/file-suffix-nil ()
  "In a file-visiting buffer when `shortest-unique-suffix' returns
nil, no link properties are stored."
  (let* ((captured-props nil)
         (result nil)
         (org-locate-file-link-type "lfile"))
    (cl-letf (((symbol-function 'derived-mode-p)
               (lambda (_mode) nil))
              ((symbol-function 'buffer-base-buffer)
               (lambda () nil))
              ((symbol-function 'org-link--file-link-to-here)
               (lambda ()
                 (cons "file:/usr/bin/emacsclient" nil)))
              ((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props)))
              ((symbol-function 'org-locate-file--run-locate)
               (lambda (_s)
                 (user-error "Not in DB"))))
      (let ((buffer-file-name "/usr/bin/emacsclient"))
        (setq result (org-locate-file-store-link)))
      (should (null captured-props))
      (should (null result)))))

;;;;; store-link-p nil: returns nil, no props stored
(ert-deftest org-locate-file-test/store/disabled-flag ()
  "When `org-locate-file-store-link-p' is nil, the store handler
returns nil without storing any properties."
  (let* ((captured-props nil)
         (result nil)
         (org-locate-file-store-link-p nil))
    (cl-letf (((symbol-function 'org-link-store-props)
               (lambda (&rest props)
                 (setq captured-props props))))
      (setq result (org-locate-file-store-link))
      (should (null captured-props))
      (should (null result)))))

(provide 'ol-locate-file-unit-test)

;;; ol-locate-file-unit-test.el ends here
