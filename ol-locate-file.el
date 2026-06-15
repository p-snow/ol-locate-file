;;; ol-locate-file.el --- Locate-based file links for Org mode -*- lexical-binding: t -*-

;; Copyright (C) 2026  Free Software Foundation, Inc.

;; Author: p-snow <public@p-snow.org>
;; Keywords: hypermedia, convenience
;; URL: https://github.com/p-snow/ol-locate-file
;; Package-Requires: ((emacs "30.1") (org "9.3"))
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
;;   - lfile:        => equivalent to file:        (find-file)
;;   - lfile+emacs:  => equivalent to file+emacs:  (find-file in Emacs)
;;   - lfile+sys:    => equivalent to file+sys:    (open with system app)
;;
;; The link type name (default "lfile") is customizable via
;; `org-locate-file-link-type'.
;;
;; When multiple files match the search substring, resolution follows
;; `org-locate-file-resolve-method', which may automatically pick the
;; first result, the most recently modified file, prompt the user, or
;; use a custom function.  Different methods can be specified for
;; follow vs. export (default: ask on follow, auto on export).
;;
;; The locate command is invoked via Emacs' built-in `locate-make-command-line'
;; by default.  The command line can be customized through the
;; `org-locate-file-locate-args' variable, which accepts a command prefix
;; string or a custom command builder function.
;;
;; Security: the package runs the locate command through `call-process'
;; rather than a shell, avoiding shell injection risks.

;;; Code:

