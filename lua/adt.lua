local first_to_upper = function(str)
    return (str:gsub("^%l", string.upper))
end

local LUAVER = tonumber(_VERSION:match("Lua (%d.%d)"))

local length = (function()
    if LUAVER > 5.1 then
        return function(t) return #t end
    else
        return table.getn
    end
end)()

local unpack_table = (function()
    if LUAVER > 5.1 then
        return table.unpack
    else
        return unpack
    end
end)()

local build_variant = function(name, parameters)
    local num_parameters = 0
    if parameters ~= nil then
        num_parameters = length(parameters)
    end

    local unique = {}

    return setmetatable(unique, {
        __call =
            function(_, ...)
                local args = { ... }
                if length(args) ~= num_parameters then
                    error("Enum variant " ..
                        first_to_upper(name) .. " requires " .. tostring(num_parameters) .. " parameters")
                else
                    local variant = {}

                    for i, actual in ipairs(args) do
                        variant[parameters[i]] = actual
                    end

                    variant.is = function(variant_type)
                        return variant_type == unique
                    end

                    variant.match = function(branches)
                        if branches[name] ~= nil then
                            return branches[name](unpack_table(args))
                        elseif branches._ ~= nil then
                            return branches._(variant)
                        else
                            error("Non exhaustive pattern matching")
                        end
                    end

                    return setmetatable(variant, unique)
                end
            end
    })
end

return function(variants)
    assert(type(variants) == "table", "Invalid argument for building a closed adt: " .. type(variants))
    assert(variants.match == nil, "Key 'match' is reserved, please avoid it")
    assert(variants.match == nil, "Key 'is' is reserved, please avoid it")

    local Variants = {}
    for name, arguments in pairs(variants) do
        Variants[name] = build_variant(name, arguments)
    end

    return Variants
end
