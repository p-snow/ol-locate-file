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
;; The link type name (default "lfile") is customizable via
;; `ol-locate-file-link-type'.
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

(defcustom ol-locate-file-store-link-p t
  "Whether `ol-locate-file-store-link' should store lfile: links.

When non-nil (the default), `org-store-link' stores an lfile: link
for the current file.  When nil, `ol-locate-file-store-link' does
nothing, allowing the default file: link type to take effect.

Users who prefer file: links for storing but still want lfile:
links for existing Org documents can set this to nil."
  :type 'boolean
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

SEARCH-STRING is expanded via `substitute-in-file-name' before
being passed to locate, so `~' and `$VAR' references are resolved
to their absolute equivalents.

The command is executed via `call-process' to avoid shell
injection risks.  No shell metacharacters are interpreted."
  (when (string-empty-p search-string)
    (user-error "Empty search string; please provide a substring to search for"))
  (let* ((expanded (substitute-in-file-name search-string))
         (cmd-args (ol-locate-file--build-command expanded))
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
              (nreverse (delete-dups results))
            (user-error "No file matching \"%s\" found in locate database"
                        search-string)))))))

;;; Path resolution engine

(defun ol-locate-file--resolve (search-string)
  "Resolve SEARCH-STRING to a single file path using locate.
When multiple files match, prompt the user via `completing-read'.
When exactly one matches, return it directly."
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

(defun ol-locate-file--shortest-unique-suffix (file-path)
  "Compute the shortest unique suffix of FILE-PATH among locate results.

Run locate with the basename of FILE-PATH, collect all matches,
and return the shortest suffix (from the end of the path components)
that uniquely identifies FILE-PATH among those matches.

When exactly one result matches the basename, return just the
basename.  When multiple results match, prepend directory components
from the parent upward until the suffix is unique.

Return nil if FILE-PATH is not found in the locate database."
  (let ((basename (file-name-nondirectory file-path)))
    (condition-case nil
        (let* ((results (ol-locate-file--run-locate basename))
               (count (length results)))
          (when (member file-path results)
            (if (= 1 count)
                basename
              (let* ((dir (file-name-directory file-path))
                     (components (when dir
                                   (split-string
                                    (directory-file-name dir) "/" t)))
                     (suffix basename))
                (cl-loop for comp in (nreverse components)
                         do (setq suffix (concat comp "/" suffix))
                         when (= 1
                                 (cl-count-if
                                  (lambda (r)
                                    (string-suffix-p suffix r))
                                  results))
                         return suffix
                         finally return suffix)))))
      (user-error nil))))

;;;###autoload
(defun ol-locate-file-store-link ()
  "Store a link to the current file using the lfile link type.

When `ol-locate-file-store-link-p' is nil, do nothing and
return nil, allowing the default file: link handler to operate.

When the file is not found in the locate database, does nothing.

When in `dired-mode', stores a link to the file at point.
When visiting a file, delegates to `org-link--file-link-to-here'
to obtain the file path and search option (e.g. line number or
heading), then stores the link with that search option.

The stored link uses the shortest unique path suffix, which is the
basename when it uniquely identifies the file, or a longer
directory-qualified suffix when disambiguation is needed.  This
suffix is resolved at follow-time via the locate database."
  (when ol-locate-file-store-link-p
    (let ((type ol-locate-file-link-type))
      (cond
       ((derived-mode-p 'dired-mode)
        (when-let* ((path (dired-get-filename nil t))
                    (file (expand-file-name path))
                    (suffix (ol-locate-file--shortest-unique-suffix file)))
          (org-link-store-props
           :type type
           :link (concat type ":" suffix)
           :description nil)))
       ((buffer-file-name (buffer-base-buffer))
        (let* ((here (org-link--file-link-to-here))
               (raw-path (replace-regexp-in-string
                          "^file:" "" (car here)))
               (desc (cdr here))
               ;; Split off any search option suffix (::...)
               (path-search (split-string raw-path "::" t))
               (file-path (expand-file-name (car path-search)))
               (search-opt (cadr path-search))
               (suffix (ol-locate-file--shortest-unique-suffix file-path)))
          (when suffix
            (org-link-store-props
             :type type
             :link (concat type ":" suffix
                           (if search-opt (concat "::" search-opt) ""))
             :description desc))))
       (t
        nil)))))

;;; Complete handler

(defun ol-locate-file-complete-link (&optional _arg)
  "Complete an lfile: link using the locate database.

Works correctly with any completion style, including Orderless
\(which passes an empty string to the dynamic completion table)
and traditional styles like `basic', `partial-completion', etc.
\(which pass the actual minibuffer input)."
  (let* ((type ol-locate-file-link-type)
         (choice
          (completing-read
           (format "%s: " type)
           (completion-table-dynamic
            (lambda (str)
              (let ((input
                     (if (and (string-empty-p str)
                              (minibufferp))
                         ;; Support orderless which sends str as empty
                         (minibuffer-contents-no-properties)
                       str)))
                (if (string-empty-p input)
                    nil
                  (condition-case nil
                      (ol-locate-file--run-locate input)
                    (user-error nil))))))
           nil nil nil 'ol-locate-file--history)))
    (if (string-empty-p choice)
        (concat type ":")
      (concat type ":" (file-name-nondirectory choice)))))

;;; Link type registration

(defun ol-locate-file--register-link-parameters ()
  "Register link behavior via `org-link-set-parameters'.

Registers :follow, :store, and :complete for the link type and its
+emacs/+sys variants.  All link behavior is controlled through
these parameters alone — there is no `org-link-abbrev-alist'
involvement."
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
  "Set up the ol-locate-file link type."
  (ol-locate-file--register-link-parameters))

;;; Footer

(provide 'ol-locate-file)

;;; ol-locate-file.el ends here
