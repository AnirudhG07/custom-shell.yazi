local function shell_choice(shell_val)
	-- input is in lowercase always
	local alt_name_map = {
		kornshell = "ksh",
		powershell = "pwsh",
		nushell = "nu",
	}

	local shell_map = {
		bash = { shell_val = "bash", supporter = "-c" },
		zsh = { shell_val = "zsh", supporter = "-ic" },
		fish = { shell_val = "fish", supporter = "-c" },
		pwsh = { shell_val = "pwsh", supporter = "-Command" },
		sh = { shell_val = "sh", supporter = "-c" },
		ksh = { shell_val = "ksh", supporter = "-c" },
		csh = { shell_val = "csh", supporter = "-c" },
		tcsh = { shell_val = "tcsh", supporter = "-c" },
		dash = { shell_val = "dash", supporter = "-c" },
		nu = { shell_val = "nu", supporter = "-ic" },
	}

	shell_val = alt_name_map[shell_val] or shell_val
	local shell_info = shell_map[shell_val]

	if shell_info then
		return shell_info.shell_val, shell_info.supporter
	else
		return nil, nil
	end
end

local function entry(_, args)
	local shell_env = os.getenv("SHELL"):match(".*/(.*)")

	local shell_value = shell_env:lower()
	if args[1] ~= "auto" then
		shell_value = args[1]:lower()
	end

	local shell_val, supp = shell_choice(shell_value)
	if shell_val == nil then
		ya.notify("Unsupported shell: " .. shell_value .. "Choosing Default Shell: " .. shell_env)
		shell_val, supp = shell_choice(shell_env)
	end

	local blocked = args[2] and args[2]:lower() == "unblock" and false or true
	local input_title = shell_value .. " Shell " .. (blocked and "(block)" or "") .. ": "

	local value, event = ya.input({
		title = input_title,
		position = { "top-center", y = 3, w = 40 },
	})

	if event == 1 then
		ya.manager_emit("shell", {
			shell_val .. " " .. supp .. " " .. ya.quote(value .. "; exit", true),
			block = blocked,
			confirm = true,
		})
	end
end

return {
	entry = entry,
}
