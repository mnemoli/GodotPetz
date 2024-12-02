meta:
  id: scp
  file-extension: scp
  endian: le
seq:
  - id: intro
    size: 62
  - id: total_states
    type: u4
  - id: start_state
    type: u4
  - id: unknown
    type: u8
  - id: actioncount
    type: u4
  - id: actions
    type: action
    repeat: expr
    repeat-expr: actioncount
  - id: size_of_scripts
    type: u4
  - id: scripts
    type: scripts
    size: (size_of_scripts) * 4
  - id: ender
    size: 62
types:
  action:
    seq:
      - id: action_id
        type: u4
      - id: script_count
        type: u4
      - id: start_state
        type: u4
      - id: end_state
        type: u4
      - id: loop_modifier
        type: u4
      - id: changes_state
        type: u2
      - id: glue_ball
        type: u2
      - id: layer_mask
        type: u2
      - id: unknown4
        type: u2
      - id: start_offset
        type: u4
    instances:
      scripts:
        io: _root._io
        pos: 86 + (_root.actioncount * 32) + (start_offset * 4)
        type: script
        repeat: expr
        repeat-expr: script_count
  scripts:
    seq:
      - id: scripts
        type: script
        repeat: eos
  script:
    seq:
      - id: size
        type: u4
      - id: command
        type: s4
        enum: verbs
        repeat: expr
        repeat-expr: size - 1
