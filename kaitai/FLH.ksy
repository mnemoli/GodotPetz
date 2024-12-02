meta:
  id: flh
  file-extension: flh
  endian: le
seq:
  - id: lw1
    type: u4
  - id: framecount
    type: u2
  - id: maxwidth
    type: u2
  - id: maxheight
    type: u2
  - id: padding
    type: u2
  - id: frames
    type: anim
    repeat: expr
    repeat-expr: framecount
types:
  anim:
    seq:
      - id: x1
        type: u2
      - id: y1
        type: u2
      - id: x2
        type: u2
      - id: y2
        type: u2
      - id: zero
        type: u4
      - id: f
        type: u4
      - id: name
        type: str
        encoding: UTF-8
        size: 16
      - id: flags
        type: u4
      - id: offset
        type: u4