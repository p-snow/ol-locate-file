# Org-linkタイプ拡張の設計判断

**Session ID:** ses_13ef8349cffejNP1Prqn1SElNS
**Created:** 6/13/2026, 9:49:34 PM
**Updated:** 6/13/2026, 9:50:04 PM

---

## User

lfileリンクタイプ作成の方法について整理しておきたいと思います。新規にfileリンクタイプを拡張したリンクタイプつくるとき、org-link-set-parametersを使う方法と、org-link-abbrev-alistを設定してfileのabbreviationとして定義する方法があるかと思います。今回は前者を使っているわけですが、その理由について書き残しておきたいと思います。

org-link-abbrev-alistの設定といった場合、部分文字列からlocateコマンドを使ってフルパスを得る変換関数を用意する方法が考えられます。こうするとfileタイプの処理を流用でき少ないコード量で済み、かつバグ混入の可能性を抑えることができるという利点がありますが、こうするとひとつ問題があります。lfileはfollow処理の場合locateを使う性質上、複数候補からユーザに開くファイルを選んでもらう処理が入ります。ですのでfollow処理は org-link-set-parametersで独自に設定したいのですが、org-link-abbrev-alistを設定してしまうとこちらの方が優先されてしまい、望む処理を実施できません。他にもありますが、これがもっとも重大な org-link-set-parametersだけを使ってパッケージ実装をしている理由になります。

上記の内容をdocs/以下のファイルに記載してください。どこに記載するか新規ファイルをつくるかなどの判断はお任せします。


---

## Assistant (Build · DeepSeek V4 Flash · 4.7s)

_Thinking:_

The user wants me to document the reasoning behind using `org-link-set-parameters` instead of `org-link-abbrev-alist` for the `lfile` link type. They want this in the `docs/` directory. Let me first check what files already exist in `docs/` to understand the structure.

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

---

## Assistant (Build · DeepSeek V4 Flash · 6.6s)

_Thinking:_

I'll create a new file `docs/approach.md` documenting the reasoning behind choosing `org-link-set-parameters` over `org-link-abbrev-alist`. Let me also quickly read the existing docs to understand the style.

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/follow.md",
  "limit": 30
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

(Showing lines 1-30 of 75. Use offset=31 to continue.)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/store.md",
  "limit": 30
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

(Showing lines 1-30 of 91. Use offset=31 to continue.)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash · 15.8s)

_Thinking:_

Good, I can see the style. I'll create a new file `docs/approach.md` explaining the design decision.

**Tool: write**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/docs/approach.md",
  "content": "# Approach: Why `org-link-set-parameters` Instead of `org-link-abbrev-alist`\n\n`ol-locate-file` registers the `lfile:` link type exclusively via\n`org-link-set-parameters`.  An alternative approach would be to\ndefine `lfile` as an abbreviation of the built-in `file:` link type\nusing `org-link-abbrev-alist` combined with a custom expansion\nfunction that transforms a search string into a full path (via\n`locate`).  This section documents why that alternative was\nrejected.\n\n## Advantages of the `org-link-abbrev-alist` Approach\n\n- Reuses all `file:` link processing (follow, export, etc.)\n  automatically, minimizing code and reducing the chance of bugs.\n- Simpler implementation: a single abbreviation entry plus an\n  expansion function is enough.\n\n## Why It Was Rejected\n\nThe critical problem is **follow handler priority**.  When\n`org-link-abbrev-alist` expands an abbreviated link, Org replaces\nthe abbreviation with the expansion result and then dispatches the\nresulting link type's follow handler.  This means the `file:` link\ntype's follow handler runs unconditionally and there is no hook\npoint to inject custom behavior.\n\n`lfile:` links, however, need a custom follow handler because\n`locate` can (and often does) return multiple matching files.  The\nfollow handler must prompt the user to select which file to open\nbefore delegating to `org-link-open-as-file`.  This behavior\ncannot be achieved if the `file:` link type's follow handler takes\nover.\n\nUsing `org-link-abbrev-alist` would also make it impossible to\nregister the variant link types (`lfile+emacs:`, `lfile+sys:`) that\nforce a specific opening method, since those rely on dedicated\nfollow handlers registered via `org-link-set-parameters`.\n\nFor these reasons, `ol-locate-file` uses `org-link-set-parameters`\nto register all link handlers explicitly, even though it requires\nmore code than the abbreviation approach.\n"
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · DeepSeek V4 Flash · 3.5s)

_Thinking:_

Done. Created `docs/approach.md` with the rationale.

Created `docs/approach.md` with the reasoning. The key points:

1. `org-link-abbrev-alist` is simpler and reuses `file:` processing, but makes the `file:` follow handler run unconditionally
2. `lfile:` needs a custom follow handler because locate may return multiple matches → user must pick
3. Also blocks variant link types (`lfile+emacs:`, `lfile+sys:`) that need dedicated follow handlers

---

