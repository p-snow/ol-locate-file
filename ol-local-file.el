;;; ol-local-file.el --- Org-mode link type for local file names -*- lexical-binding: t -*-

;; Author: p-snow
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1") (org "9.3"))
;; Homepage: https://github.com/p-snow/ol-local-file
;; Keywords: hypermedia, files, matching

;; This file is not part of GNU Emacs

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

;; Org-mode link type for local file names

;;; Code:

(require 'ol)
(require 'org-element)

(org-link-set-parameters "lfile"
                         :store #'ol-local-file-store-link)

(defvar ol-local-file-link-re
  (rx "["
      "[lfile" (opt (or "+emacs" "+sys")) ":"
      (group (minimal-match (1+ print))) "]"
      (opt "[" (0+ print) "]")
      "]")
  "Regular expression matching lfile any link.")

(defvar ol-local-file-locate-db nil)

(mapc (apply-partially 'add-to-list 'org-link-abbrev-alist)
      '(("lfile" . "file:%(ol-local-file-locate)")
        ("lfile+emacs" . "file+emacs:%(ol-local-file-locate)")
        ("lfile+sys" . "file+sys:%(ol-local-file-locate)")))

(defun ol-local-file-locate (tag)
  "Return a path found using TAG with locate program."
  (let* ((match-idx (string-match "^\\([^:]*\\)\\(::?\\(.*\\)\\)?$" tag))
         (link (if match-idx (match-string 1 tag) tag)))
    (concat (string-trim
             (shell-command-to-string
              (concat (format "plocate -d %s -e \"%s\" 2>/dev/null"
                              ol-local-file-locate-db
                              (shell-quote-argument link))
                      " | head --lines=1")))
            (when match-idx (match-string 2 tag)))))

(defun ol-local-file-store-link ()
  "Store a lfile link.

Prefix argument does matter in this function call.
If `C-u' prefix is given, file: link type will be used instead."
  (when (and (derived-mode-p 'dired-mode)
             (string-match-p
              (format "^%s" (expand-file-name "~"))
              (dired-current-directory nil)))
    (let ((path (dired-get-filename nil t)))
      (if (equal current-prefix-arg '(4))
          (org-link-store-props
           :type "file"
           :link (concat "file:" (abbreviate-file-name
                                  (expand-file-name path))))
        (org-link-store-props
         :type "lfile"
         :link (concat "lfile:" (file-name-nondirectory path)))))))

(defun ol-local-file-abbrev (raw-link &optional path-conv-fn)
  "Return an abbreviated lfile link from RAW-LINK.

RAW-LINK is supposed to be a file link type with a path and the path is
converted by `file-name-nondirectory' unless PATH-CONV-FN is supplied."
  (pcase-let ((`(,type . ,path)
               (let ((org-inhibit-startup nil)
                     (link (with-temp-buffer
                             (insert raw-link)
                             (org-mode)
                             (goto-char (point-min))
                             (org-element-link-parser))))
                 (cons (org-element-property :type link)
                       (org-element-property :path link)))))
    (cond ((string= type "file")
           (format "lfile:%s"
                   (funcall (if (functionp path-conv-fn)
                                path-conv-fn #'file-name-nondirectory)
                            path)))
          ((stringp type)
           raw-link)
          (t nil))))

(provide 'ol-local-file)

;;; ol-local-file.el ends here
