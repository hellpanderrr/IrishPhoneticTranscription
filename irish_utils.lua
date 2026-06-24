-- irish_utils.lua
-- Utility functions extracted from irish.lua

local status, ustring_lib = pcall(require, "ustring.ustring")

if not status then
    error("ustring module not found.")
end

local ulower, usub, ulen, ufind, umatch, ugsub, ugmatch, N = ustring_lib.lower,
    ustring_lib.sub,
    ustring_lib.len,
    ustring_lib.find,
    ustring_lib.match,
    ustring_lib.gsub,
    ustring_lib.gmatch,
    ustring_lib.toNFC

local utils = {}

-- Memoization helper
local function memoize(fn)
    local cache = {}
    return function(...)
        local key = table.concat({...}, ",")
        if cache[key] == nil then
            cache[key] = fn(...)
        end
        return cache[key]
    end
end
utils.memoize = memoize
utils.ulower = ulower
utils.usub = usub
utils.ulen = ulen
utils.ufind = ufind
utils.umatch = umatch
utils.ugsub = ugsub
utils.ugmatch = ugmatch
utils.N = N

-- Debug printing with category filtering
local function debug_print_minimal(category, ...)
    if C and C.MINIMAL_DEBUG_ENABLED and C.STAGE_DEBUG_ENABLED and C.STAGE_DEBUG_ENABLED[category] then
        print("    MIN_DBG (" .. category:sub(1, 10) .. "): " ..
            table.concat({...}, "\t"))
    end
end
utils.debug_print_minimal = debug_print_minimal

-- Map index translation from phonetic to original orthographic indices
local function get_original_indices_from_map(map, new_s, new_e)
    if not map or #map == 0 or new_s <= 0 then
        return new_s, (new_e - new_s + 1)
    end

    -- Check for stress marker special case first
    if new_s == 1 and new_e == 1 and map[1] and map[1].marker and map[1].name == "stress" then
        return 0, 0 -- Stress marker has no direct ortho span
    end

    local relevant_map_entries = {}
    for _, entry in ipairs(map) do
        if not entry.marker and
            math.max(entry.phon_s, new_s) <= math.min(entry.phon_e, new_e) then
            table.insert(relevant_map_entries, entry)
        end
    end

    if #relevant_map_entries == 0 then
        for _, entry in ipairs(map) do
            if not entry.marker and entry.phon_s <= new_s and entry.phon_e >= new_e then
                table.insert(relevant_map_entries, entry)
            end
        end
    end

    if #relevant_map_entries == 0 then
        return new_s, (new_e - new_s + 1)
    end

    local min_ortho = math.huge
    local max_ortho = -math.huge
    for _, entry in ipairs(relevant_map_entries) do
        if entry.ortho_s < min_ortho then min_ortho = entry.ortho_s end
        if entry.ortho_e > max_ortho then max_ortho = entry.ortho_e end
    end

    return min_ortho, (max_ortho - min_ortho + 1)
end
utils.get_original_indices_from_map = get_original_indices_from_map

-- Check if a vowel character has a stress mark (primary 'ˈ' or secondary 'ˌ')
local function is_stressed_vowel_phonetic(vowel_char)
    if not vowel_char then return false end
    -- In IPA, stress markers are separate characters preceding the stressed syllable
    -- This checks if the vowel is immediately preceded by a stress marker in the phonetic string
    -- Note: This is a placeholder - actual implementation depends on context
    return false
end
utils.is_stressed_vowel_phonetic = is_stressed_vowel_phonetic

-- String helper references (from ustring library)
-- These are documented here for reference; they are loaded from ustring.ustring in the main module
-- utils.ulen     -- ustring.len
-- utils.usub     -- ustring.sub
-- utils.umatch   -- ustring.match
-- utils.ufind    -- ustring.find
-- utils.ugsub    -- ustring.gsub
-- utils.ulower   -- ustring.lower
-- utils.ureverse -- ustring.reverse (if available)

return utils