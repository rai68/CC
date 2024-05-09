
getStatus = function ( override, sym)
    if sym == 'symbols' then
        if not override.expect_incoming and not override.expect_outgoing and not override.incoming_wormhole and not override.outgoing_wormhole and not override.open then
            return '-'
        elseif override.expect_incoming and not override.incoming_wormhole and not override.open then
            return '\x19' , colors.green
        elseif override.expect_incoming and override.incoming_wormhole and override.open then
            return '\x19' , colors.green
        elseif override.incoming_wormhole and not override.expect_incoming and not override.open then
            return '\x19'
        elseif override.incoming_wormhole and not override.expect_incoming and override.open then
            return '\x19'
        elseif override.outgoing_wormhole and not override.expect_outgoing and not override.open and override.dhd_dial then
            return '\x18'
        elseif override.outgoing_wormhole and not override.expect_outgoing and override.open and override.dhd_dial then
            return '\x18'
        elseif override.outgoing_wormhole and not override.expect_outgoing and not override.open and not override.dhd_dial then
            return '\x18'
        elseif override.outgoing_wormhole and not override.expect_outgoing and override.open and not override.dhd_dial  then
            return '\x18'
        elseif override.outgoing_wormhole and override.expect_outgoing and not override.open and not override.dhd_dial then
            return '\x18'
        elseif override.outgoing_wormhole and override.expect_outgoing and override.open and not override.dhd_dial then
            return '\x18'
        else 
            return 'Error : No match state found'
        end
    else
        if override.charging then
            return 'Charging'
        elseif not override.expect_incoming and not override.expect_outgoing and not override.incoming_wormhole and not override.outgoing_wormhole and not override.open and not override.dhd_dial then
            return 'Idle'
        elseif override.incoming_wormhole and not override.expect_incoming and not override.open then
            return 'Unknown Incoming'
        elseif override.incoming_wormhole and not override.expect_incoming and override.open then
            return 'Unknown Incoming Established'
        elseif (override.expect_incoming and not override.incoming_wormhole and not override.open) or (override.expect_incoming and override.incoming_wormhole and not override.open) then
            return 'Scheduled Incoming'
        elseif override.expect_incoming and override.incoming_wormhole and override.open then
            return 'Scheduled Incoming Established'
        elseif override.outgoing_wormhole and not override.expect_outgoing and not override.open and override.dhd_dial then
            return 'Local DHD Dialing'
        elseif override.outgoing_wormhole and not override.expect_outgoing and override.open and override.dhd_dial then
            return 'Local DHD Established'
        elseif override.outgoing_wormhole and not override.expect_outgoing and not override.open and not override.dhd_dial then
            return 'Unknown Outgoing'
        elseif override.outgoing_wormhole and not override.expect_outgoing and override.open and not override.dhd_dial  then
            return 'Unknown Outgoing Established'
        elseif override.outgoing_wormhole and override.expect_outgoing and not override.open and not override.dhd_dial then
            return 'Scheduled Outgoing'
        elseif override.outgoing_wormhole and override.expect_outgoing and override.open and not override.dhd_dial then
            return 'Scheduled Outgoing Established'
        else 
            return 'Error : No match state found'
        end
    end
end


function formatAddress(arr, reverse)
    local transformedStr = "-" .. table.concat(arr, "-") .. "-"
    
    if reverse then
        local reversedArr = {}
        for i = #arr, 1, -1 do
            table.insert(reversedArr, arr[i])
        end
        return reversedArr
    else
        return transformedStr
    end
end


function generateBar( percentage, bar_points )
    -- Calculate the number of filled points and empty points
    local filled_points = math.floor(percentage / 100 * bar_points)
    local empty_points = bar_points - filled_points
    -- Generate the bar string
    local bar = "[" .. string.rep("|", filled_points) .. string.rep("-", empty_points) .. "]"
    return bar
end

function formatFe( fe_value )
    local prefixes = {"", "k", "M", "G"}
    local prefix_index = 1

    while fe_value >= 1000 and prefix_index < #prefixes do
        fe_value = fe_value / 1000
        prefix_index = prefix_index + 1
    end
    local prefix = prefixes[prefix_index]
    local suffix 
    if prefix == "" then
        suffix = " FE"
    else
        suffix = "FE"
    end

    return fe_value, prefix .. suffix
end


