local script_compile_injection = {
	find = [[scripts[scriptname] = raw_script]],
	replace = [[
scripts[scriptname] = raw_script
EXSCR_export_script(scriptname, raw_script)]],
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
level = lvl
EXSCR_external_scripts = {}
EXSCR_get_script_cache()
EXSCR_sync_updated_scripts()

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
EXSCR_sync_updated_scripts()

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
		{
			find = [[return_used_flags(usedflags, outofrangeflags)]],
			replace = [[-- return_used_flags(usedflags, outofrangeflags)]],
			ignore_error = false,
			luapattern = false,
			allowmultiple = false
		},
		{
			find = [[local usedflags = {}
local outofrangeflags = {}]],
			replace = [[-- meow]],
			ignore_error = true,
			luapattern = false,
			allowmultiple = false
		},
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
			find = [[return function()]],
			replace = [[
return function()
	EXSCR_import_script(scriptname)]],
			ignore_error = false,
			luapattern = false,
			allowmultiple = false,
		},
	},
}