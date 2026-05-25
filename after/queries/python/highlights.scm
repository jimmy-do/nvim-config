; extends

; All imported names in from-import statements → @module (dragonYellow).
; Overrides the generic @type (PascalCase), @constant (ALL_CAPS), and
; @variable (lowercase) catches from the upstream python query.

(import_from_statement
  name: (dotted_name
    (identifier) @module)
  (#set! priority 200))

(import_from_statement
  name: (aliased_import
    name: (dotted_name
      (identifier) @module)
    alias: (identifier) @module)
  (#set! priority 200))
