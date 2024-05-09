
local URL = "https://raw.githubusercontent.com/rai68/CC/main/gateDialerv2.lua" 
local TO_START = "gateDialerv2.lua" -- Local file path

local function downloadFile(url, destination)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        local file = io.open(destination, "w")
        file:write(content)
        file:close()
        print("Downloaded new file from URL:", url)
        return true
    else
        print("Failed to download file from URL:", url)
        return false
    end
end

local function executeFile(file)
    local ok, err = pcall(dofile, file)
    if not ok then
        print("File closed file:", err)
        print("Restarting...")
        os.sleep(1) 
    end
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
        fs.remove(TO_START)
        fs.copy("tmp.lua", TO_START)
    end
    sleep(0.2)
    executeFile(TO_START)
end