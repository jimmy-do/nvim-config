; extends

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
; YAML scalar TYPE captures (.kdragon suffix = zero collision risk)
; ============================================================================
;
; The upstream query captures boolean_scalar and null_scalar inconsistently
; across parser versions, and never captures plain string scalars in value
; position. We assign each scalar type a distinct capture name so kanagawa
; overrides can color them without touching any existing capture.
;
; AST reference (ikatyang/tree-sitter-yaml):
;   (block_mapping_pair
;     key:   (flow_node (plain_scalar (string_scalar)))
;     value: (flow_node (plain_scalar (boolean_scalar))))

; Booleans: true / false / True / False / yes / no / on / off
(boolean_scalar) @boolean.yaml.kdragon

; Null: null / ~
(null_scalar) @constant.builtin.yaml.kdragon

; Integers and floats
(integer_scalar) @number.yaml.kdragon
(float_scalar)   @number.yaml.kdragon

; ============================================================================
; Plain string scalars in VALUE position
; ============================================================================
;
; The upstream query does NOT emit any capture for unquoted plain string values
; (tokens like `argocd`, `core-api`, `default`, `RollingUpdate`). Targeting by
; AST field position (value:) avoids touching keys.

; Block mapping values: namespace: argocd, project: default, type: RollingUpdate
(block_mapping_pair
  value: (flow_node (plain_scalar (string_scalar) @string.yaml.value)))

; Block sequence items: - values.yaml, - resources-finalizer.argocd.argoproj.io
(block_sequence_item
  (flow_node (plain_scalar (string_scalar) @string.yaml.value)))

; Flow pair values: { key: value }
(flow_pair
  value: (flow_node (plain_scalar (string_scalar) @string.yaml.value)))

; Flow sequence items: [item1, item2]
(flow_sequence
  (flow_node (plain_scalar (string_scalar) @string.yaml.value)))

; ============================================================================
; Quoted strings
; ============================================================================

(double_quote_scalar) @string.yaml.quoted
(single_quote_scalar) @string.yaml.quoted

; ============================================================================
; Value SHAPES — the reason yaml reads as two colours and helpers.tpl does not
; ============================================================================
;
; YAML has no grammar-level notion of "this scalar is an image ref" -- every
; unquoted value above lands in the single @string.yaml.value capture, so ~30%
; of a manifest is one flat colour. helm/gotmpl looks livelier purely because
; that grammar HAS token classes (variables, calls, keywords); yaml does not.
;
; The grammar can't tell these apart, but the text can. Each rule below re-tags
; an already-captured value by its shape, using #lua-match? (Lua patterns, NOT
; regex -- no alternation, and % is the escape).
;
; ORDER IS LOAD-BEARING: at equal priority the LAST matching capture wins, so
; these run after the generic @string.yaml.value rules above and progress from
; general to specific. Moving a block up will silently disable the ones it
; shadows.
;
; Every name degrades gracefully: an undefined @string.yaml.image falls back
; @string.yaml.image -> @string.yaml -> @string, i.e. exactly today's cyan. So
; a rule that stops matching costs nothing, and colours are opt-in per group in
; lua/config/theme_baseline.lua.

