
local TO_START = "gateDialerv2.lua" -- Local file path
local URL = "https://raw.githubusercontent.com/rai68/CC/main/gateDialerv2.lua"

local EXTRAS = {}

local function downloadFile(url, destination)
    print("Download begin from: " .. url)
    local response = http.get(url)
    if response then
        print("Download saving")
        local content = response.readAll()
        response.close()
        local file = io.open(destination, "w")
        file:write(content)
        file:close()
        print("Download saved")
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
    downloadFile(URL .. TO_START,TO_START)
    for _,url in pairs(EXTRAS) do 
        local last_slash_index = url:find("/[^/]*$")
        local content_after_last_slash = url:sub(last_slash_index + 1)
        downloadFile(url, content_after_last_slash)
    end
    sleep(0.2)
    sleep(0.2)
    executeFile(TO_START)
end