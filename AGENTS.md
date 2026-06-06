# AGENTS.md — AI Development Guide for Emacs Packages

This document provides conventions, practices, and reference
information for AI-assisted development of Emacs Lisp packages,
with specific guidance for the `ol-locate-file` project.

## 1. Emacs Lisp Coding Conventions

### 1.1 Naming Rules

- **Prefix**: All symbols (functions, variables, macros, faces) must
  use a package-specific prefix.  For `ol-locate-file`, use
  `ol-locate-file-` for public symbols and `ol-locate-file--` for
  private (internal) symbols (double hyphen convention).
- **Hyphenation**: Use hyphens (`-`) to separate words in symbol
  names.  Never use underscores or camelCase.
  - Good: `ol-locate-file-link-type`
  - Bad: `ol_locate_file_link_type`, `olLocateFileLinkType`

### 1.2 Documentation Strings (Docstrings)

- The first line of a docstring must be a single, complete sentence
  that summarizes what the function/variable does.
- Follow with a blank line, then additional details.
- For functions, document each parameter.  Use uppercase parameter
  names in prose (e.g., "PATH is the file path...").
- End sentences with a period.
- Docstrings go immediately after `defun`/`defvar`/`defcustom`, before
  any body forms.

Example:
#+end_srcelisp
(defun ol-locate-file--resolve (search-string)
  "Resolve SEARCH-STRING to a single file path using locate.

When multiple files match, prompt the user via =completing-read'.
When exactly one matches, return it directly."
  ...)
```

### 1.3 Commentary Section

- After the license block, include a =;;; Commentary:= section.
- Describe what the package does, how to use it, and any setup
  instructions.
- Keep it concise but informative.

### 1.4 Provide Form

- The =(provide 'ol-locate-file)= form must be the last executable
  expression in the file, preceded only by footer comments.
- The standard footer is: =;;; ol-locate-file.el ends here=

### 1.5 Lexical Binding

- Always use =-*- lexical-binding: t -*-= on the first line.
- This is required for modern Emacs (27+) and is expected by MELPA.

### 1.6 Line Length

- Keep lines to 80 characters or fewer where practical.
- Docstrings, in particular, should wrap at 72–80 columns.

---

## 2. MELPA Submission Requirements

### 2.1 Header Format

The first line must follow this exact format:

```
;;; package-name.el --- Short description (one line) -*- lexical-binding: t -*-
```

### 2.2 Package-Requires

- Declare only the minimum dependencies needed for the package to
  function.
- Format: =;; Package-Requires: ((emacs "27.1") (org "9.0"))=
- For =ol-locate-file=, the dependencies are =emacs= (for
  =call-process=, =completing-read=, =executable-find=, =string-trim=)
  and =org= (for =org-link-set-parameters=,
  =org-link-open-as-file=, etc.).
- Org 9.0+ is required because =org-link-set-parameters= gained its
  current API in Org 9.0.

### 2.3 License Declaration

- Use GPLv3+ as recommended by the Emacs community:
  ```
  ;; License: GPL-3.0-or-later
  ```
- Include the full GPL boilerplate in the file header.
- Provide a separate =LICENSE= file containing the full GPLv3 text.

### 2.4 Autoload Cookies

- Use =;;;###autoload= before interactive entry points and key setup
  functions (e.g., =ol-locate-file-setup=).
- Do NOT autoload internal functions.

### 2.5 Optional Headers

- =URL=: Link to the project repository.
- =Homepage=: Link to documentation or project page.
- =Keywords=: Comma-separated list for package discovery:
  ```
  ;; Keywords: org, files, convenience
  ```

---

## 3. Quality Checks

Before release, verify that the package passes these checks:

### 3.1 Byte Compilation

```bash
emacs -Q --batch -L . -f batch-byte-compile ol-locate-file.el
```

- Must produce **zero warnings and zero errors**.
- Common issues: unused variables (prefix with =_=), free variable
  references (add =defvar= stubs), undefined functions (add =require=
  or =declare-function=).

### 3.2 Checkdoc

```bash
emacs -Q --batch -l checkdoc -f checkdoc-file ol-locate-file.el
```

- All docstring warnings must be addressed.
- Every =defun=, =defvar=, =defcustom= must have a docstring.

### 3.3 Package-Lint

```bash
emacs -Q --batch -l package-lint -f package-lint-batch-and-exit ol-locate-file.el
```

- Address all lint warnings (incorrect headers, missing dependencies,
  etc.).

---

## 4. Package Structure

- **Single =.el= file**: The package should be contained in a single
  =.el= file that defines all symbols and sets up the link type.
- **README.md**: Provide a readme with usage examples, setup
  instructions, and customization options.
- **LICENSE**: Include the full GPLv3 license text.

---

## 5. =org-link-set-parameters= Reference

### 5.1 Complete Property List

| Property              | Type             | Description |
|-----------------------|------------------|-------------|
| =:follow=             | function(2 args) | Called to open the link.  Receives PATH and ARG (prefix arg). |
| =:export=             | function(4 args) | Called during export.  Receives PATH, DESC, BACKEND, INFO. |
| =:store=              | function(0 args) | Called by =org-store-link=.  Should call =org-link-store-props=. |
| =:complete=           | function(0 args) | Called during =org-insert-link= completion for this type. |
| =:face=               | face or function | Face to display the link.  Function receives PATH. |
| =:help-echo=          | string or fn(3)  | Help-echo property.  Function receives WINDOW, OBJECT, POSITION. |
| =:keymap=             | keymap           | Active keymap when point is on the link.  Default: =org-mouse-map=. |
| =:mouse-face=         | face             | Face for mouse hover.  Default: =highlight=. |
| =:display=            | symbol           | =full= prevents folding in descriptive display. |
| =:activate-func=      | function(4 args) | Called after font-lock activation. |
| =:insert-description= | string or fn(2)  | Default description for =org-insert-link=. |
| =:preview=            | function(3 args) | Generate in-buffer preview overlay. |
| =:htmlize-link=       | fn or plist      | Htmlize link property.  Default: =(:uri "type:path")=. |

### 5.2 =:follow= Function Signature

```elisp
(defun my-follow-fn (path arg)
  "PATH is the link path string.  ARG is the prefix argument."
  ...)
