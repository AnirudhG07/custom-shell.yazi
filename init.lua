local function shell_choice(shell_val)
	-- input is in lowercase always
	local alt_name_map = {
		kornshell = "ksh",
		powershell = "pwsh",
		nushell = "nu",
	}

	local shell_map = {
		bash = { shell_val = "bash", supporter = "-ic", wait_cmd = "read" },
		zsh = { shell_val = "zsh", supporter = "-ic", wait_cmd = "read" },
		fish = { shell_val = "fish", supporter = "-c", wait_cmd = "read" },
		pwsh = { shell_val = "pwsh", supporter = "-Command", wait_cmd = "Read-Host" },
		sh = { shell_val = "sh", supporter = "-c", wait_cmd = "read" },
		ksh = { shell_val = "ksh", supporter = "-c", wait_cmd = "read" },
		csh = { shell_val = "csh", supporter = "-c", wait_cmd = "$<" },
		tcsh = { shell_val = "tcsh", supporter = "-c", wait_cmd = "$<" },
		dash = { shell_val = "dash", supporter = "-c", wait_cmd = "read" },
		nu = { shell_val = "nu", supporter = "-ic", wait_cmd = "input" },
	}

	shell_val = alt_name_map[shell_val] or shell_val
	local shell_info = shell_map[shell_val]

	if shell_info then
		return shell_info.shell_val, shell_info.supporter, shell_info.wait_cmd
	else
		return nil, "-c", "read"
	end
end

local function manage_extra_args(args)
	-- set default values, --custom-shell.yazi does not use --interactive but --confirm.
	local block, confirm, orphan, wait = true, true, false, false
	for _, arg in ipairs(args) do
		if arg == "-nb" or arg == "--no-block" then
			block = false
		elseif arg == "-nc" or arg == "--no-confirm" then
			confirm = false
		elseif arg == "-o" or arg == "--orphan" then
			orphan = true
		elseif arg == "-w" or arg == "--wait" then
			wait = true
		end
	end

	return block, confirm, orphan, wait
end

local function manage_additional_title_text(block, wait)
	local txt = ""
	if block or wait then
		txt = "(" .. (block and wait and "block and wait" or block and "block" or "") .. ")"
	end
	return txt
end

local function entry(_, args)
	local shell_env = os.getenv("SHELL"):match(".*/(.*)")
	local shell_value
  local cmd

	if args[1] == "auto" then
		shell_value = shell_env:lower()
	elseif args[1] == "custom" then
		if args[2] == "--wait" or args[2] == "-w" then
      shell_value = args[3]
      cmd = args[4]
    else
      shell_value = args[2]
      cmd = args[3]
    end
	else
		shell_value = args[1]:lower()
	end

	local shell_val, supp, wait_cmd = shell_choice(shell_value:lower())
	if shell_val == nil then
		ya.notify("Unsupported shell: " .. shell_value .. "Choosing Default Shell: " .. shell_env)
		shell_val, supp = shell_choice(shell_env)
	end

	local block, confirm, orphan, wait = manage_extra_args(args)
	local additional_title_text = manage_additional_title_text(block, wait)
	local input_title = shell_value .. " Shell " .. additional_title_text .. ": "

	local event = 1
	if args[1] ~= "custom" then
		cmd, event = ya.input({
			title = input_title,
			position = { "top-center", y = 3, w = 40 },
		})
	end

	if event == 1 then
		local after_cmd = wait and wait_cmd or "exit"
		ya.manager_emit("shell", {
			shell_val .. " " .. supp .. " " .. ya.quote(cmd .. "; " .. after_cmd, true),
			block = block,
			confirm = confirm,
			orphan = orphan,
		})
	end
end

return {
	entry = entry,
}
