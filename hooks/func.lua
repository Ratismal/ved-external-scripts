local JSON = ved_require(EXSCR_PLUGIN_PATH .. "json")
external_files = {}

function EXSCR_ensure_scripts_directory()
  editingmap = level_path:gsub(".vvvvvv", "")
  local asset_folder = getlevelassetsfolder()
  if asset_folder == nil then return nil end

  local scripts_dir_path = asset_folder .. "/scripts"

  if not directory_exists(scripts_dir_path) then
    cons("Creating script directory")
    create_directory(scripts_dir_path)
  end

  return scripts_dir_path
end

function EXSCR_ensure_script_path(script_name, scripts_dir_path)
  local split_name = string.split(script_name, "/")
  if #split_name > 1 then
    local current_path = scripts_dir_path
    for i = 1, #split_name - 1 do
      current_path = current_path .. "/" .. split_name[i]
      if not directory_exists(current_path) then
        cons("Creating script subdirectory " .. current_path)
        create_directory(current_path)
      end
    end
  end
  return true
end

function EXSCR_export_script(name, raw_script)
  local scripts_dir_path = EXSCR_ensure_scripts_directory()
  if scripts_dir_path == nil then return end
  local contents = script_decompile(raw_script)
  EXSCR_ensure_script_path(name, scripts_dir_path)
  local script_name = scripts_dir_path .. "/" .. name .. ".v6"
  cons("Exporting " .. name .. " to " .. script_name)

  if internalscript then
    table.insert(contents, 1, "#.int")
  end
  writelevelfile(script_name, table.concat(contents, "\n"))
end

function EXSCR_import_script(name)
  local scripts_dir_path = EXSCR_ensure_scripts_directory()
  if scripts_dir_path == nil then return end

  local file_name = scripts_dir_path .. "/" .. name .. ".v6"
  if file_exists(file_name) then
    local file = {
      name=script_name,
      file_name=file_name,
    }
    local success, contents = EXSCR_load_file_script(file)
    cons("Importing " .. name .. " from " .. file_name .. ": " .. tostring(success))
    scripts[name] = contents
  end
end

function EXSCR_load_file_script(file)
  local success, contents = readlevelfile(file.file_name)
  cons("Loading script file " .. file.file_name .. ": " .. tostring(success))

  if success then
    contents = contents:gsub("\r", "")
    local lines = {}
    if contents:sub(-1,-1) ~= "\n" then
      contents = contents .. "\n"
    end
    for ln in contents:gmatch("([^\n]*)\n") do
      table.insert(lines, ln)
    end

    if lines[1] == "#.int" then
      table.remove(lines, 1)
      internalscript = true
    else
      internalscript = false
    end

    return script_compile(lines)
  else
    return false, contents
  end
end

function EXSCR_load_all_script_files(scripts_dir_path, dir, all_files)
  -- cons("Listing " .. scripts_dir_path .. "/" .. dir)
  local success, files, message = listfiles_generic(scripts_dir_path .. "/" .. dir, "", true)

  if success then
    for i = 1, #files do
      local file = files[i]
      if file.isdir then
        EXSCR_load_all_script_files(scripts_dir_path, dir .. file.name .. "/", all_files)
      elseif file.name:sub(-3) == ".v6" then
        local name = dir .. file.name
        -- cons("Found script file: " .. name .. " (last modified " .. table.concat(file.lastmodified, ", ") .. ")")

        all_files[name] = {
          name = name,
          isdir = false,
          lastmodified = file.lastmodified,
        }
      end
    end
  end

  return all_files
end

-- listfiles_generic returns lastmodified as a table { year, month, day, hour, minute, second }
function EXSCR_compare_dates(date_a, date_b)
  for i = 1, #date_a do
    if date_a[i] < date_b[i] then
      return -1
    elseif date_a[i] > date_b[i] then
      return 1
    end
  end
  return 0
end

function EXSCR_get_script_cache()
  local scripts_dir_path = EXSCR_ensure_scripts_directory()
  if scripts_dir_path == nil then return end

  local success, contents = readlevelfile(scripts_dir_path .. "/../.script_cache.json")
  if success then
    EXSCR_external_scripts = JSON.decode(contents)
  end
end

function EXSCR_save_script_cache()
  local scripts_dir_path = EXSCR_ensure_scripts_directory()
  if scripts_dir_path == nil then return end

  local new_cache = {}
    -- Import any updated scripts
  for k, file in pairs(EXSCR_external_scripts) do
    new_cache[k] = {
      lastmodified=file.lastmodified,
    }
  end

  local success, contents = writelevelfile(scripts_dir_path .. "/../.script_cache.json", JSON.encode(new_cache))
end

