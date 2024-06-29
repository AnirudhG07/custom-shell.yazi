# zsh.yazi

A yazi plugin to open zsh(or any other) as your default Shell.

## Previews
https://github.com/AnirudhG07/zsh.yazi/assets/146579014/4f194afe-c7bd-4c43-b361-348319d1b22d

## Acknowledgements

This code is written by the maintainer of sxyazi/yazi, and was given as solution to issue [#1206](https://github.com/sxyazi/yazi/issues/1206) I raised on the repository. Thank you so much.

## Requirements

Yazi version 0.2.5 or higher. And of course, zsh(or any other) shell as your default.

## Installation

```bash
## For linux and MacOS
git clone https://github.com/AnirudhG07/zsh.yazi.git ~/.config/yazi/plugins/zsh.yazi

## For Windows
git clone https://github.com/AnirudhG07/zsh.yazi.git %AppData%\yazi\config\plugins\zsh.yazi
```

Windows user's should check the init.lua file to make sure the paths used are correct.

## Usage

### Keymapping
Add this to your `keymap.toml` file:

For zsh:
```toml
[[manager.prepend_keymap]]
on = [ ":" ]
run = "plugin zsh"
desc = "Zsh shell"
```
For fish:
```toml
[[manager.prepend_keymap]]
on = [ ":" ]
run = "plugin fish"
desc = "Fish <°))>< shell"
```

### Shell changes
If you are using some other shell apart from, like fish, please change the directory name to `shell.yazi`. OR you can just change the keymapping description keeping `run = "plugin zsh"` as it is.

## Features

- Open zsh(or any other) as your default shell.
- Usage of aliases is supported.
