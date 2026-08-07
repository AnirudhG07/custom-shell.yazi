--[[
Standalone test suite for custom-shell.yazi's main.lua.

It runs main.lua outside of an actual yazi process by mocking the
"ya"/"ui"/"cx" globals that yazi injects into plugins, plus the bits
of Lua's io/os libraries the plugin touches (file-based history, fzf
via io.popen, os.getenv). This lets every feature be exercised and
asserted on without needing yazi, tmux, fzf, or real files.

Note: %h/%s/%sN/%d/%dN placeholders inside the *user's own command
text* are substituted by yazi's Rust core at "shell" action time, not
by this plugin, so this suite can only assert they're passed through
untouched (not mangled by quoting) - not that they resolve to real
paths. See README.md's "Selected/Hovered Files" section.

Run it from the repository root with:

    lua tests/test.lua

Any Lua 5.1+ interpreter works (lua, lua5.1, lua5.2, lua5.3, lua5.4,
luajit). No external dependencies are required. The script exits with
status 0 if every test passes, or 1 if any test fails (with a
diff-style message for each failure), so it's CI-friendly, e.g.:

    lua tests/test.lua || exit 1
]]

local MAIN_LUA = (arg and arg[0] and arg[0]:match("(.*/)") or "./") .. "../main.lua"

-- ---------------------------------------------------------------------
-- tiny test framework
-- ---------------------------------------------------------------------

local tests, failures, passed = {}, {}, 0

local function test(name, fn)
	tests[#tests + 1] = { name = name, fn = fn }
end

local function fail(msg)
	error(msg, 0)
end

local function assert_eq(actual, expected, label)
	if actual ~= expected then
		fail(string.format("%s\n    expected: %s\n    actual:   %s", label or "values differ", tostring(expected), tostring(actual)))
	end
end

local function assert_contains(haystack, needle, label)
	haystack = tostring(haystack)
	if not haystack:find(needle, 1, true) then
		fail(string.format("%s\n    expected to find: %s\n    inside:           %s", label or "substring missing", needle, haystack))
	end
end

local function assert_not_contains(haystack, needle, label)
	haystack = tostring(haystack)
	if haystack:find(needle, 1, true) then
		fail(string.format("%s\n    expected NOT to find: %s\n    inside:               %s", label or "unexpected substring", needle, haystack))
	end
end

-- ---------------------------------------------------------------------
-- mock yazi runtime (ya / ui / cx / state) + io/os shims
-- ---------------------------------------------------------------------

-- in-memory fake filesystem, so history_add/history_prev never touch disk
local fake_fs = {}

local mock -- forward declaration, filled in by reset_mocks()

local function reset_mocks(opts)
	opts = opts or {}
	fake_fs = {}

	mock = {
		notifications = {},
		emitted = nil, -- { name, cmd, block, interactive, orphan }
		input_queue = opts.input_queue or {}, -- list of {value=, event=} consumed in order by ya.input
		fzf_selection = opts.fzf_selection, -- string returned by the mocked `fzf` popen call
		target_family = opts.target_family or "unix",
		shell_env = opts.shell_env, -- value returned by os.getenv("SHELL"); nil means unset
	}

	_G.ya = {
		sync = function(fn)
			return function(...)
				return fn(_G.state, ...)
			end
		end,
		quote = function(s)
			return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
		end,
		notify = function(o)
			mock.notifications[#mock.notifications + 1] = type(o) == "table" and o.content or tostring(o)
		end,
		input = function(_opts)
			local next_input = table.remove(mock.input_queue, 1)
			if not next_input then
				return nil, 0
			end
			return next_input.value, next_input.event
		end,
		emit = function(name, o)
			mock.emitted = { name = name, cmd = o[1], block = o.block, interactive = o.interactive, orphan = o.orphan }
		end,
		target_family = function()
			return mock.target_family
		end,
	}

	_G.ui = {
		hide = function()
			return { drop = function() end }
		end,
	}

	_G.cx = { active = { selected = {}, current = { hovered = nil } } }

	_G.state = { history_path = "/fake/history", save_history = true }

	os.getenv = function(name)
		if name == "SHELL" then
			return mock.shell_env
		elseif name == "HOME" then
			return "/fake/home"
		elseif name == "APPDATA" then
			return "C:\\fake\\appdata"
		end
		return nil
	end

	io.open = function(path, mode)
		mode = mode or "r"
		if mode:find("r") and fake_fs[path] == nil then
			-- "a+" style modes still succeed even if the file doesn't exist yet
			if not mode:find("%+") and mode ~= "a" then
				return nil
			end
			fake_fs[path] = ""
		end
		fake_fs[path] = fake_fs[path] or ""
		local handle = {}
		function handle:write(s)
			fake_fs[path] = fake_fs[path] .. s
			return handle
		end
		function handle:read(fmt)
			if fmt == "*all" or fmt == "a" then
				return fake_fs[path]
			end
			return nil
		end
		function handle:close() end
		return handle
	end

	io.lines = function(path)
		local content = fake_fs[path] or ""
		local ls, i = {}, 0
		for line in content:gmatch("[^\n]+") do
			ls[#ls + 1] = line
		end
		return function()
			i = i + 1
			return ls[i]
		end
	end

	io.popen = function(_cmd)
		local selection = mock.fzf_selection or ""
		return {
			read = function(_self, _fmt)
				return selection
			end,
			close = function() end,
		}
	end
end

local function load_plugin()
	local chunk = assert(loadfile(MAIN_LUA))
	return chunk()
end

-- ---------------------------------------------------------------------
-- tests: issue #21 - crash when $SHELL is unset
-- ---------------------------------------------------------------------

test("entry() does not crash when $SHELL is unset (unix falls back to sh)", function()
	reset_mocks({ shell_env = nil, target_family = "unix" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "auto" } })
	assert_contains(table.concat(mock.notifications, "\n"), "falling back to sh", "expected a fallback notification")
end)

test("entry() falls back to pwsh on windows when $SHELL is unset", function()
	reset_mocks({ shell_env = nil, target_family = "windows", input_queue = { { value = "echo hi", event = 1 } } })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "auto" } })
	assert_contains(table.concat(mock.notifications, "\n"), "falling back to pwsh", "expected windows fallback to pwsh")
