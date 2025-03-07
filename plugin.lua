local previous = false

local function requires_reanalysis(x)
    if not x then
        return true
    end

    if tonumber(x.Type) == action_type.Batch then
        for _, v in pairs(x.EditorActions) do
            if requires_reanalysis(v) then
                return true
            end
        end
    end

    return ({
        [action_type.PlaceHitObject] = true,
        [action_type.PlaceHitObjectBatch] = true,
        [action_type.MoveHitObjects] = true,
        [action_type.ResnapHitObjects] = true,
        [action_type.ReverseHitObjects] = true,
    })[tonumber(x.Type)]
end

local function go(x)
    if not requires_reanalysis(x) then
        return
    end

    local config = read()

    config = {
        min = (type(config) == "table" and tonumber(config.min)) or 1,
        max = (type(config) == "table" and tonumber(config.max)) or 8,
        use_clipboard = type(config) == "table" and
            config.use_clipboard or
            {} ~= "false",
    }

    write(config)
    local times = ""
    local objs = map.HitObjects

    for i = 2, #objs, 1 do
        -- We're performing math.abs manually, because it's faster.
        local start_offset = objs[i].StartTime - objs[i - 1].StartTime

        if start_offset <= -config.min or
            start_offset >= config.min and
            start_offset >= -config.max and
            start_offset <= config.max then
            previous = false

            times = times ..
                (#times == 0 and "" or ",") ..
                tostring(objs[i].StartTime) ..
                "|" ..
                tostring(objs[i].Lane)
        end
    end

    if #times > 0 then
        print(
            "w",
            "Following objects are snapped " ..
            tostring(config.min) ..
            "-" ..
            tostring(config.max) ..
            "ms after their previous: " ..
            times
        )

        if config.use_clipboard then
            imgui.SetClipboardText(times)
        end
    elseif not previous then
        previous = true
        print("s", "Map has no incorrect snaps!")
    end
end

function Awake()
    listen(go)
    go()
end
