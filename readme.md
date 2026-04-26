# VED: External Scripts

> Allows you to edit scripts externally from VED.

This plugin syncs VED scripts to external files, allowing them to be edited with your text editor of choice, or even generated en masse by a program.

**NOTE**: PLEASE make a backup before using this plugin! I take no responsibility for any loss of data.

As of v1.1.0, only Ved 2.0 is supported. If you're on Ved 1.X.X, please use version v1.0.1 instead.

## Syncing

This plugin will only sync files when an asset folder has been created for a project.

There are two ways scripts can be synced - on project load/save, or when accessing individual scripts in the VED editor.

### Project sync

When a sync is performed by loading or saving a project, the following process occurs:
1. The scripts folder is scanned for all available files
2. The .vvvvvv scripts are iterated through
  1. If a file exists for a .vvvvvv script, the file is imported
  2. Otherwise, the .vvvvvv script is exported to a file
3. The remaining files from the scripts folder that didn't have a corresponding .vvvvvv script are imported

This system considers the external files to be the source of truth for the project, only overwriting with scripts from the .vvvvvv file if an external file doesn't exist.

### Individual script sync

When editing a file using VED's script editor, scripts will get loaded and exported individually.
1. When a script is opened, the file version is loaded instead if one exists.
2. When a script is closed, it is exported to the filesystem

This can lead to some unexpected consequences if the same script is being edited within VED and externally at the same time. In general, any external changes made will be overwritten by VED when the script is closed.

## Internal vs. Simplified Scripting

This plugin exports scripts in human-readable formats. To differentiate between internal and simplified scripts, the header `#.int` can be used. When this is placed by itself on the first line of a script, it informs VED that the script should be compiled using the internal command system.

## Relative Paths

You can use relative paths in commands such as iftrinkets. For example, if you're editing script `test/dir/somescript_load`, `iftrinkets(0,./somescript)` will translate into `iftrinkets(0,test/dir/somescript) #r:.`

The suffix `#r:.` tells the plugin how to translate this back into the external script file.

| Type | Suffix | Example |
| ---- | ------ | ------- |
| Relative | #r:. | customiftrinkets(0,./somescript) |
| Relative (ancestor) | #r:.. | customiftrinkets(0,../somescript) |
| Absolute | #r:/ | customiftrinkets(0,/somescript) (note: this is effectively the same as not having the initial slash)|
