local script_compile_injection = {
	find = [[scripts[scriptname] = raw_script]],
	replace = [[
scripts[scriptname] = raw_script
export_script(scriptname, raw_script)]],
	ignore_error = false,
	luapattern = false,
	allowmultiple = false,
}

sourceedits =
{
	["vvvvvvxml"] =
	{
		-- Sync scripts on load
		{
			find = [[-- Some things that for now we'll have to hardcode carrying over...]],
			replace = [[
-- Sync state of scripts
limit = thislimit
scripts = allscripts
scriptnames = myscriptnames
vedmetadata = myvedmetadata
level_path = path
sync_all_scripts()

-- Some things that for now we'll have to hardcode carrying over...]],
			ignore_error = false,
			luapattern = false,
			allowmultiple = false,
		},
		-- Sync scripts on save
		{
			find = [[cons("Assembling scripts...")]],
			replace = [[
if path ~= nil then
	level_path = path
end
if external_files_loaded == false and false then
	cons("External files not yet loaded, syncing all scripts (fakecommands workaround)")
	sync_all_scripts()
	external_files_loaded = true
else
	cons("External files already loaded, syncing updated scripts")
	sync_updated_scripts()
end

cons("Assembling scripts...")]],
			ignore_error = false,
			luapattern = false,
			allowmultiple = false,
		},
	},

	["dialog_uses"] =
	{
		script_compile_injection,
	},
	["scriptfunc"] =
	{
		script_compile_injection,
	},
	["uis/scripteditor/draw"] =
	{
		script_compile_injection,
	},
	["uis/scripteditor/keypressed"] =
	{
		script_compile_injection,
	},

	["uis/scripteditor/load"] =
	{
		{
			find = [[newinputsys.create(INPUT.MULTILINE, "script_lines", script_decompile(scripts[scriptname]))]],
			replace = [[
import_script(scriptname)
newinputsys.create(INPUT.MULTILINE, "script_lines", script_decompile(scripts[scriptname]))]],
			ignore_error = false,
			luapattern = false,
			allowmultiple = false,
		},
	},
}