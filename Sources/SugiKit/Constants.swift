let headerLength = 8

let singlePatchCount = 64
let singlePatchDataLength = 131

let multiPatchCount = 64
let multiPatchDataLength = 77

let drumHeaderLength = 11
let drumDataLength = 682
let drumNoteCount = 61
let drumNoteLength = 11

let effectPatchCount = 32
let effectPatchDataLength = 35

let allPatchDataLength = 15_123  // full bank, including SysEx header

let totalDataLength =
    headerLength +
    singlePatchCount * singlePatchDataLength +
    multiPatchCount * multiPatchDataLength +
    effectPatchCount * effectPatchDataLength +
    1