(require 'ol)
(require 'org)
(require 'cl-lib)
(require 'locate)

(declare-function org-export-file-uri "ox" (filename))
(declare-function org-export-data-with-backend "ox" (data backend info))
(declare-function org-element-create "org-element-ast" (type &optional props &rest children))
(declare-function org-element-adopt "org-element-ast" (parent &rest children))

;;; Customization group

(defgroup org-locate-file nil
  "Locate-based file links for Org mode.
Uses the `locate' command (or compatible) to resolve partial
file path substrings into full absolute paths."
  :tag "Org Startup"
  :group 'org-link)

;;; Customizable options

(defcustom org-locate-file-link-type "lfile"
  "Default link type string for ol-locate-file.
Users can change this to any string to customize the link prefix
that appears in Org buffers.  Changing this value does not
retroactively update existing links."
  :type 'string
  :group 'org-locate-file)

(defcustom org-locate-file-max-results 500
  "Maximum number of locate results to collect.
Limiting results prevents performance issues when the search
substring is very short and matches many files."
  :type 'integer
  :group 'org-locate-file)

(defcustom org-locate-file-store-link-p t
  "Whether `org-locate-file-store-link' should store lfile: links.

When non-nil (the default), `org-store-link' stores an lfile: link
for the current file.  When nil, `org-locate-file-store-link' does
nothing, allowing the default file: link type to take effect.

Users who prefer file: links for storing but still want lfile:
links for existing Org documents can set this to nil."
  :type 'boolean
  :group 'org-locate-file)

(defcustom org-locate-file-resolve-method '((follow ask) (export auto))
  "How to resolve when multiple locate results match.

A flat value applies to both follow and export:
- `auto'   -- use the first locate result without confirmation.
- `recent' -- select the most recently modified file.
- `ask'    -- prompt the user via `completing-read'.
- A function -- called with candidate list, returns a file path.

An alist specifies different methods per context:
  ((follow METHOD) (export METHOD))
where METHOD is one of the values above.  Any missing context
falls back to `auto'.  Unrecognized values also fall back to
`auto'.

The default uses `ask' for follow (prompt the user) and `auto'
for export (first result, no prompting)."
  :type '(choice
          (const :tag "First result" auto)
          (const :tag "Most recently modified" recent)
          (const :tag "Prompt user" ask)
          (function :tag "Custom function")
          (repeat :tag "Context-specific alist"
                  (list (choice (const follow) (const export))
                        (choice (const :tag "First result" auto)
                                (const :tag "Most recently modified" recent)
                                (const :tag "Prompt user" ask)
                                (function :tag "Custom function")))))
  :group 'org-locate-file)

(defcustom org-locate-file-locate-args (default-value 'locate-make-command-line)
  "How to build the locate command line for a search pattern.

When nil, delegates to `locate-make-command-line' from Emacs'
built-in `locate.el'.

When a string, it should be the locate command and any fixed
options preceding the search pattern.  For example,
\"locate --ignore-case\" will invoke
\"locate --ignore-case PATTERN\" at the command line.

When a list of strings, each element is a command-line argument.
The search pattern is appended as the last element.  For example,
\(\"locate\" \"--ignore-case\") is equivalent to the string
\"locate --ignore-case\".

When a function, it is called with the search string as the sole
argument.  It may return:
- A list of strings (COMMAND ARGS...), the same convention as
  `locate-make-command-line', or
- A string, which is split into command and arguments via
  `split-string-and-unquote'."
  :type '(choice (const :tag "Default (locate-make-command-line)" nil)
                 (string :tag "Command prefix string")
                 (repeat :tag "Command argument list" string)
                 (function :tag "Function returning command line"))
  :group 'org-locate-file)

;;; Internal variables

(defvar org-locate-file--history nil
  "History list for `ol-locate-file' minibuffer completions.")

;; Install the link type

;; Register the main link type
(org-link-set-parameters
 org-locate-file-link-type
 :follow #'org-locate-file--follow
 :store #'org-locate-file-store-link
 :complete #'org-locate-file-complete-link
 :export #'org-locate-file--export
 :preview #'org-locate-file--preview)
;; Register lfile+emacs variant
(org-link-set-parameters
 (concat org-locate-file-link-type "+emacs")
 :follow #'org-locate-file--follow-emacs
 :store #'org-locate-file-store-link
 :export #'org-locate-file--export
 :preview #'org-locate-file--preview)
;; Register lfile+sys variant
(org-link-set-parameters
 (concat org-locate-file-link-type "+sys")
 :follow #'org-locate-file--follow-sys
 :store #'org-locate-file-store-link
 :export #'org-locate-file--export
 :preview #'org-locate-file--preview)

;;; Command construction

(defun org-locate-file--build-command (search-string)
  "Build the locate command line for SEARCH-STRING.
Returns a list of (COMMAND . ARGS) suitable for `call-process',
where COMMAND is the absolute path to the locate executable.
Signals `user-error' if the locate command cannot be found.

Uses `org-locate-file-locate-args' to determine how to build the
command line.  See that variable for details."
  (let* ((cmdline (cond
                   ((null org-locate-file-locate-args)
                    (funcall locate-make-command-line search-string))
                   ((functionp org-locate-file-locate-args)
                    (let ((result (funcall org-locate-file-locate-args
                                          search-string)))
                      (if (stringp result)
                          (split-string-and-unquote result)
                        result)))
                   ((stringp org-locate-file-locate-args)
                    (let ((parts (split-string-and-unquote
                                  org-locate-file-locate-args)))
                      (append parts (list search-string))))
                   ((consp org-locate-file-locate-args)
                    (append org-locate-file-locate-args
                            (list search-string)))
                   (t
                    (user-error "Invalid value for `org-locate-file-locate-args': %S"
                                org-locate-file-locate-args))))
         (cmd (car cmdline))
         (proc (executable-find cmd))
         (args (delq nil (cdr cmdline))))
    (unless proc
      (user-error "Cannot find locate command: %s" cmd))
    (cons proc args)))

;;; Locate execution

(defun org-locate-file--run-locate (search-string)
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
         (cmd-args (org-locate-file--build-command expanded))
         (cmd (car cmd-args))
         (args (cdr cmd-args))
         (max-results org-locate-file-max-results))
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

(defun org-locate-file--pick-recent (candidates)
  "Select the most recently modified file from CANDIDATES list.
Returns the file path with the latest modification time.
If modification times cannot be determined, falls back to
the first candidate."
  (let* ((pairs (mapcar
                 (lambda (f)
                   (cons f (file-attribute-modification-time
                            (file-attributes f))))
                 candidates))
         (valid (delq nil (mapcar
                           (lambda (p) (and (cdr p) p))
                           pairs))))
    (if valid
        (caar (sort valid (lambda (a b)
                            (time-less-p (cdr b) (cdr a)))))
      (car candidates))))

(defun org-locate-file--resolve-method (&optional context)
  "Return the effective resolve method for CONTEXT.
CONTEXT is `follow', `export', or nil.  When
`org-locate-file-resolve-method' is an alist, look up CONTEXT;
otherwise return the value directly.  Falls back to `auto' when
the alist has no entry for CONTEXT or the value is unrecognized."
  (let ((value org-locate-file-resolve-method))
    (if (and (consp value) (assq (or context 'follow) value))
         (let ((method (cadr (assq (or context 'follow) value))))
          (if (memq method '(auto recent ask))
              method
            (if (functionp method) method 'auto)))
      (if (memq value '(auto recent ask))
          value
        (if (functionp value) value 'auto)))))

(defun org-locate-file--resolve (search-string &optional context)
  "Resolve SEARCH-STRING to a single file path using locate.
CONTEXT is `follow' or `export', used when
`org-locate-file-resolve-method' is an alist.
When exactly one candidate matches, return it directly."
  (let* ((method (org-locate-file--resolve-method context))
         (candidates (org-locate-file--run-locate search-string)))
    (if (null (cdr candidates))
        (car candidates)
      (pcase method
        ((pred functionp)
         (funcall method candidates))
        ('recent
         (org-locate-file--pick-recent candidates))
        ('ask
         (let ((choice
                (completing-read
                 (format "Multiple matches for \"%s\" (choose one): "
                         search-string)
                 (lambda (string pred action)
                   (if (eq action 'metadata)
                       '(metadata
                         (display-sort-function . identity)
                         (cycle-sort-function . identity))
                     (complete-with-action action candidates string pred)))
                 nil t nil 'org-locate-file--history)))
           (if (string-empty-p choice)
               (user-error "No file selected")
             choice)))
        (_
         (car candidates))))))

;;; Follow handlers

(defun org-locate-file--follow (path _arg)
  "Follow an lfile: link by resolving PATH via locate and opening the file.
Equivalent to following a file: link with the resolved path.
ARG is the universal prefix argument (currently unused)."
  (org-locate-file--follow-impl path nil))

(defun org-locate-file--follow-emacs (path _arg)
  "Follow an lfile+emacs: link by resolving PATH and opening in Emacs.
Equivalent to following a file+emacs: link."
  (org-locate-file--follow-impl path 'emacs))

(defun org-locate-file--follow-sys (path _arg)
  "Follow an lfile+sys: link by resolving PATH and opening with system app.
Equivalent to following a file+sys: link."
  (org-locate-file--follow-impl path 'system))

(defun org-locate-file--follow-impl (path in-emacs)
  "Core follow implementation for all ol-locate-file link variants.

PATH is the raw link path, which may include a \"::search-option\"
suffix.  The search option is preserved and passed through to
`org-link-open-as-file'.

IN-EMACS is passed directly to `org-link-open-as-file' and
controls how the file is opened:
- nil       => use `org-file-apps' to decide
- `emacs'   => always open in Emacs
- `system'  => always open with system application"
  (let* ((search-option (and (string-match "::\\(.*\\)\\'" path)
                             (match-string 1 path)))
         (search-string (if search-option
                            (substring path 0 (match-beginning 0))
                          path))
         (resolved (org-locate-file--resolve search-string 'follow))
         (full-path (if search-option
                        (concat resolved "::" search-option)
                      resolved)))
    (org-link-open-as-file full-path in-emacs)))

;;; Export handler

(defun org-locate-file--export (path desc backend info)
  "Export an lfile: link.

Resolve PATH via locate and delegate export to the file: link type.
PATH is the link path, which may include a \"::search-option\"
suffix.  DESC is the description text or nil.  BACKEND is the
export backend symbol.  INFO is the communication channel plist.

When multiple files match, resolution follows
`org-locate-file-resolve-method' with context `export' (default:
auto, first result without prompting).  The resolved path is wrapped
in a `file:' link and transcoded via `org-export-data-with-backend',
so each backend applies its native file-link formatting.

Signals `user-error' when resolution fails; the original PATH is
returned as a fallback file URI."
  (let* ((search-option (and (string-match "::\\(.*\\)\\'" path)
                             (match-string 1 path)))
         (search-string (if search-option
                            (substring path 0 (match-beginning 0))
                          path)))
    (condition-case nil
        (let* ((resolved (org-locate-file--resolve search-string 'export))
               (full-path (if search-option
                              (concat resolved "::" search-option)
                            resolved))
               (link (org-element-create
                      'link
                      (list :type "file" :path full-path :format 'plain))))
          (when (org-string-nw-p desc)
            (org-element-adopt link desc))
          (org-export-data-with-backend link backend info))
      (user-error (org-export-file-uri path)))))

;;; Preview handler

(defun org-locate-file--preview (ov path link)
  "Preview an lfile: link image in overlay OV.
PATH is the link path (a locate substring) which may include a
\"::search-option\" suffix.  LINK is the Org element.

Resolves PATH via locate and delegates to `org-link-preview-file'.
Returns non-nil when a preview is displayed, nil otherwise."
  (condition-case nil
      (let* ((search-option (and (string-match "::\\(.*\\)\\'" path)
                                 (match-string 1 path)))
             (search-string (if search-option
                                (substring path 0 (match-beginning 0))
                              path))
             (resolved (let ((org-locate-file-resolve-method 'auto))
                         (org-locate-file--resolve search-string))))
        (org-link-preview-file ov resolved link))
    (user-error nil)))

;;; Store handler

(defun org-locate-file--shortest-unique-suffix (file-path)
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
        (let* ((results (org-locate-file--run-locate basename))
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
(defun org-locate-file-store-link ()
  "Store a link to the current file using the lfile link type.

When `org-locate-file-store-link-p' is nil, do nothing and
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
  (when org-locate-file-store-link-p
    (let ((type org-locate-file-link-type))
      (cond
       ((derived-mode-p 'dired-mode)
        (when-let* ((path (dired-get-filename nil t))
                    (file (expand-file-name path))
                    (suffix (org-locate-file--shortest-unique-suffix file)))
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
               (suffix (org-locate-file--shortest-unique-suffix file-path)))
          (when suffix
            (org-link-store-props
             :type type
             :link (concat type ":" suffix
                           (if search-opt (concat "::" search-opt) ""))
             :description desc))))
       (t
        nil)))))

;;; Complete handler

(defun org-locate-file-complete-link (&optional _arg)
  "Complete an lfile: link using the locate database.

Works correctly with any completion style, including Orderless
\(which passes an empty string to the dynamic completion table)
and traditional styles like `basic', `partial-completion', etc.
\(which pass the actual minibuffer input)."
  (let* ((type org-locate-file-link-type)
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
                  ;; Support multi-token input (Orderless etc.) by
                  ;; querying locate for each token individually and
                  ;; combining results.  This gives the completion
                  ;; style a broad candidate set to filter.
                  (let ((tokens (split-string input "[ \t]+" t)))
                    (if (cdr tokens)
                        (delete-dups
                         (cl-loop for token in tokens
                                  append (condition-case nil
                                             (org-locate-file--run-locate token)
                                           (user-error nil))))
                      (condition-case nil
                          (org-locate-file--run-locate input)
                        (user-error nil))))))))
           nil nil nil 'org-locate-file--history)))
    (if (string-empty-p choice)
        (concat type ":")
      (concat type ":" (file-name-nondirectory choice)))))

;;; Footer

(provide 'ol-locate-file)

;;; ol-locate-file.el ends here
