
modem = peripheral.find('modem')

modem.open(47301)


local selected_item = 'pickaxe'







while true do
    sleep(0.3)
    local event, side, channel, replyChannel, data, distance = os.pullEvent('modem_message')
    if data == 'rai_dmp' or data == "rai_dmp_nofuel" then
        term.clear()
        print("Dist: ", distance)
    else 
        term.clear()
        print("N")
    end
end