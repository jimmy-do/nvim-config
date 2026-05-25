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
