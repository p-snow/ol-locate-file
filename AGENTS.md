# AGENTS.md — AI Development Guide for Emacs Packages

This document provides conventions, practices, and reference
information for AI-assisted development of Emacs Lisp packages,
with specific guidance for the `ol-locate-file` project.

## 0. Documentation Policy

- **`docs/` directory**: All feature-specific behavior designs, redesign
  notes, and detailed explanations must be documented in separate files
  under `docs/` (e.g., `docs/follow.md`, `docs/store.md`,
  `docs/complete.md`).  Do **not** write design details in `AGENTS.md`.
- **`AGENTS.md`**: Reserved exclusively for coding conventions,
  submission requirements, reference material, and project-wide
  guidance.  No feature-specific design or behavior descriptions belong
  here.
- When a new design or behavior change is discussed, always create or
  update the corresponding file under `docs/`.  `AGENTS.md` may only
  briefly note such changes when they affect a convention or reference
  entry.

## 1. Emacs Lisp Coding Conventions

### 1.1 Naming Rules

- **Prefix**: All symbols (functions, variables, macros, faces) must
  use a package-specific prefix.  For `ol-locate-file`, use
  `org-locate-file-` for public symbols and `org-locate-file--` for
  private (internal) symbols (double hyphen convention).
- **Package/File vs Prefix**: The package name and file name
  (`ol-locate-file`) follow the `ol-xxx.el` convention used by
  Org-bundled link packages, but the symbol prefix is
  `org-locate-file-` (not `ol-locate-file-`), matching the
  `org-xxx-` convention that those same packages use for symbols.
- **Hyphenation**: Use hyphens (`-`) to separate words in symbol
  names.  Never use underscores or camelCase.
  - Good: `org-locate-file-link-type`
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
(defun org-locate-file--resolve (search-string)
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
- Format: =;; Package-Requires: ((emacs "30.1") (org "9.3"))=
- For =ol-locate-file=, the dependencies are =emacs= (for
  =call-process=, =completing-read=, =executable-find=, =string-trim=)
  and =org= (for =org-link-set-parameters=,
  =org-link-open-as-file=, =org-link--file-link-to-here=).
- Org 9.3+ is specified because =ol-locate-file= uses
  =org-link--file-link-to-here=, but this is subsumed by the Emacs
  30.1 requirement (which bundles a newer Org).

### 2.3 License Declaration

- Use GPLv3+ as recommended by the Emacs community:
  ```
  ;; License: GPL-3.0-or-later
  ```
- Include the full GPL boilerplate in the file header.
- Provide a separate =LICENSE= file containing the full GPLv3 text.

### 2.4 Autoload Cookies

- Use =;;;###autoload= before interactive entry points and key setup
  functions (e.g., =org-locate-file-setup=).
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

## 6. Minimum Supported Emacs Version

### 6.1 Recommendation for =ol-locate-file=: **Emacs 30.1**

Rationale:

- =org-link--file-link-to-here= (used by the store handler) was
  introduced in Org 9.6, which ships with Emacs 29.1.  Emacs 30.1 is
  specified as the minimum to ensure mature availability of this
  internal API.
- **=lexical-binding: t= is fully stable** and widely used.
- **=when-let/= / =if-let/=** (subr-x) are available without extra
  setup.
- **=string-trim=** is available (introduced in Emacs 26.1).
- **=executable-find=** is stable and reliable.
- **Org 9.7+** is bundled (Emacs 30.1 ships with Org 9.7).

Emacs 29.1 would work but 30.1 is chosen as the baseline for broader
compatibility with the bundled Org version that includes a stable
=org-link--file-link-to-here=.

---

## 7. =ol-locate-file= Specific Guidance

### 7.1 Link Type Registration Strategy

All link behavior is controlled exclusively through
`org-link-set-parameters`.  There is **no** use of
`org-link-abbrev-alist`.  The follow, store, and complete handlers
registered via `org-link-set-parameters` are the sole mechanism for
controlling `lfile:` link type behavior.

See `docs/follow.md`, `docs/store.md`, and `docs/complete.md` for
detailed design descriptions of each handler.

### 7.2 =org-locate-file-locate-args= (Custom Variable)

`ol-locate-file` provides the customizable variable
`org-locate-file-locate-args` to control how the locate command
line is built:

- **Default value**: The current value of Emacs' built-in
  `locate-make-command-line` (which is a function that takes a
  search string and returns a command list).
- **When nil**: Delegates directly to `locate-make-command-line`.
- **When a string**: Used as the command prefix before the search
  pattern.  For example, `"locate --ignore-case"` causes the
  package to invoke `locate --ignore-case PATTERN`.
- **When a list of strings**: Each element is a command-line
  argument; the search pattern is appended as the last element.
  For example, `("locate" "--ignore-case")` is equivalent
  to the string `"locate --ignore-case"`.
- **When a function**: Takes the search string as sole argument.
  It may return either a command list `(COMMAND ARGS...)` (same
  convention as `locate-make-command-line`) or a string (which is
  then split via `split-string-and-unquote`).

There are no separate `org-locate-file-command` or
`org-locate-file-arguments` options.  Users who wish to customize
the locate command or its arguments should customize
`org-locate-file-locate-args` or the standard Emacs variables:

- `locate-command` (default: `"locate"`)
- `locate-make-command-line` (for full control over the command
  line construction)
- `locate-prompt-for-command` (additional options to pass)

Users who customize `locate-make-command-line` in their init files
will have those customizations automatically reflected in the
default value of `org-locate-file-locate-args` (via
`default-value`).

There is **no** `locate-db` variable in Emacs' built-in
`locate.el`.  Database selection is handled by the locate command
itself or by `locate-make-command-line`.

### 7.3 Security

- **Always** use =call-process= (or =make-process=) for external
  command execution — never =shell-command= with user-supplied input.
- The locate search string is passed as a direct argument to
  =call-process=, which bypasses shell interpretation entirely.

### 7.4 Session Files

- The default output directory for session files is =sessions/=.

---

## 8. References

- [Org Mode Manual: Adding Hyperlink Types](https://orgmode.org/manual/Adding-Hyperlink-Types.html)
- [GNU Emacs Manual: locate.el](https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired-and-Find.html)
- [MELPA Contributing Guide](https://melpa.org/#/contributing)
- [Emacs Lisp Style Guide](https://www.gnu.org/software/emacs/manual/html_node/elisp/Tips.html)
```