end)

test("a normal $SHELL value (with path and no crash) selects that shell", function()
	reset_mocks({ shell_env = "/usr/bin/zsh", input_queue = { { value = "echo hi", event = 1 } } })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "auto" } })
	assert_eq(#mock.notifications, 0, "no fallback notification expected when $SHELL is set")
	assert_contains(mock.emitted.cmd, "zsh -ic", "expected zsh to be selected via $SHELL")
end)

-- ---------------------------------------------------------------------
-- tests: shell selection (named / alt names / unsupported)
-- ---------------------------------------------------------------------

test("named shell selection (fish) uses its own supporter flag", function()
	reset_mocks({ shell_env = "/bin/bash", input_queue = { { value = "echo hi", event = 1 } } })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "fish" } })
	assert_contains(mock.emitted.cmd, "fish -c", "expected fish's own supporter flag (-c, not -ic)")
end)

test("alternate shell names map to their canonical form (kornshell -> ksh, nushell -> nu)", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "kornshell", "echo hi" } })
	assert_contains(mock.emitted.cmd, "ksh -c", "expected 'kornshell' to resolve to ksh")

	reset_mocks({ shell_env = "/bin/bash" })
	plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "nushell", "echo hi" } })
	assert_contains(mock.emitted.cmd, "nu -l -i -c", "expected 'nushell' to resolve to nu")
end)

test("unsupported shell name falls back to $SHELL with a notification", function()
	reset_mocks({ shell_env = "/bin/bash", input_queue = { { value = nil, event = 0 } } })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "totallynotashell" } })
	assert_contains(table.concat(mock.notifications, "\n"), "Unsupported shell", "expected an unsupported-shell notification")
	assert_contains(table.concat(mock.notifications, "\n"), "bash", "expected fallback to report the $SHELL-derived shell")
end)

-- ---------------------------------------------------------------------
-- tests: extra args (--block, --orphan, --wait, --confirm)
-- ---------------------------------------------------------------------

test("--wait appends the shell's wait command and separator", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo hi", wait = "true" } })
	assert_contains(mock.emitted.cmd, ";read", "expected bash's ';' separator + 'read' wait command")
end)

test("nushell uses its own separator/wait command when waiting", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "nu", "echo hi", wait = true } })
	assert_contains(mock.emitted.cmd, "| print;input", "expected nu's '| print;' separator + 'input' wait command")
end)

test("block/orphan/interactive(confirm) flags are forwarded to the shell emit", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo hi", block = "false", orphan = "true", confirm = "true" } })
	assert_eq(mock.emitted.block, false, "block should be false")
	assert_eq(mock.emitted.orphan, true, "orphan should be true")
	assert_eq(mock.emitted.interactive, true, "interactive should follow --confirm")
end)

test("boolean-typed args (not just strings) are also accepted", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo hi", block = false, orphan = true } })
	assert_eq(mock.emitted.block, false, "boolean false should be respected")
	assert_eq(mock.emitted.orphan, true, "boolean true should be respected")
end)

-- ---------------------------------------------------------------------
-- tests: %h/%s/%sN/%d/%dN placeholders (issues #11, #4) - PR #22
-- ---------------------------------------------------------------------

test("%h/%s/%sN/%d/%dN typed by the user pass through untouched (yazi itself expands them)", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "nvim %h; cat %s; echo %s1 %d1" } })
	assert_contains(mock.emitted.cmd, "%h", "expected %h to survive quoting untouched")
	assert_contains(mock.emitted.cmd, "%s1", "expected %s1 to survive quoting untouched")
	assert_contains(mock.emitted.cmd, "%d1", "expected %d1 to survive quoting untouched")
