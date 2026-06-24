local content = io.open("passes/10_vowels.lua", "rb"):read("*a")

-- Find the end of A_TO_AE block (right after "token.phon = \"æ\" end" + outer end)
local marker = [[then token.phon = "æ" end]]
local pos = content:find(marker, 1, true)
if not pos then print("MARKER NOT FOUND"); os.exit(1) end

-- Find the outer end (closing the if block) after this line
-- The line after should be "      end"
local end_line = content:find("end", pos + #marker)
-- Verify it looks right (should be "      end" at 6 spaces)
-- Now insert AFTER this closing end
local after_outer_end = content:find("\n", end_line)
if not after_outer_end then after_outer_end = content:find("\r", end_line) end

-- Build the insert text
local insert = [[
      -- Lexical quality overrides: a/ea → ɞ in specific words (beag, carráistí)
      if (ortho == "a" or ortho == "ea") and token.phon == "a" and context.word_ortho then
        local w = context.word_ortho:lower()
        local A_TO_OE = { beag=true, bheag=true, carráiste=true, carráistí=true }
        if A_TO_OE[w] then token.phon = "\x{00C9}\x{009E}" end  -- ɞ = U+025E
      end

      -- Lexical quality overrides: a/ea/ai → ɛ in specific words (bead, aicise, gair, daibhreas)
      if (ortho == "a" or ortho == "ea" or ortho == "ai") and token.phon == "a" and context.word_ortho then
        local w = context.word_ortho:lower()
        local A_TO_E = { bead=true, aicise=true, gair=true, daibhreas=true }
        if A_TO_E[w] then token.phon = "\x{00C9}\x{009B}" end  -- ɛ = U+025B
      end

      -- Lexical quality overrides: short i → ɪ in specific words (mire, mhire)
      if ortho == "i" and token.phon == "i" and context.word_ortho then
        local w = context.word_ortho:lower()
        local I_TO_I = { mire=true, mhire=true }
        if I_TO_I[w] then token.phon = "\x{00C9}\x{00AA}" end  -- ɪ = U+026A
      end

      -- buile: ui digraph gives i (uisce table), should be ɪ
      if ortho == "ui" and token.phon == "i" and context.word_ortho then
        local w = context.word_ortho:lower()
        if w == "buile" then token.phon = "\x{00C9}\x{00AA}" end
      end]]

content = content:sub(1, after_outer_end) .. insert .. content:sub(after_outer_end + 1)

io.open("passes/10_vowels.lua", "wb"):write(content)
print("DONE")
