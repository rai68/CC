-- Initialize the player detector peripheral
local detector = peripheral.find("playerDetector")

-- Trusted players list
local trusted = {"Skrytio"}

-- Table to keep track of players currently in range
local nearBy = {}

-- Gate control class
cGate = {
    new = function(self, closeDir, openDir, toggleDir)
        -- Determine initial state based on detectDir


        local internal = {
            toggleDir = toggleDir,
            closeDir = closeDir,
            openDir = openDir,
            moving = false,  -- Track if the gate is currently moving
            actionQueue = {} -- Queue to hold pending open/close actions
        }
        self.__index = self
        return setmetatable(internal, self)
    end,

    close = function(self)
        -- If the gate is already moving or is already closed, do nothing

        -- Add close action to the queue
        table.insert(self.actionQueue, "close")
        return true
    end,

    open = function(self)
        -- If the gate is already moving or is already open, do nothing

        -- Add open action to the queue
        table.insert(self.actionQueue, "open")
        return true
    end,

    toggleRedstone = function(self, side)
        redstone.setOutput(side, true)
        sleep(0.2)
        redstone.setOutput(side, false)
    end,

    processQueue = function(self)
        while true do
            if not self.moving and #self.actionQueue > 0 then
                self.moving = true
                local action = table.remove(self.actionQueue, 1)

                if action == "close" then
                    if not redstone.getInput(self.closeDir) then
                        print("Closing")
                        self:toggleRedstone(self.toggleDir)
                        -- Wait until the gate is fully closed
                        while not redstone.getInput(self.closeDir) do
                            sleep(0.1)
                        end
                    end

                elseif action == "open" then
                    if not redstone.getInput(self.openDir) then
                        self:toggleRedstone(self.toggleDir)
                        print("Opening")
                        -- Wait until the gate is fully open
                        while not redstone.getInput(self.openDir) do
                            sleep(0.1)
                        end
                    end
                end
                sleep(0.4)
                self.moving = false
            end
            sleep(0.1) -- Small sleep to prevent excessive CPU usage
        end
    end,
}

-- Initialize the gate
local gate = cGate:new("front","back", "right")

table.insert(gate.actionQueue, "close")



-- Function to get the list of players currently in range
local function getPlayersInRange()
    return detector.getPlayersInRange(2)
end

-- Function to check if a player is in the trusted list
local function isTrusted(playerName)
    for _, trustedPlayer in ipairs(trusted) do
        if trustedPlayer == playerName then
            return true
        end
    end
    return false
end

-- Main function to monitor players and control the gate
local function monitorPlayers()
    while true do
        -- Get the current list of players in range
        local currentPlayersInRange = getPlayersInRange()
        
        -- Create a set from the currentPlayersInRange for quick lookup
        local currentPlayersSet = {}
        for _, playerName in ipairs(currentPlayersInRange) do
            currentPlayersSet[playerName] = true
        end
        
        -- Check for players who have left the range
        for playerName, _ in pairs(nearBy) do
            if not currentPlayersSet[playerName] then
                -- Player has left the range
                print(playerName .. " LEAVING")
                if isTrusted(playerName) then
                    print("CLOSE")
                    gate:close()
                end
                -- Remove player from the nearBy list
                nearBy[playerName] = nil
            end
        end
        
        -- Check for players who have entered the range
        for _, playerName in ipairs(currentPlayersInRange) do
            if not nearBy[playerName] then
                -- Player has entered the range
                print(playerName .. " ENTERING")
                if isTrusted(playerName) then
                    print("OPEN")
                    gate:open()
                end
                -- Add player to the nearBy list
                nearBy[playerName] = true
            end
        end
        
        -- Sleep for a short duration to avoid excessive CPU usage
        sleep(1)
    end
end

-- Run the gate monitoring process and player monitoring in parallel
parallel.waitForAll(
    function() gate:processQueue() end,
    monitorPlayers
)