end)

test("%% (escaped percent) also survives quoting untouched on unix", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo literal=%%h" } })
	assert_contains(mock.emitted.cmd, "%%h", "expected %%h to survive quoting untouched on unix")
end)

test("on windows, %-placeholders survive ya.quote()'s percent-mangling", function()
	reset_mocks({ shell_env = "/bin/bash", target_family = "windows" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo %h %s1" } })
	assert_contains(mock.emitted.cmd, "%h", "expected %h to survive windows quoting")
	assert_contains(mock.emitted.cmd, "%s1", "expected %s1 to survive windows quoting")
end)

test("POSIX-arg shells (bash/zsh/sh/ksh/dash) auto-append '<shell> %s' so $@ picks up the selection", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "zsh", "echo $@" } })
	assert_contains(mock.emitted.cmd, "zsh %s", "expected zsh's name + trailing %s appended after the quoted command")
end)

test("ARGV-arg shells (fish/csh/tcsh) auto-append bare %s (no fake $0)", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "fish", "echo $argv" } })
	assert_not_contains(mock.emitted.cmd, "'fish %s'", "fish should not get a fake $0 shell-name arg")
	assert_contains(mock.emitted.cmd, "%s", "expected a trailing %s for fish")
end)

test("NONE-arg shells (pwsh/nu) do not auto-append any trailing args", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "pwsh", "echo hi" } })
	assert_not_contains(mock.emitted.cmd, "%s", "pwsh should not get an auto-appended %s suffix")

	reset_mocks({ shell_env = "/bin/bash" })
	plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "nu", "echo hi" } })
	assert_not_contains(mock.emitted.cmd, "%s", "nu should not get an auto-appended %s suffix")
end)

-- ---------------------------------------------------------------------
-- tests: history (save, dedup, replay)
-- ---------------------------------------------------------------------

test("running a command saves it to history", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo hi" } })
	assert_contains(fake_fs["/fake/history"] or "", "echo hi", "expected the command to be written to the history file")
end)

test("duplicate commands are not written to history twice", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo hi" } })
	plugin.entry(nil, { args = { "custom", "bash", "echo hi" } })
	local _, count = (fake_fs["/fake/history"] or ""):gsub("echo hi", "echo hi")
	assert_eq(count, 1, "the same command should only be stored once")
end)

test("save_history = false skips writing to the history file", function()
	reset_mocks({ shell_env = "/bin/bash" })
	_G.state.save_history = false
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "custom", "bash", "echo hi" } })
	assert_eq(fake_fs["/fake/history"] or "", "", "expected nothing written when save_history is false")
end)

test("history mode replays a previously saved command through fzf + input", function()
	reset_mocks({
		shell_env = "/bin/bash",
		fzf_selection = "echo replayed",
		input_queue = { { value = "echo replayed", event = 1 } },
	})
	fake_fs["/fake/history"] = "echo replayed\n"
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "history" } })
	assert_contains(mock.emitted.cmd, "echo replayed", "expected the replayed history command to be executed")
end)

test("history mode notifies and bails out when history is empty", function()
	reset_mocks({ shell_env = "/bin/bash" })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "history" } })
	assert_contains(table.concat(mock.notifications, "\n"), "History is Empty", "expected an empty-history notification")
	assert_eq(mock.emitted, nil, "no shell command should be emitted for empty history")
end)

-- ---------------------------------------------------------------------
-- tests: cancelling the input box should not run anything
-- ---------------------------------------------------------------------

test("cancelling the input prompt (esc) does not emit a shell command", function()
	reset_mocks({ shell_env = "/bin/bash", input_queue = { { value = nil, event = 0 } } })
	local plugin = load_plugin()
	plugin.entry(nil, { args = { "zsh" } })
	assert_eq(mock.emitted, nil, "expected no shell command to be emitted when the user cancels")
end)

-- ---------------------------------------------------------------------
-- run
-- ---------------------------------------------------------------------

for _, t in ipairs(tests) do
	local ok, err = pcall(t.fn)
	if ok then
		passed = passed + 1
		print("  ok  - " .. t.name)
	else
		failures[#failures + 1] = { name = t.name, err = err }
		print("FAIL  - " .. t.name)
	end
end

print(("\n%d passed, %d failed (%d total)"):format(passed, #failures, #tests))

if #failures > 0 then
	print("\nFailures:\n")
	for _, f in ipairs(failures) do
		print("* " .. f.name)
		print("  " .. tostring(f.err):gsub("\n", "\n  "))
		print("")
	end
	os.exit(1)
end
