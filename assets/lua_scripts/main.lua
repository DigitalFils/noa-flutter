require("graphics")
require("state")

local graphics = Graphics.new()
local state = State.new()

local image_taken = false
local image_data_sent = false
local audio_data_sent = false
local last_autoexp_time = 0

-- Frame to phone flags
MESSAGE_GEN_FLAG = "\x10"
IMAGE_GEN_FLAG = "\x11"
WILDCARD_GEN_FLAG = "\x12"
AUDIO_DATA_FLAG = "\x13"
IMAGE_DATA_FLAG = "\x14"
TRANSFER_DONE_FLAG = "\x15"

-- Phone to Frame flags
MESSAGE_RESPONSE_FLAG = "\x20"
IMAGE_RESPONSE_FLAG = "\x21"

local function bluetooth_callback(message)
    if string.sub(message, 1, 1) == MESSAGE_RESPONSE_FLAG then
        if state:is("ON_IT") or state:is("WILDCARD") then
            graphics:clear()
            state:switch("PRINT_REPLY")
        end
        if state:is("PRINT_REPLY") then
            graphics:append_text(string.sub(message, 2), "\u{1F60E}")
        end
    elseif string.sub(message, 1, 1) == IMAGE_RESPONSE_FLAG then
        if state:is("ON_IT") then
            graphics:clear()
            state:switch("PRINT_IMAGE")
        end
        if state:is("PRINT_IMAGE") then
            -- TODO
        end
    end
end

local function send_data(data)
    local try_until = frame.time.utc() + 2
    while frame.time.utc() < try_until do
        if pcall(frame.bluetooth.send, data) then
            return
        end
    end
    state:switch("NO_CONNECTION")
end

frame.bluetooth.receive_callback(bluetooth_callback)

while true do
    if state:is("START") then
        state:on_entry(function()
            graphics:append_text("", "\u{1F618}")
        end)
        state:switch_after(10, "PRE_SLEEP")
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
    elseif state:is("READY_A") then
        state:on_entry(function()
            graphics:clear()
            graphics:append_text("", "\u{1F600}")
        end)
        state:switch_after(3, "READY_B")
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
    elseif state:is("READY_B") then
        state:on_entry(function()
            graphics:append_text("", "\u{1F60F}")
        end)
        state:switch_after(3, "READY_C")
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
    elseif state:is("READY_C") then
        state:on_entry(function()
            graphics:append_text("", "\u{1F600}")
        end)
        if math.random(1, 3) == 3 then -- TODO make this 1 in 10 chance
            state:switch_after(3, "WILDCARD")
        else
            state:switch_after(3, "PRE_SLEEP")
        end
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
    elseif state:is("PRE_SLEEP") then
        state:on_entry(function()
            graphics:append_text("", "\u{1F634}")
        end)
        state:switch_after(3, "SLEEP")
        state:switch_on_tap("READY_A")
        state:switch_on_double_tap("READY_A")
    elseif state:is("SLEEP") then
        state:on_entry(function()
            frame.display.show()
            frame.sleep(0.05)
            frame.sleep()
        end)
    elseif state:is("MESSAGE_GEN") then
        state:on_entry(function()
            graphics:clear()
            graphics:append_text("", "\u{1F3A7}")
            send_data(MESSAGE_GEN_FLAG)
            state:switch("LISTEN")
        end)
    elseif state:is("IMAGE_GEN") then
        state:on_entry(function()
            graphics:clear()
            graphics:append_text("", "\u{1F929}")
            send_data(IMAGE_GEN_FLAG)
            state:switch("LISTEN")
        end)
    elseif state:is("WILDCARD") then
        state:on_entry(function()
            graphics:append_text("", "\u{1F47B}")
            send_data(WILDCARD_GEN_FLAG)
        end)
        state:switch_after(20, "CANCEL")
    elseif state:is("LISTEN") then
        state:on_entry(function()
            frame.microphone.record {}
            image_taken = false
            image_data_sent = false
            audio_data_sent = false
        end)

        if state:has_been() > 0.2 and image_taken == false then
            frame.camera.capture()
            image_taken = true
        end

        if state:has_been() > 1.4 and image_data_sent == false then
            while true do
                local image_data = frame.camera.read(frame.bluetooth.max_length() - 1)
                if (image_data == nil) then
                    break
                end
                send_data(IMAGE_DATA_FLAG .. image_data)
            end
            image_data_sent = true
        end

        local audio_data = frame.microphone.read(
            math.floor((frame.bluetooth.max_length() - 1) / 4) * 4
        )
        if audio_data ~= nil then
            send_data(AUDIO_DATA_FLAG .. audio_data)
        end

        if state:has_been() > 2 then
            state:switch_on_tap("ON_IT")
        end
        state:switch_after(10, "READY_A")
    elseif state:is("ON_IT") then
        state:on_entry(function()
            frame.microphone.stop()
            graphics:append_text("", "\u{1F603}")
        end)
        if state:has_been() > 1.4 and audio_data_sent == false then
            while true do
                local audio_data = frame.microphone.read(
                    math.floor((frame.bluetooth.max_length() - 1) / 4) * 4
                )
                if (audio_data == nil) then
                    break
                end
                send_data(AUDIO_DATA_FLAG .. audio_data)
            end
            audio_data_sent = true
            send_data(TRANSFER_DONE_FLAG)
        end
        state:switch_after(20, "CANCEL")
    elseif state:is("CANCEL") then
        state:on_entry(function()
            graphics:append_text("", "\u{1F910}")
        end)
        state:switch_after(1, "READY_A")
    elseif state:is("PRINT_REPLY") then
        graphics:on_complete(function()
            state:switch("HOLD_REPLY")
        end)
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
    elseif state:is("PRINT_IMAGE") then
        graphics:on_complete(function()
            state:switch("HOLD_REPLY")
        end)
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
    elseif state:is("HOLD_REPLY") then
        state:switch_on_tap("MESSAGE_GEN")
        state:switch_on_double_tap("IMAGE_GEN")
        state:switch_after(5, "READY_A")
    elseif state:is("NO_CONNECTION") then
        state:on_entry(function()
            graphics:clear()
            graphics:append_text("", "\u{1F4F5}")
        end)
        if frame.bluetooth.is_connected() == true then
            state:switch("START")
        end
        state:switch_after(10, "PRE_SLEEP")
    end

    graphics:print_text()

    if frame.time.utc() - last_autoexp_time > 0.1 then
        frame.camera.auto { metering = 'CENTER_WEIGHTED', exposure = -0.5, exposure_limit = 5500 }
        last_autoexp_time = frame.time.utc()
    end

    if frame.bluetooth.is_connected() == false then
        if (not state:is("PRE_SLEEP") and not state:is("SLEEP")) then
            state:switch("NO_CONNECTION")
        end
    end

    collectgarbage("collect")
end
