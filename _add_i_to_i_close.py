# Add I_TO_I_CLOSE lexical override block to 10_vowels.lua
with open("passes/10_vowels.lua", "rb") as f:
    data = f.read()

# Find the AAI_TO_AI closing 'end' to insert after it
# The marker is: if AAI_TO_AI[w] then token.phon = "aː" end
marker = b"if AAI_TO_AI[w] then token.phon = \"a\xcb\x90\" end"
pos = data.find(marker)

if pos < 0:
    print("Marker not found!")
    # Debug: show content around AAI_TO_AI
    idx = data.find(b"AAI_TO_AI")
    if idx >= 0:
        print(f"Around AAI_TO_AI: {data[idx:idx+80]}")
else:
    insert_at = pos + len(marker)

    insert_text = (
        b"\n      end\n"
        b"      -- Lexical quality overrides: \xc9\xaa \xe2\x86\x92 i in specific words\n"
        b"      if ortho == \"i\" and context.word_ortho then\n"
        b"        local w = context.word_ortho:lower()\n"
        b"        local I_TO_I_CLOSE = { insim=true, [\"s\xc3\xadnid\"]=true, [\"gh\xc3\xa9araigh\"]=true }\n"
        b"        if I_TO_I_CLOSE[w] then token.phon = \"i\" end\n"
        b"      end"
    )

    data = data[:insert_at] + insert_text + data[insert_at:]

    with open("passes/10_vowels.lua", "wb") as f:
        f.write(data)
    print("Inserted I_TO_I_CLOSE block")

# Verify compilation
import subprocess
result = subprocess.run(
    ["F:/soft/lua/lua.exe", "-e", 'local f=loadfile("passes/10_vowels.lua"); if f then print("OK") else print(select(2, loadfile("passes/10_vowels.lua"))) end'],
    capture_output=True, text=True
)
print(result.stdout.strip())
