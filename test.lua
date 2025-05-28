ustring = require('ustring.ustring')
local ufind = ustring.find -- Use the (potentially) UTF-8 aware find function

--------------------------------------------------------------------------------
print("\n--- Re-Test ULTRA-SIMPLE for 'ɔlk' using mw.ustring.find ---")
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_OLC = "aæɔeəiɪuʊʌ" 
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_OLC = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_OLC .. "])"
local C1_L_BROAD_TEST_OLC = "([lL])" 
local C2_KPT_BROAD_TEST_OLC = "([kpt])" 
local test_pattern_olc_core = "^" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_OLC .. C1_L_BROAD_TEST_OLC .. C2_KPT_BROAD_TEST_OLC .. "$"
local test_string_olc = "ɔlk"

print("Input String: ##" .. test_string_olc .. "##")
print("ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST: ##" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_OLC .. "##")
print("Test Pattern: ##" .. test_pattern_olc_core .. "##")
local s_olc, e_olc, cap_vowel_olc, cap_c1_olc, cap_c2_olc = ufind(test_string_olc, test_pattern_olc_core)
print("\nmw.ustring.find result:")
print("  s, e:", s_olc or "nil", e_olc or "nil")
print("  cap_vowel:", cap_vowel_olc or "nil"); 
print("  cap_c1:", cap_c1_olc or "nil"); 
print("  cap_c2:", cap_c2_olc or "nil")
if s_olc then print("CONCLUSION: RE-TEST CORE OLC (mw.ustring) MATCHED!") else print("CONCLUSION: RE-TEST CORE OLC (mw.ustring) DID NOT MATCH.") end
print("-------------------------------------\n")

--------------------------------------------------------------------------------
print("\n--- Re-Test ULTRA-SIMPLE for 'ɛl'f'' using mw.ustring.find ---")
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_SEILF = "aæɔeəiɪuʊʌɛ" -- Added ɛ just to be sure for this test
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_SEILF = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_SEILF .. "])"
local C1_L_SLENDER_TEST_SEILF = "([lL]')" 
local C2_F_SLENDER_TEST_SEILF = "(f')"   
local test_pattern_seilf_core = "^" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_SEILF .. C1_L_SLENDER_TEST_SEILF .. C2_F_SLENDER_TEST_SEILF .. "$"
local test_string_seilf = "ɛl'f'" 

print("Input String: ##" .. test_string_seilf .. "##")
print("ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST: ##" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_SEILF .. "##")
print("Test Pattern: ##" .. test_pattern_seilf_core .. "##")
local s_seilf, e_seilf, cap_vowel_seilf, cap_c1_seilf, cap_c2_seilf = ufind(test_string_seilf, test_pattern_seilf_core)
print("\nmw.ustring.find result:")
print("  s, e:", s_seilf or "nil", e_seilf or "nil")
print("  cap_vowel:", cap_vowel_seilf or "nil"); 
print("  cap_c1:", cap_c1_seilf or "nil"); 
print("  cap_c2:", cap_c2_seilf or "nil")
if s_seilf then print("CONCLUSION: RE-TEST CORE SEILF (mw.ustring) MATCHED!") else print("CONCLUSION: RE-TEST CORE SEILF (mw.ustring) DID NOT MATCH.") end
print("-------------------------------------\n")

--------------------------------------------------------------------------------
print("\n--- Test for 'olc' (phonetic 'ˈɔlk') with ORIGINAL PREFIX using mw.ustring.find ---")
local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR_TEST_ORIG = "kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾ"
local ANY_CONSONANT_PHONETIC_PATTERN_TEST_ORIG = "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR_TEST_ORIG .. "]"
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_ORIG_OLC = "aæɔeəiɪuʊʌ" 
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_ORIG_OLC = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_ORIG_OLC .. "])"

local EPENTHESIS_PATTERN_PREFIX_ORIG = "^(ˈ?((?:" .. ANY_CONSONANT_PHONETIC_PATTERN_TEST_ORIG .. "*'?))?)(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_ORIG_OLC .. ")"
local EPENTHESIS_PATTERN_SUFFIX_ORIG = "(#?)$"

