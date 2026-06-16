;;; ol-locate-file-test.el --- Tests for ol-locate-file -*- lexical-binding: t -*-

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

;; Unit tests for ol-locate-file.  Run via:
;;   make unit-test
;; or directly:
;;   emacs -Q --batch -L . -l tests/ol-locate-file-test.el \
;;         -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'ol-locate-file)

;;; Test coverage tracking

(defun org-locate-file-test--coverage-report ()
  "Print a coverage report using testcover data.
Reports the percentage of covered code paths for each
instrumented function in `ol-locate-file.el'.
Uses the `edebug-coverage' property vector set by edebug/testcover
on each instrumented function."
  (let ((total-forms 0)
        (covered-forms 0))
    (mapatoms
     (lambda (sym)
       (let ((vec (and (string-prefix-p "org-locate-file-" (symbol-name sym))
                       (get sym 'edebug-coverage))))
         (when (vectorp vec)
           (dotimes (i (length vec))
             (let ((val (aref vec i)))
               (cl-incf total-forms)
               (unless (eq val 'edebug-unknown)
                 (cl-incf covered-forms))))))))
    (princ (format "\n;; Coverage: %d/%d code paths covered (%.1f%%)\n"
                   covered-forms total-forms
                   (if (zerop total-forms) 100.0
                     (* 100.0 (/ covered-forms (float total-forms))))))
    (princ "\n")))

;;; Test runner entry point

;;;###autoload
(defun org-locate-file-test-run-all ()
  "Run all ol-locate-file tests and print summary with coverage."
  (interactive)
  (ert-run-tests-batch)
  (org-locate-file-test--coverage-report))

(provide 'ol-locate-file-test)

;;; ol-locate-file-test.el ends here
