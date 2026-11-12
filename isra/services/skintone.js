.pragma library

const _toneSupported = new Set([0x261D, 0x26F9, 0x270A, 0x270B, 0x270C, 0x270D, 0x1F385, 0x1F3C2, 0x1F3C3, 0x1F3C4, 0x1F3C7, 0x1F3CA, 0x1F3CB, 0x1F3CC, 0x1F442, 0x1F443, 0x1F446, 0x1F447, 0x1F448, 0x1F449, 0x1F44A, 0x1F44B, 0x1F44C, 0x1F44D, 0x1F44E, 0x1F44F, 0x1F450, 0x1F466, 0x1F467, 0x1F468, 0x1F469, 0x1F46A, 0x1F46B, 0x1F46C, 0x1F46D, 0x1F46E, 0x1F46F, 0x1F470, 0x1F471, 0x1F472, 0x1F473, 0x1F474, 0x1F475, 0x1F476, 0x1F477, 0x1F478, 0x1F47C, 0x1F481, 0x1F482, 0x1F483, 0x1F485, 0x1F486, 0x1F487, 0x1F48F, 0x1F491, 0x1F4AA, 0x1F574, 0x1F575, 0x1F57A, 0x1F590, 0x1F595, 0x1F596, 0x1F645, 0x1F646, 0x1F647, 0x1F64B, 0x1F64C, 0x1F64D, 0x1F64E, 0x1F64F, 0x1F6A3, 0x1F6B4, 0x1F6B5, 0x1F6B6, 0x1F6C0, 0x1F6CC, 0x1F90C, 0x1F90F, 0x1F918, 0x1F919, 0x1F91A, 0x1F91B, 0x1F91C, 0x1F91D, 0x1F91E, 0x1F91F, 0x1F926, 0x1F930, 0x1F931, 0x1F932, 0x1F933, 0x1F934, 0x1F935, 0x1F936, 0x1F937, 0x1F938, 0x1F939, 0x1F93C, 0x1F93D, 0x1F93E, 0x1F977, 0x1F9B5, 0x1F9B6, 0x1F9B8, 0x1F9B9, 0x1F9BB, 0x1F9CD, 0x1F9CE, 0x1F9CF, 0x1F9D1, 0x1F9D2, 0x1F9D3, 0x1F9D4, 0x1F9D5, 0x1F9D6, 0x1F9D7, 0x1F9D8, 0x1F9D9, 0x1F9DA, 0x1F9DB, 0x1F9DC, 0x1F9DD, 0x1FAC3, 0x1FAC4, 0x1FAC5, 0x1FAF0, 0x1FAF1, 0x1FAF2, 0x1FAF3, 0x1FAF4, 0x1FAF5, 0x1FAF6, 0x1FAF7, 0x1FAF8])
const _modifiers = ["", "\uD83C\uDFFB", "\uD83C\uDFFC", "\uD83C\uDFFD", "\uD83C\uDFFE", "\uD83C\uDFFF"]

const _skinToneRegex = /[\uD83C\uDFFB-\uD83C\uDFFF]/g
const _emojiPresentationSelector = "\uFE0F"
const _twoFamilyEmojis = new Set(["\uD83D\uDC69\u200D\uD83D\uDC66", "\uD83D\uDC69\u200D\uD83D\uDC67", "\uD83D\uDC68\u200D\uD83D\uDC67", "\uD83D\uDC68\u200D\uD83D\uDC66"])

function supportsTone(emoji) {
    const cleaned = emoji.replace(_skinToneRegex, "");
    let i = 0;
    while (i < cleaned.length) {
        const cp = cleaned.codePointAt(i);
        if (_toneSupported.has(cp)) {
            return true;
        }
        i += (cp > 0xFFFF) ? 2 : 1;
    }
    return false;
}


function applySkinTone(emoji, toneIndex) {
    const cleaned = emoji.replace(_skinToneRegex, "");

    if (toneIndex === 0) {
        return cleaned;
    }

    const hasModifierBase = supportsTone(cleaned);
    if (!hasModifierBase) {
        return cleaned;
    }

    const baseCount = countModifierBases(cleaned);
    if (baseCount > 2 || (baseCount === 2 && _twoFamilyEmojis.has(cleaned))) {
        return cleaned;
    }

    const modifier = _modifiers[toneIndex];
    let result = "";
    let i = 0;

    while (i < cleaned.length) {
        const cp = cleaned.codePointAt(i);
        const char = String.fromCodePoint(cp);

        if (cp === 0xFE0F) {
            i += 1;
            continue;
        }

        result += char;

        if (_toneSupported.has(cp)) {
            result += modifier;
        }

        i += (cp > 0xFFFF) ? 2 : 1;
    }

    return result;
}

function countModifierBases(emoji) {
    let count = 0;
    let i = 0;
    while (i < emoji.length) {
        const cp = emoji.codePointAt(i);
        if (_toneSupported.has(cp)) {
            count++;
        }
        i += (cp > 0xFFFF) ? 2 : 1;
    }
    return count;
}