function pad_string(str,length, char, dots)
    if not char then
        char = " "  -- Default padding character is space
    end

    if dots then
        local maxLength = length - 3 -- Account for the length of '...'
        if #str > maxLength then
            return string.sub(str, 1, maxLength) .. "..."
        end
    else
        if #str > length then
            return string.sub(str, 1, length)
        end
    end

    local padding = length - #str
    return str .. string.rep(char, padding)
end

function center_number(num, total_length, fill_char)
    local num_str = tostring(num)
    local remaining_length = total_length - #num_str - 1 -- Account for the last fill character
    local left_length = math.floor(remaining_length / 2)
    local right_length = remaining_length - left_length
    return string.rep(fill_char, left_length) .. num_str .. string.rep(fill_char, right_length) .. fill_char
end

function getClosestGate(tbl)
    local lowestDistance = math.huge
    local tableWithLowestDistance = nil

    for _, value in ipairs(tbl) do
        if value.distance and type(value.distance) == "number" then
            if value.distance ~= -1 and value.distance <= 50 then
                if value.distance < lowestDistance then
                    lowestDistance = value.distance
                    tableWithLowestDistance = value
                end
            end
        end
    end

    return tableWithLowestDistance
end

string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end

-- end gate object ----------------------------------------------------------------------
-- start network controller object ------------------------------------------------------
networkController = {
    new = function( self , modem)
        local internal = { 

            modem = peripheral.find(modem) or error('No modem found',1),

            id = os.getComputerID(),

            monitor = nil,

            addresses_book = {},
            dial_queue = {},
            next_dial = {},
            last_outgoing_address = {},

            _MESSAGE_CHANNEL = os.getComputerID(),
            _BROADCAST_CHANNEL = 24325,

            _STATE_UPDATE = 'rai_bc_state_update',
            _UPDATE_ONE = 'rai_update_one',

            --advertisement idenifiers
            _ADVERTISE_ADJ_GATE = "rai_advert_network_gate",
            _RENEW_GATE_ADVERTISEMENT_ALL = 'rai_network_renew_all',
            _RENEW_GATE_ADVERTISEMENT = 'rai_network_renew',

            -- emit gate events

            _REMOTE_SHUTDOWN = 'rai_stargate_c_remote_shutdown',
            _REMOTE_DIAL_OUT = 'rai_stargate_c_remote_dialout',

            _OUTGOING_DIAL = 'rai_msg_outgoing_dial',
            _PING = 'rai_ping',
            _DIAL_INIT = 'rai_dial_init',


        }
        self.__index = self
        return setmetatable( internal, self )
    end,

    setMonitorController = function ( self, monitorC )
        self.monitor = monitorC
    end,

    tickNetwork = function ( self )
        while true do
            -- only get modem data events

            local id, data, protocol, distance, isBroadcast = self:Receive()


            if isBroadcast then
                print(protocol)
                if protocol == self._ADVERTISE_ADJ_GATE then
                    if distance == nil then
                        distance = -1
                    else
                        data.distance = math.ceil(distance)
                    end
                    print(self:addAddress(data))
                elseif protocol == self._STATE_UPDATE then
                    if distance == nil then
                        distance = -1
                    else
                        data.distance = math.ceil(distance)
                    end
                    self:updateAddressData(data)
                elseif protocol == self._PING then
                    if distance == nil then
                        distance = -1
                    else
                        data.distance = math.ceil(distance)
                    end
                    self:updateAddressData(data)
                end


            elseif id == self.id then

            end
            ::messageHandler_end::
        end
    end,





    orderAddresses = function ( self ) 
        local function sortingFunction(pri1, pri2) 
            return pri1.priority < pri2.priority
        end

        table.sort(self.addresses_book, sortingFunction)
    end,

    addAddress = function ( self , sharable)
        --``` addAddress ( sharableL Object - Shared Gate) - adds address to local address book
        -- returns if new gate in book
        sharable.priority = self:getHighestPriority() + 1
        for idx, Tgate in ipairs(self.addresses_book) do
            if textutils.serialiseJSON(Tgate['address']) == textutils.serialiseJSON(sharable['address']) then
                self:updateAddressData( sharable )
                return false
            end
        end
        table.insert(self.addresses_book, sharable)
        self:orderAddresses()
        return true
    end,
    
    updateAddressData = function(self, shareable)
        for _, element in ipairs(self.addresses_book) do
            if textutils.serialiseJSON(element['address']) == textutils.serialiseJSON(shareable['address']) then
                for key, newValue in pairs(shareable) do
                    if element[key] ~= newValue then
                        element[key] = newValue
                    end
                end
                self:orderAddresses()
                break
            end
        end
    end,

    run = function ( self, ...)
        -- this function runs the gate routines and others passed to it
        local args = {...}
        self.modem.open(self.id)
        self.modem.open(self._BROADCAST_CHANNEL)


        self:Broadcast(0, self._RENEW_GATE_ADVERTISEMENT_ALL)
        parallel.waitForAll(function() self:tickNetwork() end, function() self.monitor:tickMonitor() end, function() self.monitor:tickMonitorEvents() end, function() self.monitor:tick() end )
    end,

    Send = function (self,to, data, protocol)
        local block = {
            data=data,
            protocol=protocol,
        }
        print(self.modem)
        self.modem.transmit(to, self._MESSAGE_CHANNEL , block)
    end,

    Broadcast = function (self, data, protocol)
        local block = {
            data=data,
            protocol=protocol,
        }
        self.modem.transmit(self._BROADCAST_CHANNEL, self.id, block)
    end,

    Receive = function ( self , protocol) 
        local Got = false
        local isBroadcast = false
        while true do 
            local event, side, channel, replyChannel, data, distance = os.pullEvent('modem_message')
            if channel == self.id then
                if protocol and dataFull.protocol == protocol then
                    return replyChannel, data.data, data.protocol, distance
                else
                    return replyChannel, data.data, data.protocol, distance
                end
            elseif channel == self._BROADCAST_CHANNEL then
                isBroadcast = true
                return replyChannel, data.data, data.protocol, distance, isBroadcast
            end
        end
    end,     

    remoteDial = function ( self , who , address)
        self:Send(who, address, self._REMOTE_DIAL_OUT)
    end,

    orderAddresses = function ( self ) 
        local function sortingFunction(pri1, pri2) 
            return pri1.priority < pri2.priority
        end

        table.sort(self.addresses_book, sortingFunction)
    end,

    getHighestPriority = function ( self )
        local last = 0
        for idx, val in ipairs(self.addresses_book) do
            if val.priority > last then
                last = val.priority
            end
        end
        return last
    end

}
-- end network controller object ------------------------------------------------------

monitorController = {
    -- this table holds most data for the dialing computer and values
    new = function( self , networkC)
        local internal = { 

            id = os.getComputerID(),

            network = networkC,

            option = {
                buffer = "",
            },

            state = {
                address_page = {
                    name = 'address_page',
                    active = true,
                    
                },
    
                address_config_page = {
                    name = 'address_config_page',
                    active = false,
                    address = nil,
                    options = {

                    },
                },
            },
            closestGate = nil,
            overrideGate = nil,
            pause = false,
            scroll = 0,
            isHoldingCTRL = false,
            isHoldingALT = false,

            _background_colour = colors.black,
            _border_colour = colors.lightGray,
        }
        self.__index = self
        return setmetatable( internal, self )
    end,

    tick = function ( self )
        while true do
            sleep(0.05)
            self.closestGate = getClosestGate(self.network.addresses_book)
        end
    end,

    tickMonitorEvents = function ( self )
        while true do
            local event, key, x, y, p4, p5 = os.pullEvent()
            if event == 'timer' then
                goto next_event
            end
            print(event, key, x, y, p4, p5)
            if event == 'key' or event == 'key_up' then
                

            elseif event == 'char' then



            elseif event == 'mouse_click' then
                if key == 1 then
                    if x > 24 and x < 27 and self.overrideGate ~= nil and y == 1 then
                        --remove gate override
                        self.overrideGate = nil
                    elseif y > 2 and y < 11 and self:getActive() == self.state.address_page.name then
                        --remote dial from address page
                        local f = y - 2
                        local address = self:getAddressPage()[f]
                        local id
                        if self.overrideGate == nil then
                            id = self.closestGate.id
                        else
                            id = self.overrideGate.id
                        end
                        self.network:remoteDial(id,address)
                        
                    elseif y == 2 and x == 2 and self:getActive() == self.state.address_config_page.name then
                        self:setActive(self.state.address_page.name)
                    end

                elseif key == 2 then
                    if y > 2 and y < 11 then
                        --add gate override
                        local f = y - 2
                        local address = self:getAddressPage()[f]
                        self.overrideGate = address
                    end
                elseif key == 3 and self:getActive() == self.state.address_page.name then
                    if y > 2 or y < 11 then
                        local f = (y - 2)
                        local address = self:getAddressPage()[f]
                        self:setActive(self.state.address_config_page.name, 'address', address)
                    end

                end


            elseif event == 'scroll' and self:getActive() == self.state.address_page.name and self:getActive() ~= self.state.address_config_page.name then
                if self.scroll <= 1 then
                    self.scroll = 1
                else
                    self.scroll = self.scroll + p1
                end

            end
            ::next_event::
        end
    end,

    tickMonitor = function ( self )
        while true do
            sleep(0.1)
            --local event, side, channel, replyChannel, data, distance = os.pullEvent()
            --print(event, side, channel, replyChannel, data, distance )
            term.clear()
            term.setCursorPos(1,1)
            if self:getActive() == self.state.address_page.name then
                if self.closestGate ~= nil then
                    if self.overrideGate ~= nil then
                        write(pad_string(tostring(self.overrideGate.id), 4 , " "))
                        term.setBackgroundColour(self._border_colour)
                        write(" ")
                        term.setBackgroundColour(self._background_colour)
                        write(" " .. pad_string(self.overrideGate.name, 16, " "))
                        write("<")
                        term.blit("XX","00","ee")
                        write(">\n")
                    else
                        write(pad_string(tostring(self.closestGate.id), 4 , " "))
                        term.setBackgroundColour(self._border_colour)
                        write(" ")
                        term.setBackgroundColour(self._background_colour)
                        write(" " .. pad_string(self.closestGate.name, 16, " ") .. "<" .. self.closestGate.distance .. ">\n")
                    end
                else
                    write("0000")
                    self:writeBlock()
                    print(" No gate in range")
                end
                term.setBackgroundColour(self._border_colour)
                print("                          ")
                term.setBackgroundColour(self._background_colour)
                local addresses = self:getAddressPage()
                for idx, val in ipairs(addresses) do
                    if #self.network.addresses_book ~= 0 then
                        write(center_number(idx,4, " "))
                        self:writeBlock() write(" ")
                        print(pad_string(val.name, 17," "))
                    end
                end
                if #addresses < 10 then
                    for i=1, (10 - #addresses) do
                        write("    ")
                        self:writeBlock() write(" ")
                        print(pad_string(" ", 17," "))
                    end
                end
                self:writeBorderLine()
            elseif self:getActive() == self.state.address_config_page.name and self:getActive() ~= self.state.address_page.name  then
                --forming gate config page
                local editGate = self.state.address_config_page.address
                self:writeBorderLine()
                self:writeBlock()
                term.blit("X","0","e")
                self:writeBlock()

                
                write(" " .. pad_string(editGate.name, 20, " ") .. " ")
                term.setBackgroundColour(self._border_colour)
                write(" \n")
                term.setBackgroundColour(self._background_colour)
                
                self:writeBorderLine()
            end
        end
    end,

    getAddressPage = function ( self )
        local result = {}
        local startIndex = math.max(self.scroll, 2) -- Ensure we don't include the first element if scroll is 1
        local endIndex = math.min(startIndex + 9, #self.network.addresses_book) -- Limit to at most 10 elements

        -- If we are at the last 10 elements or beyond, adjust the start index
        if endIndex == #self.network.addresses_book then
            startIndex = #self.network.addresses_book - 9
        end

        for i = startIndex, endIndex do
            table.insert(result, self.network.addresses_book[i])
        end

        return result
    end,

    getActive = function ( self )
        for key, value in pairs(self.state) do
            if value.active == true then
                return value.name
            end
        end
    end,

    setActive = function ( self , name, Nkey, Nvalue)
        for key, value in pairs(self.state) do
            if value.name == name then
                if Nkey and Nvalue then
                    self.state[value.name][Nkey] = Nvalue
                end
                self.state[value.name].active = true
            else
                self.state[value.name].active = false
            end
        end
    end,

    writeBorderLine = function ( self )
        term.setBackgroundColour(self._border_colour)
        write("                          \n")
        term.setBackgroundColour(self._background_colour)
    end,

    
    writeBlock = function ( self )
        term.setBackgroundColour(self._border_colour)
        write(" ")
        term.setBackgroundColour(self._background_colour)
    end,

}

local networkContr = networkController:new('modem')


local monitorContr = monitorController:new(networkContr)

networkContr:setMonitorController(monitorContr)



function startup()	-- eventHandler, handles all events from the computer
    --sleep(3)
    --print("dialing gate to addr")
    --networkContr:remoteDial(233, {address = {8,13,1,24,12,28,10,32,0},unknown = true, delay = 3})
    --sleep(1)
    networkContr:remoteDial(253, {address = {13,30,4,27,33,28,22,34,0},unknown = true, delay = 1})

    --sleep(2)

end

-- parallel setup stuff

startup()

networkContr:run()