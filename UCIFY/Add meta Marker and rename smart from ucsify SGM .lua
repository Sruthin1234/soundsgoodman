function Msg(param) reaper.ShowConsoleMsg(tostring(param) .. "\n") end

-- User-configurable metadata marker offsets
local META_AFTER_END_OFFSET = 0.0005   -- first marker this many seconds after item end
local META_SECOND_DELTA     = 0.001     -- second marker this many seconds after first

-- Helper: escape Lua pattern magic chars
local function escape_lua_pattern(s)
  return (s:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
end

-- Get clipboard text
local clipboard = reaper.CF_GetClipboard("")
if not clipboard or clipboard == "" then
  reaper.MB("Clipboard is empty!","Error",0)
  return
end

-- Extract Filename field from clipboard (expects Filename="...")
local filename = clipboard:match('Filename="(.-)"')
if not filename then
  reaper.MB("Could not find Filename in clipboard!","Error",0)
  return
end

-- Split into base + suffix (suffix is last underscore + tail)
local lastUnderscorePos = filename:match(".*()_")
local baseNoNum, suffix
if lastUnderscorePos then
  baseNoNum = filename:sub(1, lastUnderscorePos - 1)
  suffix = filename:sub(lastUnderscorePos) -- includes the underscore
else
  baseNoNum = filename
  suffix = ""
end

local escSuffix = escape_lua_pattern(suffix)

-- Count selected items
local selCount = reaper.CountSelectedMediaItems(0)
if selCount == 0 then
  reaper.MB("No items selected!","Error",0)
  return
end

-- Build a set of selected takes to avoid double-renaming
local selectedSet = {}
local selectedItems = {}
for i = 0, selCount-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  local take = item and reaper.GetActiveTake(item)
  if take then
    selectedSet[take] = true
    table.insert(selectedItems, {item=item, take=take})
  end
end

-- Scan ALL active takes in project to find existing matches and highest number
local highest = 0
local existingCount = 0
local plainTakes = {} -- existing takes with exact plain name (no number)
local itemCount = reaper.CountMediaItems(0)
for i = 0, itemCount-1 do
  local item = reaper.GetMediaItem(0,i)
  local take = reaper.GetActiveTake(item)
  if take then
    local _, tname = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    if tname and tname ~= "" then
      if tname == (baseNoNum .. suffix) then
        existingCount = existingCount + 1
        table.insert(plainTakes, {item=item, take=take})
      else
        -- Look for "<base> NN<suffix>" where NN can be 1..n (not limited to 2 digits)
        local basePart, numStr = tname:match("^(.-) (%d+)" .. escSuffix .. "$")
        if basePart and basePart == baseNoNum then
          existingCount = existingCount + 1
          local num = tonumber(numStr) or 0
          if num > highest then highest = num end
        end
      end
    end
  end
end

reaper.Undo_BeginBlock()

-- Case: no existing in project and only one selected -> keep plain name
if existingCount == 0 and #selectedItems == 1 then
  local t = selectedItems[1]
  reaper.GetSetMediaItemTakeInfo_String(t.take, "P_NAME", filename, true)
  -- META markers for that one
  local itemStart = reaper.GetMediaItemInfo_Value(t.item, "D_POSITION")
  local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(t.item, "D_LENGTH")
  local meta1Pos = itemEnd + META_AFTER_END_OFFSET
  reaper.AddProjectMarker(0, false, meta1Pos, 0, clipboard, -1)
  reaper.AddProjectMarker(0, false, meta1Pos + META_SECOND_DELTA, 0, "META", -1)
  reaper.Undo_EndBlock("Rename take (plain) + META markers", -1)
  return
end

-- First, convert any existing PLAIN takes (not selected) to numbers continuing after highest
local nextIndex = highest
for _, t in ipairs(plainTakes) do
  if not selectedSet[t.take] then
    nextIndex = nextIndex + 1
    local newname = string.format("%s %02d%s", baseNoNum, nextIndex, suffix)
    reaper.GetSetMediaItemTakeInfo_String(t.take, "P_NAME", newname, true)
  end
end

-- Now assign names to the SELECTED items, continuing the sequence
for i, t in ipairs(selectedItems) do
  nextIndex = nextIndex + 1
  local newname = string.format("%s %02d%s", baseNoNum, nextIndex, suffix)
  reaper.GetSetMediaItemTakeInfo_String(t.take, "P_NAME", newname, true)

  -- Add META markers right after item end
  local itemStart = reaper.GetMediaItemInfo_Value(t.item, "D_POSITION")
  local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(t.item, "D_LENGTH")
  local meta1Pos = itemEnd + META_AFTER_END_OFFSET
  reaper.AddProjectMarker(0, false, meta1Pos, 0, clipboard, -1)
  reaper.AddProjectMarker(0, false, meta1Pos + META_SECOND_DELTA, 0, "META", -1)
end

reaper.Undo_EndBlock("Rename takes with incremental numbering across project + META markers", -1)