enums:
  verbs:
    0x40000000: startpos
    0x40000001: actiondone0
    0x40000002: actionstart1
    0x40000003: alignscripts0
    0x40000004: alignballtoptsetup3
    0x40000005: alignballtoptgo0
    0x40000006: alignballtoptstop0
    0x40000007: alignfudgeballtoptsetup2
    0x40000008: blendtoframe3
    0x40000009: cuecode1
    0x4000000a: debugcode1
    0x4000000b: disablefudgeaim1
    0x4000000c: disableswing0
    0x4000000d: donetalking0
    0x4000000e: donetalking1
    0x4000000f: enablefudgeaim1
    0x40000010: enableswing1
    0x40000011: endblock0
    0x40000012: endblockalign0
    0x40000013: gluescripts0
    0x40000014: gluescriptsball1
    0x40000015: interruptionsdisable0
    0x40000016: interruptionsenable0
    0x40000017: lookatlocation2
    0x40000018: lookatlocationeyes2
    0x40000019: lookatrandompt0
    0x4000001a: lookatrandompteyes0
    0x4000001b: lookatsprite1
    0x4000001c: lookatspriteeyes1
    0x4000001d: lookatuser0
    0x4000001e: lookforward0
    0x4000001f: lookforwardeyes0
    0x40000020: null0
    0x40000021: null1
    0x40000022: null2
    0x40000023: null3
    0x40000024: null4
    0x40000025: null5
    0x40000026: null6
    0x40000027: playaction2
    0x40000028: playactionrecall2
    0x40000029: playactionstore2
    0x4000002a: playlayeredaction3
    0x4000002b: playlayeredaction4
    0x4000002c: playlayeredactioncallback5
    0x4000002d: playlayeredactioncallback6
    0x4000002e: playtransitiontoaction1
    0x4000002f: rand2
    0x40000030: resetfudger1
    0x40000031: resumefudging1
    0x40000032: resumelayerrotation1
    0x40000033: sequence2
    0x40000034: sequencetoend1
    0x40000035: sequencetostart1
    0x40000036: setblendoffset3
    0x40000037: setfudgeaimdefaults5
    0x40000038: setfudgerdrift2
    0x40000039: setfudgerrate2
    0x4000003a: setfudgertarget2
    0x4000003b: setfudgernow2
    0x4000003c: setheadtrackacuteness
    0x4000003d: setheadtrackmode1
    0x4000003e: setlayeredbaseframe2
    0x4000003f: setmotionscale1
    0x40000040: setmotionscale2
    0x40000041: setreverseheadtrack1
    0x40000042: setrotationpivotball1
    0x40000043: soundemptyqueue0
    0x40000044: soundloop1
    0x40000045: soundsetpan1
    0x40000046: soundplay1
    0x40000047: soundplay2
    0x40000048: soundplay3
    0x40000049: soundplay4
    0x4000004a: soundplay5
    0x4000004b: soundqueue1
    0x4000004c: soundqueue2
    0x4000004d: soundqueue3
    0x4000004e: soundqueue4
    0x4000004f: soundqueue5
    0x40000050: soundsetdefltvocpitch1
    0x40000051: soundsetpitch1
    0x40000052: soundsetvolume1
    0x40000053: soundstop0
    0x40000054: startlistening0
    0x40000055: startblockloop1
    0x40000056: startblockcallback2
    0x40000057: startblockchance1
    0x40000058: startblockdialogsynch0
    0x40000059: startblockelse0
    0x4000005a: startblocklisten0
    0x4000005b: stopfudging1
    0x4000005c: suspendfudging1
    0x4000005d: suspendlayerrotation1
    0x4000005e: tailsetneutral1
    0x4000005f: tailsetrestoreneutral1
    0x40000060: tailsetwag1
    0x40000061: targetsprite4
    0x40000062: throwme0
    0x40000063: endpos
  cuecodes:
    0x00: introdone
    0x01: intronotdone
    0x02: grabobject
    0x03: releaseobject
    0x04: lookatinterest
    0x05: lookatinteractor
    0x06: useobject
    0x07: swatobject
    0x08: gnawobject
    0x09: scratchobject
    0x0a: dighole
    0x0b: fillhole
    0x0c: trip
    0x0d: snoreactive
    0x0e: snorein
    0x0f: snoreout
    0x10: snoredream
    0x11: atefood
    0x12: scare
    0x13: stephandl
    0x14: stephandr
    0x15: stepfootl
    0x16: stepfootr
    0x17: stomphandl
    0x18: stomphandr
    0x19: stompfootl
    0x1a: stompfootr
    0x1b: land
    0x1c: scuff
    0x1d: showlinez
    0x1e: hidelinez
    0x1f: none
    0x20: cursor
    0x21: shelf
    0x22: otherpet
    0x23: focussprite1
    0x24: focussprite2
    0x25: focussprite3
    0x26: percentchance
    0x27: ifsoundadult
    0x28: isadoptionkit
  fudgers:
    0x00: rotation
    0x01: roll
    0x02: tilt
    0x03: headrotation
    0x04: headtilt
    0x05: headcock
    0x06: reyelidheight
    0x07: leyelidheight
    0x08: reyelidtilt
    0x09: leyelidtilt
    0x0a: eyetargetx
    0x0b: eyetargety
    0x0c: xtrans
    0x0d: ytrans
    0x0e: scalex
    0x0f: scaley
    0x10: scalez
    0x11: ballscale
    0x12: masterscale
    0x13: reyesizexxx
    0x14: leyesizexxx
    0x15: rarmsizexxx
    0x16: larmsizexxx
    0x17: rlegsizexxx
    0x18: llegsizexxx
    0x19: rhandsizexxx
    0x1a: lhandsizexxx
    0x1b: rfootsizexxx
    0x1c: lfootsizexxx
    0x1d: headsizexxx
    0x1e: bodyextend
    0x1f: frontlegextend
    0x20: hindlegextend
    0x21: faceextend
    0x22: headenlarge
    0x23: headenlargebalance
    0x24: earextend
    0x25: footenlarge
    0x26: footenlargebalance
    0x27: prerotation
    0x28: preroll
    0x29: addballz0
    0x2a: addballzflower1
    0x2b: addballzheart2
    0x2c: addballzquestion3
    0x2d: addballzexclamation4
    0x2e: addballzlightbulboff5
    0x2f: addballzstickman6
    0x30: addballzcrossbones7
    0x31: addballzlightning8
    0x32: addballzbrokenheart9
    0x33: addballzsnowone10
    0x34: addballzsnowtwo11
    0x35: addballzsnowthree12
    0x36: addballzlightbulbon13
    0x37: addballztears14
    0x38: addballzoddlove15
    0x39: morph
    0x3a: botheyelidheights
    0x3b: botheyelidtilts
    0x3c: botheyesizes
    0x3d: botharmsizes
    0x3e: bothlegsizes
    0x3f: rightlimbsizes
    0x40: leftlimbsizes
    0x41: alllimbsizes
    0x42: bothhandsizes
    0x43: bothfeetsizes
    0x44: rightdigitsizes
    0x45: leftdigitsizes
    0x46: alldigitsizes
    0x47: allfudgers