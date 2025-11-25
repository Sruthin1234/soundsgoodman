-- @description UCS Inject Render Metadata
-- @version 1.0
-- @author soundsgoodman
-- @about
--   UCS Inject Render Metadata — pre-populates project render metadata keys
--   Populates BWF/iXML metadata fields according to Universal Category System (UCS) conventions

-- Check if reaper is available
if not reaper then
  return
end

-- UCS Metadata field definitions
local UCS_FIELDS = {
  { key = "IXML:USER:CatID", desc = "Category ID" },
  { key = "IXML:USER:Category", desc = "Category Name" },
  { key = "IXML:USER:SubCategory", desc = "Sub-Category" },
  { key = "IXML:USER:UserCategory", desc = "User Category" },
  { key = "IXML:USER:VendorCategory", desc = "Vendor Category" },
  { key = "IXML:USER:FXName", desc = "Effect Name" },
  { key = "IXML:USER:Library", desc = "Library Name" },
  { key = "IXML:USER:Creator", desc = "Creator" },
  { key = "IXML:USER:SourceID", desc = "Source ID" },
  { key = "BWF:Description", desc = "BWF Description" },
  { key = "BWF:Originator", desc = "BWF Originator" },
  { key = "BWF:OriginatorReference", desc = "BWF Originator Reference" },
}

-- Set a render metadata field
local function setRenderMetadata(key, value)
  if reaper.GetSetProjectInfo_String then
    reaper.GetSetProjectInfo_String(0, "RENDER_METADATA", key .. "|" .. value, true)
  end
end

-- Check if a metadata field is already set
local function getRenderMetadata(key)
  local retval, value = reaper.GetSetProjectInfo_String(0, "RENDER_METADATA", key, false)
  if retval then
    return value
  end
  return ""
end

-- Pre-populate UCS metadata fields with placeholder values if not set
local function injectMetadataFields()
  local count = 0
  
  for _, field in ipairs(UCS_FIELDS) do
    local currentValue = getRenderMetadata(field.key)
    if currentValue == "" then
      -- Use placeholder to indicate field needs to be filled
      setRenderMetadata(field.key, "[" .. field.desc .. "]")
      count = count + 1
    end
  end
  
  return count
end

-- Main function
local function main()
  local injectedCount = injectMetadataFields()
  
  reaper.Undo_OnStateChange("UCS Inject Render Metadata Fields")
  
  local msg = string.format("Initialized %d UCS metadata fields.\n\nGo to:\nFile -> Project Settings -> Project Render Metadata\nto fill in the values.", injectedCount)
  reaper.ShowMessageBox(msg, "UCS Inject Metadata", 0)
end

main()
