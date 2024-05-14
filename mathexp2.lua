luaxp = require("luaxp")

chatBox = peripheral.find("chatBox")

string.startswith = function(self, str)
    return self:find('^' .. str) ~= nil
end

-- Table to store the context for each player
local playerContexts = {}

while true do
    local event, username, message, uuid, isHidden = os.pullEvent("chat")
    if isHidden then
        if message:startswith("eval ") then
            local expression = string.sub(message, 6)
            chatBox.sendMessage(username .. ", evaluating: " .. expression, "Maths")
            sleep(1.05)

            -- Get or create the player's context
            local context = playerContexts[username] or {}
            local parsedExp, parseErr = luaxp.compile(expression)
            
            if parsedExp then
                local result, evalErr = luaxp.run(parsedExp, context)
                if result then
                    chatBox.sendMessage(username .. ", I evaluated: " .. tostring(result), "Maths")
                else
                    chatBox.sendMessage(username .. ", evaluation error: " .. luaxp.dump(evalErr.message), "Maths")
                end
            else
                chatBox.sendMessage(username .. ", parsing error: " .. luaxp.dump(parseErr.message), "Maths")
            end
        elseif message:startswith("set ") then
            local rest = string.sub(message, 5)
            local spaceIndex = rest:find(" ")
            if spaceIndex then
                local varName = rest:sub(1, spaceIndex - 1)
                local value = rest:sub(spaceIndex + 1)
                if varName and value then
                    -- Get or create the player's context
                    playerContexts[username] = playerContexts[username] or {}
                    playerContexts[username][varName] = tonumber(value) or value
                    chatBox.sendMessage(username .. ", set " .. varName .. " to " .. value, "Maths")
                else
                    chatBox.sendMessage(username .. ", invalid set command.", "Maths")
                end
            else
                chatBox.sendMessage(username .. ", invalid set command.", "Maths")
            end
        elseif message:startswith("clear") then
            playerContexts[username] = nil
            chatBox.sendMessage(username .. ", your context has been cleared.", "Maths")
        end
    end
end