function EXSCR_sync_updated_scripts()
  cons("Syncing updated scripts")
  local scripts_dir_path = EXSCR_ensure_scripts_directory()
  if scripts_dir_path == nil then return end

  local file_scripts = {}
  local files = EXSCR_load_all_script_files(scripts_dir_path, "", {})
  local success = true

  if FAKECOMMANDS_load ~= nil then
    print("LOADING FAKECOMMANDS")
    FAKECOMMANDS_load(getlevelassetsfolder())
  end

  for name, file in pairs(files) do
    local file_name = file.name
    local script_name = file_name:gsub(".v6", "")

    scriptname = script_name

    local existing = EXSCR_external_scripts[script_name]
    if existing ~= nil then
      local comparison = EXSCR_compare_dates(file.lastmodified, existing.lastmodified)
      if comparison > 0 then
        -- File is newer, import it
        file_scripts[script_name] = {
          name=script_name,
          file_name=scripts_dir_path .. "/" .. file_name,
          lastmodified=file.lastmodified,
        }

        EXSCR_external_scripts[script_name] = file_scripts[script_name]
      end
    else
      -- New file, import it
      file_scripts[script_name] = {
        name=script_name,
        file_name=scripts_dir_path .. "/" .. file_name,
        lastmodified=file.lastmodified,
      }

      EXSCR_external_scripts[script_name] = file_scripts[script_name]
    end
  end

  -- For each script that exists in the level file, check if a separate file exists
  for script_i = 1, #scriptnames do
    local k, v = scriptnames[script_i], scripts[scriptnames[script_i]]
    -- print("\n=======================\nChecking script " .. k)
    -- print(table.concat(v, "\n"))
    scriptname = k

    if file_scripts[k] ~= nil then
      local file = file_scripts[k]

      -- Load the file, overwrite the level's script list with it
      local success, contents = EXSCR_load_file_script(file)
      if success then
        scripts[k] = contents
      end

      file_scripts[k] = nil
    elseif EXSCR_external_scripts[k] == nil then
      -- No separate file exists, export the script to a new file
      EXSCR_export_script(k, v)
    end
  end

  -- Import any updated scripts
  for k, file in pairs(file_scripts) do
    scriptname = k
    local success, contents = EXSCR_load_file_script(file)
    if success then
      scripts[k] = contents
      table.insert(scriptnames, k)
    end
  end

  EXSCR_save_script_cache()
end

-- Syncs all scripts in the level with external files
-- WARNING: SLOW. Only call on load.
function EXSCR_sync_all_scripts()
  cons("Syncing scripts")
  local level_modified_date = getmodtime(levelsfolder .. dirsep .. level_path)
  cons("Level last modified: " .. tostring(level_modified_date))

  external_files_loaded = false
  local scripts_dir_path = EXSCR_ensure_scripts_directory()
  if scripts_dir_path == nil then return end

  if FAKECOMMANDS_load ~= nil then
    print("LOADING FAKECOMMANDS")
    FAKECOMMANDS_load(getlevelassetsfolder())
  end

  -- local success, files, message = listfiles_generic(scripts_dir_path, true)

  EXSCR_external_scripts = {}
  local file_scripts = {}
  local files = EXSCR_load_all_script_files(scripts_dir_path, "", {})
  local success = true

  if success then
    -- Compile list of scripts in separate files
    for name, file in pairs(files) do
      local file_name = file.name
      local script_name = file_name:gsub(".v6", "")

      scriptname = script_name

      file_scripts[script_name] = {
        name=script_name,
        file_name=scripts_dir_path .. "/" .. file_name,
        lastmodified=file.lastmodified,
      }

      EXSCR_external_scripts[script_name] = file_scripts[script_name]
    end

    -- For each script that exists in the level file, check if a separate file exists
    for script_i = 1, #scriptnames do
      local k, v = scriptnames[script_i], scripts[scriptnames[script_i]]
      scriptname = k
      if file_scripts[k] ~= nil then
        local file = file_scripts[k]

        -- Load the file, overwrite the level's script list with it
        -- TODO: Check last modified time to see which is newer?
        local success, contents = EXSCR_load_file_script(file)
        if success then
          scripts[k] = contents
        end

        file_scripts[k] = nil
      else
        -- No separate file exists, export the script to a new file
        EXSCR_export_script(k, v)
      end
    end

    -- Any remaining scripts in file_scripts are new, so load them and add them to the level
    for k, file in pairs(file_scripts) do
      scriptname = k
      local success, contents = EXSCR_load_file_script(file)
      if success then
        scripts[k] = contents
        table.insert(scriptnames, k)
      end
    end
  else
    cons("Could not load files: " .. message)
  end
end
