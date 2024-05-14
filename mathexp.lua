luaxp = require("luaxp")

chatBox = peripheral.find("chatBox")

string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end


while true do
    local event, username, message, uuid, isHidden = os.pullEvent("chat")
    if isHidden then
        if message:startswith("math ") then
            local shortened_str = string.sub(message, 5)
            chatBox.sendMessage("".. username .. ", evaluating: " .. shortened_str , "Maths")
            sleep(1.05)
            local r, m = luaxp.compile(shortened_str)
            local res, m = luaxp.run(r)
            print(res, m)
            if res == nil and m ~= nil then
                chatBox.sendMessage("".. username .. ", I failed from: " .. luaxp.dump(m.message), "Maths")
            elseif res ~= nil and m == nil then
                local res, m = luaxp.dump(res)
                chatBox.sendMessage("".. username .. ", I evaluated: " .. tostring(res) , "Maths")
            else
                chatBox.sendMessage("".. username .. ", error." , "Maths")
            end
        end
    end
end