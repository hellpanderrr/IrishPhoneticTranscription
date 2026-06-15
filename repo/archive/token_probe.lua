local core = require("irish_core")
local irish = require("irish_main")
local tokens = require("irish_tokens")

local N = core.N
local ulen = core.ulen
local usub = core.usub
local ugsub = core.ugsub
local umatch = core.umatch

local function levenshtein(str1, str2)
    local m = ulen(str1)
    local n = ulen(str2)
    local v0, v1 = {}, {}
    for i = 0, n do v0[i] = i end
    for i = 1, m do
        v1[0] = i
        for j = 1, n do
            local cost = (usub(str1, i, i) == usub(str2, j, j)) and 0 or 1
            v1[j] = math.min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + cost)
        end
        for j = 0, n do v0[j] = v1[j] end
    end
    return v1[n]
end

local words = {
    "glas",
    "glais",
    "alt",
    "ailt",
    "seomra",
    "trom",
    "bonn",
    "fón",
    "sheol",
    "thóg",
    "shíl",
    "a Sheáin",
    "aithrí",
    "brath",
    "cnoc",
    "tnúth",
    "Tadhg",
    "'ur",
    "íocfaidh",
    "marcaigh",
    "chugham",
    "láimh",
    "leabhar",
    "greamaím",
    "dugaire",
    "Gaelach",
    "Gaedhlaing",
}

print("\n--- Token Prototype Side-by-Side Probe ---\n")
print(string.format("%-18s | %-28s | %-28s | %s", "Input", "Production", "TokenProto", "Dist"))
print(string.rep("-", 92))

local total_distance = 0
for _, word in ipairs(words) do
    local production = irish.transcribe(N(word))
    local proto, token_state = tokens.transcribe_tokens(N(word))
    local distance = levenshtein(production, proto)
    total_distance = total_distance + distance

    print(string.format("%-18s | %-28s | %-28s | %d", word, production, proto, distance))

    if distance > 0 or word:match("sheol") or word:match("thóg") or word:match("brath") or word:match("cnoc") or word:match("láimh") or word:match("leabhar") then
        print("  TOKENS:")
        for i, token in ipairs(token_state) do
            print(string.format(
                "    %02d ortho=%q type=%s phon=%q palatal=%s stress=%s indices=[%d,%d]",
                i,
                token.ortho or "",
                token.type or "",
                token.phon or "",
                tostring(token.palatal),
                tostring(token.stress),
                token.ortho_indices and token.ortho_indices[1] or 0,
                token.ortho_indices and token.ortho_indices[2] or 0
            ))
        end
    end
end

print("\nSummary:")
print(string.format("  Cases: %d", #words))
print(string.format("  Total production-vs-token distance: %d", total_distance))
print(string.format("  Average distance: %.4f", total_distance / #words))
