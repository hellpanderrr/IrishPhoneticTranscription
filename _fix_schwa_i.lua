-- Add restore_i for ə→i bucket words: sínid, ghéaraigh, diagaire
local content = io.open("passes/10_vowels.lua", "rb"):read("*a")

-- Add sínid to verb_suffix_words table
local marker1 = [[["coisrig"] = true,]]
local pos1 = content:find(marker1, 1, true)
if not pos1 then print("MARKER1 NOT FOUND"); os.exit(1) end

local insert1 = [[
            ["sínid"] = true, ["ghéaraigh"] = true,]]
content = content:sub(1, pos1 + #marker1 - 1) .. insert1 .. content:sub(pos1 + #marker1)

-- Add diagaire to medial unstressed i list
local marker2 = [[w == "traidisiún"]]
local pos2 = content:find(marker2, 1, true)
if not pos2 then print("MARKER2 NOT FOUND"); os.exit(1) end

-- Find the end of this line (the closing ]] then " then ...)
local line_end = content:find("\n", pos2)
if not line_end then line_end = content:find("\r", pos2) end

local insert2 = [[ w == "diagaire" or]]
content = content:sub(1, line_end - 1) .. insert2 .. content:sub(line_end)

io.open("passes/10_vowels.lua", "wb"):write(content)
print("DONE")
