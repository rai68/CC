
local URL = "https://raw.githubusercontent.com/username/repository/branch/file.lua" -- Replace with your GitHub file URL
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
        print("Error executing file:", err)
        print("Restarting...")
        os.sleep(5)  -- Adjust the delay before restarting if needed
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
    if not fs.exists(TO_START) then
        downloadFile(URL, TO_START)
    else
        if areFilesDifferent(TO_START, "temp_file.lua") then
            fs.remove(TO_START)
            fs.copy("temp_file.lua", TO_START)
        end
    end
    executeFile(TO_START)
end