function multipattern(patternWithChoices)
    local bracesPattern = "%b{}"
    local first, last = patternWithChoices:find(bracesPattern)
    local parts = {patternWithChoices:sub(1, (first or 0) - 1)}

    while first do
        local choicesStr = patternWithChoices:sub(first, last)
        local choices = {}

        for choice in choicesStr:gmatch("([^|{}]+)") do
            table.insert(choices, choice)
        end

        local prevLast = last
        first, last = patternWithChoices:find(bracesPattern, last)
        table.insert(parts, choices)
        table.insert(parts, patternWithChoices:sub(prevLast + 1, (first or 0) - 1))
    end

    local function combine(idx, str, results)
        local part = parts[idx]

        if part == nil then
            table.insert(results, str)
        elseif type(part) == 'string' then
            combine(idx + 1, str .. part, results)
        else
            for _, choice in ipairs(part) do
                combine(idx + 1, str .. choice, results)
            end
        end

        return results
    end

    return combine(1, '', {})
end

function tableToString(t)
    local function escapeStr(s)
        return string.format("%q", s):gsub("\\\n", "\\n")
    end

    local function toStr(val, indent, visited)
        local t = type(val)
        
        if t == "string" then
            return escapeStr(val)
        elseif t == "number" or t == "boolean" or t == "nil" then
            return tostring(val)
        elseif t == "function" then
            return "function(...)"
        elseif t ~= "table" then
            return escapeStr(tostring(val))
        end
        
        -- Handle table recursion
        visited = visited or {}
        if visited[val] then return "\"<cyclic reference>\"" end
        visited[val] = true
        
        -- Output for tables
        local indent2 = indent + 2
        local parts = {}
        local isArray = true
        local keys = {}
        
        -- Check type and collect keys
        local i = 1
        for k in pairs(val) do
            if k ~= i then isArray = false end
            keys[#keys+1] = k
            i = i + 1
        end
        
        -- Special handling for arrays
        if isArray and #keys > 0 then
            for _, v in ipairs(val) do
                parts[#parts+1] = string.rep(" ", indent2) .. toStr(v, indent2, visited)
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" 
                   .. string.rep(" ", indent) .. "}"
        end
        
        -- Handle key-value pairs
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end  -- First sort by type
            
            -- Then sort by value within same type
            if ta == "string" then return a < b
            elseif ta == "number" then return a < b
            else return tostring(a) < tostring(b)
            end
        end)
        
        for _, k in ipairs(keys) do
            local v = val[k]
            local keyStr = (type(k) == "string" and k:match("^[%a_][%w_]*$"))
                          and k 
                          or "[" .. toStr(k, 0, visited) .. "]"
                          
            parts[#parts+1] = string.rep(" ", indent2) .. keyStr .. " = " .. toStr(v, indent2, visited)
        end
        
        return "{\n" .. table.concat(parts, ",\n") .. "\n" 
               .. string.rep(" ", indent) .. "}"
    end

    return toStr(t, 0)
end

print(

tableToString(multipattern("a{b|c}d{e|f|g}h")))