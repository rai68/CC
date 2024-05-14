
local TO_START = "gateDialerv2.lua" -- Local file path
local URL = "https://raw.githubusercontent.com/rai68/CC/main/" .. TO_START


local function downloadFile(url, destination)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        local file = io.open(destination, "w")
        file:write(content)
        file:close()
        return true
    else
        return false
    end
end

local function executeFile(file)
    shell.run(file)
    print("program closed")
    print("Restarting...")
    os.sleep(1)
    term.clear()
end

local function areFilesDifferent(file1, file2)
    local f1 = io.open(file1, "r")
    local content1 = f1:read("*a")
    f1:close()

    local f2 = io.open(file2, "r")
    local content2 = f2:read("*a")
    f2:close()

    return content1 ~= content2
end

while true do
    sleep(0.2)
    downloadFile(URL, "tmp.lua")
    sleep(0.2)
    if areFilesDifferent(TO_START, "tmp.lua") then
        fs.delete(TO_START)
        fs.copy("tmp.lua", TO_START)
    end
    sleep(0.2)
    executeFile(TO_START)
end