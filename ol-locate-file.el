;;; ol-locate-file.el --- Locate-based file links for Org mode -*- lexical-binding: t -*-

;; Copyright (C) 2026  Free Software Foundation, Inc.

;; Author: p-snow
;; Keywords: hypermedia, convenience
;; URL: https://github.com/p-snow/ol-locate-file
;; Package-Requires: ((emacs "27.1") (org "9.0"))
;; Version: 0.0.1

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

;; This package provides a new Org link type that resolves partial
;; file path substrings into full paths using the `locate' command.
;;
;; With this package, instead of writing a full absolute path:
;;
;;     [[file:/usr/bin/emacsclient][emacsclient]]
;;
;; you can write just a distinctive substring:
;;
;;     [[lfile:emacsclient][emacsclient]]
;;
;; The package opens the resolved file as if it were a regular
;; `file:' link.  Three variants are provided:
;;
;;   - lfile:        → equivalent to file:        (find-file)
;;   - lfile+emacs:  → equivalent to file+emacs:  (find-file in Emacs)
;;   - lfile+sys:    → equivalent to file+sys:    (open with system app)
;;
;; The mechanism uses `org-link-abbrev-alist' internally to delegate
;; to the built-in `file:' link type after resolving the partial
;; substring via the locate database.  The link type name itself
;; (default "lfile") is customizable via `ol-locate-file-link-type'.
;;
;; When multiple files match the search substring, the user is
;; prompted with `completing-read' to select the intended target.
;;
;; The locate command is invoked via Emacs' built-in `locate-make-command-line',
;; so any customizations to that variable (or to `locate-command',
;; `locate-prompt-for-command', etc.) are automatically honored.
;;
;; Security: the package runs the locate command through `call-process'
;; rather than a shell, avoiding shell injection risks.

;;; Code:

(require 'ol)
(require 'org)
(require 'cl-lib)
(require 'locate)

;;; Customization group

(defgroup ol-locate-file nil
  "Locate-based file links for Org mode.
Uses the `locate' command (or compatible) to resolve partial
file path substrings into full absolute paths."
  :group 'org-link
  :prefix "ol-locate-file-")

;;; Customizable options