local C1_L_BROAD_TEST_ORIG_OLC = "([lL])" 
local C2_KPT_BROAD_TEST_ORIG_OLC = "([kpt])" 
local test_pattern_olc_full_orig = EPENTHESIS_PATTERN_PREFIX_ORIG .. C1_L_BROAD_TEST_ORIG_OLC .. C2_KPT_BROAD_TEST_ORIG_OLC .. EPENTHESIS_PATTERN_SUFFIX_ORIG
local test_string_olc_full = "ˈɔlk"

print("Input String: ##" .. test_string_olc_full .. "##")
print("Test Pattern: ##" .. test_pattern_olc_full_orig .. "##")
local s_olc_f, e_olc_f, cap_stress_olc_f, cap_pre_cons_olc_f, cap_vowel_olc_f, cap_c1_olc_f, cap_c2_olc_f, cap_boundary_olc_f = ufind(test_string_olc_full, test_pattern_olc_full_orig)
print("\nmw.ustring.find result:")
print("  s, e:", s_olc_f or "nil", e_olc_f or "nil")
print("  1 (stress_cap):", cap_stress_olc_f or "nil"); print("  2 (pre_vowel_cons_cap):", cap_pre_cons_olc_f or "nil")
print("  3 (vowel_nuc_cap):", cap_vowel_olc_f or "nil"); print("  4 (c1_cap - L_BROAD):", cap_c1_olc_f or "nil")
print("  5 (c2_cap - KPT_BROAD):", cap_c2_olc_f or "nil"); print("  6 (boundary_cap):", cap_boundary_olc_f or "nil")
if s_olc_f then print("CONCLUSION: ORIGINAL PREFIX OLC (mw.ustring) MATCHED!") else print("CONCLUSION: ORIGINAL PREFIX OLC (mw.ustring) DID NOT MATCH.") end
print("-------------------------------------\n")

--------------------------------------------------------------------------------
print("\n--- Test for 'seilf' (phonetic 's'ɛl'f'') with ORIGINAL PREFIX using mw.ustring.find ---")
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_ORIG_SEILF = "aæɔeəiɪuʊʌɛ"
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_ORIG_SEILF = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR_TEST_ORIG_SEILF .. "])"
local EPENTHESIS_PATTERN_PREFIX_ORIG_SEILF = "(ˈ?((?:" .. ANY_CONSONANT_PHONETIC_PATTERN_TEST_ORIG .. "*'?))?)(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS_TEST_ORIG_SEILF .. ")"


local C1_L_SLENDER_TEST_ORIG_SEILF = "([lL]')" 
local C2_F_SLENDER_TEST_ORIG_SEILF = "(f')"   
local test_pattern_seilf_full_orig = EPENTHESIS_PATTERN_PREFIX_ORIG_SEILF .. C1_L_SLENDER_TEST_ORIG_SEILF .. C2_F_SLENDER_TEST_ORIG_SEILF .. EPENTHESIS_PATTERN_SUFFIX_ORIG
local test_string_seilf_full = "s'il'f'" 

print("Input String: ##" .. test_string_seilf_full .. "##")
print("Test Pattern: ##" .. test_pattern_seilf_full_orig .. "##")
local s_seilf_f, e_seilf_f, cap_stress_seilf_f, cap_pre_cons_seilf_f, cap_vowel_seilf_f, cap_c1_seilf_f, cap_c2_seilf_f, cap_boundary_seilf_f = ufind(test_string_seilf_full, test_pattern_seilf_full_orig)
print("\nmw.ustring.find result:")
print("  s, e:", s_seilf_f or "nil", e_seilf_f or "nil")
print("  1 (stress_cap):", cap_stress_seilf_f or "nil"); print("  2 (pre_vowel_cons_cap):", cap_pre_cons_seilf_f or "nil")
print("  3 (vowel_nuc_cap):", cap_vowel_seilf_f or "nil"); print("  4 (c1_cap - L_SLENDER):", cap_c1_seilf_f or "nil")
print("  5 (c2_cap - F_SLENDER):", cap_c2_seilf_f or "nil"); print("  6 (boundary_cap):", cap_boundary_seilf_f or "nil")
if s_seilf_f then print("CONCLUSION: ORIGINAL PREFIX SEILF (mw.ustring) MATCHED!") else print("CONCLUSION: ORIGINAL PREFIX SEILF (mw.ustring) DID NOT MATCH.") end
print("-------------------------------------\n")