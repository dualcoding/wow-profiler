local OUR_NAME, profiler = ...

--
-- Load addon and handle events
--

profiler.frame = CreateFrame("Frame", "Profiler", UIParent)
profiler.events = {
    ADDON_LOADED = function(frame, addon_name)
        print("loaded", addon_name)
        if addon_name==OUR_NAME then
            -- We were loaded
            if not profiler.isFirstAddonLoaded() then
                error(OUR_NAME, "was not loaded first")
            end

            -- Claim our own functions, and attribute the rest to Blizzard
            profiler.registerNamespace(OUR_NAME, profiler)
            profiler.registerBlizzard()

            -- Start listening for new globals
            local new = profiler.newGlobals()
            if new then error("shouldn't find any new globals yet!") end

        else
            -- another addon was loaded - assume new stuff comes from it
            local new = profiler.newGlobals()
            profiler.registerNamespace(addon_name, new)
        end
    end,

    PLAYER_LOGIN = function(frame, ...)
        -- TODO: attribute to "startup"
    end,

    PLAYER_ENTERING_WORLD = function(frame, ...)
        profiler.ui.Window:init()
    end,

}


-- Dispatch events
profiler.frame:SetScript("OnEvent", function(self, event, ...)
    profiler.events[event](self, ...)
end)

-- Register events
for k, v in pairs(profiler.events) do
    profiler.frame:RegisterEvent(k)
end

_G.profiler = profiler