(defcustom ol-locate-file-link-type "lfile"
  "Default link type string for ol-locate-file.
Users can change this to any string to customize the link prefix
that appears in Org buffers.  Changing this value does not
retroactively update existing links."
  :type 'string
  :group 'ol-locate-file)

(defcustom ol-locate-file-max-results 500
  "Maximum number of locate results to collect.
Limiting results prevents performance issues when the search
substring is very short and matches many files."
  :type 'integer
  :group 'ol-locate-file)

;;; Internal variables

(defvar ol-locate-file--history nil
  "History list for `ol-locate-file' minibuffer completions.")

;;; Command construction

(defun ol-locate-file--build-command (search-string)
  "Build the locate command line for SEARCH-STRING.
Returns a list of (COMMAND . ARGS) suitable for `call-process',
where COMMAND is the absolute path to the locate executable.
Signals `user-error' if the locate command cannot be found.

Delegates to `locate-make-command-line' from Emacs' built-in
`locate.el', which users can customize directly to control the
locate command and its arguments."
  (let* ((cmdline (funcall locate-make-command-line search-string))
         (cmd (car cmdline))
         (proc (executable-find cmd))
         (args (delq nil (cdr cmdline))))
    (unless proc
      (user-error "Cannot find locate command: %s" cmd))
    (cons proc args)))

;;; Locate execution

(defun ol-locate-file--run-locate (search-string)
  "Run the locate command for SEARCH-STRING.
Returns a list of absolute file paths matching SEARCH-STRING.
If no results are found, signals `user-error'.

The command is executed via `call-process' to avoid shell
injection risks.  No shell metacharacters are interpreted."
  (when (string-empty-p search-string)
    (user-error "Empty search string; please provide a substring to search for"))
  (let* ((cmd-args (ol-locate-file--build-command search-string))
         (cmd (car cmd-args))
         (args (cdr cmd-args))
         (max-results ol-locate-file-max-results))
    (with-temp-buffer
      (let ((_exit-code (apply #'call-process cmd nil
                              (list (current-buffer) nil) nil args)))
        ;; Note: `locate' may exit non-zero when there are no matches;
        ;; we treat an empty output buffer as "no matches" regardless
        ;; of exit code.
        (goto-char (point-min))
        (let ((results nil)
              (count 0))
          (while (and (not (eobp))
                      (or (null max-results) (< count max-results)))
            (let ((line (string-trim
                         (buffer-substring-no-properties
                          (line-beginning-position)
                          (line-end-position)))))
              (unless (string-empty-p line)
                (push line results)
                (cl-incf count)))
            (forward-line 1))
          (if results
              (nreverse results)
            (user-error "No file matching \"%s\" found in locate database"
                        search-string)))))))

;;; Path resolution engine

(defun ol-locate-file--resolve (search-string)
  "Resolve SEARCH-STRING to a single file path using locate.
When multiple files match, prompt the user via `completing-read'.
When exactly one matches, return it directly.

This function is used during interactive link-following."
  (let ((candidates (ol-locate-file--run-locate search-string)))
    (if (null (cdr candidates))
        ;; Exactly one result: return immediately
        (car candidates)
      ;; Multiple results: prompt the user to choose
      (let ((choice
             (completing-read
              (format "Multiple matches for \"%s\" (choose one): " search-string)
              (lambda (string pred action)
                (if (eq action 'metadata)
                    '(metadata
                      (display-sort-function . identity)
                      (cycle-sort-function . identity))
                  (complete-with-action action candidates string pred)))
              nil t nil 'ol-locate-file--history)))
        (if (string-empty-p choice)
            (user-error "No file selected")
          choice)))))

;;; Abbreviation expansion function (for org-link-abbrev-alist)

(defun ol-locate-file-locate (tag)
  "Resolve TAG to an absolute file path using locate, without prompting.

TAG is the link path substring, which may include an Org search
option after \"::\" (e.g. \"emacsclient::10\").  The portion
before \"::\" is used as the locate search term; any search
option is preserved in the output.

When multiple files match, the first result is returned silently
  (this function is designed for non-interactive use during link
  abbreviation expansion).  Use `ol-locate-file--resolve' for
interactive prompting.

This function is intended for use in `org-link-abbrev-alist'
with the \"%(ol-locate-file-locate)\" syntax."
  (let (search-string search-option)
    (if (string-match "::\\(.*\\)\\'" tag)
        (setq search-string (substring tag 0 (match-beginning 0))
              search-option (match-string 1 tag))
      (setq search-string tag
            search-option nil))
    (condition-case nil
        (let ((resolved (car (ol-locate-file--run-locate search-string))))
          (if search-option
              (concat resolved "::" search-option)
            resolved))
      (user-error tag))))

;;; Follow handlers

(defun ol-locate-file--follow (path _arg)
  "Follow an lfile: link by resolving PATH via locate and opening the file.
Equivalent to following a file: link with the resolved path.
ARG is the universal prefix argument (currently unused)."
  (ol-locate-file--follow-impl path nil))

(defun ol-locate-file--follow-emacs (path _arg)
  "Follow an lfile+emacs: link by resolving PATH and opening in Emacs.
Equivalent to following a file+emacs: link."
  (ol-locate-file--follow-impl path 'emacs))

(defun ol-locate-file--follow-sys (path _arg)
  "Follow an lfile+sys: link by resolving PATH and opening with system app.
Equivalent to following a file+sys: link."
  (ol-locate-file--follow-impl path 'system))

(defun ol-locate-file--follow-impl (path in-emacs)
  "Core follow implementation for all ol-locate-file link variants.

PATH is the raw link path, which may include a \"::search-option\"
suffix.  The search option is preserved and passed through to
`org-link-open-as-file'.

IN-EMACS is passed directly to `org-link-open-as-file' and
controls how the file is opened:
- nil       → use `org-file-apps' to decide
- `emacs'   → always open in Emacs
- `system'  → always open with system application"
  (let* ((search-option (and (string-match "::\\(.*\\)\\'" path)
                             (match-string 1 path)))
         (search-string (if search-option
                            (substring path 0 (match-beginning 0))
                          path))
         (resolved (ol-locate-file--resolve search-string))
         (full-path (if search-option
                        (concat resolved "::" search-option)
                      resolved)))
    (org-link-open-as-file full-path in-emacs)))

;;; Store handler

;;;###autoload
(defun ol-locate-file-store-link ()
  "Store a link to the current file using the lfile link type.

When in `dired-mode', uses the basename of the file at point.
When visiting a file, uses the basename of the buffer file.
The stored link uses only the basename, which is resolved at
follow-time via the locate database."
  (let ((type ol-locate-file-link-type))
    (cond
     ((derived-mode-p 'dired-mode)
      (let ((file (dired-get-filename nil t)))
        (when file
          (org-link-store-props
           :type type
           :link (concat type ":" (file-name-nondirectory file))
           :description (abbreviate-file-name file)))))
     ((buffer-file-name)
      (let ((file (buffer-file-name)))
        (org-link-store-props
         :type type
         :link (concat type ":" (file-name-nondirectory file))
         :description (abbreviate-file-name file))))
     (t
      ;; Not in a file-visiting buffer or dired; fall back to
      ;; whatever Org's default store would do.
      nil))))

;;; Complete handler

(defun ol-locate-file-complete-link ()
  "Complete an lfile: link using the locate database.

This function is called by `org-insert-link' when the link type
is the value of `ol-locate-file-link-type'.  It queries the
locate database to provide completion candidates.

If the locate query returns no results, the user's raw input is
used as-is."
  (let* ((type ol-locate-file-link-type)
         (prompt (format "%s (locate search): " type))
         (partial (read-string prompt)))
    (if (string-empty-p partial)
        (concat type ":")
      (condition-case nil
          (let* ((candidates (ol-locate-file--run-locate partial))
                 (choice (if (cdr candidates)
                             (completing-read
                              (format "Choose file for %s: " type)
                              candidates nil t nil
                              'ol-locate-file--history)
                           (car candidates))))
            (concat type ":" choice))
        (user-error
         ;; If locate fails, just use the raw input
         (concat type ":" partial))))))

;;; Link type registration

(defun ol-locate-file--register-abbrevs ()
  "Register link abbreviations for display purposes.

Registers lfile:, lfile+emacs, and lfile+sys abbreviations in
`org-link-abbrev-alist'.  Abbreviations expand links to file:
equivalents at parse time, using the first locate match (non-
interactive).

See also `ol-locate-file--register-link-parameters', which defines
link behavior (follow, export, store, complete)."
  (let ((type ol-locate-file-link-type))
    (cl-pushnew (cons type
                      (concat "file:%(ol-locate-file-locate)"))
                org-link-abbrev-alist
                :test #'equal)
    (cl-pushnew (cons (concat type "+emacs")
                      (concat "file+emacs:%(ol-locate-file-locate)"))
                org-link-abbrev-alist
                :test #'equal)
    (cl-pushnew (cons (concat type "+sys")
                      (concat "file+sys:%(ol-locate-file-locate)"))
                org-link-abbrev-alist
                :test #'equal)))

(defun ol-locate-file--register-link-parameters ()
  "Register link behavior via `org-link-set-parameters'.

Registers :follow, :store, and :complete for the link type and its +emacs/+sys
variants.

This defines what happens when a link is clicked, exported, or
stored.  Display and parsing are handled separately by
`ol-locate-file--register-abbrevs', which expands lfile: links to
file: links at parse time using the first locate match.

The dual registration (abbrevs + parameters) is required: abbrevs
control display, while parameters control behavior."
  ;; Register the main link type
  (org-link-set-parameters
   ol-locate-file-link-type
   :follow #'ol-locate-file--follow
   :store #'ol-locate-file-store-link
   :complete #'ol-locate-file-complete-link)

  ;; Register lfile+emacs variant
  (org-link-set-parameters
   (concat ol-locate-file-link-type "+emacs")
   :follow #'ol-locate-file--follow-emacs
   :store #'ol-locate-file-store-link)

  ;; Register lfile+sys variant
  (org-link-set-parameters
   (concat ol-locate-file-link-type "+sys")
   :follow #'ol-locate-file--follow-sys
   :store #'ol-locate-file-store-link))

;;;###autoload
(defun ol-locate-file-setup ()
  "Set up the ol-locate-file link type.

This function performs two registrations required for correct
operation:

1. Link abbreviations (`ol-locate-file--register-abbrevs'):
   Expand lfile: links to file: links for display and parsing.

2. Link parameters (`ol-locate-file--register-link-parameters'):
   Define follow, export, store, and complete behavior.

Call this in your init file after this package is loaded:

    (with-eval-after-load \\='ol
      (require \\='ol-locate-file)
      (ol-locate-file-setup))"
  (ol-locate-file--register-abbrevs)
  (ol-locate-file--register-link-parameters))

;;; Footer

(provide 'ol-locate-file)

;;; ol-locate-file.el ends here
