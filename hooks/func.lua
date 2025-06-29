function ensure_scripts_directory()
  local scripts_dir_path = levelsfolder .. dirsep .. level_path:gsub(".vvvvvv", "/scripts")

  if not directory_exists(scripts_dir_path) then
    cons("Creating script directory")
    create_directory(scripts_dir_path)
  end

  return scripts_dir_path
end

function export_script(name, raw_script)
  local scripts_dir_path = ensure_scripts_directory()
  local contents = script_decompile(raw_script)
  local script_name = scripts_dir_path .. "/" .. name .. ".v6script"
  cons("Exporting " .. name .. " to " .. script_name)

  if internalscript then
    table.insert(contents, 1, "#.int.v6script")
  end
  writelevelfile(script_name, table.concat(contents, "\n"))
end

function import_script(name)
  local scripts_dir_path = ensure_scripts_directory()
  local file_name = scripts_dir_path .. "/" .. name .. ".v6script"
  if file_exists(file_name) then
    local file = {
      name=script_name,
      file_name=file_name,
    }
    local success, contents = load_file_script(file)
    scripts[name] = contents
  end
end

function load_file_script(file)
  local success, contents = readlevelfile(file.file_name)

  if success then
    contents = contents:gsub("\r", "")
    local lines = {}
    if contents:sub(-1,-1) ~= "\n" then
      contents = contents .. "\n"
    end
    for ln in contents:gmatch("([^\n]*)\n") do
      table.insert(lines, ln)
    end

    if lines[1] == "#.int.v6script" then
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

function sync_scripts()
  cons("Syncing scripts")
  local scripts_dir_path = ensure_scripts_directory(level_path)

  local success, files, message = listfiles_generic(scripts_dir_path, ".v6script", true)

  local file_scripts = {}

  if success then
    for file_i = 1, #files do
      local file_name = files[file_i].name
      local script_name = file_name:gsub(".v6script", "")

      file_scripts[script_name] = {
        name=script_name,
        file_name=scripts_dir_path .. "/" .. file_name,
      }
    end

    for script_i = 1, #scriptnames do
      local k, v = scriptnames[script_i], scripts[scriptnames[script_i]]
      if file_scripts[k] ~= nil then
        local file = file_scripts[k]

        local success, contents = load_file_script(file)
        if success then
          scripts[k] = contents
        end

        file_scripts[k] = nil
      else
        export_script(k, v)
      end
    end

    for k, file in pairs(file_scripts) do
      local success, contents = load_file_script(file)
      if success then
        scripts[k] = contents
        table.insert(scriptnames, k)
      end
    end
  else
    cons("Could not load files: " .. message)
  end
end

-- function getMyExamplePluginText()
-- 	return "An example plugin is causing this text to be displayed!"
-- end