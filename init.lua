return {
	entry = function()
		local value, event = ya.input({
			title = "Zsh shell:",
			-- title = "Fish <º))>< shell:",
			position = { "top-center", y = 3, w = 40 },
		})
		if event == 1 then
			ya.manager_emit("shell", {
				"zsh -ic 'source ~/.zshrc; " .. ya.quote(value .. "; exit'", true),
				-- "fish -c " .. ya.quote(value .. "; exit", true),
				block = true,
				confirm = true,
			})
		end
	end,
}
