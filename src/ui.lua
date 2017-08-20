-- UI code for the Profiler window

local ADDON_NAME, profiler = ...
local ui = profiler.ui


-- Data

local colors = ui.data.colors
local fonts  = ui.data.fonts
local size   = ui.data.size


-- UI helper functions

local edgecolor = ui.utility.edgecolor
local bgcolor   = ui.utility.bgcolor

--local align     = ui.utility.align
--local size      = ui.utility.size
--local height    = ui.utility.height
--local width     = ui.utility.width

local box       = ui.utility.box
--local text      = ui.utility.text



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

function Window:init()
    -- Set up the window position, size and textures
    local window = ui.Window
    window:SetSize(unpack(size.window)); window:SetPoint("center");
    bgcolor(window, colors.window, colors.windowborder)
    window:SetMovable(true)

    local titlebar
    titlebar = box(window, colors.titlebar)
    titlebar:SetPoint("topleft")
    titlebar:SetPoint("topright")
    titlebar:SetHeight(size.titlebar)
    do
        local title
        title = titlebar:CreateFontString(nil, "medium", fonts.title)
        title:SetPoint("left", 2, 0)
        title:SetText("Profiler")

        local subtitle
        subtitle = titlebar:CreateFontString(nil, "medium", fonts.subtitle)
        subtitle:SetPoint("left", title, "right", 2, 0)
        subtitle:SetText("Root")

        -- handlers
        titlebar:SetScript("OnMouseDown", function(self, button)
            if button=="LeftButton" then window:StartMoving() end
        end)
        titlebar:SetScript("OnMouseUp", function(self, button)
            if button=="LeftButton" then window:StopMovingOrSizing() end
        end)

        titlebar.title = title
        titlebar.subtitle = subtitle
    end
    window.titlebar = titlebar

    local header
    header = CreateFrame("Frame", nil, window)
    header:SetPoint("topleft", titlebar, "bottomleft")
    header:SetPoint("topright", titlebar, "bottomright")
    header:SetHeight(size.header)
    bgcolor(header, colors.header)
    do
        local name
        name = header:CreateFontString(nil, "MEDIUM", fonts.text)
        name:SetText("Name")
        name:SetPoint("left", 2, 0)
        header.name = name

        local cpu
        cpu = header:CreateFontString(nil, "MEDIUM", fonts.text)
        cpu:SetText("CPU")
        cpu:SetPoint("right", -2, 0)
        header.cpu = cpu

        local ncalls
        ncalls = header:CreateFontString(nil, "MEDIUM", fonts.text)
        ncalls:SetText("Called")
        ncalls:SetPoint("right", -size.cpu, 0)
        header.ncalls = ncalls
    end

    local footer
    footer = CreateFrame("Frame", nil, window)
    footer:SetHeight(size.footer)
    footer:SetPoint("bottomleft")
    footer:SetPoint("bottomright")
    bgcolor(footer, colors.footer)

    local workspace
    workspace = CreateFrame("Frame", nil, window)
    workspace:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    workspace:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")
    bgcolor(workspace, colors.workspace)

    local rows = {}
    do
        local maxRows = math.floor(workspace:GetHeight()/size.row)
        for i=1, maxRows do
            local offset = (i-1)*size.row

            local row
            row = CreateFrame("Frame", nil, workspace)
            row:SetHeight(size.row)
            row:SetPoint("TOPLEFT", workspace, "TOPLEFT", 0, -offset)
            row:SetPoint("TOPRIGHT", workspace, "TOPRIGHT", 0, -offset)
            bgcolor(row, colors.rowbg)

            local columns = {}
            do
                local name
                name = CreateFrame("Frame", nil, row)
                bgcolor(name, colors.namebg)
                name:SetHeight(size.row)
                name:SetPoint("LEFT")
                name.text = name:CreateFontString(nil, "MEDIUM", fonts.text)
                name.text:SetPoint("LEFT", 2, 0)
                name.text:SetText("None")
                columns.name = name

                local cpu
                cpu = CreateFrame("Frame", nil, row)
                bgcolor(cpu, colors.cpubg)
                cpu:SetSize(size.cpu, size.row)
                cpu:SetPoint("RIGHT")
                cpu.text = cpu:CreateFontString(nil, "MEDIUM", fonts.value)
                cpu.text:SetPoint("RIGHT", -2, 0)
                cpu.text:SetText("0.0")
                columns.cpu = cpu

                local ncalls
                ncalls = CreateFrame("Frame", nil, row)
                bgcolor(ncalls, colors.ncallsbg)
                ncalls:SetSize(size.ncalls, size.row)
                ncalls:SetPoint("RIGHT", cpu, "LEFT")
                ncalls.text = ncalls:CreateFontString(nil, "MEDIUM", fonts.value)
                ncalls.text:SetPoint("RIGHT", -2, 0)
                ncalls.text:SetText("0")
                columns.ncalls = ncalls

                name:SetPoint("right", ncalls, "left")
            end
            row.columns = columns

            row.id = nil
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
            row.columns.name.text:SetText(info.title)
            row.columns.cpu.text:SetText(string.format("%6.0fms", info.cpu))
            if info.mem then
                row.columns.ncalls.text:SetText(string.format("%6.2fmb", info.mem/1024))
            elseif info.ncalls then
                row.columns.ncalls.text:SetText(info.ncalls)
            else
                row.columns.ncalls.text:SetText("")
            end
            if info.type=="table" then
                row.columns.name.text:SetTextColor(0.5, 0.0, 0.0)
            elseif info.type=="addon" then
                row.columns.name.text:SetTextColor(0.0, 0.5, 0.0)
            else
                row.columns.name.text:SetTextColor(0.0, 0.0, 0.0)
            end
        else
            row.id = nil
            row.columns.name.text:SetText("")
            row.columns.cpu.text:SetText("")
            row.columns.ncalls.text:SetText("")
        end
    end
end
