
t = ...  -- Required for this info file to work.

t.shortname = "External Scripts"  -- The name that will be displayed on the button in the plugins list. Should be no longer than 21 characters, or it will be wider than the button.
t.longname = "External Scripts"  -- This can be about twice as long
t.author = "stupid cat"  -- Your name
t.version = "1.0.0"  -- The current version of this plugin, can be anything you want
t.minimumved = "1.12.0"  -- The minimum version of Ved this plugin is designed to work with. If unsure, just use the latest version.
t.description = [[
Syncs VED scripts to external files, allowing them to be
edited with your text editor of choice.

Scripts are synced any time a project is loaded or saved
(favouring external script files), and individual scripts
are updated when opened in the VED editor.
]]  -- The description that will be displayed in the plugins list. This uses the help/notepad system, so you can use text formatting here, and even images!
t.overrideinfo = false  -- Set this to true if you want to make your description fully custom and disable the default header with the plugin name, your username and the plugin version at the top. Leave at false if uncertain.