; extends

; ============================================================================
; CAPTURE NAMING — read this before adding a rule
; ============================================================================
;
; Every capture in this file is either a STANDARD Nvim capture (see
; :help treesitter-highlight-groups) or a custom LEAF under a standard parent.
; Nothing invents a new root, and nothing puts a fake language segment in the
; middle of a name.
;
; The two rules from the manual that govern this:
;
;   1. "A fallback system is implemented, so that more specific groups fallback
;      to more generic ones."   -> @string.special.image falls back to
;      @string.special, then @string. A leaf nobody has coloured costs nothing.
;
;   2. "capture highlights can always be specialized by language, by appending
;      the language name after an additional dot."   -> @comment.c, @comment.lua.
;      THE LANGUAGE GOES LAST. It is not a namespace you nest inside.
;
; Rule 2 is why the old names here were wrong. `@string.yaml.url` claimed to be
; "@string, language yaml, language url", which is meaningless -- and because
; Nvim appends the buffer language when it resolves a capture, the group that
; actually got looked up was `@string.yaml.url.yaml`. That doubled suffix is
; where the junk keys in theme_baseline_saved.lua came from; nobody chose them.
;
; So: capture the STANDARD name here, and colour the language-suffixed form in
; the theme tables. Capture @string.special.url, style @string.special.url.yaml.
; The yaml tuning then stays off python/go/js for the reason the standard says
; it does, not by accident of a private namespace.
;
; The `.kdragon` suffix (named after kanagawa-dragon, long since applied to
; every theme) is gone for the same reason: booleans are @boolean, numbers are
; @number, null is @constant.builtin. Those are the standard names and every
; colorscheme already styles them.

; ============================================================================
; Punctuation — not emitted by upstream nvim-treesitter yaml query
; ============================================================================

":" @punctuation.delimiter
"-" @punctuation.special
"|" @punctuation.special
">" @punctuation.special
"[" @punctuation.bracket
"]" @punctuation.bracket
"{" @punctuation.bracket
"}" @punctuation.bracket
"," @punctuation.delimiter

(anchor_name) @label
(alias_name) @label
(tag) @type

; ============================================================================
; YAML scalar types
; ============================================================================
;
; The upstream query captures boolean_scalar and null_scalar inconsistently
; across parser versions and never captures plain string scalars in value
; position, so these are asserted here. All four are STANDARD captures.
;
; AST reference (ikatyang/tree-sitter-yaml):
;   (block_mapping_pair
;     key:   (flow_node (plain_scalar (string_scalar)))
;     value: (flow_node (plain_scalar (boolean_scalar))))

; Booleans: true / false / True / False / yes / no / on / off
(boolean_scalar) @boolean

; Null: null / ~
(null_scalar) @constant.builtin

; Integers and floats
(integer_scalar) @number
(float_scalar)   @number

; ============================================================================
; Plain string scalars in VALUE position
; ============================================================================
;
; The upstream query does NOT emit any capture for unquoted plain string values
; (tokens like `argocd`, `core-api`, `default`). Targeting by AST field position
; (value:) avoids touching keys -- keys are plain scalars too, so anything not
; anchored on a field will repaint them. Every value rule below is anchored.

; Block mapping values: namespace: argocd, project: default
(block_mapping_pair
  value: (flow_node (plain_scalar (string_scalar) @string)))

; Block sequence items: - values.yaml, - resources-finalizer.argocd.argoproj.io
(block_sequence_item
  (flow_node (plain_scalar (string_scalar) @string)))

; Flow pair values: { key: value }
(flow_pair
  value: (flow_node (plain_scalar (string_scalar) @string)))

; Flow sequence items: [item1, item2]
(flow_sequence
  (flow_node (plain_scalar (string_scalar) @string)))

; ============================================================================
; Quoted strings
; ============================================================================
;
; Plain @string, same as unquoted values. These were a separate capture
; (@string.yaml.quoted) that every theme then assigned the SAME colour as
; plain values -- a distinction that existed in the table and never on screen.

(double_quote_scalar) @string
(single_quote_scalar) @string

