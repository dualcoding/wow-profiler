-- UI code for the Profiler window

local ADDON, profiler = ...
local ui = profiler.ui


-- Data

local colors = ui.data.colors
local fonts  = ui.data.fonts


-- UI helper functions

local edgecolor = ui.utility.edgecolor
local bgcolor   = ui.utility.bgcolor

local align     = ui.utility.align
local size      = ui.utility.size
local height    = ui.utility.height
local width     = ui.utility.width

local box       = ui.utility.box
local text      = ui.utility.text



--
-- UI
--

ui.Window = CreateFrame("Frame", "ProfilerWindow", UIParent)
local Window = ui.Window

local elapsed = 0
local function updateTimer(self, dT)
    elapsed = elapsed + dT
    if elapsed < 2 then return
    else
        ui.Window:update()
        elapsed = 0
    end
end

function Window.init(self)
    local window = ui.Window
    size(window, 400, 200); align(window, "center"); bgcolor(window, colors.windowborder, {1.0, 0.0, 0.0, 1.0})
    window:SetMovable(true)

    local titlebar = box(window, colors.titlebar)
    do
        height(titlebar, 20)
        align(titlebar, "below", window, "top", {inset=1, gap=1})

        local title = text(titlebar, "Profiler", fonts.title)
        align(title, "left", titlebar)

        local subtitle = text(titlebar, "Test", fonts.subtitle)
        align(subtitle, "left", title, "right", {x=2})

        local minimize = box(titlebar, colors.minimize)
        size(minimize, 15, 15)
        align(minimize, "right", titlebar, "right", {x=-3, y=1})


        local function titlebarMouseDown(self, button)
            if button=="LeftButton" then
                window:StartMoving()
            end
        end
        local function titlebarMouseUp(self, button)
            if button=="LeftButton" then
                window:StopMovingOrSizing()
            end
        end
        titlebar:SetScript("OnMouseDown", titlebarMouseDown) -- TODO -> OnDrag
        titlebar:SetScript("OnMouseUp", titlebarMouseUp)
    end

    local header = box(window, colors.header)
    align(header, "below", titlebar); height(header, 20)

    local footer = box(window, colors.header)
    height(footer, 20)
    align(footer, "above", window, "bottom", {inset=1, gap=1})

    local workspace = CreateFrame("Frame", nil, window)
    do
        workspace:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
        workspace:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")

        bgcolor(workspace, colors.workspace)
    end

    local rows = {}
    do
        local rowHeight = 15
        local maxRows = math.floor(workspace:GetHeight()/rowHeight)
        for i=1, maxRows do
            local offset = (i-1)*rowHeight
            local row = {}
            local bg = CreateFrame("StatusBar", nil, workspace)
            bg:SetHeight(rowHeight)
            bg:SetPoint("TOPLEFT", workspace, "TOPLEFT", 0, -offset)
            bg:SetPoint("TOPRIGHT", workspace, "TOPRIGHT", 0, -offset)

            local text = bg:CreateFontString(nil, "MEDIUM", fonts.text)
            text:SetPoint("LEFT", 2, 0)
            text:SetText("None")

            local valuetext = bg:CreateFontString(nil, "MEDIUM", fonts.value)
            valuetext:SetPoint("RIGHT", -2, 0)
            valuetext:SetText("0.0")

            row.bg = bg
            row.name = text
            row.value = valuetext
            rows[#rows+1] = row
        end
    end

    window:SetScript("OnUpdate", updateTimer)
    window:SetScript("OnMouseWheel", function(self, delta)
        rows.scrolling = rows.scrolling - delta
        if rows.scrolling > #window.addOnInfo - #rows then
            rows.scrolling = #window.addOnInfo - #rows
        elseif rows.scrolling < 0 then
            rows.scrolling = 0
        end
        window:update()
    end)
    rows.scrolling = 0

    window.rows = rows
end

function Window:update()
    local window = self
    local rows = window.rows
    local scrolling = rows.scrolling
    local data = profiler.updateAddOnInfo()
    table.sort(data, function(a,b) return a.cpu>b.cpu end)
    for i=1,#rows do
        local row = rows[i]
        local info = data[i+scrolling]
        if info then
            row.name:SetText(info.title)
            row.value:SetText(string.format("%6.4fms", info.cpu))
        else
            row.name:SetText("")
            row.value:SetText("")
        end
    end
    self.addOnInfo = data
end
