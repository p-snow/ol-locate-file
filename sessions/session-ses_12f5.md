# パッケージREADMEに謝辞を追加

**Session ID:** ses_12f5a1e78ffeD5lhysCi0yraKf
**Created:** 6/16/2026, 10:36:32 PM
**Updated:** 6/16/2026, 10:36:56 PM

---

## User

このパッケージは以下のブログ記事から着想を得て開発されました。README内に謝辞を入れてください。

https://karl-voit.at/2022/02/10/lfile/


---

## Assistant (Build · DeepSeek V4 Flash · 6.5s)

_Thinking:_

The user wants me to add an acknowledgment in the README, crediting the blog article that inspired this package. Let me first read the blog article and the README.org file.

**Tool: webfetch**

**Input:**
```json
{
  "url": "https://karl-voit.at/2022/02/10/lfile/",
  "format": "markdown"
}
```

**Output:**
```
                        UOMF: Path-Independent Links to Local Files Via Locate

[π](source.org.txt)

    [![public voit logo](//Karl-Voit.at/images/public-voit_logo.svg)](../../../../)    » [2022](../../../) – [02](../../) – [10](../)

-   [emacs](//Karl-Voit.at/tags/emacs/)
-   [pim](//Karl-Voit.at/tags/pim/)
-   [software](//Karl-Voit.at/tags/software/)
-   [language:english](//Karl-Voit.at/2016/11/16/empty-language-autotag-page)

# UOMF: Path-Independent Links to Local Files Via Locate

Reading time about 7 minutes

[Show Sidebar](#show-sidebar)

  

-   [Recent articles](//Karl-Voit.at)
-   [About this blog](//Karl-Voit.at/about)
-   [How to use this blog efficiently](//Karl-Voit.at/how-to-use-this-blog)
-   ![RSS icon](//Karl-Voit.at/images/feed-icon-14x14.png) Subscribe to one of my feeds:
    -   [links only feed](//Karl-Voit.at/feeds/lazyblorg-all.atom_1.0.links-only.xml) (most reliable)
    -   [article teaser feed](//Karl-Voit.at/feeds/lazyblorg-all.atom_1.0.links-and-teaser.xml)
    -   [full content feed](//Karl-Voit.at/feeds/lazyblorg-all.atom_1.0.links-and-content.xml)
-   [TBD](https://en.wiktionary.org/wiki/TBD): Per Tag Feeds
-   [TBD](https://en.wiktionary.org/wiki/TBD): Archive
-   Top [tags](//Karl-Voit.at/tags/):
    -   [software](//Karl-Voit.at/tags/software) (270)
    -   [pim](//Karl-Voit.at/tags/pim) (178)
    -   [hardware](//Karl-Voit.at/tags/hardware) (121)
    -   [austria](//Karl-Voit.at/tags/austria) (85)
    -   [emacs](//Karl-Voit.at/tags/emacs) (78)
    -   [graz](//Karl-Voit.at/tags/graz) (77)
    -   [security](//Karl-Voit.at/tags/security) (68)
    -   [diy](//Karl-Voit.at/tags/diy) (64)
    -   [privacy](//Karl-Voit.at/tags/privacy) (63)
    -   [cloud](//Karl-Voit.at/tags/cloud) (63)
-   Random articles that were published on the same day of the year:
    -   [Evolutional Steps of Computer Systems](//Karl-Voit.at/2017/02/10/evolution-of-systems/)

This is an article from a series of blog postings. Please do read [my "Using Org Mode Features" (UOMF) series page](//Karl-Voit.at/2019/09/25/using-orgmode) for explanations on articles of this series.

-   Update 2022-02-11:
    -   Why Not Use Attachments?
    -   Why Using Local Files?
    -   How I Generate Static File Links

For linking to local files, I have already written about my `tsfile:` [custom link method using Memacs](//Karl-Voit.at/2017/01/01/memacs-grep). I use this for [managing local files such as images](//Karl-Voit.at/managing-digital-photographs) and it is also [an important help for my blogging system](//Karl-Voit.at/2019/10/16/lazyblorg-linked-image-width).

Here, I want to explain a simpler version for people who don't use Memacs for indexing files (yet).

The biggest advantage of using Org-mode links based on that concept is that you only have to provide the [basename](https://en.wikipedia.org/wiki/Basename) of a file without its storage path and still get a successful retrieval process as long as you use unique file names. This way, **you can move around files** in your file system **and rename directories without breaking any links in your Org-mode**. How cool is that?

## Why Not Use Attachments?

Org-mode provides a method to associate reference material with an outline node via [attachments](https://orgmode.org/manual/Attachments.html).

I don't use this handy Org-mode feature except for some rare cases where [my Org heading structure](//Karl-Voit.at/2020/05/03/current-org-files) corresponds with [my file system structure](//Karl-Voit.at/folder-hierarchy). While the fact that my Org hierarchy differs from my file hierarchy could be discussed separately (there are good arguments for both sides), this is my situation for now. This way, org attachments do not provide me much advantage to this method of linking local files while it does give me freedom to move around things without breaking stuff.

## Why Using Local Files?

I do care a lot about local files. I will continue to curate a local file collection that contains my [digital photographs](//Karl-Voit.at/managing-digital-photographs), [my scanned paper documents](//Karl-Voit.at/2015/04/05/digitizing-paper), the files I generate for various purposes, and so forth.

You can [read about my opinion on using the public cloud](//Karl-Voit.at/cloud) and [what you need to consider before starting to give away your data to those services](//Karl-Voit.at/cloud-data-conditions) such as Apple, Google, Microsoft, Dropbox and you name it.

## How I Generate Static File Links

Before I explain how those robust file links are done, I would like to mention what my alternative looks like when I create classic static file links.

1.  I usually invoke `C-z` which is bound to `my-dired-recent-dirs()` from [my Emacs configuration](https://github.com/novoid/dot-emacs/blob/master/config.org).
    -   It was briefly mentioned in [my complex folder article](//Karl-Voit.at/2020/01/25/avoid-complex-folder-hierarchies) and deserves more attention. It allows me to jump to [recently and frequently used](https://en.wikipedia.org/wiki/Frecency) directories very efficiently.
2.  I chose the file to link, usually by invoking the file filter via `/`
3.  Invoke one of my two hydra-provided functions to generate a file link.
4.  Switch back to my Org-mode buffer and yank the newly generated link.

To actually generate a file link, I do have two different functions at hand: `my-dired-copy-filename-as-absolute-link()` which is called "absolute link" in my `hydra-dired()` returns something like that:

 \[\[file:/home/user/dir1/filename.pdf\]\]	  

Furthermore, "Absolute basename" from `hydra-dired()` returns something like that:

 \[\[file:/home/user/dir1/filename.pdf\]\[filename.pdf\]\]	  

As you can see, those links do break when the file is moved to a different directory or any directory within its path is renamed.

Therefore, I usually do link files that have unique file names with a different method I want to explain in the following sections.

Now let's see how this is implemented.

## What Is Locate?

The method to retrieve local files here is using the [locate](https://en.wikipedia.org/wiki/Locate_\(Unix\)) command, UNIX-like systems do provide out of the box. In simple words, the `updatedb` command indexes filenames of all local files once a day. This simple index can be queried using the `locate` command. A command line query looks like that:

 locate "2022-02-10 report"	  

... or sometimes:

 locate 2022-02-10 | grep -i report	  

This way, I do retrieve most files when I can not remember their storage path. It's my poor man's desktop search if you will. It is noteworthy that it doesn't index or query file content, just the file name.

If you're running GNU/Linux or [macOS](https://superuser.com/questions/109590/whats-the-equivalent-of-linuxs-updatedb-command-for-the-mac), this index comes "for free". If you want to use that index to link and retrieve local files, you might want to implement the method explained here.

## How Will It Look Like?

The method described here is using the custom link definition method introduced with [Org 9.0](https://orgmode.org/worg/org-release-notes.html) as [explained by John Kitchin here](https://kitchingroup.cheme.cmu.edu/blog/2016/11/04/New-link-features-in-org-9/).

For the link name, I chose `lfile:` which stands for "local file" or "locate file" - whatever you prefer.

An example link looks like that:

 \[\[lfile:2022-02-10 business report -- final.pdf\]\]	  

With a description, it looks like that:

 \[\[lfile:2022-02-10 business report -- final.pdf\]\[Our business report from Q1 2022\]\]	  

If I do invoke `org-open-at-point` (usually via `C-c C-o`) when my point is above such a link, my system-defined application that handles the file extension is opened with that file. In this case, my default PDF viewer shows me the report.

## A Method to Open the Files

First, we do need a method to handle the link:

(defun my-handle-lfile-link (querystring)
  ;; get a list of hits
  (let ((queryresults (split-string
                       (s-trim
                        (shell-command-to-string
                         (concat
                          "locate \\""
                          querystring
                          "\\" "
                          )))
                       "\\n" t)))
    ;; check length of list (number of lines)
    (cond
     ((= 0 (length queryresults))
      ;; edge case: empty query result
      (message "Sorry, no results found for query: %s" querystring))
     ((= 1 (length queryresults))
      ;; exactly one hit:
      (my-open-in-external-app (car queryresults))
      )
     (t
      ;; in any other case:
      (message "Sorry, multiple results found for query: %s" querystring)
      ;; FIXXME: ask user to select among multiple hits.
      )
      )))	  

If you do take a look at [my Emacs configuration](https://github.com/novoid/dot-emacs/blob/master/config.org), you can also find `my-handle-tsfile-link()` which asks you to choose among multiple entries when the search result is not unique. I omitted this here because I link only unique file names myself which is mostly ensured by applying [date2name](https://github.com/novoid/date2name) on file names.

You can't use the method above directly without either using `my-open-in-external-app()` which you can also find in my configuration or using a method of choice to open arbitrary files.

For that purpose, you can find ideas here:

-   `find-file` is the commend to open it in GNU Emacs directly. So you can just replace "my-open-in-external-app" with "find-file" if you prefer an Emacs-only experience.
    -   [Visiting-functions](https://www.gnu.org/software/emacs/manual/html_node/elisp/Visiting-Functions.html) explain you more about that set of functions.
-   Xah Lee has [an article on opening files in external apps](http://xahlee.info/emacs/emacs/emacs_dired_open_file_in_ext_apps.html) if you prefer the system applications approach without re-using my method.

## The Org-Mode Configuration to Connect the Link With the Open Function

Now that we do have a function that is able to handle the file links, we do have to tell Org-mode to use that method for links with the abbreviation `lfile:`.

This is done via the following snippet:

(org-link-set-parameters
 "lfile"
 :follow (lambda (filename) (my-handle-lfile-link filename))
 :help-echo "Opens the file located via \\"locate\\" with your default application"
 :face '(:foreground "DarkSeaGreen" :underline t)
)	  

You can adjust the face for the link to your liking. If you take a look at my configuration, I do maintain different classes of link colors for local and remote links (search for "link colors") to keep the color scheme small and recognizable.

In my case, I had to restart GNU Emacs in order to make sure that everything is loaded properly and I could start using my new custom links.

## Efficiently Adding New Links

The most commonly used snippet system might be [YASnippet](https://www.emacswiki.org/emacs/Yasnippet). I prefer an extension for it named [yankpad](https://github.com/Kungsgeten/yankpad) which simplifies the management of the snippets by using Org-mode files for it.

With yankpad, I defined the following heading to add a new link which I usually do have in my clipboard:

 \*\* lfile: lfile
 \[\[lfile:$1\]\[${2:$$(unless yas-modified-p
  (let ((field (nth 0 (yas--snippet-fields (first (yas--snippets-at-point))))))
    (concat (buffer-substring (yas--field-start field) (yas--field-end field)))))}\]\] $0	  

You can use a simpler definition. Mine does generate something like ...

 \[\[lfile:foo\]\[foo\]\]	  

... by only providing "foo" once.

Therefore, my process for adding a link looks like that:

1.  Get the basename of the file in my (system) clipboard.
2.  In Org-mode, type `lfile` and press the binding for `yankpad-expand` to invoke yankpad.
3.  Yank the basename and proceed with the tabulator key.

The new link is inserted at the current point. Opening the linked file is as easy as invoking `C-c C-o` onto the link or using a mouse click.

## Faster Update Cycles

My main use of `lfile:` links is on my business machine where I don't use or need Memacs at the moment. Since the whole storage is on a fast SSD, `updatedb` only runs for about ten seconds. You can check this on your machine if you run `sudo time updatedb` yourself.

Having such a fast update process at hand, you can decide to go from a daily update - which is the default - to an hourly update.

For that, I just had to move the execution script on my Ubuntu machine from one directory to another:

 sudo mv /etc/cron.daily/locate /etc/cron.hourly/	  

If your system has a different method to invoke the database update, please refer to your system documentation.

## Happy Linking!

That's it.

I hope you could follow my idea and the instructions so that you're able to profit from this neat method yourself. I can not think of **not** using this method any more. It offers so much advantages to me on an daily basis.

Please add comments below if you want to ask me something or if you do have an add-on idea.

---

Related articles that link to this one:

-   [Blog Series: Using Org Mode Features (UOMF)](//Karl-Voit.at/2019/09/25/using-orgmode)
-   [Nobody Needs a Generic Folder Hierarchy Convention](//Karl-Voit.at/2023/03/20/generic-file-hierarchy)
-   [Logseq from an Org-mode Point of View](//Karl-Voit.at/2024/01/28/logseq-from-org-pov)

Published on 2022-02-10T20:12 [Share on](https://share.joinmastodon.org/?text=%22UOMF%3A%20Path-Independent%20Links%20to%20Local%20Files%20Via%20Locate%22%0Ahttps%3A%2F%2FKarl-Voit.at%2F2022%2F02%2F10%2Flfile%0A%23publicvoit%20%2320220210_Lfile)

[Comment via](https://share.joinmastodon.org/?text=Comment%20on%20the%20%23publicvoit%20article%3A%20UOMF%3A%20Path-Independent%20Links%20to%20Local%20Files%20Via%20Locate%0Ahttps%3A%2F%2FKarl-Voit.at%2F2022%2F02%2F10%2Flfile%0A%0A%2320220210_Lfile) using the hashtag `#20220210_Lfile` (decentralized), [email](mailto:publicvoit-comment@Karl-Voit.at?subject=2022-02-10-lfile%20comment:%20&body=Please%20do%20not%20remove%20'2022-02-10-lfile%20comment:'%20in%20subject%20and%20please%20tell%20me%20whether%20or%20not%20it%20is%20OK%20to%20add%20your%20comment%20and%2For%20your%20name%20and%2For%20your%20email%20address%20to%20the%20blog%20entry!) (persistent) or via [Disqus](//disqus.com) (ephemeral) comments below:

Load Disqus Comments 

Please enable JavaScript to view the [Disqus comments.](//disqus.com/?ref_noscript)

*[public voit](//Karl-Voit.at/about)* is authored in [Org mode](//orgmode.org) and generated by [lazyblorg](https://github.com/novoid/lazyblorg)  •  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)  •  [HTML5](//validator.w3.org/check/referer)  •  [CSS3](//jigsaw.w3.org/css-validator/)  •  [Archive](https://web.archive.org/web/*/Karl-Voit.at/2022/02/10/lfile/)  •  [Designed to Last](https://jeffhuang.com/designed_to_last/)  • [](https://graz.social/@publicvoit)
```

**Tool: glob**

**Input:**
```json
{
  "pattern": "README*"
}
```

**Output:**
```
/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/README.org
```

---

## Assistant (Build · DeepSeek V4 Flash · 5.1s)

_Thinking:_

Let me read the current README.org file to see its contents and understand where to add the acknowledgment.

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
4: #+email: public (at) p-snow.org
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
26: even if the file's full path is long or hard to remember.  Moreover,
27: as long as the filename itself stays the same, the link remains valid
28: even if the file is moved to a different directory — making your links
29: resilient across system updates, reinstallations, or PC migration.
30: 
31: Three link variants are provided:
32: 
33: - =lfile:= — equivalent to =file:= (=find-file=, respecting =org-file-apps=)
34: - =lfile+emacs:= — equivalent to =file+emacs:= (always opens in Emacs)
35: - =lfile+sys:= — equivalent to =file+sys:= (always opens with system app)
36: 
37: The link type prefix (default ~"lfile"~) is customizable via
38: ~org-locate-file-link-type~.
39: 
40: * Installation
41: 
42: ** Using =use-package= with =:vc=
43: 
44: This package is not yet available on any package archive (MELPA
45: submission is planned for the future).  In the meantime, install
46: directly from the repository using =:vc=:
47: 
48: #+begin_src emacs-lisp
49:   (use-package ol-locate-file
50:     :vc (:url "https://github.com/p-snow/ol-locate-file"
51:          :rev :last-release))
52: #+end_src
53: 
54: ** Manual installation
55: 
56: Clone the repository and add it to your =load-path=, then require the
57: package:
58: 
59: #+begin_src emacs-lisp
60:   (add-to-list 'load-path "/path/to/ol-locate-file")
61:   (require 'ol-locate-file)
62: #+end_src
63: 
64: * Supported operations
65: 
66: ** Follow
67: 
68: When you open an =lfile:= link (e.g. ~C-c C-o~), the package runs the
69: locate command with the link's path substring, resolves it to a single
70: absolute file path, and opens it as if it were a regular =file:= link.
71: 
72: If multiple files match, you are prompted to choose via
73: ~completing-read~.  This behavior can be customized — see
74: ~org-locate-file-resolve-method~ below.
75: 
76: ** Export
77: 
78: When exporting an Org document containing =lfile:= links (e.g. to
79: HTML or LaTeX), the package resolves each link to a full file path
80: and delegates to the standard =file:= link export handler.  This
81: means each backend applies its native file-link formatting (e.g. a
82: clickable link in HTML).
83: 
84: If multiple files match, the first locate result is used
85: automatically without prompting (customizable via
86: ~org-locate-file-resolve-method~).
87: 
88: ** Store
89: 
90: When you invoke ~org-store-link~ (~C-c l~) in a file-visiting buffer or
91: Dired, the handler stores an =lfile:= link using the *shortest unique
92: path suffix*.  For example:
93: 
94: - ~lfile:emacsclient~ (when the basename is unique in the locate db)
95: - ~lfile:bin/emacsclient~ (when multiple files share the basename)
96: 
97: Stored links may include search option suffixes such as ~::10~ (line
98: number) or ~::#heading~ (Org heading), obtained from
99: ~org-link--file-link-to-here~.
100: 
101: You can disable lfile: link storage entirely by setting
102: ~org-locate-file-store-link-p~ to ~nil~.
103: 
104: ** Complete
105: 
106: When inserting a link via ~org-insert-link~ (~C-c C-l~) and selecting
107: the =lfile:= type, the package queries the locate database dynamically
108: as you type.  Completion candidates are basenames of matching files, and
109: the inserted link uses just the basename (e.g. ~lfile:emacsclient~).
110: 
111: If no locate results match, your raw input is used as-is, allowing you
112: to type a path that is not in the locate database.
113: 
114: * Custom variables
115: 
116: ** ~org-locate-file-link-type~
117: 
118: ~string~ (default: ~"lfile"~)
119: 
120: The link type prefix used in Org buffers.  Changing this does not
121: retroactively update existing links.
122: 
123: ** ~org-locate-file-max-results~
124: 
125: ~integer~ (default: ~500~)
126: 
127: Maximum number of locate results to collect.  Prevents performance
128: issues when the search substring is very short and matches many files.
129: 
130: ** ~org-locate-file-store-link-p~
131: 
132: ~boolean~ (default: ~t~)
133: 
134: When non-nil, ~org-store-link~ stores an =lfile:= link.  When nil, the
135: handler does nothing, allowing the default =file:= link storage.
136: 
137: ** ~org-locate-file-resolve-method~
138: 
139: Controls how files are resolved when multiple locate results match.
140: 
141: A flat value applies to both follow and export:
142: 
143: - ~auto~ (default for export): use the first locate result without confirmation
144: - ~recent~: select the most recently modified file
145: - ~ask~ (default for follow): prompt the user via ~completing-read~
146: - ~function~: a custom function receiving the candidate list and returning a single path
147: 
148: An alist specifies different methods per context:
149: 
150: #+begin_example
151:   ((follow ask) (export auto))
152: #+end_example
153: 
154: This is the default: follow prompts the user, export auto-selects
155: the first result.
156: 
157: ** ~org-locate-file-locate-args~
158: 
159: Controls how the locate command line is built:
160: 
161: - ~nil~: delegate to Emacs' ~locate-make-command-line~
162: - ~string~: e.g. ~"locate --ignore-case"~ → ~locate --ignore-case PATTERN~
163: - ~list~: e.g. ~("locate" "--ignore-case")~ (search pattern appended)
164: - ~function~: called with the search string; returns a command list or
165:   a string
166: 
167: * Additional notes
168: 
169: ** Search options (~::~ suffix)
170: 
171: =lfile:= links support Org's search option syntax.  For example:
172: 
173: #+begin_example
174:   [[lfile:emacsclient::10]]
175:   [[lfile:foo.el::#some-function]]
176:   [[lfile:project.org::*Introduction]]
177: #+end_example
178: 
179: The search option (after ~::~) is preserved through resolution and
180: passed to ~org-link-open-as-file~.  The substring before ~::~ is used
181: for the locate lookup.
182: 
183: ** Export
184: 
185: Currently, no =:export= handler is registered for the =lfile:= link
186: type.  During Org export, link types without an explicit export handler
187: are handled by the export backend's fallback logic.  For HTML export,
188: the link is typically rendered as-is (just the raw ~lfile:PATH~ text)
189: or may be dropped depending on the backend.  An export handler may be
190: added in a future release.
191: 
192: ** Customizing the link type prefix
193: 
194: If you prefer a different prefix (e.g. ~"floc"~), set
195: ~org-locate-file-link-type~ before loading the package:
196: 
197: #+begin_src emacs-lisp
198:   (setq org-locate-file-link-type "floc")
199:   (require 'ol-locate-file)
200: #+end_src
201: 
202: ** Security
203: 
204: The locate command is executed via ~call-process~, not a shell.  This
205: avoids shell injection risks — no shell metacharacters in search strings
206: are interpreted.
207: 
208: ** Dependencies
209: 
210: - Emacs 30.1 (bundles Org 9.7+)
211: - The =locate= command (or compatible, such as =plocate=) must be
212:   installed on your system.
213: 
214: * License
215: 
216: Copyright (C) 2026 Free Software Foundation, Inc.
217: 
218: This program is free software: you can redistribute it and/or modify it
219: under the terms of the GNU General Public License as published by the
220: Free Software Foundation, either version 3 of the License, or (at your
221: option) any later version.
222: 
223: This program is distributed in the hope that it will be useful, but
224: WITHOUT ANY WARRANTY; without even the implied warranty of
225: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
226: General Public License for more details.
227: 
228: You should have received a copy of the GNU General Public License along
229: with this program.  If not, see <https://www.gnu.org/licenses/>.

(End of file - total 229 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash · 7.7s)

_Thinking:_

I need to add an acknowledgment section to the README.org, crediting Karl Voit's blog article. I'll add it before the License section. Let me add a proper acknowledgment.

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/p-snow/.local/share/ghq/github.com/p-snow/ol-locate-file/README.org",
  "newString": "* License\n\nCopyright (C) 2026 Free Software Foundation, Inc.\n\nThis program is free software: you can redistribute it and/or modify it\nunder the terms of the GNU General Public License as published by the\nFree Software Foundation, either version 3 of the License, or (at your\noption) any later version.\n\nThis program is distributed in the hope that it will be useful, but\nWITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU\nGeneral Public License for more details.\n\nYou should have received a copy of the GNU General Public License along\nwith this program.  If not, see <https://www.gnu.org/licenses/>.\n\n* Acknowledgments\n\nThis package was inspired by Karl Voit's blog article [[https://karl-voit.at/2022/02/10/lfile/][UOMF:\nPath-Independent Links to Local Files Via Locate]].  Many thanks to\nKarl for sharing the idea and his implementation.",
  "oldString": "* License\n\nCopyright (C) 2026 Free Software Foundation, Inc.\n\nThis program is free software: you can redistribute it and/or modify it\nunder the terms of the GNU General Public License as published by the\nFree Software Foundation, either version 3 of the License, or (at your\noption) any later version.\n\nThis program is distributed in the hope that it will be useful, but\nWITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU\nGeneral Public License for more details.\n\nYou should have received a copy of the GNU General Public License along\nwith this program.  If not, see <https://www.gnu.org/licenses/>."
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · DeepSeek V4 Flash · 4.4s)

_Thinking:_

The edit was applied successfully. The acknowledgment section has been added to the README.org file, crediting Karl Voit's blog article.

`README.org` に Acknowledgments セクションを追加し、Karl Voit 氏のブログ記事への謝辞を記載しました。

---

