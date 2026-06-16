# README.org作成とAGENTS.md更新

**Session ID:** ses_1450e9ddcffeCSoSdQbi1LNuC3
**Created:** 6/12/2026, 5:27:22 PM
**Updated:** 6/12/2026, 5:44:40 PM

---

## User

プロジェクトのREADMEを作成してください。Org形式で作成し、README.orgとします。AGENTS.mdに反映させてください。

内容は要点を押さえてあまり長く説明的になりすぎないようにします。もちろん言語は英語を使用します。

パッケージの簡単な説明
このorg-linkを使うと何ができるのか。実際にどんなリンク記述になるのかを例を交えて簡単に説明してください。

パッケージのインストール方法
use-packageを使った記述とソースをDL配置してrequireする記述の2パターンを提示します。
現在、パッケージはまだどのパッケージアーカイブにも掲載されていないので、use-packageでは、:ensureではなく:vcを使って記述してください。ただし将来的にはMELPAに提出予定であることも付け添えておいてください。

lfileリンクでサポートする動作
follow, store, completeをどのようにサポートするのかをそれぞれ簡単に説明してください。詳細な説明はdocstringなどに譲ります。

設定可能なカスタム変数の説明
各カスタム変数についての説明と必要であればこの変数を設定することで具体的にどんなことが制御可能かを記述してください。

その他の特記事項
ユーザが疑問にもちそうな事項について、現時点で書けることがあれば記載します。例えば::を使ったsearch optionが利用可能なこと、export時にはリンクはどう出力されるのか、などが書けるかと思います。

その他、記載する必要があると判断した内容を書いてみてください。

ライセンス
最後にライセンスについて記述してください。


---

## Assistant (Build · DeepSeek V4 Flash · 25.3s)

_Thinking:_

The user wants me to create a README.org file for the ol-locate-file project and update AGENTS.md to reference it. Let me first understand the project by reading the source code and existing docs.

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file</path>
<type>directory</type>
<entries>
.git/
AGENTS.md
docs/
LICENSE
notes.org
ol-locate-file.el
ol-locate-file.elc
ol-locate-file.eln
sessions/

