


local gate = peripheral.find("advanced_crystal_interface")


local dial = true

gate.disconnectStargate()

function event()
    event = os.pullEvent()

    if event[1] == "stargate_outgoing_wormhole" then
        dial = false
    elseif event[1] == "stargate_reset" then
        dial = false
    end
end


function dial()
    while true do
        sleep()
        if dial then
            for idx,val in ipairs({26,35,15,28,33,1,8,22}) do
                sleep()
                gate.engageSymbol(val)
            end
        end
    end
end




parallel.waitForAll(dial, event)
