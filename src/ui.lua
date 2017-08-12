-- UI code for the Profiler window

--
-- Settings
--

local colors = {
    --               R       G      B      A
    windowborder = {0.00,  0.00,  0.00,  1.00},
    titlebar     = {0.05,  0.05,  0.05,  1.00},
    header       = {0.80,  0.80,  0.80,  0.90},
    workspace    = {1.00,  1.00,  1.00,  0.90},
}

local fonts = {
    title    = "GameFontNormalSmall",
    subtitle = "GameFontDisableSmall",
    text     = "QuestFontNormalSmall",
    value    = "QuestFontNormalSmall",
}


--
-- Helper functions (NOT intended as a framework, so don't make it into one!)
--
local function edgecolor(frame, color)
    -- ...yeah. Switch to file edge textures at some point.
    local left = frame:CreateTexture(nil)
    left:SetPoint("topleft", -1, 1)
    left:SetPoint("bottomleft", -1, -1)
    left:SetWidth(1)
    left:SetColorTexture(unpack(color))
        
    local top = frame:CreateTexture(nil)
    top:SetPoint("topleft", -1, 1)
    top:SetPoint("topright", 1, 1)
    top:SetHeight(1)
    top:SetColorTexture(unpack(color))

    local right = frame:CreateTexture(nil)
    right:SetPoint("topright", 1, 1)
    right:SetPoint("bottomright", 1, -1)
    right:SetWidth(1)
    right:SetColorTexture(unpack(color))

    local bottom = frame:CreateTexture(nil)
    bottom:SetPoint("bottomleft",  -1, -1)
    bottom:SetPoint("bottomright",  1, -1)
    bottom:SetHeight(1)
    bottom:SetColorTexture(unpack(color))
end
local function bgcolor(frame, bg, edge)
    local texture = frame:CreateTexture(nil, "MEDIUM")
    texture:SetAllPoints(true)
    texture:SetColorTexture(unpack(bg))
    if edge then edgecolor(frame, edge) end
    return texture
end

local function align(frame, point, anchor, relativeTo, offsets)
    local inset, gap, x, y = 0, 0, 0, 0
    if offsets then
        inset = offsets.inset or 0
        gap = offsets.gap or 0
        x = offsets.x or 0
        y = offsets.y or 0
    end
    if point=="below" then
        local rel = relativeTo or "bottom"
        frame:SetPoint("topleft",  anchor, rel.."left",   inset, -gap)
        frame:SetPoint("topright", anchor, rel.."right", -inset, -gap)
    elseif point=="above" then
        local rel = relativeTo or "top"
        frame:SetPoint("bottomleft",  anchor, rel.."left",   inset, gap)
        frame:SetPoint("bottomright", anchor, rel.."right", -inset, gap)
    else
        local rel = relativeTo or point
        if anchor then
            frame:SetPoint(point, anchor, rel, x, y)
        else
            frame:SetPoint(point, x, y)
        end
    end
end

local function size(frame, width, height)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
    return frame
end
local function height(frame, height)
    frame:SetHeight(height)
    return frame
end
local function width(frame, width)
    frame:SetWidth(width)
    return frame
end

local function box(parent, bg, name)
    local frame = CreateFrame("Frame", name, parent)
    if bg then bgcolor(frame, bg) end
    return frame
end
local function text(parent, text, font)
    local fontstring = parent:CreateFontString(nil, "MEDIUM", font)
    fontstring:SetText(text)
    return fontstring
end




function Profiler:UpdateUI()
    local window = self.window
    local rows = window.rows
    local data = Profiler:updateAddOnInfo()
    table.sort(data, function(a,b) return a.cpu>b.cpu end)
    for i=1,#rows do
        local row = rows[i]
        local info = data[i]
        if info then
            row.name:SetText(info.title)
            row.value:SetText(string.format("%6.4fms", info.cpu))
        else
            row.name:SetText("")
            row.value:SetText("")
        end
    end
end

--
-- Create UI
--

function Profiler:CreateUI()
    local window = CreateFrame("Frame", "ProfilerWindow", UIParent)
    size(window, 400, 200); align(window, "center"); bgcolor(window, colors.windowborder, {1.0, 0.0, 0.0, 1.0})
    window:SetMovable(true)

    local titlebar = box(window, colors.titlebar)
    do
        height(titlebar, 20)
        align(titlebar, "below", window, "top", {inset=1, gap=1})

        local title = text(titlebar, "Profiler", fonts.title)
        align(title, "left", titlebar)

        local subtitle = text(titlebar, "Test", fonts.subtitle)
        align(subtitle, "left", title, "right", {gap=2})

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
    window:Show()

    window.rows = rows
    self.window = window
    self:UpdateUI()
end
