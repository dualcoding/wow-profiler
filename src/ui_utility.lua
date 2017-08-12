-- Helper functions to make UI code less verbose

local ADDON, profiler = ...

if not profiler.ui then
    profiler.ui = {}
end
local ui = profiler.ui

if not ui.utility then
    ui.utility = {}
end


-- Colors and texture

function ui.utility.edgecolor(frame, color)
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
local edgecolor = ui.utility.edgecolor

function ui.utility.bgcolor(frame, bg, edge)
    local texture = frame:CreateTexture(nil, "MEDIUM")
    texture:SetAllPoints(true)
    texture:SetColorTexture(unpack(bg))
    if edge then edgecolor(frame, edge) end
    return texture
end
local bgcolor = ui.utility.bgcolor



-- Placement and sizing

function ui.utility.align(frame, point, anchor, relativeTo, offsets)
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

function ui.utility.size(frame, width, height)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
    return frame
end

function ui.utility.height(frame, height)
    frame:SetHeight(height)
    return frame
end

function ui.utility.width(frame, width)
    frame:SetWidth(width)
    return frame
end



-- Elements

function ui.utility.box(parent, bg, name)
    local frame = CreateFrame("Frame", name, parent)
    if bg then bgcolor(frame, bg) end
    return frame
end

function ui.utility.text(parent, text, font)
    local fontstring = parent:CreateFontString(nil, "MEDIUM", font)
    fontstring:SetText(text)
    return fontstring
end
