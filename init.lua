local function entry(_, args)

	local shell_value = os.getenv("SHELL"):match(".*/(.*)")

	if args[1]=="auto" then
		shell_value = shell_value
	else
		shell_value = args[1]
	end

	local value, event = ya.input({
		title = shell_value .. " Shell:",
		position = { "top-center", y = 3, w = 40 },
	})
	
	if event == 1 then
		ya.manager_emit("shell", {
			shell_value .. " -ic " .. ya.quote(value .. "; exit", true),
			block = true,
			confirm = true,
		})
	end
end

return {
	entry = entry
}