```

Note: The =:follow= function must accept **two arguments** (the
two-argument signature has been mandatory since Org 9.4).

### 5.3 =:export= Function Signature

```elisp
(defun my-export-fn (path desc backend info)
  "PATH is the link path.  DESC is the description or nil.
BACKEND is the export backend symbol.  INFO is the communication plist."
  ...)
```

---

## 6. =org-link-abbrev-alist= vs =org-link-set-parameters=

### 6.1 When to Use =org-link-abbrev-alist=

- Use when the new link type is essentially a shortcut for an existing
  type (e.g., =lfile:= is a shortcut for =file:= with locate
  resolution).
- Abbreviations are expanded at parse time, so the expanded form is
  what Org sees when activating, displaying, and following links.
- The =%(function)= syntax allows dynamic computation of the
  replacement value.

### 6.2 When to Use =org-link-set-parameters=

- Use for the primary registration of the link type's behavior
  (=:follow=, =:store=, =:export=, =:complete=).
- Even when abbreviations are used, registering parameters provides
  fallback behavior (e.g., if the abbreviation expansion fails).

### 6.3 Using Both Together

- Register the link type via =org-link-set-parameters= with full
  =:follow= and other handlers.
- Register a corresponding abbreviation in =org-link-abbrev-alist= to
  ensure consistent display and parsing.
- This dual approach is the strategy used by =ol-locate-file=.

---

## 7. Minimum Supported Emacs Version

### 7.1 Recommendation for =ol-locate-file=: **Emacs 27.1**

Rationale:

- **=lexical-binding: t= is fully stable** and widely used.
- **=when-let/= / =if-let/=** (subr-x) are available without extra
  setup.
- **=string-trim=** is available (introduced in Emacs 26.1).
- **=executable-find=** is stable and reliable.
- **Org 9.0+** is bundled (Emacs 27.1 ships with Org 9.3).
- **Wide adoption**: Emacs 27.1 was released in August 2020 and is the
  baseline for most active Emacs users.  Many popular packages (e.g.,
  Vertico, Corfu, Eglot) require 27.1.

Earlier versions (26.x) would work with minor adjustments but represent
a diminishing user base.  Versions before 26.x lack =string-trim= and
reliable =when-let/=.

---

## 8. =ol-locate-file= Specific Guidance

### 8.1 Locate Program Variants

| Variant   | Command   | Default DB Path            | DB Flag          |
|-----------|-----------|----------------------------|------------------|
| mlocate   | =locate=  | =/var/lib/mlocate/mlocate.db= | =-d=          |
| plocate   | =plocate= | =/var/lib/plocate/plocate.db= | =--database=  |
| GNU findutils | =locate= | (varies)               | =-d=             |

The package auto-detects plocate via =ol-locate-file--plocate-p= and
adjusts the database flag accordingly.

### 8.2 Security

- **Always** use =call-process= (or =make-process=) for external
  command execution — never =shell-command= with user-supplied input.
- The locate search string is passed as a direct argument to
  =call-process=, which bypasses shell interpretation entirely.

### 8.3 Link Resolution Flow

```
User: [[lfile:emacsclient]]
       ↓
org-link-abbrev-alist expansion (non-interactive):
  → ol-locate-file-locate("emacsclient")
  → Runs locate → returns "/usr/bin/emacsclient" (first result)
  → Expanded to: file:/usr/bin/emacsclient
       ↓
Display: file:/usr/bin/emacsclient  (for font-lock / help-echo)
       ↓
User opens link (org-open-at-point):
  → ol-locate-file--follow("emacsclient", nil)
  → ol-locate-file--resolve("emacsclient")
  → Runs locate → if single result, return it
  → If multiple results, completing-read → user selects
  → org-link-open-as-file("/usr/bin/emacsclient", nil)
```

---

## 9. References

- [Org Mode Manual: Adding Hyperlink Types](https://orgmode.org/manual/Adding-Hyperlink-Types.html)
- [GNU Emacs Manual: locate.el](https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired-and-Find.html)
- [MELPA Contributing Guide](https://melpa.org/#/contributing)
- [Emacs Lisp Style Guide](https://www.gnu.org/software/emacs/manual/html_node/elisp/Tips.html)
```
