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
;; file path substrings into full paths using the `locate' command
;; (or its compatible implementations such as mlocate or plocate).
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
;; Security: the package runs the locate command through `call-process'
;; rather than a shell, avoiding shell injection risks.

;;; Code:

(require 'ol)
(require 'org)
(require 'cl-lib)

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

(defcustom ol-locate-file-command
  (if (and (boundp 'locate-command)
           (stringp locate-command))
      locate-command
    "locate")
  "Executable program used to search the file database.
Defaults to the value of `locate-command' from Emacs' built-in
`locate.el' package if available; otherwise defaults to \"locate\"."
  :type 'string
  :group 'ol-locate-file)

(defcustom ol-locate-file-arguments
  '("-i")
  "List of command-line arguments passed to the locate command.
These are inserted before the search term.  The default (\"-i\")
enables case-insensitive matching, which is supported by both
mlocate and plocate.  Set to nil for case-sensitive matching."
  :type '(repeat string)
  :group 'ol-locate-file)

(defcustom ol-locate-file-database
  (if (and (boundp 'locate-db)
           (stringp locate-db))
      locate-db
    nil)
  "Path to the locate database file.
When non-nil, the locate command is invoked with the appropriate
flag to use this specific database.  Defaults to the value of
`locate-db' from Emacs' built-in `locate.el' if available;
otherwise nil (which means the default system database is used).

If you use plocate, the flag \"--database\" is automatically
used; for mlocate and other implementations, \"-d\" is used."
  :type '(choice (const :tag "Default database" nil)
                 (file :tag "Database file"))
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

;;; plocate detection

(defun ol-locate-file--plocate-p ()
  "Return non-nil if the configured locate command is plocate.
Detects plocate by inspecting the command name.  Also returns
non-nil if the locate command is not found but plocate is
available as a fallback."
  (let ((cmd-name (file-name-nondirectory ol-locate-file-command)))
    (or (string-match-p "plocate" cmd-name)
        (and (not (executable-find ol-locate-file-command))
             (executable-find "plocate")))))

;;; Database argument construction

(defun ol-locate-file--database-args ()
  "Return a list of arguments specifying the locate database.
When `ol-locate-file-database' is nil, returns an empty list."
  (when ol-locate-file-database
    (if (ol-locate-file--plocate-p)
        (list "--database" ol-locate-file-database)
      (list "-d" ol-locate-file-database))))

;;; Command construction

(defun ol-locate-file--build-command (search-string)
  "Build the locate command line for SEARCH-STRING.
Returns a list of (command . args) suitable for `call-process'.
Signals `user-error' if the locate command cannot be found."
  (let ((cmd (executable-find ol-locate-file-command)))
    (unless cmd
      (if (ol-locate-file--plocate-p)
          (setq cmd (executable-find "plocate"))
        (user-error "Cannot find locate command: %s" ol-locate-file-command)))
    (unless cmd
      (user-error "Cannot find locate command: %s" ol-locate-file-command))
    (append (list cmd)
            ol-locate-file-arguments
            (ol-locate-file--database-args)
            (list search-string))))

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
      (let ((exit-code (apply #'call-process cmd nil
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

;;; Export handler

(defun ol-locate-file--export (path desc backend info)
  "Export an lfile: link by resolving PATH and delegating to file: export.

PATH is resolved via the locate database.  The resolved absolute
path is then passed to the `file:' link type's export handler.
If no export handler is registered for `file:', the resolved
path is returned as a plain string.

DESC is the link description or nil.
BACKEND is the export backend symbol.
INFO is the export communication channel plist."
  (condition-case nil
      (let* ((search-option (and (string-match "::\\(.*\\)\\'" path)
                                 (match-string 1 path)))
             (search-string (if search-option
                                (substring path 0 (match-beginning 0))
                              path))
             (resolved (ol-locate-file--resolve search-string))
             (full-path (if search-option
                            (concat resolved "::" search-option)
                          resolved)))
        (let ((file-export-fn (org-link-get-parameter "file" :export)))
          (if (functionp file-export-fn)
              (funcall file-export-fn full-path desc backend info)
            ;; Fallback: return the resolved path verbatim
            full-path)))
    (user-error
     ;; If locate fails during export, return the raw path
     (concat ol-locate-file-link-type ":" path))))

;;; Help-echo handler

(defun ol-locate-file--help-echo (_window _object _position)
  "Provide a help-echo string for lfile: links.
Shows the link type and the raw search substring."
  (when-let* ((context (org-element-context))
              ((eq (org-element-type context) 'link))
              (type (org-element-property :type context))
              ((or (string= type ol-locate-file-link-type)
                   (string= type (concat ol-locate-file-link-type "+emacs"))
                   (string= type (concat ol-locate-file-link-type "+sys"))))
              (path (org-element-property :path context)))
    (format "%s: %s  (resolved via locate)" type path)))

;;; Face definition (face that inherits from org-link)

(defface ol-locate-file-link
  '((t :inherit org-link))
  "Face for ol-locate-file links.
Inherits from `org-link' by default.  Customize this to visually
distinguish locate-based links from regular file links."
  :group 'ol-locate-file)

;;; Keymap

(defvar ol-locate-file-link-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'org-open-at-point)
    (define-key map [mouse-2] 'org-open-at-point)
    map)
  "Keymap active on ol-locate-file links.")

;;; Link type registration

(defun ol-locate-file--register-abbrevs ()
  "Register link abbreviations for lfile variants in `org-link-abbrev-alist'.

The abbreviations cause Org to display and parse the links as
their `file:' equivalents, with the locate resolution happening
transparently.

Registered abbreviations:
  TYPE         → file:%(ol-locate-file-locate)
  TYPE+emacs   → file+emacs:%(ol-locate-file-locate)
  TYPE+sys     → file+sys:%(ol-locate-file-locate)

where TYPE is the value of `ol-locate-file-link-type'."
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

(defun ol-locate-file--register-link ()
  "Register the lfile: link type and its variants with Org.

Sets :follow, :store, :export, :complete, :face, :help-echo,
and :keymap parameters for all three link type variants."
  ;; Register the main link type
  (org-link-set-parameters
   ol-locate-file-link-type
   :follow #'ol-locate-file--follow
   :store #'ol-locate-file-store-link
   :export #'ol-locate-file--export
   :complete #'ol-locate-file-complete-link
   :face 'ol-locate-file-link
   :help-echo #'ol-locate-file--help-echo
   :keymap ol-locate-file-link-map)

  ;; Register lfile+emacs variant
  (org-link-set-parameters
   (concat ol-locate-file-link-type "+emacs")
   :follow #'ol-locate-file--follow-emacs
   :store #'ol-locate-file-store-link
   :export #'ol-locate-file--export
   :face 'ol-locate-file-link
   :help-echo #'ol-locate-file--help-echo
   :keymap ol-locate-file-link-map)

  ;; Register lfile+sys variant
  (org-link-set-parameters
   (concat ol-locate-file-link-type "+sys")
   :follow #'ol-locate-file--follow-sys
   :store #'ol-locate-file-store-link
   :export #'ol-locate-file--export
   :face 'ol-locate-file-link
   :help-echo #'ol-locate-file--help-echo
   :keymap ol-locate-file-link-map))

;;;###autoload
(defun ol-locate-file-setup ()
  "Set up the ol-locate-file link type.

Registers link type parameters via `org-link-set-parameters' and
link abbreviations via `org-link-abbrev-alist'.  Call this in
your init file after this package is loaded:

    (with-eval-after-load 'ol
      (require 'ol-locate-file)
      (ol-locate-file-setup))"
  (ol-locate-file--register-abbrevs)
  (ol-locate-file--register-link))

;;; Footer

(provide 'ol-locate-file)

;;; ol-locate-file.el ends here
