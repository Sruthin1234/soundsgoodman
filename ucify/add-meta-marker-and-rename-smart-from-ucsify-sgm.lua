-- @description Add META marker and rename smart from ucsify SGM
-- @version 1.0
-- @author soundsgoodman
-- @about
--   Add META marker and rename smart from ucsify SGM
--   Uses clipboard Filename="..." entry to extract and apply UCS naming conventions

-- Check if reaper is available
if not reaper then
  return
end

-- Check if SWS extension is available (required for clipboard access)
local function checkSWSAvailable()
  if not reaper.CF_GetClipboard then
    reaper.ShowMessageBox("This script requires the SWS Extension.\nPlease install it from: https://www.sws-extension.org/", "SWS Extension Required", 0)
    return false
  end
  return true
end

-- Get clipboard text (requires SWS extension)
local function getClipboardText()
  local clipboard = reaper.CF_GetClipboard()
  if clipboard then
    return clipboard
  end
  return ""
end

-- Extract filename from clipboard text (expects format: Filename="...")
local function extractFilename(text)
  local filename = text:match('Filename="([^"]+)"')
  return filename
end

-- Add META marker at current position
local function addMetaMarker(name)
  local cursorPos = reaper.GetCursorPosition()
  local markerIdx = reaper.AddProjectMarker(0, false, cursorPos, 0, name, -1)
  return markerIdx
end

-- Main function
local function main()
  -- Check SWS extension is available
  if not checkSWSAvailable() then
    return
  end
  
  local clipboardText = getClipboardText()
  
  if clipboardText == "" then
    reaper.ShowMessageBox("Clipboard is empty", "Error", 0)
    return
  end
  
  local filename = extractFilename(clipboardText)
  
  if not filename then
    reaper.ShowMessageBox("Could not extract filename from clipboard.\nExpected format: Filename=\"...\"", "Error", 0)
    return
  end
  
  addMetaMarker("META: " .. filename)
  reaper.Undo_OnStateChange("Add META marker from UCSify SGM")
  
  reaper.ShowMessageBox("Added META marker: " .. filename, "Success", 0)
end

main()
