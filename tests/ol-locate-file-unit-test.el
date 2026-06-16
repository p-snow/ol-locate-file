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

(provide 'ol-locate-file-unit-test)

;;; ol-locate-file-unit-test.el ends here
