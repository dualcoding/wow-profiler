-- Static UI data

local ADDON_NAME, profiler = ...

if not profiler.ui then
    profiler.ui = {}
end

local ui = profiler.ui
if not ui.data then
    ui.data = {}
end



ui.data.colors = {
    --               R       G      B      A
    windowborder = {0.00,  0.00,  0.00,  1.00},
    titlebar     = {0.05,  0.05,  0.05,  1.00},
    header       = {0.80,  0.80,  0.80,  0.90},
    workspace    = {1.00,  1.00,  1.00,  0.90},
    minimize     = {1.00,  0.00,  0.00,  1.00},
}

ui.data.fonts = {
    title    = "GameFontNormalSmall",
    subtitle = "GameFontDisableSmall",
    text     = "QuestFontNormalSmall",
    value    = "QuestFontNormalSmall",
}
