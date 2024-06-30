# Custom-shell.yazi

A yazi plugin to open your custom-shell as your default yazi Shell.

## Previews
https://github.com/AnirudhG07/zsh.yazi/assets/146579014/4f194afe-c7bd-4c43-b361-348319d1b22d

## Requirements

Yazi version 0.2.5 or higher. And of course, zsh shell.

# Installation

```bash
## For linux and MacOS
git clone https://github.com/AnirudhG07/custom-shell.yazi.git ~/.config/yazi/plugins/custom-shell.yazi

## For Windows
git clone https://github.com/AnirudhG07/custom-shell.yazi.git %AppData%\yazi\config\plugins\custom-shell.yazi
```

Windows user's should check the init.lua file to make sure the paths used are correct.

# Usage

## Modes
There are 2 ways you can set your custom-shell. 
- The `auto` mode automatically sets the custom-shell to the value of `$SHELL` environment variable.
- The `shell_name` sets the custom-shell to the shell you want to use.

| **Mode** | **Description**                           |
|----------|-------------------------------------------|
| `auto`   | Automatically set custom-shell = `$SHELL` |
| `zsh`    | Set custom-shell = `zsh`                  |
| `bash`   | Set custom-shell = `bash`                 |
| `fish`   | Set custom-shell = `fish`                 |
| `ksh`    | Set custom-shell = `ksh` or Kornshell     |

Similarly you can input the name of the shell you want to use.
<br>
These commands uses the below command to run the shells-
```bash
custom_shell -ic "command";exit
```
For shell's like `nushell` where `-ic` is not supported, you will have to change the args in the `init.lua` file to support it.

## Keymapping
Add this to your `keymap.toml` file:

To use the `auto` mode, you can set the keymappings as-
```toml
[[manager.prepend_keymap]]
on = [ ":" ]
run = "plugin custom-shell --args=auto" 
desc = "custom-shell as default"
```
To choose a specific shell, you can set the keymappings as-
```toml
[[manager.prepend_keymap]]
on = [ ":" ]
run = "plugin custom-shell --args=zsh" # Example
desc = "custom-shell as default"
```
**NOTE:** For the shells with names different than the command used to call them, like 'Kornshell' which is called using 'ksh', you have to set `args=ksh` instead of `args=Kornshell`.

# Features
- Open your custom-shell as your default shell like zsh, [fish](https://github.com/AnirudhG07/fish.yazi), bash, etc.
- Usage of aliases is supported.
- When using 'auto' mode, if you change your default shell, it will automatically change the custom-shell to the new default shell.

## Acknowledgement

This code is referenced from issue [#1206](https://github.com/sxyazi/yazi/issues/1206) and PR [#84](https://github.com/yazi-rs/yazi-rs.github.io/pull/84) I raised on the repositories. Thank you to the maintainers of sxyazi/yazi for the help.