; --- Paths: /healthz, ./chart, values.yaml, ca.crt --------------------------
((plain_scalar (string_scalar) @string.yaml.path)
  (#lua-match? @string.yaml.path "^%.?%.?/"))

((plain_scalar (string_scalar) @string.yaml.path)
  (#lua-match? @string.yaml.path "^[%w_%-%.]+%.[%a][%a][%a]?[%a]?$"))

; --- URLs: https://…, oci://…, git@… ---------------------------------------
((plain_scalar (string_scalar) @string.yaml.url)
  (#lua-match? @string.yaml.url "^%a[%w%+%-%.]*://"))

; --- Quantities: 512Mi, 500m, 2Gi, 30s, 100ms -------------------------------
; Digits followed by a unit suffix. k8s resource quantities and Go durations
; both land here; a bare 8080 stays @number via the integer_scalar rule above.
((plain_scalar (string_scalar) @number.yaml.quantity)
  (#lua-match? @number.yaml.quantity "^%d+%.?%d*%a+$"))

; --- Versions: v1, apps/v1, networking.k8s.io/v1beta1, 1.2.3 ----------------
((plain_scalar (string_scalar) @string.yaml.version)
  (#lua-match? @string.yaml.version "^[%w%.%-]*/?v%d+[%w]*$"))

; Two numeric parts is enough: catches 1.2.3 and 1.25, but also 1.9.x and 1.4-rc1
; which a three-numeric-part pattern silently missed (common in setup-* actions).
((plain_scalar (string_scalar) @string.yaml.version)
  (#lua-match? @string.yaml.version "^v?%d+%.%d+"))

; --- Enum-like CamelCase: Deployment, RollingUpdate, ClusterIP, Always ------
; The single most common value shape in k8s manifests and the one most worth
; seeing at a glance -- it is almost always an API enum or a Kind.
((plain_scalar (string_scalar) @type.yaml.enum)
  (#lua-match? @type.yaml.enum "^%u%l[%w]*$"))

; --- Bare lowercase words: plan, apply, write, choice, main, default --------
; (added 2026-07-27) A single short lowercase word as a value is a selector
; from a fixed vocabulary (GHA permissions, input types, branch names), not
; prose. Without this class a workflow's `permissions:` block or an input's
; options list is a wall of plain string colour: keys + one value colour = the
; "two colours" read. Multi-word prose ("Terraform action") has spaces and
; never matches; paths/versions/urls carry . / digits and are shape-classed
; above (earlier captures win in nvim, later patterns override — this sits
; after the specific shapes so any scalar they claimed stays theirs... but
; treesitter gives LATER patterns priority, so exclude their shapes here:
; letters only, no dots, no slashes, no digits. Booleans/null are distinct
; scalar node types and never reach string_scalar.
; VALUE-POSITION ONLY (fixed 2026-07-27): the first cut matched any bare
; plain_scalar — and yaml KEYS are plain scalars too, so `path:`, `helm:`,
; `server:` lit up in the word colour. Same field-anchoring as the value
; rules at the top of this file: keys can never match these patterns.
((block_mapping_pair
  value: (flow_node (plain_scalar (string_scalar) @string.yaml.word)))
  (#lua-match? @string.yaml.word "^%l%l?%l?%l?%l?%l?%l?%l?%l?%l?%l?%l?$"))
((block_sequence_item
  (flow_node (plain_scalar (string_scalar) @string.yaml.word)))
  (#lua-match? @string.yaml.word "^%l%l?%l?%l?%l?%l?%l?%l?%l?%l?%l?%l?$"))
((flow_pair
  value: (flow_node (plain_scalar (string_scalar) @string.yaml.word)))
  (#lua-match? @string.yaml.word "^%l%l?%l?%l?%l?%l?%l?%l?%l?%l?%l?%l?$"))

; --- CONSTANT_CASE: LOG_LEVEL, POSTGRES_HOST -------------------------------
; Env var names, which appear as VALUES under `- name:` in a container spec.
((plain_scalar (string_scalar) @constant.yaml.env)
  (#lua-match? @constant.yaml.env "^%u[%u%d_]+$"))

; --- Conditions: inputs.action == 'plan' || inputs.action == 'apply' -------
; `if:` expressions in Actions. They are code, but yaml hands them over as one
; plain scalar, so they sat in the same cyan as every ordinary value despite
; being the one line in a step you actually have to read carefully. Matched by
; the operators rather than by key name, so it also catches `when:` in Argo and
; any other tool that puts a boolean expression in a scalar.
((plain_scalar (string_scalar) @string.yaml.condition)
  (#lua-match? @string.yaml.condition "[=!<>]="))

((plain_scalar (string_scalar) @string.yaml.condition)
  (#lua-match? @string.yaml.condition "||"))

((plain_scalar (string_scalar) @string.yaml.condition)
  (#lua-match? @string.yaml.condition "&&"))

; --- Image refs: registry.example.com/api:1.2.3, nginx:1.25 ----------------
; Last, and deliberately so: an image ref also matches the path and version
; shapes above, and this is the reading that should win.
((plain_scalar (string_scalar) @string.yaml.image)
  (#lua-match? @string.yaml.image "^[%w%.%-_]+/?[%w%.%-_/]*:[%w%.%-_]+$"))

; GitHub Actions refs: actions/checkout@v4, hashicorp/setup-terraform@v3.
; Same capture as image refs on purpose -- both are "a pinned external artifact
; at a version", they are the single most common value in a workflow file, and
; giving them one colour means uses:/image: read the same way.
((plain_scalar (string_scalar) @string.yaml.image)
  (#lua-match? @string.yaml.image "^[%w%-_%.]+/[%w%-_%.]+@[%w%.%-_]+$"))

; ============================================================================
; Top-level keys vs nested keys
; ============================================================================
;
; The other axis yaml actually has: document-root keys (apiVersion, kind,
; metadata, spec) are the manifest's skeleton, and everything else hangs off
; them. Only the root is captured; nested keys keep plain @property.yaml, so
; the existing field colour is untouched by design.

; The capture sits on (string_scalar), NOT on the enclosing (flow_node), even
; though both span the same text. Upstream captures @property at string_scalar
; depth, and when two captures overlap the one on the INNER node wins no matter
; which query file is loaded last -- capturing the flow_node here silently
; loses every time.
(document
  (block_node
    (block_mapping
      (block_mapping_pair
        key: (flow_node (plain_scalar (string_scalar) @property.yaml.toplevel))))))

; ============================================================================
; Second-level keys — the middle rung of the key ramp        (added 2026-07-26)
; ============================================================================
;
; The toplevel rule above gives the manifest skeleton its own colour, but
; everything below it was one flat @property.yaml no matter how deep. In a
; k8s manifest or an Actions workflow that is most of the file, so nesting
; carried no colour information at all.
;
; This captures EXACTLY depth 2 (document > mapping > pair > mapping > pair).
; Depth 3 and deeper do not match and keep plain @property.yaml, giving a
; three-rung ramp: toplevel (brightest) > level2 (mid) > deeper (dimmest).
;
; Degrades like every other rule here: with no colour assigned,
; @property.yaml.level2 -> @property.yaml and nothing changes.
(document
  (block_node
    (block_mapping
      (block_mapping_pair
        value: (block_node (block_mapping (block_mapping_pair
          key: (flow_node (plain_scalar (string_scalar) @property.yaml.level2)))))))))

; ============================================================================
; Merge keys — `<<: *anchor`                                 (added 2026-07-26)
; ============================================================================
;
; `<<` is not punctuation to the grammar; it is an ordinary string_scalar in
; key position, so it inherited the key colour and read as a field named "<<".
; It is an operator, and it belongs with the anchors it works with.
;
; MUST stay after the level2 rule above: `<<` matches that rule too, and at
; equal priority the LAST matching capture wins. Moving this up silently gives
; the merge key back to the key ramp.
((plain_scalar (string_scalar) @punctuation.special.merge)
  (#eq? @punctuation.special.merge "<<"))

; ============================================================================
; Document markers — `---` and `...`                         (added 2026-07-26)
; ============================================================================
;
; Anonymous nodes on (document). In a multi-doc manifest these are the only
; separator between one object and the next and they rendered as plain text.
;
; NOT added here: (block_scalar). It compiles and matches, but it spans the
; whole `run: |` body, and those bodies carry an injected bash parser whose
; highlights this would sit on top of. The `|` / `>` indicators are already
; captured as @punctuation.special above, which is the part worth seeing.
(document "---" @punctuation.special.doc)
(document "..." @punctuation.special.doc)

; ============================================================================
; Prose keys — `name:` is not an enum                        (added 2026-07-26)
; ============================================================================
;
; The CamelCase enum rule above was written for k8s, where `kind: Deployment`
; and `type: RollingUpdate` genuinely are API constants worth spotting. But it
; matches on SHAPE, and a GitHub Actions step name is prose that happens to be
; capitalised -- so `- name: Checkout` was painted as an API enum.
;
; Worse, it was inconsistent: `Checkout` is one CamelCase word and matched, but
; `Configure AWS credentials` has spaces and did not, so identical fields came
; out in two different colours depending on how many words the name had.
;
; Keyed on the FIELD, not the shape: a value under one of these keys is prose,
; whatever it looks like. Must stay at the end of this file -- it re-tags values
; the enum rule already claimed, and at equal priority the last capture wins.
((block_mapping_pair
   key: (flow_node (plain_scalar (string_scalar) @_prosekey))
   value: (flow_node (plain_scalar (string_scalar) @string.yaml.value)))
 (#any-of? @_prosekey "name" "description" "title" "summary" "displayName"))
