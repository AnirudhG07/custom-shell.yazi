# Custom-shell.yazi

A yazi plugin to open your custom-shell as your default yazi Shell.

## Previews

https://github.com/AnirudhG07/custom-shell.yazi/assets/146579014/1cd6ab98-5b79-4ee8-b59a-dbee053edad5

## Requirements

Yazi version 0.2.5 or higher. And of course, your custom-shell as default shell.

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
| -------- | ----------------------------------------- |
| `auto`   | Automatically set custom-shell = `$SHELL` |
| `zsh`    | Set custom-shell = `zsh`                  |
| `bash`   | Set custom-shell = `bash`                 |
| `fish`   | Set custom-shell = `fish`  <°))><         |
| `nu`     | Set custom-shell = `nu`                   |
| `ksh`    | Set custom-shell = `ksh` or Kornshell     |

Similarly you can input the name of the shell you want to use.
<br>
These commands uses the below command to run the shells-

```bash
custom_shell -i -c "command";exit
```

## Keymapping

Add this to your `keymap.toml` file:

To use the `auto` mode, you can set the keymappings as-

```toml
[[manager.prepend_keymap]]
on = [ ";" ]
run = "plugin custom-shell"
desc = "custom-shell using default shell"
```

To use the `block` mode, you can set the keymappings as-

```toml
[[manager.prepend_keymap]]
on = [ ":" ]
run = "plugin custom-shell --args='auto --block'"
desc = "custom-shell with blocking"
```

To choose a specific shell, you can set the keymappings as-

```toml
[[manager.prepend_keymap]]
on = [ ";" ]
run = "plugin custom-shell --args=zsh"
desc = "custom-shell with zsh"
```

To run a specific command in a specific shell, you can set the keymappings as-

```toml
[[manager.prepend_keymap]]
on = [ ";" ]
run = "plugin custom-shell --args='fish \"echo example command with --block and --confirm flags ; read c\" --block --confirm'"
desc = "Run a blocking echo command with fish"
```

**NOTE:** The first argument must be either "auto" or the shell name e.g. "fish". Multiple arguments must be quoted with single quotes.

# Features

- Open your custom-shell as your default shell like zsh, <°))>< [fish](https://github.com/AnirudhG07/fish.yazi), bash, etc.
- Usage of aliases is supported except in nushell.
- When using 'auto' mode, if you change your default shell, it will automatically change the custom-shell to the new default shell.
- If your shell runs extra commands like printing texts, taskwarrior, newsupdates, etc. when you open the shell, they will not hinder into it's functioning.

## Acknowledgement

This code is referenced from issue [#1206](https://github.com/sxyazi/yazi/issues/1206) and PR [#84](https://github.com/yazi-rs/yazi-rs.github.io/pull/84) I raised on the repositories. Thank you to the maintainers of sxyazi/yazi for the help.
