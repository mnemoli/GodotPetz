meta:
  id: srf
  file-extension: srf
  endian: le
seq:
  - id: scale
    type: u4
  - id: h
    type: u4
  - id: w
    type: u4
  - id: surface
    type: u1
    repeat: expr
    repeat-expr: w * h
  - id: horizon
    type: u4
    repeat: expr
    repeat-expr: w