(9 entries)
</entries>
```

---

## Assistant (Build · DeepSeek V4 Flash · 3.4s)

_Thinking:_

Let me read the main source file and the docs to understand the project fully before creating the README.

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/ol-locate-file.el"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/ol-locate-file.el</path>
<type>file</type>
<content>
1: ;;; ol-locate-file.el --- Locate-based file links for Org mode -*- lexical-binding: t -*-
2: 
3: ;; Copyright (C) 2026  Free Software Foundation, Inc.
4: 
5: ;; Author: p-snow
6: ;; Keywords: hypermedia, convenience
7: ;; URL: https://github.com/p-snow/ol-locate-file
8: ;; Package-Requires: ((emacs "30.1") (org "9.3"))
9: ;; Version: 0.0.1
10: 
11: ;; This file is NOT part of GNU Emacs.
12: 
13: ;; This program is free software: you can redistribute it and/or modify
14: ;; it under the terms of the GNU General Public License as published by
15: ;; the Free Software Foundation, either version 3 of the License, or
16: ;; (at your option) any later version.
17: 
18: ;; This program is distributed in the hope that it will be useful,
19: ;; but WITHOUT ANY WARRANTY; without even the implied warranty of
20: ;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
21: ;; GNU General Public License for more details.
22: 
23: ;; You should have received a copy of the GNU General Public License
24: ;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
25: 
26: ;;; Commentary:
27: 
28: ;; This package provides a new Org link type that resolves partial
29: ;; file path substrings into full paths using the `locate' command.
30: ;;
31: ;; With this package, instead of writing a full absolute path:
32: ;;
33: ;;     [[file:/usr/bin/emacsclient][emacsclient]]
34: ;;
35: ;; you can write just a distinctive substring:
36: ;;
37: ;;     [[lfile:emacsclient][emacsclient]]
38: ;;
39: ;; The package opens the resolved file as if it were a regular
40: ;; `file:' link.  Three variants are provided:
41: ;;
42: ;;   - lfile:        → equivalent to file:        (find-file)
43: ;;   - lfile+emacs:  → equivalent to file+emacs:  (find-file in Emacs)
44: ;;   - lfile+sys:    → equivalent to file+sys:    (open with system app)
45: ;;
46: ;; The link type name (default "lfile") is customizable via
47: ;; `org-locate-file-link-type'.
48: ;;
49: ;; When multiple files match the search substring, the user is
50: ;; prompted with `completing-read' to select the intended target.
51: ;; This behavior can be customized via
52: ;; `org-locate-file-follow-auto', which supports automatic selection
53: ;; (first result, most recently modified, or a custom function).
54: ;;
55: ;; The locate command is invoked via Emacs' built-in `locate-make-command-line'
56: ;; by default.  The command line can be customized through the
57: ;; `org-locate-file-locate-args' variable, which accepts a command prefix
58: ;; string or a custom command builder function.
59: ;;
60: ;; Security: the package runs the locate command through `call-process'
61: ;; rather than a shell, avoiding shell injection risks.
62: 
63: ;;; Code:
64: 
65: (require 'ol)
66: (require 'org)
67: (require 'cl-lib)
68: (require 'locate)
69: 
70: ;;; Customization group
71: 
72: (defgroup org-locate-file nil
73:   "Locate-based file links for Org mode.
74: Uses the `locate' command (or compatible) to resolve partial
75: file path substrings into full absolute paths."
76:   :tag "Org Startup"
77:   :group 'org-link)
78: 
79: ;;; Customizable options
80: 
81: (defcustom org-locate-file-link-type "lfile"
82:   "Default link type string for ol-locate-file.
83: Users can change this to any string to customize the link prefix
84: that appears in Org buffers.  Changing this value does not
85: retroactively update existing links."
86:   :type 'string
87:   :group 'org-locate-file)
88: 
89: (defcustom org-locate-file-max-results 500
90:   "Maximum number of locate results to collect.
91: Limiting results prevents performance issues when the search
92: substring is very short and matches many files."
93:   :type 'integer
94:   :group 'org-locate-file)
95: 
96: (defcustom org-locate-file-store-link-p t
97:   "Whether `org-locate-file-store-link' should store lfile: links.
98: 
99: When non-nil (the default), `org-store-link' stores an lfile: link
100: for the current file.  When nil, `org-locate-file-store-link' does
101: nothing, allowing the default file: link type to take effect.
102: 
103: Users who prefer file: links for storing but still want lfile:
104: links for existing Org documents can set this to nil."
105:   :type 'boolean
106:   :group 'org-locate-file)
107: 
108: (defcustom org-locate-file-follow-auto nil
109:   "How to automatically select a candidate when multiple files match.
110: 
111: When nil (the default), the user is prompted to choose from the
112: matching candidates via `completing-read'.
113: 
114: When t, the first candidate from locate output is used without
115: confirmation.
116: 
117: When the symbol `recent', the candidate with the most recent
118: modification time is selected among the matching files.
119: 
120: When a function, it is called with the list of candidate file
121: paths and must return a single file path string."
122:   :type '(choice (const :tag "Prompt user" nil)
123:                  (const :tag "First result" t)
124:                  (const :tag "Most recently modified" recent)
125:                  (function :tag "Custom function"))
126:   :group 'org-locate-file)
127: 
128: (defcustom org-locate-file-locate-args (default-value 'locate-make-command-line)
129:   "How to build the locate command line for a search pattern.
130: 
131: When nil, delegates to `locate-make-command-line' from Emacs'
132: built-in `locate.el'.
133: 
134: When a string, it should be the locate command and any fixed
135: options preceding the search pattern.  For example,
136: \"locate --ignore-case\" will invoke
137: \"locate --ignore-case PATTERN\" at the command line.
138: 
139: When a list of strings, each element is a command-line argument.
140: The search pattern is appended as the last element.  For example,
141: \(\"locate\" \"--ignore-case\") is equivalent to the string
142: \"locate --ignore-case\".
143: 
144: When a function, it is called with the search string as the sole
145: argument.  It may return:
146: - A list of strings (COMMAND ARGS...), the same convention as
147:   `locate-make-command-line', or
148: - A string, which is split into command and arguments via
149:   `split-string-and-unquote'."
150:   :type '(choice (const :tag "Default (locate-make-command-line)" nil)
151:                  (string :tag "Command prefix string")
152:                  (repeat :tag "Command argument list" string)
153:                  (function :tag "Function returning command line"))
154:   :group 'org-locate-file)
155: 
156: ;;; Internal variables
157: 
158: (defvar org-locate-file--history nil
159:   "History list for `ol-locate-file' minibuffer completions.")
160: 
161: ;; Install the link type
162: 
163: ;; Register the main link type
164: (org-link-set-parameters
165:  org-locate-file-link-type
166:  :follow #'org-locate-file--follow
167:  :store #'org-locate-file-store-link
168:  :complete #'org-locate-file-complete-link)
169: ;; Register lfile+emacs variant
170: (org-link-set-parameters
171:  (concat org-locate-file-link-type "+emacs")
172:  :follow #'org-locate-file--follow-emacs
173:  :store #'org-locate-file-store-link)
174: ;; Register lfile+sys variant
175: (org-link-set-parameters
176:  (concat org-locate-file-link-type "+sys")
177:  :follow #'org-locate-file--follow-sys
178:  :store #'org-locate-file-store-link)
179: 
180: ;;; Command construction
181: 
182: (defun org-locate-file--build-command (search-string)
183:   "Build the locate command line for SEARCH-STRING.
184: Returns a list of (COMMAND . ARGS) suitable for `call-process',
185: where COMMAND is the absolute path to the locate executable.
186: Signals `user-error' if the locate command cannot be found.
187: 
188: Uses `org-locate-file-locate-args' to determine how to build the
189: command line.  See that variable for details."
190:   (let* ((cmdline (cond
191:                    ((null org-locate-file-locate-args)
192:                     (funcall locate-make-command-line search-string))
193:                    ((functionp org-locate-file-locate-args)
194:                     (let ((result (funcall org-locate-file-locate-args
195:                                           search-string)))
196:                       (if (stringp result)
197:                           (split-string-and-unquote result)
198:                         result)))
199:                    ((stringp org-locate-file-locate-args)
200:                     (let ((parts (split-string-and-unquote
201:                                   org-locate-file-locate-args)))
202:                       (append parts (list search-string))))
203:                    ((consp org-locate-file-locate-args)
204:                     (append org-locate-file-locate-args
205:                             (list search-string)))
206:                    (t
207:                     (user-error "Invalid value for `org-locate-file-locate-args': %S"
208:                                 org-locate-file-locate-args))))
209:          (cmd (car cmdline))
210:          (proc (executable-find cmd))
211:          (args (delq nil (cdr cmdline))))
212:     (unless proc
213:       (user-error "Cannot find locate command: %s" cmd))
214:     (cons proc args)))
215: 
216: ;;; Locate execution
217: 
218: (defun org-locate-file--run-locate (search-string)
219:   "Run the locate command for SEARCH-STRING.
220: Returns a list of absolute file paths matching SEARCH-STRING.
221: If no results are found, signals `user-error'.
222: 
223: SEARCH-STRING is expanded via `substitute-in-file-name' before
224: being passed to locate, so `~' and `$VAR' references are resolved
225: to their absolute equivalents.
226: 
227: The command is executed via `call-process' to avoid shell
228: injection risks.  No shell metacharacters are interpreted."
229:   (when (string-empty-p search-string)
230:     (user-error "Empty search string; please provide a substring to search for"))
231:   (let* ((expanded (substitute-in-file-name search-string))
232:          (cmd-args (org-locate-file--build-command expanded))
233:          (cmd (car cmd-args))
234:          (args (cdr cmd-args))
235:          (max-results org-locate-file-max-results))
236:     (with-temp-buffer
237:       (let ((_exit-code (apply #'call-process cmd nil
238:                                (list (current-buffer) nil) nil args)))
239:         ;; Note: `locate' may exit non-zero when there are no matches;
240:         ;; we treat an empty output buffer as "no matches" regardless
241:         ;; of exit code.
242:         (goto-char (point-min))
243:         (let ((results nil)
244:               (count 0))
245:           (while (and (not (eobp))
246:                       (or (null max-results) (< count max-results)))
247:             (let ((line (string-trim
248:                          (buffer-substring-no-properties
249:                           (line-beginning-position)
250:                           (line-end-position)))))
251:               (unless (string-empty-p line)
252:                 (push line results)
253:                 (cl-incf count)))
254:             (forward-line 1))
255:           (if results
256:               (nreverse (delete-dups results))
257:             (user-error "No file matching \"%s\" found in locate database"
258:                         search-string)))))))
259: 
260: ;;; Path resolution engine
261: 
262: (defun org-locate-file--pick-recent (candidates)
263:   "Select the most recently modified file from CANDIDATES list.
264: Returns the file path with the latest modification time.
265: If modification times cannot be determined, falls back to
266: the first candidate."
267:   (let* ((pairs (mapcar
268:                  (lambda (f)
269:                    (cons f (file-attribute-modification-time
270:                             (file-attributes f))))
271:                  candidates))
272:          (valid (delq nil (mapcar
273:                            (lambda (p) (and (cdr p) p))
274:                            pairs))))
275:     (if valid
276:         (caar (sort valid (lambda (a b)
277:                             (time-less-p (cdr b) (cdr a)))))
278:       (car candidates))))
279: 
280: (defun org-locate-file--resolve (search-string)
281:   "Resolve SEARCH-STRING to a single file path using locate.
282: When multiple files match and `org-locate-file-follow-auto' is
283: nil, prompt the user via `completing-read'.  Otherwise, select
284: automatically based on the value of that variable.
285: When exactly one matches, return it directly."
286:   (let ((candidates (org-locate-file--run-locate search-string)))
287:     (if (null (cdr candidates))
288:         (car candidates)
289:       (pcase org-locate-file-follow-auto
290:         ((pred functionp)
291:          (funcall org-locate-file-follow-auto candidates))
292:         ('recent
293:          (org-locate-file--pick-recent candidates))
294:         ((pred identity)
295:          (car candidates))
296:         (_
297:          (let ((choice
298:                 (completing-read
299:                  (format "Multiple matches for \"%s\" (choose one): "
300:                          search-string)
301:                  (lambda (string pred action)
302:                    (if (eq action 'metadata)
303:                        '(metadata
304:                          (display-sort-function . identity)
305:                          (cycle-sort-function . identity))
306:                      (complete-with-action action candidates string pred)))
307:                  nil t nil 'org-locate-file--history)))
308:            (if (string-empty-p choice)
309:                (user-error "No file selected")
310:              choice)))))))
311: 
312: ;;; Follow handlers
313: 
314: (defun org-locate-file--follow (path _arg)
315:   "Follow an lfile: link by resolving PATH via locate and opening the file.
316: Equivalent to following a file: link with the resolved path.
317: ARG is the universal prefix argument (currently unused)."
318:   (org-locate-file--follow-impl path nil))
319: 
320: (defun org-locate-file--follow-emacs (path _arg)
321:   "Follow an lfile+emacs: link by resolving PATH and opening in Emacs.
322: Equivalent to following a file+emacs: link."
323:   (org-locate-file--follow-impl path 'emacs))
324: 
325: (defun org-locate-file--follow-sys (path _arg)
326:   "Follow an lfile+sys: link by resolving PATH and opening with system app.
327: Equivalent to following a file+sys: link."
328:   (org-locate-file--follow-impl path 'system))
329: 
330: (defun org-locate-file--follow-impl (path in-emacs)
331:   "Core follow implementation for all ol-locate-file link variants.
332: 
333: PATH is the raw link path, which may include a \"::search-option\"
334: suffix.  The search option is preserved and passed through to
335: `org-link-open-as-file'.
336: 
337: IN-EMACS is passed directly to `org-link-open-as-file' and
338: controls how the file is opened:
339: - nil       → use `org-file-apps' to decide
340: - `emacs'   → always open in Emacs
341: - `system'  → always open with system application"
342:   (let* ((search-option (and (string-match "::\\(.*\\)\\'" path)
343:                              (match-string 1 path)))
344:          (search-string (if search-option
345:                             (substring path 0 (match-beginning 0))
346:                           path))
347:          (resolved (org-locate-file--resolve search-string))
348:          (full-path (if search-option
349:                         (concat resolved "::" search-option)
350:                       resolved)))
351:     (org-link-open-as-file full-path in-emacs)))
352: 
353: ;;; Store handler
354: 
355: (defun org-locate-file--shortest-unique-suffix (file-path)
356:   "Compute the shortest unique suffix of FILE-PATH among locate results.
357: 
358: Run locate with the basename of FILE-PATH, collect all matches,
359: and return the shortest suffix (from the end of the path components)
360: that uniquely identifies FILE-PATH among those matches.
361: 
362: When exactly one result matches the basename, return just the
363: basename.  When multiple results match, prepend directory components
364: from the parent upward until the suffix is unique.
365: 
366: Return nil if FILE-PATH is not found in the locate database."
367:   (let ((basename (file-name-nondirectory file-path)))
368:     (condition-case nil
369:         (let* ((results (org-locate-file--run-locate basename))
370:                (count (length results)))
371:           (when (member file-path results)
372:             (if (= 1 count)
373:                 basename
374:               (let* ((dir (file-name-directory file-path))
375:                      (components (when dir
376:                                    (split-string
377:                                     (directory-file-name dir) "/" t)))
378:                      (suffix basename))
379:                 (cl-loop for comp in (nreverse components)
380:                          do (setq suffix (concat comp "/" suffix))
381:                          when (= 1
382:                                  (cl-count-if
383:                                   (lambda (r)
384:                                     (string-suffix-p suffix r))
385:                                   results))
386:                          return suffix
387:                          finally return suffix)))))
388:       (user-error nil))))
389: 
390: ;;;###autoload
391: (defun org-locate-file-store-link ()
392:   "Store a link to the current file using the lfile link type.
393: 
394: When `org-locate-file-store-link-p' is nil, do nothing and
395: return nil, allowing the default file: link handler to operate.
396: 
397: When the file is not found in the locate database, does nothing.
398: 
399: When in `dired-mode', stores a link to the file at point.
400: When visiting a file, delegates to `org-link--file-link-to-here'
401: to obtain the file path and search option (e.g. line number or
402: heading), then stores the link with that search option.
403: 
404: The stored link uses the shortest unique path suffix, which is the
405: basename when it uniquely identifies the file, or a longer
406: directory-qualified suffix when disambiguation is needed.  This
407: suffix is resolved at follow-time via the locate database."
408:   (when org-locate-file-store-link-p
409:     (let ((type org-locate-file-link-type))
410:       (cond
411:        ((derived-mode-p 'dired-mode)
412:         (when-let* ((path (dired-get-filename nil t))
413:                     (file (expand-file-name path))
414:                     (suffix (org-locate-file--shortest-unique-suffix file)))
415:           (org-link-store-props
416:            :type type
417:            :link (concat type ":" suffix)
418:            :description nil)))
419:        ((buffer-file-name (buffer-base-buffer))
420:         (let* ((here (org-link--file-link-to-here))
421:                (raw-path (replace-regexp-in-string
422:                           "^file:" "" (car here)))
423:                (desc (cdr here))
424:                ;; Split off any search option suffix (::...)
425:                (path-search (split-string raw-path "::" t))
426:                (file-path (expand-file-name (car path-search)))
427:                (search-opt (cadr path-search))
428:                (suffix (org-locate-file--shortest-unique-suffix file-path)))
429:           (when suffix
430:             (org-link-store-props
431:              :type type
432:              :link (concat type ":" suffix
433:                            (if search-opt (concat "::" search-opt) ""))
434:              :description desc))))
435:        (t
436:         nil)))))
437: 
438: ;;; Complete handler
439: 
440: (defun org-locate-file-complete-link (&optional _arg)
441:   "Complete an lfile: link using the locate database.
442: 
443: Works correctly with any completion style, including Orderless
444: \(which passes an empty string to the dynamic completion table)
445: and traditional styles like `basic', `partial-completion', etc.
446: \(which pass the actual minibuffer input)."
447:   (let* ((type org-locate-file-link-type)
448:          (choice
449:           (completing-read
450:            (format "%s: " type)
451:            (completion-table-dynamic
452:             (lambda (str)
453:               (let ((input
454:                      (if (and (string-empty-p str)
455:                               (minibufferp))
456:                          ;; Support orderless which sends str as empty
457:                          (minibuffer-contents-no-properties)
458:                        str)))
459:                 (if (string-empty-p input)
460:                     nil
461:                   ;; Support multi-token input (Orderless etc.) by
462:                   ;; querying locate for each token individually and
463:                   ;; combining results.  This gives the completion
464:                   ;; style a broad candidate set to filter.
465:                   (let ((tokens (split-string input "[ \t]+" t)))
466:                     (if (cdr tokens)
467:                         (delete-dups
468:                          (cl-loop for token in tokens
469:                                   append (condition-case nil
470:                                              (org-locate-file--run-locate token)
471:                                            (user-error nil))))
472:                       (condition-case nil
473:                           (org-locate-file--run-locate input)
474:                         (user-error nil))))))))
475:            nil nil nil 'org-locate-file--history)))
476:     (if (string-empty-p choice)
477:         (concat type ":")
478:       (concat type ":" (file-name-nondirectory choice)))))
479: 
480: ;;; Footer
481: 
482: (provide 'ol-locate-file)
483: 
484: ;;; ol-locate-file.el ends here

(End of file - total 484 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs</path>
<type>directory</type>
<entries>
complete.md
complete.org
follow.md
store.md

(4 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/AGENTS.md"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/AGENTS.md</path>
<type>file</type>
<content>
1: # AGENTS.md — AI Development Guide for Emacs Packages
2: 
3: This document provides conventions, practices, and reference
4: information for AI-assisted development of Emacs Lisp packages,
5: with specific guidance for the `ol-locate-file` project.
6: 
7: ## 0. Documentation Policy
8: 
9: - **`docs/` directory**: All feature-specific behavior designs, redesign
10:   notes, and detailed explanations must be documented in separate files
11:   under `docs/` (e.g., `docs/follow.md`, `docs/store.md`,
12:   `docs/complete.md`).  Do **not** write design details in `AGENTS.md`.
13: - **`AGENTS.md`**: Reserved exclusively for coding conventions,
14:   submission requirements, reference material, and project-wide
15:   guidance.  No feature-specific design or behavior descriptions belong
16:   here.
17: - When a new design or behavior change is discussed, always create or
18:   update the corresponding file under `docs/`.  `AGENTS.md` may only
19:   briefly note such changes when they affect a convention or reference
20:   entry.
21: 
22: ## 1. Emacs Lisp Coding Conventions
23: 
24: ### 1.1 Naming Rules
25: 
26: - **Prefix**: All symbols (functions, variables, macros, faces) must
27:   use a package-specific prefix.  For `ol-locate-file`, use
28:   `org-locate-file-` for public symbols and `org-locate-file--` for
29:   private (internal) symbols (double hyphen convention).
30: - **Package/File vs Prefix**: The package name and file name
31:   (`ol-locate-file`) follow the `ol-xxx.el` convention used by
32:   Org-bundled link packages, but the symbol prefix is
33:   `org-locate-file-` (not `ol-locate-file-`), matching the
34:   `org-xxx-` convention that those same packages use for symbols.
35: - **Hyphenation**: Use hyphens (`-`) to separate words in symbol
36:   names.  Never use underscores or camelCase.
37:   - Good: `org-locate-file-link-type`
38:   - Bad: `ol_locate_file_link_type`, `olLocateFileLinkType`
39: 
40: ### 1.2 Documentation Strings (Docstrings)
41: 
42: - The first line of a docstring must be a single, complete sentence
43:   that summarizes what the function/variable does.
44: - Follow with a blank line, then additional details.
45: - For functions, document each parameter.  Use uppercase parameter
46:   names in prose (e.g., "PATH is the file path...").
47: - End sentences with a period.
48: - Docstrings go immediately after `defun`/`defvar`/`defcustom`, before
49:   any body forms.
50: 
51: Example:
52: #+end_srcelisp
53: (defun org-locate-file--resolve (search-string)
54:   "Resolve SEARCH-STRING to a single file path using locate.
55: 
56: When multiple files match, prompt the user via =completing-read'.
57: When exactly one matches, return it directly."
58:   ...)
59: ```
60: 
61: ### 1.3 Commentary Section
62: 
63: - After the license block, include a =;;; Commentary:= section.
64: - Describe what the package does, how to use it, and any setup
65:   instructions.
66: - Keep it concise but informative.
67: 
68: ### 1.4 Provide Form
69: 
70: - The =(provide 'ol-locate-file)= form must be the last executable
71:   expression in the file, preceded only by footer comments.
72: - The standard footer is: =;;; ol-locate-file.el ends here=
73: 
74: ### 1.5 Lexical Binding
75: 
76: - Always use =-*- lexical-binding: t -*-= on the first line.
77: - This is required for modern Emacs (27+) and is expected by MELPA.
78: 
79: ### 1.6 Line Length
80: 
81: - Keep lines to 80 characters or fewer where practical.
82: - Docstrings, in particular, should wrap at 72–80 columns.
83: 
84: ---
85: 
86: ## 2. MELPA Submission Requirements
87: 
88: ### 2.1 Header Format
89: 
90: The first line must follow this exact format:
91: 
92: ```
93: ;;; package-name.el --- Short description (one line) -*- lexical-binding: t -*-
94: ```
95: 
96: ### 2.2 Package-Requires
97: 
98: - Declare only the minimum dependencies needed for the package to
99:   function.
100: - Format: =;; Package-Requires: ((emacs "30.1") (org "9.3"))=
101: - For =ol-locate-file=, the dependencies are =emacs= (for
102:   =call-process=, =completing-read=, =executable-find=, =string-trim=)
103:   and =org= (for =org-link-set-parameters=,
104:   =org-link-open-as-file=, =org-link--file-link-to-here=).
105: - Org 9.3+ is specified because =ol-locate-file= uses
106:   =org-link--file-link-to-here=, but this is subsumed by the Emacs
107:   30.1 requirement (which bundles a newer Org).
108: 
109: ### 2.3 License Declaration
110: 
111: - Use GPLv3+ as recommended by the Emacs community:
112:   ```
113:   ;; License: GPL-3.0-or-later
114:   ```
115: - Include the full GPL boilerplate in the file header.
116: - Provide a separate =LICENSE= file containing the full GPLv3 text.
117: 
118: ### 2.4 Autoload Cookies
119: 
120: - Use =;;;###autoload= before interactive entry points and key setup
121:   functions (e.g., =org-locate-file-setup=).
122: - Do NOT autoload internal functions.
123: 
124: ### 2.5 Optional Headers
125: 
126: - =URL=: Link to the project repository.
127: - =Homepage=: Link to documentation or project page.
128: - =Keywords=: Comma-separated list for package discovery:
129:   ```
130:   ;; Keywords: org, files, convenience
131:   ```
132: 
133: ---
134: 
135: ## 3. Quality Checks
136: 
137: Before release, verify that the package passes these checks:
138: 
139: ### 3.1 Byte Compilation
140: 
141: ```bash
142: emacs -Q --batch -L . -f batch-byte-compile ol-locate-file.el
143: ```
144: 
145: - Must produce **zero warnings and zero errors**.
146: - Common issues: unused variables (prefix with =_=), free variable
147:   references (add =defvar= stubs), undefined functions (add =require=
148:   or =declare-function=).
149: 
150: ### 3.2 Checkdoc
151: 
152: ```bash
153: emacs -Q --batch -l checkdoc -f checkdoc-file ol-locate-file.el
154: ```
155: 
156: - All docstring warnings must be addressed.
157: - Every =defun=, =defvar=, =defcustom= must have a docstring.
158: 
159: ### 3.3 Package-Lint
160: 
161: ```bash
162: emacs -Q --batch -l package-lint -f package-lint-batch-and-exit ol-locate-file.el
163: ```
164: 
165: - Address all lint warnings (incorrect headers, missing dependencies,
166:   etc.).
167: 
168: ---
169: 
170: ## 4. Package Structure
171: 
172: - **Single =.el= file**: The package should be contained in a single
173:   =.el= file that defines all symbols and sets up the link type.
174: - **README.md**: Provide a readme with usage examples, setup
175:   instructions, and customization options.
176: - **LICENSE**: Include the full GPLv3 license text.
177: 
178: ---
179: 
180: ## 5. =org-link-set-parameters= Reference
181: 
182: ### 5.1 Complete Property List
183: 
184: | Property              | Type             | Description |
185: |-----------------------|------------------|-------------|
186: | =:follow=             | function(2 args) | Called to open the link.  Receives PATH and ARG (prefix arg). |
187: | =:export=             | function(4 args) | Called during export.  Receives PATH, DESC, BACKEND, INFO. |
188: | =:store=              | function(0 args) | Called by =org-store-link=.  Should call =org-link-store-props=. |
189: | =:complete=           | function(0 args) | Called during =org-insert-link= completion for this type. |
190: | =:face=               | face or function | Face to display the link.  Function receives PATH. |
191: | =:help-echo=          | string or fn(3)  | Help-echo property.  Function receives WINDOW, OBJECT, POSITION. |
192: | =:keymap=             | keymap           | Active keymap when point is on the link.  Default: =org-mouse-map=. |
193: | =:mouse-face=         | face             | Face for mouse hover.  Default: =highlight=. |
194: | =:display=            | symbol           | =full= prevents folding in descriptive display. |
195: | =:activate-func=      | function(4 args) | Called after font-lock activation. |
196: | =:insert-description= | string or fn(2)  | Default description for =org-insert-link=. |
197: | =:preview=            | function(3 args) | Generate in-buffer preview overlay. |
198: | =:htmlize-link=       | fn or plist      | Htmlize link property.  Default: =(:uri "type:path")=. |
199: 
200: ### 5.2 =:follow= Function Signature
201: 
202: ```elisp
203: (defun my-follow-fn (path arg)
204:   "PATH is the link path string.  ARG is the prefix argument."
205:   ...)
206: ```
207: 
208: Note: The =:follow= function must accept **two arguments** (the
209: two-argument signature has been mandatory since Org 9.4).
210: 
211: ### 5.3 =:export= Function Signature
212: 
213: ```elisp
214: (defun my-export-fn (path desc backend info)
215:   "PATH is the link path.  DESC is the description or nil.
216: BACKEND is the export backend symbol.  INFO is the communication plist."
217:   ...)
218: ```
219: 
220: ---
221: 
222: ## 6. Minimum Supported Emacs Version
223: 
224: ### 6.1 Recommendation for =ol-locate-file=: **Emacs 30.1**
225: 
226: Rationale:
227: 
228: - =org-link--file-link-to-here= (used by the store handler) was
229:   introduced in Org 9.6, which ships with Emacs 29.1.  Emacs 30.1 is
230:   specified as the minimum to ensure mature availability of this
231:   internal API.
232: - **=lexical-binding: t= is fully stable** and widely used.
233: - **=when-let/= / =if-let/=** (subr-x) are available without extra
234:   setup.
235: - **=string-trim=** is available (introduced in Emacs 26.1).
236: - **=executable-find=** is stable and reliable.
237: - **Org 9.7+** is bundled (Emacs 30.1 ships with Org 9.7).
238: 
239: Emacs 29.1 would work but 30.1 is chosen as the baseline for broader
240: compatibility with the bundled Org version that includes a stable
241: =org-link--file-link-to-here=.
242: 
243: ---
244: 
245: ## 7. =ol-locate-file= Specific Guidance
246: 
247: ### 7.1 Link Type Registration Strategy
248: 
249: All link behavior is controlled exclusively through
250: `org-link-set-parameters`.  There is **no** use of
251: `org-link-abbrev-alist`.  The follow, store, and complete handlers
252: registered via `org-link-set-parameters` are the sole mechanism for
253: controlling `lfile:` link type behavior.
254: 
255: See `docs/follow.md`, `docs/store.md`, and `docs/complete.md` for
256: detailed design descriptions of each handler.
257: 
258: ### 7.2 =org-locate-file-locate-args= (Custom Variable)
259: 
260: `ol-locate-file` provides the customizable variable
261: `org-locate-file-locate-args` to control how the locate command
262: line is built:
263: 
264: - **Default value**: The current value of Emacs' built-in
265:   `locate-make-command-line` (which is a function that takes a
266:   search string and returns a command list).
267: - **When nil**: Delegates directly to `locate-make-command-line`.
268: - **When a string**: Used as the command prefix before the search
269:   pattern.  For example, `"locate --ignore-case"` causes the
270:   package to invoke `locate --ignore-case PATTERN`.
271: - **When a list of strings**: Each element is a command-line
272:   argument; the search pattern is appended as the last element.
273:   For example, `("locate" "--ignore-case")` is equivalent
274:   to the string `"locate --ignore-case"`.
275: - **When a function**: Takes the search string as sole argument.
276:   It may return either a command list `(COMMAND ARGS...)` (same
277:   convention as `locate-make-command-line`) or a string (which is
278:   then split via `split-string-and-unquote`).
279: 
280: There are no separate `org-locate-file-command` or
281: `org-locate-file-arguments` options.  Users who wish to customize
282: the locate command or its arguments should customize
283: `org-locate-file-locate-args` or the standard Emacs variables:
284: 
285: - `locate-command` (default: `"locate"`)
286: - `locate-make-command-line` (for full control over the command
287:   line construction)
288: - `locate-prompt-for-command` (additional options to pass)
289: 
290: Users who customize `locate-make-command-line` in their init files
291: will have those customizations automatically reflected in the
292: default value of `org-locate-file-locate-args` (via
293: `default-value`).
294: 
295: There is **no** `locate-db` variable in Emacs' built-in
296: `locate.el`.  Database selection is handled by the locate command
297: itself or by `locate-make-command-line`.
298: 
299: ### 7.3 Security
300: 
301: - **Always** use =call-process= (or =make-process=) for external
302:   command execution — never =shell-command= with user-supplied input.
303: - The locate search string is passed as a direct argument to
304:   =call-process=, which bypasses shell interpretation entirely.
305: 
306: ### 7.4 Session Files
307: 
308: - The default output directory for session files is =sessions/=.
309: 
310: ---
311: 
312: ## 8. References
313: 
314: - [Org Mode Manual: Adding Hyperlink Types](https://orgmode.org/manual/Adding-Hyperlink-Types.html)
315: - [GNU Emacs Manual: locate.el](https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired-and-Find.html)
316: - [MELPA Contributing Guide](https://melpa.org/#/contributing)
317: - [Emacs Lisp Style Guide](https://www.gnu.org/software/emacs/manual/html_node/elisp/Tips.html)
318: ```

(End of file - total 318 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash · 3.4s)

_Thinking:_

Now I have a good understanding of the project. Let me also read the docs files to get more context about the design details.

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/follow.md"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/follow.md</path>
<type>file</type>
<content>
1: # Follow Handlers
2: 
3: The follow handlers are called when the user opens an `lfile:` link
4: (via `org-open-at-point`, typically `C-c C-o`).  There are three
5: variants, each registered via `org-link-set-parameters`.
6: 
7: ## Variants
8: 
9: | Link Type       | Follow Function              | Effect |
10: |-----------------|------------------------------|--------|
11: | `lfile:PATH`    | `org-locate-file--follow`     | Opens resolved file using `org-file-apps` |
12: | `lfile+emacs:PATH` | `org-locate-file--follow-emacs` | Always opens in Emacs |
13: | `lfile+sys:PATH`   | `org-locate-file--follow-sys`   | Always opens with system application |
14: 
15: ## Resolution Flow
16: 
17: ```
18: User opens [[lfile:emacsclient::10]]
19:        │
20:        ▼
21: org-locate-file--follow("emacsclient::10", nil)
22:        │
23:        ▼
24: org-locate-file--follow-impl("emacsclient::10", nil)
25:        │
26:        ├── Extracts search option: "10"
27:        ├── Extracts search string: "emacsclient"
28:        │
29:        ▼
30: org-locate-file--resolve("emacsclient")
31:        │
32:        ├── org-locate-file--run-locate("emacsclient")
33: │   │
34:         │   ├── org-locate-file--build-command("emacsclient")
35:         │   │   ├── Uses org-locate-file-locate-args:
36:         │   │   │   • nil         → locate-make-command-line
37:         │   │   │   • string      → split prefix + ("emacsclient")
38:         │   │   │   • list        → append ("emacsclient")
39:         │   │   │   • function    → (funcall fn "emacsclient")
40:         │   │   │       → ("locate" "--regex" "emacsclient")
41:         │   │
42:         │   └── call-process("locate" ... "--regex" "emacsclient")
43:        │       → ("/usr/bin/emacsclient", "/usr/bin/emacs", ...)
44:        │
45:        ├── Single result → return "/usr/bin/emacsclient"
46:        └── Multiple results:
47:             ├── org-locate-file-follow-auto = nil  → completing-read
48:             ├── org-locate-file-follow-auto = t    → first result
49:             ├── org-locate-file-follow-auto = 'recent → most recent mtime
50:             └── org-locate-file-follow-auto = fn   → (funcall fn candidates)
51:        │
52:        ▼
53: org-link-open-as-file("/usr/bin/emacsclient::10", nil)
54:   → Opens file and jumps to line 10
55: ```
56: 
57: ## Design Notes
58: 
59: - The three variants (`lfile`, `lfile+emacs`, `lfile+sys`) mirror the
60:   standard `file`, `file+emacs`, and `file+sys` link types.  After
61:   resolving the path via locate, they all delegate to
62:   `org-link-open-as-file` with the appropriate `in-emacs` argument.
63: - PATH may include a search-option suffix (`::line`, `::#heading`,
64:   `::*target`) which is preserved through the resolution and passed
65:   to `org-link-open-as-file`.
66: - Because there is no `org-link-abbrev-alist` expansion, Org never
67:   rewrites the link text at parse time.  The link is always displayed
68:   as the original `lfile:` form, and resolution happens only at
69:   follow-time via the `:follow` handler.
70: - Each variant is registered as a separate link type (not as a
71:   parameter on a single type), which is required for Org to dispatch
72:   the correct follow function based on the link prefix.
73: - `org-locate-file-follow-auto` controls automatic candidate selection
74:   when multiple files match.  See the docstring of that variable for
75:   details on the possible values.

(End of file - total 75 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/store.md"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/store.md</path>
<type>file</type>
<content>
1: # Store Handler: `org-locate-file-store-link`
2: 
3: The store handler is called when the user invokes `org-store-link`
4: (typically `C-c l`).  It determines whether an `lfile:` link is
5: stored for the current file or buffer.
6: 
7: ## Customization: `org-locate-file-store-link-p`
8: 
9: This boolean option (default: `t`) controls whether the store
10: handler produces an `lfile:` link.
11: 
12: | Value | Behavior |
13: |-------|----------|
14: | `t` (default) | `org-store-link` stores an `lfile:` link for the current file |
15: | `nil` | `org-locate-file-store-link` does nothing, allowing the default `file:` link handler to operate normally |
16: 
17: Users who prefer `file:` links for storing but still want `lfile:`
18: links in existing Org documents can set this to `nil`:
19: 
20: ```elisp
21: (setq org-locate-file-store-link-p nil)
22: ```
23: 
24: ## Store Behavior (when the flag is non-nil)
25: 
26: Before storing a link, the handler verifies that the file exists
27: in the locate database by running locate with the file's basename.
28: If the file is not found, no `lfile:` link is stored (returns nil).
29: 
30: 1. **File-visiting buffer**: Calls `org-link--file-link-to-here` to
31:    obtain the file path and any search option (line number, Org
32:    heading `#name`, or `*target`).  If the file is found in the
33:    locate database, stores an `lfile:` link using the shortest unique
34:    path suffix (see "Link Suffix Disambiguation" below).  The
35:    description comes from `org-link--file-link-to-here` (e.g., an
36:    Org heading text).
37: 
38: 2. **Dired mode**: Uses `dired-get-filename` to get the file at
39:    point.  If the file is found in the locate database, stores an
40:    `lfile:` link using the shortest unique path suffix, with no
41:    description.
42: 
43: 3. **Other buffers**: Does nothing (returns nil), which lets Org's
44:    built-in store handlers work as usual.
45: 
46: ## Link Suffix Disambiguation
47: 
48: Instead of always using the bare basename, the handler computes the
49: **shortest unique suffix** of the file path among all files in the
50: locate database that share the same basename.
51: 
52: - When the basename is already unique, the stored link uses just the
53:   basename (e.g. `lfile:emacsclient`).
54: - When multiple files share the same basename, parent directory
55:   components are prepended one by one until the suffix is unique
56:   (e.g. `lfile:bin/emacsclient` or `lfile:local/bin/emacsclient`).
57: 
58: This ensures that following the stored link resolves to the correct
59: file without ambiguity, even when the same filename appears in
60: multiple locations.
61: 
62: ## Link Format
63: 
64: The stored link uses the shortest unique path suffix, so it looks
65: like `lfile:emacsclient` (when unique) or `lfile:bin/emacsclient`
66: (when disambiguation is needed).  The suffix is resolved at
67: follow-time via the locate database (see `org-locate-file--resolve`
68: and `org-locate-file--shortest-unique-suffix`).
69: 
70: When in a file-visiting buffer, the link may include a search option
71: suffix such as `lfile:foo.el::10` (line number) or
72: `lfile:foo.el::#heading` (Org heading), handled by
73: `org-link--file-link-to-here`.
74: 
75: ## Link Properties
76: 
77: When storing, the handler sets these properties via
78: `org-link-store-props`:
79: 
80: - `:type` — `org-locate-file-link-type` (default: `"lfile"`)
81: - `:link` — The `lfile:` URI (e.g. `"lfile:emacsclient"`,
82:   `"lfile:bin/emacsclient"`, or `"lfile:foo.el::10"`)
83: - `:description` — For file-visiting buffers, the description from
84:   `org-link--file-link-to-here` (e.g. an Org heading).  For dired
85:   buffers, `nil` (no description).
86: 
87: ## Registration
88: 
89: The store handler is registered for all three link variants
90: (`lfile`, `lfile+emacs`, `lfile+sys`) via `org-link-set-parameters`
91: in `org-locate-file--register-link-parameters`.

(End of file - total 91 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/complete.md"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/complete.md</path>
<type>file</type>
<content>
1: # Complete Handler: `org-locate-file-complete-link`
2: 
3: When the user invokes `org-insert-link` (typically `C-c C-l`) and
4: selects the `lfile:` link type (or whatever
5: `org-locate-file-link-type` is set to), the complete handler is
6: called to allow the user to choose a link target.
7: 
8: ## Behavior
9: 
10: 1. A single `completing-read` session opens in the minibuffer.
11: 
12: 2. As the user types, each keystroke triggers a fresh locate query
13:    via `completion-table-dynamic`.  The locate database is queried
14:    with whatever substring the user has entered so far, and the
15:    matching files are presented as completion candidates.
16: 
17: 3. Completion candidates are the **basenames** of matching files
18:    (via `file-name-nondirectory`), not the full absolute paths.
19:    This means:
20:    - The inserted link looks like `lfile:emacsclient` instead of
21:      `lfile:/usr/bin/emacsclient`.
22:    - The link is resolved again at follow-time via the locate
23:      database, so it remains valid even if the file moves (as long
24:      as the locate database is updated).
25: 
26: 4. If the locate query returns no results for the current input,
27:    the user's raw input is used as-is.  This allows typing a path
28:    that is not in the locate database.
29: 
30: 5. The history variable `org-locate-file--history` stores previously
31:    selected basenames for easy recall.
32: 
33: ## Example
34: 
35: ```
36: # User types "emacs" in the completing-read prompt.
37: # Locate returns: ["/usr/bin/emacsclient", "/usr/bin/emacs"]
38: # Candidates shown: "emacsclient", "emacs"
39: # User selects "emacsclient".
40: # Inserted link: [[lfile:emacsclient]]
41: ```
42: 
43: ## Design Notes
44: 
45: - The `:complete` handler is registered via `org-link-set-parameters`
46:   in `org-locate-file--register-link-parameters`.
47: - The dynamic table is constructed with `completion-table-dynamic`,
48:   which calls `org-locate-file--run-locate` on each completion
49:   request with the current minibuffer input.
50: - Only basenames are used so that links are concise and remain
51:   resolvable at follow-time regardless of the file's absolute path.

(End of file - total 51 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/LICENSE"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/LICENSE</path>
<type>file</type>
<content>
1:                     GNU GENERAL PUBLIC LICENSE
2:                        Version 3, 29 June 2007
3: 
4:  Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
5:  Everyone is permitted to copy and distribute verbatim copies
6:  of this license document, but changing it is not allowed.
7: 
8:                             Preamble
9: 
10:   The GNU General Public License is a free, copyleft license for
11: software and other kinds of works.
12: 
13:   The licenses for most software and other practical works are designed
14: to take away your freedom to share and change the works.  By contrast,
15: the GNU General Public License is intended to guarantee your freedom to
16: share and change all versions of a program--to make sure it remains free
17: software for all its users.  We, the Free Software Foundation, use the
18: GNU General Public License for most of our software; it applies also to
19: any other work released this way by its authors.  You can apply it to
20: your programs, too.
21: 
22:   When we speak of free software, we are referring to freedom, not
23: price.  Our General Public Licenses are designed to make sure that you
24: have the freedom to distribute copies of free software (and charge for
25: them if you wish), that you receive source code or can get it if you
26: want it, that you can change the software or use pieces of it in new
27: free programs, and that you know you can do these things.
28: 
29:   To protect your rights, we need to prevent others from denying you
30: these rights or asking you to surrender the rights.  Therefore, you have
31: certain responsibilities if you distribute copies of the software, or if
32: you modify it: responsibilities to respect the freedom of others.
33: 
34:   For example, if you distribute copies of such a program, whether
35: gratis or for a fee, you must pass on to the recipients the same
36: freedoms that you received.  You must make sure that they, too, receive
37: or can get the source code.  And you must show them these terms so they
38: know their rights.
39: 
40:   Developers that use the GNU GPL protect your rights with two steps:
41: (1) assert copyright on the software, and (2) offer you this License
42: giving you legal permission to copy, distribute and/or modify it.
43: 
44:   For the developers' and authors' protection, the GPL clearly explains
45: that there is no warranty for this free software.  For both users' and
46: authors' sake, the GPL requires that modified versions be marked as
47: changed, so that their problems will not be attributed erroneously to
48: authors of previous versions.
49: 
50:   Some devices are designed to deny users access to install or run
51: modified versions of the software inside them, although the manufacturer
52: can do so.  This is fundamentally incompatible with the aim of
53: protecting users' freedom to change the software.  The systematic
54: pattern of such abuse occurs in the area of products for individuals to
55: use, which is precisely where it is most unacceptable.  Therefore, we
56: have designed this version of the GPL to prohibit the practice for those
57: products.  If such problems arise substantially in other domains, we
58: stand ready to extend this provision to those domains in future versions
59: of the GPL, as needed to protect the freedom of users.
60: 
61:   Finally, every program is threatened constantly by software patents.
62: States should not allow patents to restrict development and use of
63: software on general-purpose computers, but in those that do, we wish to
64: avoid the special danger that patents applied to a free program could
65: make it effectively proprietary.  To prevent this, the GPL assures that
66: patents cannot be used to render the program non-free.
67: 
68:   The precise terms and conditions for copying, distribution and
69: modification follow.
70: 
71:                        TERMS AND CONDITIONS
72: 
73:   0. Definitions.
74: 
75:   "This License" refers to version 3 of the GNU General Public License.
76: 
77:   "Copyright" also means copyright-like laws that apply to other kinds of
78: works, such as semiconductor masks.
79: 
80:   "The Program" refers to any copyrightable work licensed under this
81: License.  Each licensee is addressed as "you".  "Licensees" and
82: "recipients" may be individuals or organizations.
83: 
84:   To "modify" a work means to copy from or adapt all or part of the work
85: in a fashion requiring copyright permission, other than the making of an
86: exact copy.  The resulting work is called a "modified version" of the
87: earlier work or a work "based on" the earlier work.
88: 
89:   A "covered work" means either the unmodified Program or a work based
90: on the Program.
91: 
92:   To "propagate" a work means to do anything with it that, without
93: permission, would make you directly or secondarily liable for
94: infringement under applicable copyright law, except executing it on a
95: computer or modifying a private copy.  Propagation includes copying,
96: distribution (with or without modification), making available to the
97: public, and in some countries other activities as well.
98: 
99:   To "convey" a work means any kind of propagation that enables other
100: parties to make or receive copies.  Mere interaction with a user through
101: a computer network, with no transfer of a copy, is not conveying.
102: 
103:   An interactive user interface displays "Appropriate Legal Notices"
104: to the extent that it includes a convenient and prominently visible
105: feature that (1) displays an appropriate copyright notice, and (2)
106: tells the user that there is no warranty for the work (except to the
107: extent that warranties are provided), that licensees may convey the
108: work under this License, and how to view a copy of this License.  If
109: the interface presents a list of user commands or options, such as a
110: menu, a prominent item in the list meets this criterion.
111: 
112:   1. Source Code.
113: 
114:   The "source code" for a work means the preferred form of the work
115: for making modifications to it.  "Object code" means any non-source
116: form of a work.
117: 
118:   A "Standard Interface" means an interface that either is an official
119: standard defined by a recognized standards body, or, in the case of
120: interfaces specified for a particular programming language, one that
121: is widely used among developers working in that language.
122: 
123:   The "System Libraries" of an executable work include anything, other
124: than the work as a whole, that (a) is included in the normal form of
125: packaging a Major Component, but which is not part of that Major
126: Component, and (b) serves only to enable use of the work with that
127: Major Component, or to implement a Standard Interface for which an
128: implementation is available to the public in source code form.  A
129: "Major Component", in this context, means a major essential component
130: (kernel, window system, and so on) of the specific operating system
131: (if any) on which the executable work runs, or a compiler used to
132: produce the work, or an object code interpreter used to run it.
133: 
134:   The "Corresponding Source" for a work in object code form means all
135: the source code needed to generate, install, and (for an executable
136: work) run the object code and to modify the work, including scripts to
137: control those activities.  However, it does not include the work's
138: System Libraries, or general-purpose tools or generally available free
139: programs which are used unmodified in performing those activities but
140: which are not part of the work.  For example, Corresponding Source
141: includes interface definition files associated with source files for
142: the work, and the source code for shared libraries and dynamically
143: linked subprograms that the work is specifically designed to require,
144: such as by intimate data communication or control flow between those
145: subprograms and other parts of the work.
146: 
147:   The Corresponding Source need not include anything that users
148: can regenerate automatically from other parts of the Corresponding
149: Source.
150: 
151:   The Corresponding Source for a work in source code form is that
152: same work.
153: 
154:   2. Basic Permissions.
155: 
156:   All rights granted under this License are granted for the term of
157: copyright on the Program, and are irrevocable provided the stated
158: conditions are met.  This License explicitly affirms your unlimited
159: permission to run the unmodified Program.  The output from running a
160: covered work is covered by this License only if the output, given its
161: content, constitutes a covered work.  This License acknowledges your
162: rights of fair use or other equivalent, as provided by copyright law.
163: 
164:   You may make, run and propagate covered works that you do not
165: convey, without conditions so long as your license otherwise remains
166: in force.  You may convey covered works to others for the sole purpose
167: of having them make modifications exclusively for you, or provide you
168: with facilities for running those works, provided that you comply with
169: the terms of this License in conveying all material for which you do
170: not control copyright.  Those thus making or running the covered works
171: for you must do so exclusively on your behalf, under your direction
172: and control, on terms that prohibit them from making any copies of
173: your copyrighted material outside their relationship with you.
174: 
175:   Conveying under any other circumstances is permitted solely under
176: the conditions stated below.  Sublicensing is not allowed; section 10
177: makes it unnecessary.
178: 
179:   3. Protecting Users' Legal Rights From Anti-Circumvention Law.
180: 
181:   No covered work shall be deemed part of an effective technological
182: measure under any applicable law fulfilling obligations under article
183: 11 of the WIPO copyright treaty adopted on 20 December 1996, or
184: similar laws prohibiting or restricting circumvention of such
185: measures.
186: 
187:   When you convey a covered work, you waive any legal power to forbid
188: circumvention of technological measures to the extent such circumvention
189: is effected by exercising rights under this License with respect to
190: the covered work, and you disclaim any intention to limit operation or
191: modification of the work as a means of enforcing, against the work's
192: users, your or third parties' legal rights to forbid circumvention of
193: technological measures.
194: 
195:   4. Conveying Verbatim Copies.
196: 
197:   You may convey verbatim copies of the Program's source code as you
198: receive it, in any medium, provided that you conspicuously and
199: appropriately publish on each copy an appropriate copyright notice;
200: keep intact all notices stating that this License and any
201: non-permissive terms added in accord with section 7 apply to the code;
202: keep intact all notices of the absence of any warranty; and give all
203: recipients a copy of this License along with the Program.
204: 
205:   You may charge any price or no price for each copy that you convey,
206: and you may offer support or warranty protection for a fee.
207: 
208:   5. Conveying Modified Source Versions.
209: 
210:   You may convey a work based on the Program, or the modifications to
211: produce it from the Program, in the form of source code under the
212: terms of section 4, provided that you also meet all of these conditions:
213: 
214:     a) The work must carry prominent notices stating that you modified
215:     it, and giving a relevant date.
216: 
217:     b) The work must carry prominent notices stating that it is
218:     released under this License and any conditions added under section
219:     7.  This requirement modifies the requirement in section 4 to
220:     "keep intact all notices".
221: 
222:     c) You must license the entire work, as a whole, under this
223:     License to anyone who comes into possession of a copy.  This
224:     License will therefore apply, along with any applicable section 7
225:     additional terms, to the whole of the work, and all its parts,
226:     regardless of how they are packaged.  This License gives no
227:     permission to license the work in any other way, but it does not
228:     invalidate such permission if you have separately received it.
229: 
230:     d) If the work has interactive user interfaces, each must display
231:     Appropriate Legal Notices; however, if the Program has interactive
232:     interfaces that do not display Appropriate Legal Notices, your
233:     work need not make them do so.
234: 
235:   A compilation of a covered work with other separate and independent
236: works, which are not by their nature extensions of the covered work,
237: and which are not combined with it such as to form a larger program,
238: in or on a volume of a storage or distribution medium, is called an
239: "aggregate" if the compilation and its resulting copyright are not
240: used to limit the access or legal rights of the compilation's users
241: beyond what the individual works permit.  Inclusion of a covered work
242: in an aggregate does not cause this License to apply to the other
243: parts of the aggregate.
244: 
245:   6. Conveying Non-Source Forms.
246: 
247:   You may convey a covered work in object code form under the terms
248: of sections 4 and 5, provided that you also convey the
249: machine-readable Corresponding Source under the terms of this License,
250: in one of these ways:
251: 
252:     a) Convey the object code in, or embodied in, a physical product
253:     (including a physical distribution medium), accompanied by the
254:     Corresponding Source fixed on a durable physical medium
255:     customarily used for software interchange.
256: 
257:     b) Convey the object code in, or embodied in, a physical product
258:     (including a physical distribution medium), accompanied by a
259:     written offer, valid for at least three years and valid for as
260:     long as you offer spare parts or customer support for that product
261:     model, to give anyone who possesses the object code either (1) a
262:     copy of the Corresponding Source for all the software in the
263:     product that is covered by this License, on a durable physical
264:     medium customarily used for software interchange, for a price no
265:     more than your reasonable cost of physically performing this
266:     conveying of source, or (2) access to copy the
267:     Corresponding Source from a network server at no charge.
268: 
269:     c) Convey individual copies of the object code with a copy of the
270:     written offer to provide the Corresponding Source.  This
271:     alternative is allowed only occasionally and noncommercially, and
272:     only if you received the object code with such an offer, in accord
273:     with subsection 6b.
274: 
275:     d) Convey the object code by offering access from a designated
276:     place (gratis or for a charge), and offer equivalent access to the
277:     Corresponding Source in the same way through the same place at no
278:     further charge.  You need not require recipients to copy the
279:     Corresponding Source along with the object code.  If the place to
280:     copy the object code is a network server, the Corresponding Source
281:     may be on a different server (operated by you or a third party)
282:     that supports equivalent copying facilities, provided you maintain
283:     clear directions next to the object code saying where to find the
284:     Corresponding Source.  Regardless of what server hosts the
285:     Corresponding Source, you remain obligated to ensure that it is
286:     available for as long as needed to satisfy these requirements.
287: 
288:     e) Convey the object code using peer-to-peer transmission, provided
289:     you inform other peers where the object code and Corresponding
290:     Source of the work are being offered to the general public at no
291:     charge under subsection 6d.
292: 
293:   A separable portion of the object code, whose source code is excluded
294: from the Corresponding Source as a System Library, need not be
295: included in conveying the object code work.
296: 
297:   A "User Product" is either (1) a "consumer product", which means any
298: tangible personal property which is normally used for personal, family,
299: or household purposes, or (2) anything designed or sold for incorporation
300: into a dwelling.  In determining whether a product is a consumer product,
301: doubtful cases shall be resolved in favor of coverage.  For a particular
302: product received by a particular user, "normally used" refers to a
303: typical or common use of that class of product, regardless of the status
304: of the particular user or of the way in which the particular user
305: actually uses, or expects or is expected to use, the product.  A product
306: is a consumer product regardless of whether the product has substantial
307: commercial, industrial or non-consumer uses, unless such uses represent
308: the only significant mode of use of the product.
309: 
310:   "Installation Information" for a User Product means any methods,
311: procedures, authorization keys, or other information required to install
312: and execute modified versions of a covered work in that User Product from
313: a modified version of its Corresponding Source.  The information must
314: suffice to ensure that the continued functioning of the modified object
315: code is in no case prevented or interfered with solely because
316: modification has been made.
317: 
318:   If you convey an object code work under this section in, or with, or
319: specifically for use in, a User Product, and the conveying occurs as
320: part of a transaction in which the right of possession and use of the
321: User Product is transferred to the recipient in perpetuity or for a
322: fixed term (regardless of how the transaction is characterized), the
323: Corresponding Source conveyed under this section must be accompanied
324: by the Installation Information.  But this requirement does not apply
325: if neither you nor any third party retains the ability to install
326: modified object code on the User Product (for example, the work has
327: been installed in ROM).
328: 
329:   The requirement to provide Installation Information does not include a
330: requirement to continue to provide support service, warranty, or updates
331: for a work that has been modified or installed by the recipient, or for
332: the User Product in which it has been modified or installed.  Access to a
333: network may be denied when the modification itself materially and
334: adversely affects the operation of the network or violates the rules and
335: protocols for communication across the network.
336: 
337:   Corresponding Source conveyed, and Installation Information provided,
338: in accord with this section must be in a format that is publicly
339: documented (and with an implementation available to the public in
340: source code form), and must require no special password or key for
341: unpacking, reading or copying.
342: 
343:   7. Additional Terms.
344: 
345:   "Additional permissions" are terms that supplement the terms of this
346: License by making exceptions from one or more of its conditions.
347: Additional permissions that are applicable to the entire Program shall
348: be treated as though they were included in this License, to the extent
349: that they are valid under applicable law.  If additional permissions
350: apply only to part of the Program, that part may be used separately
351: under those permissions, but the entire Program remains governed by
352: this License without regard to the additional permissions.
353: 
354:   When you convey a copy of a covered work, you may at your option
355: remove any additional permissions from that copy, or from any part of
356: it.  (Additional permissions may be written to require their own
357: removal in certain cases when you modify the work.)  You may place
358: additional permissions on material, added by you to a covered work,
359: for which you have or can give appropriate copyright permission.
360: 
361:   Notwithstanding any other provision of this License, for material you
362: add to a covered work, you may (if authorized by the copyright holders of
363: that material) supplement the terms of this License with terms:
364: 
365:     a) Disclaiming warranty or limiting liability differently from the
366:     terms of sections 15 and 16 of this License; or
367: 
368:     b) Requiring preservation of specified reasonable legal notices or
369:     author attributions in that material or in the Appropriate Legal
370:     Notices displayed by works containing it; or
371: 
372:     c) Prohibiting misrepresentation of the origin of that material, or
373:     requiring that modified versions of such material be marked in
374:     reasonable ways as different from the original version; or
375: 
376:     d) Limiting the use for publicity purposes of names of licensors or
377:     authors of the material; or
378: 
379:     e) Declining to grant rights under trademark law for use of some
380:     trade names, trademarks, or service marks; or
381: 
382:     f) Requiring indemnification of licensors and authors of that
383:     material by anyone who conveys the material (or modified versions of
384:     it) with contractual assumptions of liability to the recipient, for
385:     any liability that these contractual assumptions directly impose on
386:     those licensors and authors.
387: 
388:   All other non-permissive additional terms are considered "further
389: restrictions" within the meaning of section 10.  If the Program as you
390: received it, or any part of it, contains a notice stating that it is
391: governed by this License along with a term that is a further
392: restriction, you may remove that term.  If a license document contains
393: a further restriction but permits relicensing or conveying under this
394: License, you may add to a covered work material governed by the terms
395: of that license document, provided that the further restriction does
396: not survive such relicensing or conveying.
397: 
398:   If you add terms to a covered work in accord with this section, you
399: must place, in the relevant source files, a statement of the
400: additional terms that apply to those files, or a notice indicating
401: where to find the applicable terms.
402: 
403:   Additional terms, permissive or non-permissive, may be stated in the
404: form of a separately written license, or stated as exceptions;
405: the above requirements apply either way.
406: 
407:   8. Termination.
408: 
409:   You may not propagate or modify a covered work except as expressly
410: provided under this License.  Any attempt otherwise to propagate or
411: modify it is void, and will automatically terminate your rights under
412: this License (including any patent licenses granted under the third
413: paragraph of section 11).
414: 
415:   However, if you cease all violation of this License, then your
416: license from a particular copyright holder is reinstated (a)
417: provisionally, unless and until the copyright holder explicitly and
418: finally terminates your license, and (b) permanently, if the copyright
419: holder fails to notify you of the violation by some reasonable means
420: prior to 60 days after the cessation.
421: 
422:   Moreover, your license from a particular copyright holder is
423: reinstated permanently if the copyright holder notifies you of the
424: violation by some reasonable means, this is the first time you have
425: received notice of violation of this License (for any work) from that
426: copyright holder, and you cure the violation prior to 30 days after
427: your receipt of the notice.
428: 
429:   Termination of your rights under this section does not terminate the
430: licenses of parties who have received copies or rights from you under
431: this License.  If your rights have been terminated and not permanently
432: reinstated, you do not qualify to receive new licenses for the same
433: material under section 10.
434: 
435:   9. Acceptance Not Required for Having Copies.
436: 
437:   You are not required to accept this License in order to receive or
438: run a copy of the Program.  Ancillary propagation of a covered work
439: occurring solely as a consequence of using peer-to-peer transmission
440: to receive a copy likewise does not require acceptance.  However,
441: nothing other than this License grants you permission to propagate or
442: modify any covered work.  These actions infringe copyright if you do
443: not accept this License.  Therefore, by modifying or propagating a
444: covered work, you indicate your acceptance of this License to do so.
445: 
446:   10. Automatic Licensing of Downstream Recipients.
447: 
448:   Each time you convey a covered work, the recipient automatically
449: receives a license from the original licensors, to run, modify and
450: propagate that work, subject to this License.  You are not responsible
451: for enforcing compliance by third parties with this License.
452: 
453:   An "entity transaction" is a transaction transferring control of an
454: organization, or substantially all assets of one, or subdividing an
455: organization, or merging organizations.  If propagation of a covered
456: work results from an entity transaction, each party to that
457: transaction who receives a copy of the work also receives whatever
458: licenses to the work the party's predecessor in interest had or could
459: give under the previous paragraph, plus a right to possession of the
460: Corresponding Source of the work from the predecessor in interest, if
461: the predecessor has it or can get it with reasonable efforts.
462: 
463:   You may not impose any further restrictions on the exercise of the
464: rights granted or affirmed under this License.  For example, you may
465: not impose a license fee, royalty, or other charge for exercise of
466: rights granted under this License, and you may not initiate litigation
467: (including a cross-claim or counterclaim in a lawsuit) alleging that
468: any patent claim is infringed by making, using, selling, offering for
469: sale, or importing the Program or any portion of it.
470: 
471:   11. Patents.
472: 
473:   A "contributor" is a copyright holder who authorizes use under this
474: License of the Program or a work on which the Program is based.  The
475: work thus licensed is called the contributor's "contributor version".
476: 
477:   A contributor's "essential patent claims" are all patent claims
478: owned or controlled by the contributor, whether already acquired or
479: hereafter acquired, that would be infringed by some manner, permitted
480: by this License, of making, using, or selling its contributor version,
481: but do not include claims that would be infringed only as a
482: consequence of further modification of the contributor version.  For
483: purposes of this definition, "control" includes the right to grant
484: patent sublicenses in a manner consistent with the requirements of
485: this License.
486: 
487:   Each contributor grants you a non-exclusive, worldwide, royalty-free
488: patent license under the contributor's essential patent claims, to
489: make, use, sell, offer for sale, import and otherwise run, modify and
490: propagate the contents of its contributor version.
491: 
492:   In the following three paragraphs, a "patent license" is any express
493: agreement or commitment, however denominated, not to enforce a patent
494: (such as an express permission to practice a patent or covenant not to
495: sue for patent infringement).  To "grant" such a patent license to a
496: party means to make such an agreement or commitment not to enforce a
497: patent against the party.
498: 
499:   If you convey a covered work, knowingly relying on a patent license,
500: and the Corresponding Source of the work is not available for anyone
501: to copy, free of charge and under the terms of this License, through a
502: publicly available network server or other readily accessible means,
503: then you must either (1) cause the Corresponding Source to be so
504: available, or (2) arrange to deprive yourself of the benefit of the
505: patent license for this particular work, or (3) arrange, in a manner
506: consistent with the requirements of this License, to extend the patent
507: license to downstream recipients.  "Knowingly relying" means you have
508: actual knowledge that, but for the patent license, your conveying the
509: covered work in a country, or your recipient's use of the covered work
510: in a country, would infringe one or more identifiable patents in that
511: country that you have reason to believe are valid.
512: 
513:   If, pursuant to or in connection with a single transaction or
514: arrangement, you convey, or propagate by procuring conveyance of, a
515: covered work, and grant a patent license to some of the parties
516: receiving the covered work authorizing them to use, propagate, modify
517: or convey a specific copy of the covered work, then the patent license
518: you grant is automatically extended to all recipients of the covered
519: work and works based on it.
520: 
521:   A patent license is "discriminatory" if it does not include within
522: the scope of its coverage, prohibits the exercise of, or is
523: conditioned on the non-exercise of one or more of the rights that are
524: specifically granted under this License.  You may not convey a covered
525: work if you are a party to an arrangement with a third party that is
526: in the business of distributing software, under which you make payment
527: to the third party based on the extent of your activity of conveying
528: the work, and under which the third party grants, to any of the
529: parties who would receive the covered work from you, a discriminatory
530: patent license (a) in connection with copies of the covered work
531: conveyed by you (or copies made from those copies), or (b) primarily
532: for and in connection with specific products or compilations that
533: contain the covered work, unless you entered into that arrangement,
534: or that patent license was granted, prior to 28 March 2007.
535: 
536:   Nothing in this License shall be construed as excluding or limiting
537: any implied license or other defenses to infringement that may
538: otherwise be available to you under applicable patent law.
539: 
540:   12. No Surrender of Others' Freedom.
541: 
542:   If conditions are imposed on you (whether by court order, agreement or
543: otherwise) that contradict the conditions of this License, they do not
544: excuse you from the conditions of this License.  If you cannot convey a
545: covered work so as to satisfy simultaneously your obligations under this
546: License and any other pertinent obligations, then as a consequence you may
547: not convey it at all.  For example, if you agree to terms that obligate you
548: to collect a royalty for further conveying from those to whom you convey
549: the Program, the only way you could satisfy both those terms and this
550: License would be to refrain entirely from conveying the Program.
551: 
552:   13. Use with the GNU Affero General Public License.
553: 
554:   Notwithstanding any other provision of this License, you have
555: permission to link or combine any covered work with a work licensed
556: under version 3 of the GNU Affero General Public License into a single
557: combined work, and to convey the resulting work.  The terms of this
558: License will continue to apply to the part which is the covered work,
559: but the special requirements of the GNU Affero General Public License,
560: section 13, concerning interaction through a network will apply to the
561: combination as such.
562: 
563:   14. Revised Versions of this License.
564: 
565:   The Free Software Foundation may publish revised and/or new versions of
566: the GNU General Public License from time to time.  Such new versions will
567: be similar in spirit to the present version, but may differ in detail to
568: address new problems or concerns.
569: 
570:   Each version is given a distinguishing version number.  If the
571: Program specifies that a certain numbered version of the GNU General
572: Public License "or any later version" applies to it, you have the
573: option of following the terms and conditions either of that numbered
574: version or of any later version published by the Free Software
575: Foundation.  If the Program does not specify a version number of the
576: GNU General Public License, you may choose any version ever published
577: by the Free Software Foundation.
578: 
579:   If the Program specifies that a proxy can decide which future
580: versions of the GNU General Public License can be used, that proxy's
581: public statement of acceptance of a version permanently authorizes you
582: to choose that version for the Program.
583: 
584:   Later license versions may give you additional or different
585: permissions.  However, no additional obligations are imposed on any
586: author or copyright holder as a result of your choosing to follow a
587: later version.
588: 
589:   15. Disclaimer of Warranty.
590: 
591:   THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
592: APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
593: HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
594: OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
595: THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
596: PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
597: IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
598: ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
599: 
600:   16. Limitation of Liability.
601: 
602:   IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
603: WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
604: THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
605: GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
606: USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
607: DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
608: PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
609: EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
610: SUCH DAMAGES.
611: 
612:   17. Interpretation of Sections 15 and 16.
613: 
614:   If the disclaimer of warranty and limitation of liability provided
615: above cannot be given local legal effect according to their terms,
616: reviewing courts shall apply local law that most closely approximates
617: an absolute waiver of all civil liability in connection with the
618: Program, unless a warranty or assumption of liability accompanies a
619: copy of the Program in return for a fee.
620: 
621:                      END OF TERMS AND CONDITIONS
622: 
623:             How to Apply These Terms to Your New Programs
624: 
625:   If you develop a new program, and you want it to be of the greatest
626: possible use to the public, the best way to achieve this is to make it
627: free software which everyone can redistribute and change under these terms.
628: 
629:   To do so, attach the following notices to the program.  It is safest
630: to attach them to the start of each source file to most effectively
631: state the exclusion of warranty; and each file should have at least
632: the "copyright" line and a pointer to where the full notice is found.
633: 
634:     <one line to give the program's name and a brief idea of what it does.>
635:     Copyright (C) <year>  <name of author>
636: 
637:     This program is free software: you can redistribute it and/or modify
638:     it under the terms of the GNU General Public License as published by
639:     the Free Software Foundation, either version 3 of the License, or
640:     (at your option) any later version.
641: 
642:     This program is distributed in the hope that it will be useful,
643:     but WITHOUT ANY WARRANTY; without even the implied warranty of
644:     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
645:     GNU General Public License for more details.
646: 
647:     You should have received a copy of the GNU General Public License
648:     along with this program.  If not, see <https://www.gnu.org/licenses/>.
649: 
650: Also add information on how to contact you by electronic and paper mail.
651: 
652:   If the program does terminal interaction, make it output a short
653: notice like this when it starts in an interactive mode:
654: 
655:     <program>  Copyright (C) <year>  <name of author>
656:     This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
657:     This is free software, and you are welcome to redistribute it
658:     under certain conditions; type `show c' for details.
659: 
660: The hypothetical commands `show w' and `show c' should show the appropriate
661: parts of the General Public License.  Of course, your program's commands
662: might be different; for a GUI interface, you would use an "about box".
663: 
664:   You should also get your employer (if you work as a programmer) or school,
665: if any, to sign a "copyright disclaimer" for the program, if necessary.
666: For more information on this, and how to apply and follow the GNU GPL, see
667: <https://www.gnu.org/licenses/>.
668: 
669:   The GNU General Public License does not permit incorporating your program
670: into proprietary programs.  If your program is a subroutine library, you
671: may consider it more useful to permit linking proprietary applications with
672: the library.  If this is what you want to do, use the GNU Lesser General
673: Public License instead of this License.  But first, please read
674: <https://www.gnu.org/licenses/why-not-lgpl.html>.

(End of file - total 674 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash · 7.1s)

_Thinking:_

Now I have a thorough understanding of the project. Let me create the README.org file. I need to check if an export handler is currently defined - looking at the source, I don't see an :export parameter registered via org-link-set-parameters. The user mentioned that export behavior should be noted. Let me think about what export does - since there's no :export handler registered, Org's default export behavior for unknown link types would likely apply. Actually, looking at the code, there's no :export handler. Let me think about what would happen...

When no :export handler is registered for a link type, Org's export backends fall back to their default behavior. For HTML export, org-html-link would handle it. Without a specific handler, the link would likely be exported as-is or potentially the backend would try to resolve it. Actually, I think without an :export handler, Org export backends may not be able to handle the lfile: link type properly. The user wants me to mention this.

Actually, let me re-read the requirements more carefully:

1. Package description with example links
2. Installation instructions (use-package :vc and manual require)
3. Supported operations (follow, store, complete)
4. Custom variables
5. Other notes (:: search option, export behavior)
6. License

Let me also check the docs/complete.org file:

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/complete.org"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/complete.org</path>
<type>file</type>
<content>
1: * Complete Handler: =org-locate-file-complete-link=
2: :PROPERTIES:
3: :CUSTOM_ID: complete-handler-org-locate-file-complete-link
4: :END:
5: When the user invokes =org-insert-link= (typically =C-c C-l=) and
6: selects the =lfile:= link type (or whatever =org-locate-file-link-type=
7: is set to), the complete handler is called to allow the user to choose a
8: link target.
9: 
10: ** Behavior
11: :PROPERTIES:
12: :CUSTOM_ID: behavior
13: :END:
14: 1. A single =completing-read= session opens in the minibuffer.
15: 
16: 2. As the user types, each keystroke triggers a fresh locate query via
17:    =completion-table-dynamic=. The locate database is queried with
18:    whatever substring the user has entered so far, and the matching
19:    files are presented as completion candidates.
20: 
21: 3. Completion candidates are the *basenames* of matching files (via
22:    =file-name-nondirectory=), not the full absolute paths. This means:
23: 
24:    - The inserted link looks like =lfile:emacsclient= instead of
25:      =lfile:/usr/bin/emacsclient=.
26:    - The link is resolved again at follow-time via the locate database,
27:      so it remains valid even if the file moves (as long as the locate
28:      database is updated).
29: 
30: 4. If the locate query returns no results for the current input, the
31:    user's raw input is used as-is. This allows typing a path that is not
32:    in the locate database.
33: 
34: 5. The history variable =org-locate-file--history= stores previously
35:    selected basenames for easy recall.
36: 
37: ** Example
38: :PROPERTIES:
39: :CUSTOM_ID: example
40: :END:
41: #+begin_example
42: # User types "emacs" in the completing-read prompt.
43: # Locate returns: ["/usr/bin/emacsclient", "/usr/bin/emacs"]
44: # Candidates shown: "emacsclient", "emacs"
45: # User selects "emacsclient".
46: # Inserted link: [[lfile:emacsclient]]
47: #+end_example
48: 
49: ** Design Notes
50: :PROPERTIES:
51: :CUSTOM_ID: design-notes
52: :END:
53: - The =:complete= handler is registered via =org-link-set-parameters= in
54:   =org-locate-file--register-link-parameters=.
55: - The dynamic table is constructed with =completion-table-dynamic=,
56:   which calls =org-locate-file--run-locate= on each completion request
57:   with the current minibuffer input.
58: - Only basenames are used so that links are concise and remain
59:   resolvable at follow-time regardless of the file's absolute path.

(End of file - total 59 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/notes.org"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/notes.org</path>
<type>file</type>
<content>
1: ol-local-file is an extended org link type for files in local machine. It is inspired by [[https://karl-voit.at/2022/02/10/lfile/][Kerl Voit's implementation]].

(End of file - total 1 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash · 15.9s)

_Thinking:_

Now I have everything I need. Let me create the README.org file and update AGENTS.md. Let me write a good, concise README.org.

Key points to cover:
1. Brief description with examples
2. Installation (use-package :vc and manual require, mention MELPA plans)
3. Supported operations (follow with 3 variants, store with shortest unique suffix, complete with dynamic completion)
4. Custom variables (link-type, max-results, store-link-p, follow-auto, locate-args)
5. Other notes (:: search option, export behavior - currently no :export handler, so export will likely just use the raw link text or fail gracefully; security via call-process; link type is customizable)
6. License (GPLv3+)

Let me check the AGENTS.md section about README - it says "README.md" but we're creating README.org. I should update the AGENTS.md reference.

Now let me write the README.org.

**Tool: write**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/README.org",
  "content": "#+title: ol-locate-file\n#+subtitle: Locate-based file links for Org mode\n#+author: p-snow\n#+email: p-snow (at) users.noreply.github.com\n#+language: en\n\n* Introduction\n\n~ol-locate-file~ provides a new Org link type that resolves partial file\npath substrings into full absolute paths using the =locate= command (or a\ncompatible alternative like =plocate=).\n\nInstead of writing a full absolute path:\n\n#+begin_example\n  [[file:/usr/bin/emacsclient][emacsclient]]\n#+end_example\n\nyou can write just a distinctive substring:\n\n#+begin_example\n  [[lfile:emacsclient][emacsclient]]\n#+end_example\n\nThe link resolves at follow-time via the locate database, so it works\neven if the file's full path is long or hard to remember.\n\nThree link variants are provided:\n\n- =lfile:= — equivalent to =file:= (=find-file=, respecting =org-file-apps=)\n- =lfile+emacs:= — equivalent to =file+emacs:= (always opens in Emacs)\n- =lfile+sys:= — equivalent to =file+sys:= (always opens with system app)\n\nThe link type prefix (default ~\"lfile\"~) is customizable via\n~org-locate-file-link-type~.\n\n* Installation\n\n** Using =use-package= with =:vc=\n\nThis package is not yet available on any package archive (MELPA\nsubmission is planned for the future).  In the meantime, install\ndirectly from the repository using =:vc=:\n\n#+begin_src emacs-lisp\n  (use-package ol-locate-file\n    :vc (:url \"https://github.com/p-snow/ol-locate-file\"\n         :rev :last-release))\n#+end_src\n\n** Manual installation\n\nClone the repository and add it to your =load-path=, then require the\npackage:\n\n#+begin_src emacs-lisp\n  (add-to-list 'load-path \"/path/to/ol-locate-file\")\n  (require 'ol-locate-file)\n#+end_src\n\n* Supported operations\n\n** Follow\n\nWhen you open an =lfile:= link (e.g. ~C-c C-o~), the package runs the\nlocate command with the link's path substring, resolves it to a single\nabsolute file path, and opens it as if it were a regular =file:= link.\n\nIf multiple files match, you are prompted to choose via\n~completing-read~.  This behavior can be customized — see\n~org-locate-file-follow-auto~ below.\n\n** Store\n\nWhen you invoke ~org-store-link~ (~C-c l~) in a file-visiting buffer or\nDired, the handler stores an =lfile:= link using the *shortest unique\npath suffix*.  For example:\n\n- ~lfile:emacsclient~ (when the basename is unique in the locate db)\n- ~lfile:bin/emacsclient~ (when multiple files share the basename)\n\nStored links may include search option suffixes such as ~::10~ (line\nnumber) or ~::#heading~ (Org heading), obtained from\n~org-link--file-link-to-here~.\n\nYou can disable lfile: link storage entirely by setting\n~org-locate-file-store-link-p~ to ~nil~.\n\n** Complete\n\nWhen inserting a link via ~org-insert-link~ (~C-c C-l~) and selecting\nthe =lfile:= type, the package queries the locate database dynamically\nas you type.  Completion candidates are basenames of matching files, and\nthe inserted link uses just the basename (e.g. ~lfile:emacsclient~).\n\nIf no locate results match, your raw input is used as-is, allowing you\nto type a path that is not in the locate database.\n\n* Custom variables\n\n** ~org-locate-file-link-type~\n\n~string~ (default: ~\"lfile\"~)\n\nThe link type prefix used in Org buffers.  Changing this does not\nretroactively update existing links.\n\n** ~org-locate-file-max-results~\n\n~integer~ (default: ~500~)\n\nMaximum number of locate results to collect.  Prevents performance\nissues when the search substring is very short and matches many files.\n\n** ~org-locate-file-store-link-p~\n\n~boolean~ (default: ~t~)\n\nWhen non-nil, ~org-store-link~ stores an =lfile:= link.  When nil, the\nhandler does nothing, allowing the default =file:= link storage.\n\n** ~org-locate-file-follow-auto~\n\nControls automatic candidate selection when multiple files match:\n\n- ~nil~ (default): prompt the user via ~completing-read~\n- ~t~: use the first result without confirmation\n- ~'recent~: select the most recently modified file\n- ~function~: a custom function receiving the candidate list and\n  returning a single path\n\n** ~org-locate-file-locate-args~\n\nControls how the locate command line is built:\n\n- ~nil~: delegate to Emacs' ~locate-make-command-line~\n- ~string~: e.g. ~\"locate --ignore-case\"~ → ~locate --ignore-case PATTERN~\n- ~list~: e.g. ~(\"locate\" \"--ignore-case\")~ (search pattern appended)\n- ~function~: called with the search string; returns a command list or\n  a string\n\n* Additional notes\n\n** Search options (~::~ suffix)\n\n=lfile:= links support Org's search option syntax.  For example:\n\n#+begin_example\n  [[lfile:emacsclient::10]]\n  [[lfile:foo.el::#some-function]]\n  [[lfile:project.org::*Introduction]]\n#+end_example\n\nThe search option (after ~::~) is preserved through resolution and\npassed to ~org-link-open-as-file~.  The substring before ~::~ is used\nfor the locate lookup.\n\n** Export\n\nCurrently, no =:export= handler is registered for the =lfile:= link\ntype.  During Org export, link types without an explicit export handler\nare handled by the export backend's fallback logic.  For HTML export,\nthe link is typically rendered as-is (just the raw ~lfile:PATH~ text)\nor may be dropped depending on the backend.  An export handler may be\nadded in a future release.\n\n** Customizing the link type prefix\n\nIf you prefer a different prefix (e.g. ~\"floc\"~), set\n~org-locate-file-link-type~ before loading the package:\n\n#+begin_src emacs-lisp\n  (setq org-locate-file-link-type \"floc\")\n  (require 'ol-locate-file)\n#+end_src\n\n** Security\n\nThe locate command is executed via ~call-process~, not a shell.  This\navoids shell injection risks — no shell metacharacters in search strings\nare interpreted.\n\n** Dependencies\n\n- Emacs 30.1 (bundles Org 9.7+)\n- The =locate= command (or compatible, such as =plocate=) must be\n  installed on your system.\n\n* License\n\nCopyright (C) 2026 Free Software Foundation, Inc.\n\nThis program is free software: you can redistribute it and/or modify it\nunder the terms of the GNU General Public License as published by the\nFree Software Foundation, either version 3 of the License, or (at your\noption) any later version.\n\nThis program is distributed in the hope that it will be useful, but\nWITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU\nGeneral Public License for more details.\n\nYou should have received a copy of the GNU General Public License along\nwith this program.  If not, see <https://www.gnu.org/licenses/>."
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · DeepSeek V4 Flash · 6.2s)

_Thinking:_

Now I need to update AGENTS.md to reference README.org instead of README.md. The relevant section is in section 4 (Package Structure) where it says "README.md: Provide a readme with usage examples...".

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/AGENTS.md",
  "newString": "- **README.org**: Provide a readme with usage examples, setup",
  "oldString": "- **README.md**: Provide a readme with usage examples, setup"
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · DeepSeek V4 Flash · 5.9s)

_Thinking:_

Both files are created/updated. Let me verify the README.org looks correct by reading it back.

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/README.org"
}
```

**Output:**
```
<path>/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/README.org</path>
<type>file</type>
<content>
1: #+title: ol-locate-file
2: #+subtitle: Locate-based file links for Org mode
3: #+author: p-snow
4: #+email: p-snow (at) users.noreply.github.com
5: #+language: en
6: 
7: * Introduction
8: 
9: ~ol-locate-file~ provides a new Org link type that resolves partial file
10: path substrings into full absolute paths using the =locate= command (or a
11: compatible alternative like =plocate=).
12: 
13: Instead of writing a full absolute path:
14: 
15: #+begin_example
16:   [[file:/usr/bin/emacsclient][emacsclient]]
17: #+end_example
18: 
19: you can write just a distinctive substring:
20: 
21: #+begin_example
22:   [[lfile:emacsclient][emacsclient]]
23: #+end_example
24: 
25: The link resolves at follow-time via the locate database, so it works
26: even if the file's full path is long or hard to remember.
27: 
28: Three link variants are provided:
29: 
30: - =lfile:= — equivalent to =file:= (=find-file=, respecting =org-file-apps=)
31: - =lfile+emacs:= — equivalent to =file+emacs:= (always opens in Emacs)
32: - =lfile+sys:= — equivalent to =file+sys:= (always opens with system app)
33: 
34: The link type prefix (default ~"lfile"~) is customizable via
35: ~org-locate-file-link-type~.
36: 
37: * Installation
38: 
39: ** Using =use-package= with =:vc=
40: 
41: This package is not yet available on any package archive (MELPA
42: submission is planned for the future).  In the meantime, install
43: directly from the repository using =:vc=:
44: 
45: #+begin_src emacs-lisp
46:   (use-package ol-locate-file
47:     :vc (:url "https://github.com/p-snow/ol-locate-file"
48:          :rev :last-release))
49: #+end_src
50: 
51: ** Manual installation
52: 
53: Clone the repository and add it to your =load-path=, then require the
54: package:
55: 
56: #+begin_src emacs-lisp
57:   (add-to-list 'load-path "/path/to/ol-locate-file")
58:   (require 'ol-locate-file)
59: #+end_src
60: 
61: * Supported operations
62: 
63: ** Follow
64: 
65: When you open an =lfile:= link (e.g. ~C-c C-o~), the package runs the
66: locate command with the link's path substring, resolves it to a single
67: absolute file path, and opens it as if it were a regular =file:= link.
68: 
69: If multiple files match, you are prompted to choose via
70: ~completing-read~.  This behavior can be customized — see
71: ~org-locate-file-follow-auto~ below.
72: 
73: ** Store
74: 
75: When you invoke ~org-store-link~ (~C-c l~) in a file-visiting buffer or
76: Dired, the handler stores an =lfile:= link using the *shortest unique
77: path suffix*.  For example:
78: 
79: - ~lfile:emacsclient~ (when the basename is unique in the locate db)
80: - ~lfile:bin/emacsclient~ (when multiple files share the basename)
81: 
82: Stored links may include search option suffixes such as ~::10~ (line
83: number) or ~::#heading~ (Org heading), obtained from
84: ~org-link--file-link-to-here~.
85: 
86: You can disable lfile: link storage entirely by setting
87: ~org-locate-file-store-link-p~ to ~nil~.
88: 
89: ** Complete
90: 
91: When inserting a link via ~org-insert-link~ (~C-c C-l~) and selecting
92: the =lfile:= type, the package queries the locate database dynamically
93: as you type.  Completion candidates are basenames of matching files, and
94: the inserted link uses just the basename (e.g. ~lfile:emacsclient~).
95: 
96: If no locate results match, your raw input is used as-is, allowing you
97: to type a path that is not in the locate database.
98: 
99: * Custom variables
100: 
101: ** ~org-locate-file-link-type~
102: 
103: ~string~ (default: ~"lfile"~)
104: 
105: The link type prefix used in Org buffers.  Changing this does not
106: retroactively update existing links.
107: 
108: ** ~org-locate-file-max-results~
109: 
110: ~integer~ (default: ~500~)
111: 
112: Maximum number of locate results to collect.  Prevents performance
113: issues when the search substring is very short and matches many files.
114: 
115: ** ~org-locate-file-store-link-p~
116: 
117: ~boolean~ (default: ~t~)
118: 
119: When non-nil, ~org-store-link~ stores an =lfile:= link.  When nil, the
120: handler does nothing, allowing the default =file:= link storage.
121: 
122: ** ~org-locate-file-follow-auto~
123: 
124: Controls automatic candidate selection when multiple files match:
125: 
126: - ~nil~ (default): prompt the user via ~completing-read~
127: - ~t~: use the first result without confirmation
128: - ~'recent~: select the most recently modified file
129: - ~function~: a custom function receiving the candidate list and
130:   returning a single path
131: 
132: ** ~org-locate-file-locate-args~
133: 
134: Controls how the locate command line is built:
135: 
136: - ~nil~: delegate to Emacs' ~locate-make-command-line~
137: - ~string~: e.g. ~"locate --ignore-case"~ → ~locate --ignore-case PATTERN~
138: - ~list~: e.g. ~("locate" "--ignore-case")~ (search pattern appended)
139: - ~function~: called with the search string; returns a command list or
140:   a string
141: 
142: * Additional notes
143: 
144: ** Search options (~::~ suffix)
145: 
146: =lfile:= links support Org's search option syntax.  For example:
147: 
148: #+begin_example
149:   [[lfile:emacsclient::10]]
150:   [[lfile:foo.el::#some-function]]
151:   [[lfile:project.org::*Introduction]]
152: #+end_example
153: 
154: The search option (after ~::~) is preserved through resolution and
155: passed to ~org-link-open-as-file~.  The substring before ~::~ is used
156: for the locate lookup.
157: 
158: ** Export
159: 
160: Currently, no =:export= handler is registered for the =lfile:= link
161: type.  During Org export, link types without an explicit export handler
162: are handled by the export backend's fallback logic.  For HTML export,
163: the link is typically rendered as-is (just the raw ~lfile:PATH~ text)
164: or may be dropped depending on the backend.  An export handler may be
165: added in a future release.
166: 
167: ** Customizing the link type prefix
168: 
169: If you prefer a different prefix (e.g. ~"floc"~), set
170: ~org-locate-file-link-type~ before loading the package:
171: 
172: #+begin_src emacs-lisp
173:   (setq org-locate-file-link-type "floc")
174:   (require 'ol-locate-file)
175: #+end_src
176: 
177: ** Security
178: 
179: The locate command is executed via ~call-process~, not a shell.  This
180: avoids shell injection risks — no shell metacharacters in search strings
181: are interpreted.
182: 
183: ** Dependencies
184: 
185: - Emacs 30.1 (bundles Org 9.7+)
186: - The =locate= command (or compatible, such as =plocate=) must be
187:   installed on your system.
188: 
189: * License
190: 
191: Copyright (C) 2026 Free Software Foundation, Inc.
192: 
193: This program is free software: you can redistribute it and/or modify it
194: under the terms of the GNU General Public License as published by the
195: Free Software Foundation, either version 3 of the License, or (at your
196: option) any later version.
197: 
198: This program is distributed in the hope that it will be useful, but
199: WITHOUT ANY WARRANTY; without even the implied warranty of
200: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
201: General Public License for more details.
202: 
203: You should have received a copy of the GNU General Public License along
204: with this program.  If not, see <https://www.gnu.org/licenses/>.

(End of file - total 204 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash · 7.6s)

_Thinking:_

Looks good. Let me summarize what I've done.

Done. Created `README.org` (204 lines) and updated `AGENTS.md` section 4 to reference `README.org` instead of `README.md`.

The README covers:
- **Introduction**: what the package does with before/after link examples and the three link variants
- **Installation**: `use-package` with `:vc` (noting no package archive yet, MELPA planned) and manual `require`
- **Supported operations**: follow (resolve + open), store (shortest unique suffix), complete (dynamic locate-backed completion)
- **Custom variables**: all 5 `defcustom` entries with types, defaults, and descriptions
- **Additional notes**: `::` search option syntax, current export behavior (no handler yet), prefix customization, security (`call-process`), dependencies

---

## User

introductionで、lfileリンクタイプを利用するメリットとして、ファイルのフルパスが長い場合に省略したものを使えること、に加えて、ファイル名さえ変えなければそのファイルをシステム内のどのディレクトリに再配置してもorg-linkが有効に機能するという御利益をつけ加えてください。システムの更新やPCの乗り換え時などにも有効ですよね。

---

## Assistant (Build · DeepSeek V4 Flash · 6.1s)

_Thinking:_

The user wants me to add an additional benefit to the Introduction section: that as long as the filename doesn't change, the org-link remains valid even if the file is relocated to a different directory within the system. This is especially useful during system updates or when migrating to a new PC.

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/README.org",
  "newString": "The link resolves at follow-time via the locate database, so it works\neven if the file's full path is long or hard to remember.  Moreover,\nas long as the filename itself stays the same, the link remains valid\neven if the file is moved to a different directory — making your links\nresilient across system updates, reinstallations, or PC migration.",
  "oldString": "The link resolves at follow-time via the locate database, so it works\neven if the file's full path is long or hard to remember."
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · DeepSeek V4 Flash · 4.3s)

_Thinking:_

Done. Added the benefit about relocation resilience and cross-system portability.

Added a sentence explaining that `lfile:` links remain valid when files are moved to different directories (same filename), making them resilient across system updates and PC migration.

---

