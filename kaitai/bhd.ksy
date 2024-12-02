meta:
  id: bhd
  file-extension: bhd
  endian: le
seq:
  - id: frames_offset
    type: u2
  - id: unknown1
    type: u2
  - id: version
    type: u2
  - id: num_balls
    type: u2
  - id: start_frame_no
    type: u4
  - id: total_frames
    type: u4
  - id: unknown2
    type: s2
    repeat: expr
    repeat-expr: 11
  - id: ball_sizes
    type: u2
    repeat: expr
    repeat-expr: num_balls
  - id: animation_count
    type: u2
  - id: ends
    type: u2
    repeat: expr
    repeat-expr: animation_count
  
instances:
  frames:
    pos: frames_offset
    type: animation(_index)
    repeat: expr
    repeat-expr: animation_count
    
types:
  animation:
    params:
      - id: index
        type: u2
    seq:
      - id: frame_offsets
        type: u4
        repeat: expr
        repeat-expr: (_parent.ends[index] - _parent.ends[index - 1])
        if: index > 0
      - id: frame_offsets2
        type: u4
        repeat: expr
        repeat-expr: _parent.ends[index]
        if: index == 0