; ============================================================================
; Value SHAPES — the reason yaml reads as two colours and helpers.tpl does not
; ============================================================================
;
; YAML has no grammar-level notion of "this scalar is an image ref" -- every
; unquoted value above lands in one @string capture, so ~30% of a manifest is
; one flat colour. helm/gotmpl looks livelier purely because that grammar HAS
; token classes (variables, calls, keywords); yaml does not.
;
; The grammar can't tell these apart, but the text can. Each rule below re-tags
; an already-captured value by its shape, using #lua-match? (Lua patterns, NOT
; regex -- no alternation, and % is the escape).
;
; ORDER IS LOAD-BEARING: at equal priority the LAST matching capture wins, so
; these run after the generic @string rules above and progress from general to
; specific. Moving a block up will silently disable the ones it shadows.
;
; Every name degrades gracefully via rule 1 at the top of this file:
; @string.special.image -> @string.special -> @string, i.e. exactly the plain
; value colour. A rule that stops matching costs nothing.

; --- Paths: /healthz, ./chart, values.yaml, ca.crt --------------------------
; @string.special.path is STANDARD ("filenames").
((plain_scalar (string_scalar) @string.special.path)
  (#lua-match? @string.special.path "^%.?%.?/"))

((plain_scalar (string_scalar) @string.special.path)
  (#lua-match? @string.special.path "^[%w_%-%.]+%.[%a][%a][%a]?[%a]?$"))

; --- URLs: https://…, oci://…  ---------------------------------------------
; @string.special.url is STANDARD ("URIs (e.g. hyperlinks)").
((plain_scalar (string_scalar) @string.special.url)
  (#lua-match? @string.special.url "^%a[%w%+%-%.]*://"))

; --- Quantities: 512Mi, 500m, 2Gi, 30s, 100ms -------------------------------
; Digits followed by a unit suffix. k8s resource quantities and Go durations
; both land here; a bare 8080 stays @number via the integer_scalar rule above.
; Custom leaf under the standard @number parent.
((plain_scalar (string_scalar) @number.quantity)
  (#lua-match? @number.quantity "^%d+%.?%d*%a+$"))

; --- Versions: v1, apps/v1, networking.k8s.io/v1beta1, 1.2.3 ----------------
((plain_scalar (string_scalar) @string.special.version)
  (#lua-match? @string.special.version "^[%w%.%-]*/?v%d+[%w]*$"))

; Two numeric parts is enough: catches 1.2.3 and 1.25, but also 1.9.x and 1.4-rc1
; which a three-numeric-part pattern silently missed (common in setup-* actions).
((plain_scalar (string_scalar) @string.special.version)
  (#lua-match? @string.special.version "^v?%d+%.%d+"))

; --- Enum-like CamelCase: Deployment, RollingUpdate, ClusterIP, Always ------
; The single most common value shape in k8s manifests and the one most worth
; seeing at a glance -- it is almost always an API enum or a Kind, i.e. a TYPE.
; @type is standard and is what (tag) already uses above.
((plain_scalar (string_scalar) @type)
  (#lua-match? @type "^%u%l[%w]*$"))

; --- Bare lowercase words: plan, apply, write, choice, main, default --------
; A short lowercase word as a value is a selector from a fixed vocabulary (GHA
; permissions, input types, branch names), not prose. Without this class a
; workflow's `permissions:` block or an input's options list is a wall of plain
; string colour: keys + one value colour = the "two colours" read.
;
; @string.special.symbol is STANDARD -- the manual defines it as "symbols or
; atoms", which is exactly what a fixed-vocabulary selector is.
;
; VALUE-POSITION ONLY: the first cut of this rule matched any bare plain_scalar
; -- and yaml KEYS are plain scalars too, so `path:`, `helm:` and `server:` lit
; up in the word colour. Same field-anchoring as the value rules above.
;
; The pattern is "lowercase letters and internal hyphens, nothing else". It used
; to be an unrolled `^%l%l?%l?...%l?$` capped at 12 characters -- a bound with no
; stated reason that silently split `dependencies` (12, matched) from
; `configuration` (13, did not). Length was never the signal; SHAPE is. Digits,
; dots and slashes still exclude a scalar here, and those are what the path /
; version / url / image rules key on, so no shape-classed value is stolen back.
; Multi-word prose has spaces and can never match.
((block_mapping_pair
  value: (flow_node (plain_scalar (string_scalar) @string.special.symbol)))
  (#lua-match? @string.special.symbol "^%l[%l%-]*$"))
((block_sequence_item
  (flow_node (plain_scalar (string_scalar) @string.special.symbol)))
  (#lua-match? @string.special.symbol "^%l[%l%-]*$"))
((flow_pair
  value: (flow_node (plain_scalar (string_scalar) @string.special.symbol)))
  (#lua-match? @string.special.symbol "^%l[%l%-]*$"))

; --- CONSTANT_CASE: LOG_LEVEL, POSTGRES_HOST -------------------------------
; Env var names, which appear as VALUES under `- name:` in a container spec.
; @constant.macro is standard and is the closest documented fit for a
; CONSTANT_CASE identifier.
((plain_scalar (string_scalar) @constant.macro)
  (#lua-match? @constant.macro "^%u[%u%d_]+$"))

; --- Conditions: inputs.action == 'plan' || inputs.action == 'apply' -------
; `if:` / `when:` expressions. They are code, but yaml hands them over as one
; plain scalar. Matched by the operators rather than by key name, so this also
; catches Argo's `when:` and anything else putting an expression in a scalar.
;
; NOTE: lua/plugins/yaml-expr.lua tokenizes these bodies with extmarks at
; priority 220, so on screen the interior is painted per-token (context /
; property / operator / string) exactly like a braced ${{ }} expression. This
; capture is the FALLBACK underneath that -- it is what shows if the tokenizer
; is disabled or the buffer is over its line cap.
((plain_scalar (string_scalar) @string.special.condition)
  (#lua-match? @string.special.condition "[=!<>]="))

((plain_scalar (string_scalar) @string.special.condition)
  (#lua-match? @string.special.condition "||"))

((plain_scalar (string_scalar) @string.special.condition)
  (#lua-match? @string.special.condition "&&"))

; --- Image refs: registry.example.com/api:1.2.3, nginx:1.25 ----------------
; Last, and deliberately so: an image ref also matches the path and version
; shapes above, and this is the reading that should win.
((plain_scalar (string_scalar) @string.special.image)
  (#lua-match? @string.special.image "^[%w%.%-_]+/?[%w%.%-_/]*:[%w%.%-_]+$"))

; GitHub Actions refs: actions/checkout@v4, hashicorp/setup-terraform@v3.
; Same capture as image refs on purpose -- both are "a pinned external artifact
; at a version", they are the single most common value in a workflow file, and
; giving them one colour means uses:/image: read the same way.
((plain_scalar (string_scalar) @string.special.image)
  (#lua-match? @string.special.image "^[%w%-_%.]+/[%w%-_%.]+@[%w%.%-_]+$"))

; ============================================================================
; Merge keys — `<<: *anchor`
; ============================================================================
;
; `<<` is not punctuation to the grammar; it is an ordinary string_scalar in
; key position, so it inherited the key colour and read as a field named "<<".
; It is an OPERATOR, and @operator is the standard capture for one. yaml has no
; other operators, so @operator.yaml is free for it alone.
;
; Key depth is painted by lua/plugins/yaml-key-depth.lua (extmarks, priority
; 200), which deliberately skips any key this rule claims -- see that file.
((plain_scalar (string_scalar) @operator)
  (#eq? @operator "<<"))

; ============================================================================
; Document markers — `---` and `...`
; ============================================================================
;
; Anonymous nodes on (document). In a multi-doc manifest these are the only
; separator between one object and the next and they rendered as plain text.
; Custom leaf under the standard @punctuation.special parent, so it falls back
; to the same colour as the list dashes if nobody assigns it one.
;
; NOT added here: (block_scalar). It compiles and matches, but it spans the
; whole `run: |` body, and those bodies carry an injected bash parser whose
; highlights this would sit on top of. The `|` / `>` indicators are already
; captured as @punctuation.special above, which is the part worth seeing.
(document "---" @punctuation.special.document)
(document "..." @punctuation.special.document)

; ============================================================================
; Prose keys — `name:` is not an enum
; ============================================================================
;
; The CamelCase enum rule above was written for k8s, where `kind: Deployment`
; and `type: RollingUpdate` genuinely are API constants worth spotting. But it
; matches on SHAPE, and a GitHub Actions step name is prose that happens to be
; capitalised -- so `- name: Checkout` was painted as an API enum.
;
; Worse, it was inconsistent: `Checkout` is one CamelCase word and matched, but
; `Configure AWS credentials` has spaces and did not, so identical fields came
; out in two different colours depending on how many words the name had. The
; same applies to the lowercase symbol rule: `- name: build` is prose too.
;
; Keyed on the FIELD, not the shape: a value under one of these keys is prose,
; whatever it looks like. Must stay at the end of this file -- it re-tags values
; the enum and symbol rules already claimed, and at equal priority the last
; capture wins.
((block_mapping_pair
   key: (flow_node (plain_scalar (string_scalar) @_prosekey))
   value: (flow_node (plain_scalar (string_scalar) @string)))
 (#any-of? @_prosekey "name" "description" "title" "summary" "displayName"))
