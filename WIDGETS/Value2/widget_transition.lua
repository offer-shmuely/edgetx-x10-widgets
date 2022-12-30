local app_name, p2 = ...

local M = {}
M.app_name = app_name
M.tele_src_name = nil
M.tele_src_id = nil

local getTime = getTime
local lcd = lcd

--------------------------------------------------------------
local function log(fmt, ...)
    local num_arg = #{ ... }
    local msg
    if num_arg > 0 then
        msg = string.format(fmt, ...)
    else
        msg = fmt
    end
    print(M.app_name .. ": " .. msg)
end
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- transitions
local transition_info =
{
    state_from = "a",
    fade_out_duration = 200,
    fade_in_duration = 600,
    startTime = nil,
    t_state = "OFF" -- "OFF", "FADE_OUT", "FADE_IN"
}

function M.areaTransition(wgt, state_to, refresh_a, refresh_b, transitionType)

    if transition_info.t_state == "OFF" then
        if state_to == transition_info.state_from then
            -- no transition needed
        else
            transition_info.startTime = getTime() * 10
            transition_info.t_state = "FADE_OUT"
            log("trans OFF --> FADE_OUT")
        end

        if transition_info.state_from == "a" then
            refresh_a(wgt)
        else
            refresh_b(wgt)
        end

    elseif transition_info.t_state == "FADE_OUT" then
        if transition_info.state_from == "a" then
            refresh_a(wgt)
        else
            refresh_b(wgt)
        end

        local elapsed = getTime() *10 - transition_info.startTime
        log("trans FADE_OUT elapsed: %s (/ %s)", elapsed, transition_info.fade_out_duration)
        local elapsed_percent = elapsed / transition_info.fade_out_duration
        lcd.drawFilledRectangle(wgt.zone.x, wgt.zone.y, wgt.zone.w, wgt.zone.h * elapsed_percent, BLACK)
        if elapsed >= transition_info.fade_out_duration then
            transition_info.startTime = getTime() * 10
            transition_info.t_state = "FADE_IN"
            log("trans FADE_OUT --> FADE_IN")
        end

    elseif transition_info.t_state == "FADE_IN" then
        if state_to == "a" then
            refresh_a(wgt)
        else
            refresh_b(wgt)
        end

        local elapsed = getTime() *10 - transition_info.startTime
        log("trans FADE_OUT elapsed: %d (/%d)", elapsed, transition_info.fade_in_duration)
        local elapsed_percent = elapsed / transition_info.fade_in_duration
        lcd.drawFilledRectangle(wgt.zone.x, wgt.zone.y, wgt.zone.w, wgt.zone.h * (1 - elapsed_percent), BLACK)
        if elapsed >= transition_info.fade_in_duration then
            transition_info.t_state = "OFF"
            transition_info.state_from = state_to
        end
    end

end

---------------------------------------------------------------------------------------------------

return M
