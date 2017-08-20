-- UI code for the Profiler window

local ADDON_NAME, profiler = ...
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
    if elapsed < 1 then return
    else
        profiler.updateTimes(ui.Window.data)
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

        local subtitle = text(titlebar, "Root", fonts.subtitle)
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
        titlebar:SetScript("OnMouseDown", titlebarMouseDown)
        titlebar:SetScript("OnMouseUp", titlebarMouseUp)

        titlebar.title = title
        titlebar.subtitle = subtitle
        window.titlebar = titlebar
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
            --local row = {}
            local row = CreateFrame("StatusBar", nil, workspace)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", workspace, "TOPLEFT", 0, -offset)
            row:SetPoint("TOPRIGHT", workspace, "TOPRIGHT", 0, -offset)
            bgcolor(row, {1.0,1.0,1.0})

            local name = box(row, {0.9,0.9,0.9})
            name:SetSize(200, rowHeight)
            name:SetPoint("LEFT")
            name.text = name:CreateFontString(nil, "MEDIUM", fonts.text)
            name.text:SetPoint("LEFT", 2, 0)
            name.text:SetText("None")

            local cpu = box(row, {0.8, 0.8, 0.8})
            cpu:SetSize(50, rowHeight)
            cpu:SetPoint("RIGHT")
            cpu.text = cpu:CreateFontString(nil, "MEDIUM", fonts.value)
            cpu.text:SetPoint("RIGHT", -2, 0)
            cpu.text:SetText("0.0")

            local ncalls = box(row, {0.9, 0.9, 0.9})
            ncalls:SetSize(50, rowHeight)
            ncalls:SetPoint("RIGHT", cpu, "LEFT")
            ncalls.text = ncalls:CreateFontString(nil, "MEDIUM", fonts.value)
            ncalls.text:SetPoint("RIGHT", -2, 0)
            ncalls.text:SetText("0")

            row.name = name.text
            row.value = cpu.text
            row.id = nil
            row.typespecial = ncalls.text
            rows[#rows+1] = row

            row:SetScript("OnMouseUp", function(self, button)
                if button=="LeftButton" then
                    local d = window.data[self.id]
                    window.data = type(d)~="function" and d or window.data
                    rows.scrolling = 0
                elseif button=="RightButton" then
                    window.data = window.data[-1] or window.data
                    rows.scrolling = 0
                end
                window.titlebar.subtitle:SetText(window.data[0].name)
                window:update()
            end)
        end
    end

    window:SetScript("OnUpdate", updateTimer)

    window:SetScript("OnMouseWheel", function(self, delta)
        rows.scrolling = rows.scrolling - delta
        if rows.scrolling > #window.data - #rows then
            rows.scrolling = #window.data - #rows
        elseif rows.scrolling < 0 then
            rows.scrolling = 0
        end
        window:update()
    end)
    rows.scrolling = 0

    window.rows = rows
    window.data = profiler.namespaces
    profiler.updateTimes(window.data)
    window:update()
end

function Window:update()
    local window = self
    local rows = window.rows
    local scrolling = rows.scrolling
    local data = window.data

    for i=1,#rows do
        local row = rows[i]
        local info = data[i+scrolling]
        if info then
            row.id = info.name
            row.name:SetText(info.title)
            row.value:SetText(string.format("%6.0fms", info.cpu))
            if info.mem then
                row.typespecial:SetText(string.format("%6.2fmb", info.mem/1024))
            elseif info.ncalls then
                row.typespecial:SetText(info.ncalls)
            else
                row.typespecial:SetText("")
            end
            if info.type=="table" then
                row.name:SetTextColor(0.5, 0.0, 0.0)
            elseif info.type=="addon" then
                row.name:SetTextColor(0.0, 0.5, 0.0)
            else
                row.name:SetTextColor(0.0, 0.0, 0.0)
            end
        else
            row.id = nil
            row.name:SetText("")
            row.value:SetText("")
            row.typespecial:SetText("")
        end
    end
end
