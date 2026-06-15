-- Irish G2P entry point.
-- Delegates to the token-array pipeline (passes/).
-- Compatible API: irish.transcribe(word, dialect) -> phonetic_string

local engine = require("irish_engine_new")

return {
  transcribe = function(word, dialect)
    return engine.transcribe(word, dialect)
  end,
}
