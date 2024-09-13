local data_save = {
    turn_count = 0,
    forward_count = 0,
    turn_threshold = 1
}

PICKAXE = 'minecraft:diamond_pickaxe'
MODEM = 'computercraft:wireless_modem_advanced'

selected_item = 'NULL'

function selectPickaxe()
    if selected_item == PICKAXE then
        return true
    else
        turtle.select(16)
        turtle.equipLeft()
        selected_item = PICKAXE
        return true
    end
end

function selectModem()
    if selected_item == MODEM then
        return true
    else
        turtle.select(16)
        turtle.equipLeft()
        selected_item = MODEM
        return true
    end

end

function getStartItem()
    turtle.select(16)
    local selectedNow = turtle.getItemDetail()['name']
    print(selectedNow)
    if selectedNow == PICKAXE then
        selected_item = MODEM
        return true
    else
        turtle.equipLeft()
        selected_item = MODEM
        return true
    end

end

local function loadSave()
    if fs.exists("data_digi_mover.txt") then
        local file = io.open("data_digi_mover.txt", "r")
        data_save = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("data_digi_mover.txt", "w")
    file:write(textutils.serialise(data_save))
    file:close()
end

loadSave()

-- eq modem

getStartItem()

selectModem()
modem = peripheral.find('modem')
modem.transmit(47301, 47301 , 'rai_dmp')

-- eq pickaxe




while true do
    if turtle.getFuelLevel() < 10 then
        -- equpt modem and loop distance forever
        selectModem()
        modem = peripheral.find('modem')
        while true do 
            sleep(1)
            
            modem.transmit(47301, 47301 , 'rai_dmp_nofuel')
        end
    end
    if not peripheral.find("digitalMiner") then
        -- if digital miner not placed, place it
        turtle.select(1)
        turtle.placeUp()

        turtle.turnLeft()
        turtle.turnLeft()
        turtle.back()

        turtle.select(2)
        turtle.place()

        turtle.back()
        turtle.up()
        turtle.up()
        turtle.up()

        turtle.select(3)
        turtle.placeDown()

        turtle.forward()
        turtle.forward()
    else
        print("digiminer already placed, skipping placement..")
    end
    local digi = peripheral.wrap("bottom")
    digi.start()
    digi.setAutoEject(true)


    selectModem()
    print('1')
    sleep(1)
    local modemR = peripheral.find('modem')
    repeat
        sleep(2)
        term.clear()
        term.setCursorPos(1,1)
        
        modemR.transmit(47301, 47301 , 'rai_dmp')
        print("Ores left: "..digi.getToMine())
        print("Data:")
        print("turn_count: "..data_save.turn_count)
        print("forward_count: "..data_save.forward_count)
        print("turn_threshold: "..data_save.turn_threshold)
    until digi.getToMine() == 0

    print("Changing Position!")
    --eqipt pickaxe and pick up digital miner
    selectPickaxe()

    
    digi.setAutoEject(false)
    digi.stop()

    turtle.back()
    turtle.back()

    turtle.select(3)
    turtle.digDown()

    turtle.down()
    turtle.down()
    turtle.down()
    turtle.forward()

    turtle.select(2)
    turtle.dig()

    turtle.forward()

    turtle.select(1)
    turtle.digUp()

    turtle.turnLeft()
    turtle.turnLeft()

    for i1=1, 64 do
        turtle.forward()
        turtle.dig()
        term.setCursorPos(1,1)
        term.write("Moving: "..i1.."/64")
    end

    data_save.forward_count = data_save.forward_count + 1
    if data_save.forward_count >= data_save.turn_threshold then
        turtle.turnRight()
        data_save.forward_count = 0
        data_save.turn_count = data_save.turn_count + 1
        if data_save.turn_count >= 2 then
            data_save.turn_threshold = data_save.turn_threshold+1
            data_save.turn_count = 0
        end
    end
    writeSave()

    selectPickaxe()
end