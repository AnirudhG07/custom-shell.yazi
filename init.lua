return {
	entry = function(_, args)
		-- Always default to automatic shell
		local shell_value = os.getenv("SHELL"):match(".*/(.*)")
		-- Store text box entry value
		local value_string = ""
		-- Block and confirm command flags
		local block = false
		local confirm = true

		-- Parse command flags
		for idx, item in ipairs(args) do
			if item == "--block" then
				block = true
			elseif item == "--confirm" then
				confirm = false
			elseif idx ~= 1 then
				value_string = value_string .. " " .. item
			end
		end

		-- If custom shell is chosen, use it
		if args[1] and not args[1]:match("auto") and not args[1]:match("^%-%-") then
			shell_value = args[1]:lower() == "kornshell" and "ksh" or args[1]
		end

		-- Change prompt title if block is selected
		local prompt_title = block and shell_value:gsub("^%l", string.upper) .. " Shell (block):"
			or shell_value:gsub("^%l", string.upper) .. " Shell:"

		-- Display prompt if confirm is not selected
		local value, event
		if not confirm then
			value, event = ya.input({
				title = prompt_title,
				value = value_string,
				position = { "top-center", y = 3, w = 40 },
			})
		else
			value = value_string
			event = 1
		end

		-- Execute
		if event == 1 then
			ya.manager_emit("shell", {
				shell_value .. " -i -c " .. ya.quote(value .. "; exit", true),
				block = block,
				confirm = true,
			})
		end
	end,
}
