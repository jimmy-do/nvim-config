; extends

; JSON block scalars (keys ending in .json)
(block_mapping_pair
  key: (flow_node) @_key
  (#lua-match? @_key "%.json$")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "json")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))

; YAML block scalars (keys ending in .yaml or .yml)
(block_mapping_pair
  key: (flow_node) @_key
  (#lua-match? @_key "%.ya?ml$")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "yaml")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))

; TOML block scalars (keys ending in .toml)
(block_mapping_pair
  key: (flow_node) @_key
  (#lua-match? @_key "%.toml$")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "toml")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))

; Shell script block scalars (keys ending in .sh)
(block_mapping_pair
  key: (flow_node) @_key
  (#lua-match? @_key "%.sh$")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "bash")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))

; Bash script block scalars (keys ending in .bash)
(block_mapping_pair
  key: (flow_node) @_key
  (#lua-match? @_key "%.bash$")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "bash")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))

; Dockerfile block scalars (key named exactly "Dockerfile")
(block_mapping_pair
  key: (flow_node) @_key
  (#eq? @_key "Dockerfile")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "dockerfile")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))

; Dockerfile block scalars (keys ending in .dockerfile)
(block_mapping_pair
  key: (flow_node) @_key
  (#lua-match? @_key "%.dockerfile$")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "dockerfile")
    (#set! injection.combined)
    (#offset! @injection.content 0 1 0 0)))
