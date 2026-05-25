; extends
;
; The upstream helm highlights.scm uses `; inherits: gotmpl`, but gotmpl.so
; is not a registered/installed parser, so that inheritance silently fails.
; This file restores all the gotmpl captures directly for the helm parser,
; which shares the same grammar node types since it is a fork of gotmpl.
;
; All priorities match the gotmpl query (110) so they override surrounding
; injected language highlights without conflicting with helm-specific rules.

; Variables — $name forms
((variable) @variable
  (#set! priority 110))

; Field access — .Values, .Chart.Name, .someField etc.
([
  (field)
  (field_identifier)
] @variable.member
  (#set! priority 110))

; Non-builtin function calls (builtins handled by upstream helm query)
(function_call
  function: (identifier) @function.call
  (#set! priority 105))

(method_call
  method: (selector_expression
    field: (field_identifier) @function.call
    (#set! priority 105)))

; Operators
([
  "|"
  "="
  ":="
] @operator
  (#set! priority 110))

; Delimiters
([
  "."
  ","
] @punctuation.delimiter
  (#set! priority 110))

; Brackets — action delimiters
([
  "{{"
  "}}"
  "{{-"
  "-}}"
  ")"
  "("
] @punctuation.bracket
  (#set! priority 110))

; Keywords — if / with / else / end
(if_action
  [
    "if"
    "else"
    "end"
  ] @keyword.conditional
  (#set! priority 110))

(with_action
  [
    "with"
    "else"
    "end"
  ] @keyword.conditional
  (#set! priority 110))

; Keywords — range loop
(range_action
  [
    "range"
    "else"
    "end"
  ] @keyword.repeat
  (#set! priority 110))

(continue_action
  "continue" @keyword.repeat
  (#set! priority 110))

(break_action
  "break" @keyword.repeat
  (#set! priority 110))

; Keywords — template definition / block
(define_action
  [
    "define"
    "end"
  ] @keyword.conditional
  (#set! priority 110))

(block_action
  [
    "block"
    "end"
  ] @keyword.conditional
  (#set! priority 110))

(template_action
  "template" @function.builtin
  (#set! priority 110))

; String literals
([
  (interpreted_string_literal)
  (raw_string_literal)
] @string
  (#set! priority 110))

((rune_literal) @string.special.symbol
  (#set! priority 110))

((escape_sequence) @string.escape
  (#set! priority 110))

; Numbers
([
  (int_literal)
  (imaginary_literal)
] @number
  (#set! priority 110))

((float_literal) @number.float
  (#set! priority 110))

; Booleans
([
  (true)
  (false)
] @boolean
  (#set! priority 110))

; nil constant
((nil) @constant.builtin
  (#set! priority 110))

; Comments  {{/* ... */}}
((comment) @comment @spell
  (#set! priority 110))
