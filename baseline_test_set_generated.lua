local baseline_test_set = { {ortho="ceann", expected_ipa="cɑnˠ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="am", expected_ipa="ˈɑm", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="fonn", expected_ipa="fɔnˠ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="poll", expected_ipa="pɔlˠ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="trom", expected_ipa="t̪rɔm", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="corr", expected_ipa="kɔɾˠ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="bord", expected_ipa="bɔrd̪", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="tallann", expected_ipa="tɑlˠənˠ", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="seanchas", expected_ipa="ʃɑn̪xəs", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="im", expected_ipa="ˈiːmʲ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="roinnt", expected_ipa="rəinʲtʲ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="caill", expected_ipa="cɑːlʲ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="coill", expected_ipa="kəilʲ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="poinn", expected_ipa="pəinʲ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="cill", expected_ipa="ciːlʲ", dialect="connacht", phenomenon="Strong Sonorant"},
{ortho="bainne", expected_ipa="bʲainʲi", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="leabhar", expected_ipa="ləuər", dialect="connacht", phenomenon="Vocalized Fricative / Specific Diphthong"},
{ortho="amhrán", expected_ipa="əurrɑːn̪", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="samhradh", expected_ipa="səurrə", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="slaghdán", expected_ipa="sləidɑːn̪", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="adhradh", expected_ipa="əirə", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="laghadh", expected_ipa="ləiə", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="feabhas", expected_ipa="fʲəuəs", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="ghabh", expected_ipa="ɣəu", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="damhsa", expected_ipa="dəuəə", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="deifir", expected_ipa="dʲɛfʲiɾʲ", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="nimhe", expected_ipa="niː", dialect="connacht", phenomenon="Vocalized Fricative / Specific Diphthong"},
{ortho="suidhe", expected_ipa="siː", dialect="connacht", phenomenon="Vocalized Fricative / Specific Diphthong"},
{ortho="beidh", expected_ipa="bʲai", dialect="connacht", phenomenon="Vocalized Fricative / Specific Diphthong"},
{ortho="lae", expected_ipa="leː", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="scadán", expected_ipa="skʊdɑːn̪", dialect="connacht", phenomenon="Disyllabic Short-Long Raising"},
{ortho="cailín", expected_ipa="cɪlʲiːn̪", dialect="connacht", phenomenon="Disyllabic Short-Long Raising"},
{ortho="soláthar", expected_ipa="sɔlɑːhər", dialect="connacht", phenomenon="Auto-generated baseline"},
{ortho="bacán", expected_ipa="bʊkɑːn̪", dialect="connacht", phenomenon="Disyllabic Short-Long Raising"},
{ortho="fuinneog", expected_ipa="fɪnʲoːg", dialect="connacht", phenomenon="Disyllabic Short-Long Raising"},
{ortho="oileán", expected_ipa="ˈɔləɑːn̪", dialect="connacht", phenomenon="Disyllabic Short-Long Raising"},
{ortho="fear", expected_ipa="fʲɑːɾʲ", dialect="connacht", phenomenon="ea Allophony"},
{ortho="geal", expected_ipa="ɟɑl̪", dialect="connacht", phenomenon="ea Allophony"},
{ortho="bean", expected_ipa="bʲɑn̪", dialect="connacht", phenomenon="ea Allophony"},
{ortho="teach", expected_ipa="tʲæx", dialect="connacht", phenomenon="ea Allophony"},
{ortho="leaba", expected_ipa="lɑbə", dialect="connacht", phenomenon="ea Allophony"},
{ortho="seacht", expected_ipa="ʃɑxt̪", dialect="connacht", phenomenon="ea Allophony"},
}
old_print = print
irishPhonetics = require('irish')
print = old_print  
function run_my_tests(baseline_test_set)
    print(123)
    local failures = 0
    local successes = 0
    for i, test_case in ipairs(baseline_test_set) do
        -- Assuming your transcriber is in a module called 'my_transcriber'
        -- and has a function called 'transcribe'
        local got_ipa = irishPhonetics.transcribe(test_case.ortho)
        if got_ipa == test_case.expected_ipa then
            successes = successes + 1
            print(string.format("SUCCESS: %s -> Expected [%s], Got [%s]", test_case.ortho, test_case.expected_ipa, got_ipa))
        else
            failures = failures + 1
            print(string.format("FAILURE: %s", test_case.ortho))
            print(string.format("  Expected: [%s]", test_case.expected_ipa))
            print(string.format("  Got:      [%s]", got_ipa))
            print(string.format("  Phenom:   %s", test_case.phenomenon))
        end
    end
    print(string.format("\nTest Summary: %d Successes, %d Failures", successes, failures))
end
run_my_tests(baseline_test_set)
