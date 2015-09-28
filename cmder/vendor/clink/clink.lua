--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
clink.matches = {}
clink.generators = {}

clink.prompt = {}
clink.prompt.filters = {}

--------------------------------------------------------------------------------
function clink.compute_lcd(text, list)
    local list_n = #list
    if list_n < 2 then
        return
    end

    -- Find min and max limits
    local max = 100000
    for i = 1, #list, 1 do
        local j = #(list[i])
        if max > j then
            max = j
        end
    end

    -- For each character in the search range...
    local mid = #text
    local lcd = ""
    for i = 1, max, 1 do
        local same = true
        local l = list[1]:sub(i, i)
        local m = l:lower()

        -- Compare character at the index with each other character in the
        -- other matches.
        for j = 2, list_n, 1 do
            local n = list[j]:sub(i, i):lower()
            if m ~= n then
                same = false
                break
            end
        end

        -- If all characters match then use first match's character.
        if same then
            lcd = lcd..l 
        else
            -- Otherwise use what the user's typed or if we're past that then
            -- bail out.
            if i <= mid then
                lcd = lcd..text:sub(i, i)
            else
                break
            end
        end
    end

    return lcd
end

--------------------------------------------------------------------------------
function clink.is_single_match(matches)
    if #matches <= 1 then
        return true
    end

    local first = matches[1]:lower()
    for i = 2, #matches, 1 do
        if first ~= matches[i]:lower() then
            return false
        end
    end

    return true
end

--------------------------------------------------------------------------------
function clink.is_point_in_quote(str, i)
    if i > #str then
        i = #str
    end

    local c = 1
    local q = string.byte("\"")
    for j = 1, i do
        if string.byte(str, j) == q then
            c = c * -1
        end
    end

    if c < 0 then
        return true
    end

    return false
end

--------------------------------------------------------------------------------
function clink.adjust_for_separator(buffer, point, first, last)
    local seps = nil
    if clink.get_host_process() == "cmd.exe" then
        seps = "|&"
    end

    if seps then
        -- Find any valid command separators and if found, manipulate the
        -- completion state a little bit.
        local leading = buffer:sub(1, first - 1)

        -- regex is: <sep> <not_seps> <eol>
        local regex = "["..seps.."]([^"..seps.."]*)$"
        local sep_found, _, post_sep = leading:find(regex)

        if sep_found and not clink.is_point_in_quote(leading, sep_found) then
            local delta = #leading - #post_sep
            buffer = buffer:sub(delta + 1)
            first = first - delta
            last = last - delta
            point = point - delta

            if first < 1 then
                first = 1
            end
        end
    end

    return buffer, point, first, last
end

--------------------------------------------------------------------------------
function clink.generate_matches(text, first, last)
    local line_buffer
    local point

    line_buffer, point, first, last = clink.adjust_for_separator(
        rl_state.line_buffer,
        rl_state.point,
        first,
        last
    )

    rl_state.line_buffer = line_buffer
    rl_state.point = point

    clink.matches = {}
    clink.match_display_filter = nil

    for _, generator in ipairs(clink.generators) do
        if generator.f(text, first, last) == true then
            if #clink.matches > 1 then
                -- Catch instances where there's many entries of a single match
                if clink.is_single_match(clink.matches) then
                    clink.matches = { clink.matches[1] }
                    return true;
                end

                -- First entry in the match list should be the user's input,
                -- modified here to be the lowest common denominator.
                local lcd = clink.compute_lcd(text, clink.matches)
                table.insert(clink.matches, 1, lcd)
            end

            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
function clink.add_match(match)
    if type(match) == "table" then
        for _, i in ipairs(match) do
            table.insert(clink.matches, i)
        end

        return
    end

    table.insert(clink.matches, match)
end

--------------------------------------------------------------------------------
function clink.register_match_generator(func, priority)
    if priority == nil then
        priority = 999
    end

    table.insert(clink.generators, {f=func, p=priority})
    table.sort(clink.generators, function(a, b) return a["p"] < b["p"] end)
end

--------------------------------------------------------------------------------
function clink.is_match(needle, candidate)
    if needle == nil then
        error("Nil needle value when calling clink.is_match()", 2)
    end

    if clink.lower(candidate:sub(1, #needle)) == clink.lower(needle) then
        return true
    end
    return false
end

--------------------------------------------------------------------------------
function clink.match_count()
    return #clink.matches
end

--------------------------------------------------------------------------------
function clink.set_match(i, value)
    clink.matches[i] = value
end

--------------------------------------------------------------------------------
function clink.get_match(i)
    return clink.matches[i]
end

--------------------------------------------------------------------------------
function clink.match_words(text, words)
    local count = clink.match_count()

    for _, i in ipairs(words) do
        if clink.is_match(text, i) then
            clink.add_match(i)
        end
    end

    return clink.match_count() - count
end

--------------------------------------------------------------------------------
function clink.match_files(pattern, full_path, find_func)
    -- Fill out default values
    if type(find_func) ~= "function" then
        find_func = clink.find_files
    end

    if full_path == nil then
        full_path = true
    end

    if pattern == nil then
        pattern = "*"
    end

    -- Glob files.
    pattern = pattern:gsub("/", "\\")
    local glob = find_func(pattern, true)

    -- Get glob's base.
    local base = ""
    local i = pattern:find("[\\:][^\\:]*$")
    if i and full_path then
        base = pattern:sub(1, i)
    end

    -- Match them.
    local count = clink.match_count()

    for _, i in ipairs(glob) do
        local full = base..i
        clink.add_match(full)
    end

    return clink.match_count() - count
end

--------------------------------------------------------------------------------
function clink.split(str, sep)
    local i = 1
    local ret = {}
    for _, j in function() return str:find(sep, i, true) end do
        table.insert(ret, str:sub(i, j - 1))
        i = j + 1
    end
    table.insert(ret, str:sub(i, j))

    return ret
end

--------------------------------------------------------------------------------
function clink.quote_split(str, ql, qr)
    if not qr then
        qr = ql
    end

    -- First parse in "pre[ql]quote_string[qr]" chunks
    local insert = table.insert
    local i = 1
    local needle = "%b"..ql..qr
    local parts = {}
    for l, r, quote in function() return str:find(needle, i) end do
        -- "pre"
        if l > 1 then
            insert(parts, str:sub(i, l - 1))
        end

        -- "quote_string"
        insert(parts, str:sub(l, r))
        i = r + 1
    end

    -- Second parse what remains as "pre[ql]being_quoted"
    local l = str:find(ql, i, true)
    if l then
        -- "pre"
        if l > 1 then
            insert(parts, str:sub(i, l - 1))
        end

        -- "being_quoted"
        insert(parts, str:sub(l))
    elseif i <= #str then
        -- Finally add whatever remains...
        insert(parts, str:sub(i))
    end

    return parts
end

--------------------------------------------------------------------------------
function clink.prompt.register_filter(filter, priority)
    if priority == nil then
        priority = 999
    end

    table.insert(clink.prompt.filters, {f=filter, p=priority})
    table.sort(clink.prompt.filters, function(a, b) return a["p"] < b["p"] end)
end

--------------------------------------------------------------------------------
function clink.filter_prompt(prompt)
    local function add_ansi_codes(p)
        local c = tonumber(clink.get_setting_int("prompt_colour"))
        if c < 0 then
            return p
        end

        c = c % 16

        --[[
            <4              >=4             %2
            0 0  0 Black    4 1 -3 Blue     0
            1 4  3 Red      5 5  0 Magenta  1
            2 2  0 Green    6 3 -3 Cyan     0
            3 6  3 Yellow   7 7  0 Gray     1
        --]]

        -- Convert from cmd.exe colour indices to ANSI ones.
        local colour_id = c % 8
        if (colour_id % 2) == 1 then
            if colour_id < 4 then
                c = c + 3
            end
        elseif colour_id >= 4 then
            c = c - 3
        end

        -- Clamp
        if c > 15 then
            c = 15
        end

        -- Build ANSI code
        local code = "\x1b[0;"
        if c > 7 then
            c = c - 8
            code = code.."1;"
        end
        code = code..(c + 30).."m"

        return code..p.."\x1b[0m"
    end

    clink.prompt.value = prompt

    for _, filter in ipairs(clink.prompt.filters) do
        if filter.f() == true then
            return add_ansi_codes(clink.prompt.value)
        end
    end

    return add_ansi_codes(clink.prompt.value)
end

-- vim: expandtab
--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
clink.arg = {}

--------------------------------------------------------------------------------
local parsers               = {}
local is_parser
local is_sub_parser
local new_sub_parser
local parser_go_impl
local merge_parsers

local parser_meta_table     = {}
local sub_parser_meta_table = {}

--------------------------------------------------------------------------------
function parser_meta_table.__concat(lhs, rhs)
    if not is_parser(rhs) then
        error("Right-handside must be parser.", 2)
    end

    local t = type(lhs)
    if t == "table" then
        local ret = {}
        for _, i in ipairs(lhs) do
            table.insert(ret, i .. rhs)
        end

        return ret
    elseif t ~= "string" then
        error("Left-handside must be a string or a table.", 2)
    end

    return new_sub_parser(lhs, rhs)
end

--------------------------------------------------------------------------------
local function unfold_table(source, target)
    for _, i in ipairs(source) do
        if type(i) == "table" and getmetatable(i) == nil then
            unfold_table(i, target)
        else
            table.insert(target, i)
        end
    end
end

--------------------------------------------------------------------------------
local function parser_is_flag(parser, part)
    if part == nil then
        return false
    end

    local prefix = part:sub(1, 1)
    return prefix == "-" or prefix == "/"
end

--------------------------------------------------------------------------------
local function parser_add_arguments(parser, ...)
    for _, i in ipairs({...}) do
        -- Check all arguments are tables.
        if type(i) ~= "table" then
            error("All arguments to add_arguments() must be tables.", 2)
        end

        -- Only parsers are allowed to be specified without being wrapped in a
        -- containing table.
        if getmetatable(i) ~= nil then
            if is_parser(i) then
                table.insert(parser.arguments, i)
            else
                error("Tables can't have meta-tables.", 2)
            end
        else
            -- Expand out nested tables and insert into object's arguments table.
            local arguments = {}
            unfold_table(i, arguments)
            table.insert(parser.arguments, arguments)
        end
    end

    return parser
end

--------------------------------------------------------------------------------
local function parser_set_arguments(parser, ...)
    parser.arguments = {}
    return parser:add_arguments(...)
end

--------------------------------------------------------------------------------
local function parser_add_flags(parser, ...)
    local flags = {}
    unfold_table({...}, flags)

    -- Validate the specified flags.
    for _, i in ipairs(flags) do
        if is_sub_parser(i) then
            i = i.key
        end

        -- Check all flags are strings.
        if type(i) ~= "string" then
            error("All parser flags must be strings. Found "..type(i), 2)
        end

        -- Check all flags start with a - or a /
        if not parser:is_flag(i) then
            error("Flags must begin with a '-' or a '/'", 2)
        end
    end

    -- Append flags to parser's existing table of flags.
    for _, i in ipairs(flags) do
        table.insert(parser.flags, i)
    end

    return parser
end

--------------------------------------------------------------------------------
local function parser_set_flags(parser, ...)
    parser.flags = {}
    return parser:add_flags(...)
end

--------------------------------------------------------------------------------
local function parser_flatten_argument(parser, index, func_thunk)
    -- Sanity check the 'index' param to make sure it's valid.
    if type(index) == "number" then
        if index <= 0 or index > #parser.arguments then
            return parser.use_file_matching
        end
    end

    -- index == nil is a special case that returns the parser's flags
    local opts = {}
    local arg_opts
    if index == nil then
        arg_opts = parser.flags
    else
        arg_opts = parser.arguments[index]
    end

    -- Convert each argument option into a string and collect them in a table.
    for _, i in ipairs(arg_opts) do
        if is_sub_parser(i) then
            table.insert(opts, i.key)
        else
            local t = type(i)
            if t == "function" then
                local results = func_thunk(i)
                local t = type(results)
                if not results then
                    return parser.use_file_matching
                elseif t == "boolean" then
                    return (results and parser.use_file_matching)
                elseif t == "table" then
                    for _, j in ipairs(results) do
                        table.insert(opts, j)
                    end
                end
            elseif t == "string" or t == "number" then
                table.insert(opts, tostring(i))
            end
        end
    end

    return opts
end

--------------------------------------------------------------------------------
local function parser_go_args(parser, state)
    local exhausted_args = false
    local exhausted_parts = false

    local part = state.parts[state.part_index]
    local arg_index = state.arg_index
    local arg_opts = parser.arguments[arg_index]
    local arg_count = #parser.arguments

    -- Is the next argument a parser? Parse control directly on to it.
    if is_parser(arg_opts) then
        state.arg_index = 1
        return parser_go_impl(arg_opts, state)
    end

    -- Advance parts state.
    state.part_index = state.part_index + 1
    if state.part_index > #state.parts then
        exhausted_parts = true
    end

    -- Advance argument state.
    state.arg_index = arg_index + 1
    if arg_index > arg_count then
        exhausted_args = true
    end

    -- We've exhausted all available arguments. We either loop or we're done.
    if parser.loop_point > 0 and state.arg_index > arg_count then
        state.arg_index = parser.loop_point
        if state.arg_index > arg_count then
            state.arg_index = arg_count
        end
    end

    -- Is there some state to process?
    if not exhausted_parts and not exhausted_args then
        local exact = false
        for _, arg_opt in ipairs(arg_opts) do
            -- Is the argument a key to a sub-parser? If so then hand control
            -- off to it.
            if is_sub_parser(arg_opt) then
                if arg_opt.key == part then
                    state.arg_index = 1
                    return parser_go_impl(arg_opt.parser, state)
                end
            end

            -- Check so see if the part has an exact match in the argument. Note
            -- that only string-type options are considered.
            if type(arg_opt) == "string" then
                exact = exact or arg_opt == part
            else
                exact = true
            end
        end

        -- If the parser's required to be precise then check here.
        if parser.precise and not exact then
            exhausted_args = true
        else
            return nil
        end
    end

    -- If we've no more arguments to traverse but there's still parts remaining
    -- then we start skipping arguments but keep going so that flags still get
    -- parsed (as flags have no position).
    if exhausted_args then
        state.part_index = state.part_index - 1

        if not exhausted_parts then
            if state.depth <= 1 then
                state.skip_args = true
                return
            end

            return parser.use_file_matching
        end
    end

    -- Now we've an index into the parser's arguments that matches the line
    -- state. Flatten it.
    local func_thunk = function(func)
        return func(part)
    end

    return parser:flatten_argument(arg_index, func_thunk)
end

--------------------------------------------------------------------------------
local function parser_go_flags(parser, state)
    local part = state.parts[state.part_index]

    -- Advance parts state.
    state.part_index = state.part_index + 1
    if state.part_index > #state.parts then
        return parser:flatten_argument()
    end

    for _, arg_opt in ipairs(parser.flags) do
        if is_sub_parser(arg_opt) then
            if arg_opt.key == part then
                local arg_index_cache = state.arg_index
                local skip_args_cache = state.skip_args

                state.arg_index = 1
                state.skip_args = false
                state.depth = state.depth + 1

                local ret = parser_go_impl(arg_opt.parser, state)
                if type(ret) == "table" then
                    return ret
                end

                state.depth = state.depth - 1
                state.skip_args = skip_args_cache
                state.arg_index = arg_index_cache
            end
        end
    end
end

--------------------------------------------------------------------------------
function parser_go_impl(parser, state)
    local has_flags = #parser.flags > 0

    while state.part_index <= #state.parts do
        local part = state.parts[state.part_index]
        local dispatch_func

        if has_flags and parser:is_flag(part) then
            dispatch_func = parser_go_flags
        elseif not state.skip_args then
            dispatch_func = parser_go_args
        end

        if dispatch_func ~= nil then
            local ret = dispatch_func(parser, state)
            if ret ~= nil then
                return ret
            end
        else
            state.part_index = state.part_index + 1
        end
    end

    return parser.use_file_matching
end

--------------------------------------------------------------------------------
local function parser_go(parser, parts)
    -- Validate 'parts'.
    if type(parts) ~= "table" then
        error("'Parts' param must be a table of strings ("..type(parts)..").", 2)
    else
        if #parts == 0 then
            part = { "" }
        end

        for i, j in ipairs(parts) do
            local t = type(parts[i])
            if t ~= "string" then
                error("'Parts' table can only contain strings; "..j.."="..t, 2)
            end
        end
    end

    local state = {
        arg_index = 1,
        part_index = 1,
        parts = parts,
        skip_args = false,
        depth = 1,
    }

    return parser_go_impl(parser, state)
end

--------------------------------------------------------------------------------
local function parser_dump(parser, depth)
    if depth == nil then
        depth = 0
    end

    function prt(depth, index, text)
        local indent = string.sub("                                 ", 1, depth)
        text = tostring(text)
        print(indent..depth.."."..index.." - "..text)
    end

    -- Print arguments
    local i = 0
    for _, arg_opts in ipairs(parser.arguments) do
        for _, arg_opt in ipairs(arg_opts) do
            if is_sub_parser(arg_opt) then
                prt(depth, i, arg_opt.key)
                arg_opt.parser:dump(depth + 1)
            else
                prt(depth, i, arg_opt)
            end
        end

        i = i + 1
    end

    -- Print flags
    for _, flag in ipairs(parser.flags) do
        prt(depth, "F", flag)
    end
end

--------------------------------------------------------------------------------
function parser_be_precise(parser)
    parser.precise = true
    return parser
end

--------------------------------------------------------------------------------
function is_parser(p)
    return type(p) == "table" and getmetatable(p) == parser_meta_table
end

--------------------------------------------------------------------------------
function is_sub_parser(sp)
    return type(sp) == "table" and getmetatable(sp) == sub_parser_meta_table
end

--------------------------------------------------------------------------------
local function get_sub_parser(argument, str)
    for _, arg in ipairs(argument) do
        if is_sub_parser(arg) then
            if arg.key == str then
                return arg.parser
            end
        end
    end
end

--------------------------------------------------------------------------------
function new_sub_parser(key, parser)
    local sub_parser = {}
    sub_parser.key = key
    sub_parser.parser = parser

    setmetatable(sub_parser, sub_parser_meta_table)
    return sub_parser
end

--------------------------------------------------------------------------------
local function parser_disable_file_matching(parser)
    parser.use_file_matching = false
    return parser
end

--------------------------------------------------------------------------------
local function parser_loop(parser, loop_point)
    if loop_point == nil or type(loop_point) ~= "number" or loop_point < 1 then
        loop_point = 1
    end

    parser.loop_point = loop_point
    return parser
end

--------------------------------------------------------------------------------
local function parser_initialise(parser, ...)
    for _, word in ipairs({...}) do
        local t = type(word)
        if t == "string" then
            parser:add_flags(word)
        elseif t == "table" then
            if is_sub_parser(word) and parser_is_flag(nil, word.key) then
                parser:add_flags(word)
            else
                parser:add_arguments(word)
            end
        else
            error("Additional arguments to new_parser() must be tables or strings", 2)
        end
    end
end

--------------------------------------------------------------------------------
function clink.arg.new_parser(...)
    local parser = {}

    -- Methods
    parser.set_flags = parser_set_flags
    parser.add_flags = parser_add_flags
    parser.set_arguments = parser_set_arguments
    parser.add_arguments = parser_add_arguments
    parser.dump = parser_dump
    parser.go = parser_go
    parser.flatten_argument = parser_flatten_argument
    parser.be_precise = parser_be_precise
    parser.disable_file_matching = parser_disable_file_matching
    parser.loop = parser_loop
    parser.is_flag = parser_is_flag

    -- Members.
    parser.flags = {}
    parser.arguments = {}
    parser.precise = false
    parser.use_file_matching = true
    parser.loop_point = 0

    setmetatable(parser, parser_meta_table)

    -- If any arguments are provided treat them as parser's arguments or flags
    if ... then
        success, msg = pcall(parser_initialise, parser, ...)
        if not success then
            error(msg, 2)
        end
    end

    return parser
end

--------------------------------------------------------------------------------
function merge_parsers(lhs, rhs)
    -- Merging parsers is not a trivial matter and this implementation is far
    -- from correct. It is however sufficient for the majority of cases.

    -- Merge flags.
    for _, rflag in ipairs(rhs.flags) do
        table.insert(lhs.flags, rflag)
    end

    -- Remove (and save value of) the first argument in RHS.
    local rhs_arg_1 = table.remove(rhs.arguments, 1)
    if rhs_arg_1 == nil then
        return
    end

    -- Get reference to the LHS's first argument table (creating it if needed).
    local lhs_arg_1 = lhs.arguments[1]
    if lhs_arg_1 == nil then
        lhs_arg_1 = {}
        table.insert(lhs.arguments, lhs_arg_1)
    end

    -- Link RHS to LHS through sub-parsers.
    for _, rarg in ipairs(rhs_arg_1) do
        local child

        -- Split sub parser
        if is_sub_parser(rarg) then
            child = rarg.parser     
            rarg = rarg.key
        else
            child = rhs
        end

        -- If LHS's first argument has rarg in it which links to a sub-parser
        -- then we need to recursively merge them.
        local lhs_sub_parser = get_sub_parser(lhs_arg_1, rarg)
        if lhs_sub_parser then
            merge_parsers(lhs_sub_parser, child)
        else
            local to_add = rarg
            if type(rarg) ~= "function" then
                to_add = rarg .. child
            end

            table.insert(lhs_arg_1, to_add)
        end
    end
end

--------------------------------------------------------------------------------
function clink.arg.register_parser(cmd, parser)
    if not is_parser(parser) then
        local p = clink.arg.new_parser()
        p:set_arguments({ parser })
        parser = p
    end

    cmd = cmd:lower()
    local prev = parsers[cmd]
    if prev ~= nil then
        merge_parsers(prev, parser)
    else
        parsers[cmd] = parser
    end
end

--------------------------------------------------------------------------------
local function argument_match_generator(text, first, last)
    local leading = rl_state.line_buffer:sub(1, first - 1):lower()

    -- Extract the command.
    local cmd_l, cmd_r
    if leading:find("^%s*\"") then
        -- Command appears to be surround by quotes.
        cmd_l, cmd_r = leading:find("%b\"\"")
        if cmd_l and cmd_r then
            cmd_l = cmd_l + 1
            cmd_r = cmd_r - 1
        end
    else
        -- No quotes so the first, longest, non-whitespace word is extracted.
        cmd_l, cmd_r = leading:find("[^%s]+")
    end

    if not cmd_l or not cmd_r then
        return false
    end

    local regex = "[\\/:]*([^\\/:.]+)(%.*[%l]*)%s*$"
    local _, _, cmd, ext = leading:sub(cmd_l, cmd_r):lower():find(regex)

    -- Check to make sure the extension extracted is in pathext.
    if ext and ext ~= "" then
        if not clink.get_env("pathext"):lower():match(ext.."[;$]", 1, true) then
            return false
        end
    end
    
    -- Find a registered parser.
    local parser = parsers[cmd]
    if parser == nil then
        return false
    end

    -- Split the command line into parts.
    local str = rl_state.line_buffer:sub(cmd_r + 2, last)
    local parts = {}
    for _, sub_str in ipairs(clink.quote_split(str, "\"")) do
        -- Quoted strings still have their quotes. Look for those type of
        -- strings, strip the quotes and add it completely.
        if sub_str:sub(1, 1) == "\"" then
            local l, r = sub_str:find("\"[^\"]+")
            if l then
                local part = sub_str:sub(l + 1, r)
                table.insert(parts, part)
            end
        else
            -- Extract non-whitespace parts.
            for _, r, part in function () return sub_str:find("^%s*([^%s]+)") end do
                table.insert(parts, part)
                sub_str = sub_str:sub(r + 1)
            end
        end
    end

    -- If 'text' is empty then add it as a part as it would have been skipped
    -- by the split loop above.
    if text == "" then
        table.insert(parts, text)
    end

    -- Extend rl_state with match generation state; text, first, and last.
    rl_state.text = text
    rl_state.first = first
    rl_state.last = last

    -- Call the parser.
    local needle = parts[#parts]
    local ret = parser:go(parts)
    if type(ret) ~= "table" then
        return not ret
    end

    -- Iterate through the matches the parser returned and collect matches.
    for _, match in ipairs(ret) do
        if clink.is_match(needle, match) then
            clink.add_match(match)
        end
    end

    return true
end

--------------------------------------------------------------------------------
clink.register_match_generator(argument_match_generator, 25)

-- vim: expandtab

--------------------------------------------------------------------------------
-- dir.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
function dir_match_generator_impl(text)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    local include_dots = text:find("%.+$") ~= nil

    local matches = {}
    local mask = text.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_dirs(mask, true)) do
        local file = prefix..dir

        if include_dots or (dir ~= "." and dir ~= "..") then
            if clink.is_match(text, file) then
                table.insert(matches, prefix..dir)
            end
        end
    end

    return matches
end

--------------------------------------------------------------------------------
local function dir_match_generator(word)
    local matches = dir_match_generator_impl(word)

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end

--------------------------------------------------------------------------------
clink.arg.register_parser("cd", dir_match_generator)
clink.arg.register_parser("chdir", dir_match_generator)
clink.arg.register_parser("pushd", dir_match_generator)
clink.arg.register_parser("rd", dir_match_generator)
clink.arg.register_parser("rmdir", dir_match_generator)
clink.arg.register_parser("md", dir_match_generator)
clink.arg.register_parser("mkdir", dir_match_generator)

-- vim: expandtab

--------------------------------------------------------------------------------
-- env.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local special_env_vars = {
    "cd", "date", "time", "random", "errorlevel",
    "cmdextversion", "cmdcmdline", "highestnumanodenumber"
}

--------------------------------------------------------------------------------
local function env_vars_display_filter(matches)
    local to_display = {}
    for _, m in ipairs(matches) do
        local _, _, out = m:find("(%%[^%%]+%%)$")
        table.insert(to_display, out)
    end

    return to_display
end

--------------------------------------------------------------------------------
local function env_vars_find_matches(candidates, prefix, part)
    local part_len = #part
    for _, name in ipairs(candidates) do
        if clink.lower(name:sub(1, part_len)) == part then
            clink.add_match(prefix..'%'..name:lower()..'%')
        end
    end
end

--------------------------------------------------------------------------------
local function env_vars_match_generator(text, first, last)
    local all = rl_state.line_buffer:sub(1, last)

    -- Skip pairs of %s
    local i = 1
    for _, r in function () return all:find("%b%%", i) end do
        i = r + 2
    end

    -- Find a solitary %
    local i = all:find("%%", i)
    if not i then
        return false
    end

    if i < first then
        return false
    end

    local part = clink.lower(all:sub(i + 1))
    local part_len = #part

    i = i - first
    local prefix = text:sub(1, i)

    env_vars_find_matches(clink.get_env_var_names(), prefix, part)
    env_vars_find_matches(special_env_vars, prefix, part)

    if clink.match_count() >= 1 then
        clink.match_display_filter = env_vars_display_filter

        clink.suppress_char_append()
        clink.suppress_quoting()

        return true
    end

    return false
end

--------------------------------------------------------------------------------
if clink.get_host_process() == "cmd.exe" then
    clink.register_match_generator(env_vars_match_generator, 10)
end

-- vim: expandtab

--------------------------------------------------------------------------------
-- exec.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local dos_commands = {
    "assoc", "break", "call", "cd", "chcp", "chdir", "cls", "color", "copy",
    "date", "del", "dir", "diskcomp", "diskcopy", "echo", "endlocal", "erase",
    "exit", "for", "format", "ftype", "goto", "graftabl", "if", "md", "mkdir",
    "mklink", "more", "move", "path", "pause", "popd", "prompt", "pushd", "rd",
    "rem", "ren", "rename", "rmdir", "set", "setlocal", "shift", "start",
    "time", "title", "tree", "type", "ver", "verify", "vol"
}

--------------------------------------------------------------------------------
local function get_environment_paths()
    local paths = clink.split(clink.get_env("PATH"), ";")

    -- We're expecting absolute paths and as ';' is a valid path character
    -- there maybe unneccessary splits. Here we resolve them.
    local paths_merged = { paths[1] }
    for i = 2, #paths, 1 do
        if not paths[i]:find("^[a-zA-Z]:") then
            local t = paths_merged[#paths_merged];
            paths_merged[#paths_merged] = t..paths[i]
        else
            table.insert(paths_merged, paths[i])
        end
    end

    -- Append slashes.
    for i = 1, #paths_merged, 1 do
        table.insert(paths, paths_merged[i].."\\")
    end

    return paths
end

--------------------------------------------------------------------------------
local function exec_match_generator(text, first, last)
    -- If match style setting is < 0 then consider executable matching disabled.
    local match_style = clink.get_setting_int("exec_match_style")
    if match_style < 0 then
        return false
    end

    -- We're only interested in exec completion if this is the first word of the
    -- line, or the first word after a command separator.
    if clink.get_setting_int("space_prefix_match_files") > 0 then
        if first > 1 then
            return false
        end
    else
        local leading = rl_state.line_buffer:sub(1, first - 1)
        local is_first = leading:find("^%s*\"*$")
        if not is_first then
            return false
        end
    end

    -- Strip off any path components that may be on text
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    -- Extract any possible extension that maybe on the text being completed.
    local ext = nil
    local dot = text:find("%.[^.]*")
    if dot then
        ext = text:sub(dot):lower()
    end

    local suffices = clink.split(clink.get_env("pathext"), ";")
    for i = 1, #suffices, 1 do
        local suffix = suffices[i]

        -- Does 'text' contain some of the suffix (i.e. "cmd.e")? If it does
        -- then merge them so we get "cmd.exe" rather than "cmd.*.exe".
        if ext and suffix:sub(1, #ext):lower() == ext then
            suffix = ""
        end

        suffices[i] = text.."*"..suffix
    end

    -- First step is to match executables in the environment's path.
    if not text:find("[\\/:]") then
        local paths = get_environment_paths()
        for _, suffix in ipairs(suffices) do
            for _, path in ipairs(paths) do
                clink.match_files(path..suffix, false)
            end
        end

        -- If the terminal is cmd.exe check it's commands for matches.
        if clink.get_host_process() == "cmd.exe" then
            clink.match_words(text, dos_commands)
        end

        -- Lastly add console aliases as matches.
        local aliases = clink.get_console_aliases()
        clink.match_words(text, aliases)
    elseif match_style < 1 then
        -- 'text' is an absolute or relative path. If we're doing Bash-style
        -- matching should now consider directories.
        match_style = 2
    end

    -- Optionally include executables in the cwd (or absolute/relative path).
    if clink.match_count() == 0 or match_style >= 1 then
        for _, suffix in ipairs(suffices) do
            clink.match_files(suffix)
        end
    end

    -- Lastly we may wish to consider directories too.
    if clink.match_count() == 0 or match_style >= 2 then
        clink.match_files(text.."*", true, clink.find_dirs)
    end

    clink.matches_are_files()
    return true
end

--------------------------------------------------------------------------------
clink.register_match_generator(exec_match_generator, 50)

-- vim: expandtab

--------------------------------------------------------------------------------
-- git.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local git_argument_tree = {
    -- Porcelain and ancillary commands from git's man page.
    "add", "am", "archive", "bisect", "branch", "bundle", "checkout",
    "cherry-pick", "citool", "clean", "clone", "commit", "describe", "diff",
    "fetch", "format-patch", "gc", "grep", "gui", "init", "log", "merge", "mv",
    "notes", "pull", "push", "rebase", "reset", "revert", "rm", "shortlog",
    "show", "stash", "status", "submodule", "tag", "config", "fast-export",
    "fast-import", "filter-branch", "lost-found", "mergetool", "pack-refs",
    "prune", "reflog", "relink", "remote", "repack", "replace", "repo-config",
    "annotate", "blame", "cherry", "count-objects", "difftool", "fsck",
    "get-tar-commit-id", "help", "instaweb", "merge-tree", "rerere",
    "rev-parse", "show-branch", "verify-tag", "whatchanged"
}

clink.arg.register_parser("git", git_argument_tree)

-- vim: expandtab

--------------------------------------------------------------------------------
-- go.lua
--

--
-- Copyright (c) 2013 Dobroslaw Zybort
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

--------------------------------------------------------------------------------
local go_tool_parser = clink.arg.new_parser()
go_tool_parser:set_flags("-n")
go_tool_parser:set_arguments({
    "8a", "8c", "8g", "8l", "addr2line", "cgo", "dist", "nm", "objdump",
    "pack",
    "cover" .. flags("-func", "-html", "-mode", "-o", "-var"),
    "fix"   .. flags("-diff", "-force", "-r"),
    "prof"  .. flags("-p", "-t", "-d", "-P", "-h", "-f", "-l", "-r", "-s",
                     "-hs"),
    "pprof" .. flags(-- Options:
                     "--cum", "--base", "--interactive", "--seconds",
                     "--add_lib", "--lib_prefix",
                     -- Reporting Granularity:
                     "--addresses", "--lines", "--functions", "--files",
                     -- Output type:
                     "--text", "--callgrind", "--gv", "--web", "--list",
                     "--disasm", "--symbols", "--dot", "--ps", "--pdf",
                     "--svg", "--gif", "--raw",
                     -- Heap-Profile Options:
                     "--inuse_space", "--inuse_objects", "--alloc_space",
                     "--alloc_objects", "--show_bytes", "--drop_negative",
                     -- Contention-profile options:
                     "--total_delay", "--contentions", "--mean_delay",
                     -- Call-graph Options:
                     "--nodecount", "--nodefraction", "--edgefraction",
                     "--focus", "--ignore", "--scale", "--heapcheck",
                     -- Miscellaneous:
                     "--tools", "--test", "--help", "--version"),
    "vet"   .. flags("-all", "-asmdecl", "-assign", "-atomic", "-buildtags",
                     "-composites", "-compositewhitelist", "-copylocks",
                     "-methods", "-nilfunc", "-printf", "-printfuncs",
                     "-rangeloops", "-shadow", "-shadowstrict", "-structtags",
                     "-test", "-unreachable", "-v"),
    "yacc"  .. flags("-l", "-o", "-p", "-v"),
})

--------------------------------------------------------------------------------
local go_parser = clink.arg.new_parser()
go_parser:set_arguments({
    "env",
    "fix",
    "version",
    "build"    .. flags("-o", "-a", "-n", "-p", "-installsuffix", "-v", "-x",
                        "-work", "-gcflags", "-ccflags", "-ldflags",
                        "-gccgoflags", "-tags", "-compiler", "-race"),
    "clean"    .. flags("-i", "-n", "-r", "-x"),
    "fmt"      .. flags("-n", "-x"),
    "get"      .. flags("-d", "-fix", "-t", "-u",
                        -- Build flags
                        "-a", "-n", "-p", "-installsuffix", "-v", "-x",
                        "-work", "-gcflags", "-ccflags", "-ldflags",
                        "-gccgoflags", "-tags", "-compiler", "-race"),
    "install"  .. flags(-- All `go build` flags
                        "-o", "-a", "-n", "-p", "-installsuffix", "-v", "-x",
                        "-work", "-gcflags", "-ccflags", "-ldflags",
                        "-gccgoflags", "-tags", "-compiler", "-race"),
    "list"     .. flags("-e", "-race", "-f", "-json", "-tags"),
    "run"      .. flags("-exec",
                        -- Build flags
                        "-a", "-n", "-p", "-installsuffix", "-v", "-x",
                        "-work", "-gcflags", "-ccflags", "-ldflags",
                        "-gccgoflags", "-tags", "-compiler", "-race"),
    "test"     .. flags(-- Local.
                        "-c", "-file", "-i", "-cover", "-coverpkg",
                        -- Build flags
                        "-a", "-n", "-p", "-x", "-work", "-ccflags",
                        "-gcflags", "-exec", "-ldflags", "-gccgoflags",
                        "-tags", "-compiler", "-race", "-installsuffix", 
                        -- Passed to 6.out
                        "-bench", "-benchmem", "-benchtime", "-covermode",
                        "-coverprofile", "-cpu", "-cpuprofile", "-memprofile",
                        "-memprofilerate", "-blockprofile",
                        "-blockprofilerate", "-outputdir", "-parallel", "-run",
                        "-short", "-timeout", "-v"),
    "tool"     .. go_tool_parser,
    "vet"      .. flags("-n", "-x"),
})

--------------------------------------------------------------------------------
local go_help_parser = clink.arg.new_parser()
go_help_parser:set_arguments({
    "help" .. clink.arg.new_parser():set_arguments({
        go_parser:flatten_argument(1)
    })
})

--------------------------------------------------------------------------------
local godoc_parser = clink.arg.new_parser()
godoc_parser:set_flags(
    "-zip", "-write_index", "-analysis", "-http", "-server", "-html","-src",
    "-url", "-q", "-v", "-goroot", "-tabwidth", "-timestamps", "-templates",
    "-play", "-ex", "-links", "-index", "-index_files", "-maxresults",
    "-index_throttle", "-notes", "-httptest.serve"
)

--------------------------------------------------------------------------------
local gofmt_parser = clink.arg.new_parser()
gofmt_parser:set_flags(
    "-cpuprofile", "-d", "-e", "-l", "-r", "-s", "-w"
)

--------------------------------------------------------------------------------
clink.arg.register_parser("go", go_parser)
clink.arg.register_parser("go", go_help_parser)
clink.arg.register_parser("godoc", godoc_parser)
clink.arg.register_parser("gofmt", gofmt_parser)

--------------------------------------------------------------------------------
-- hg.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local hg_tree = {
    "add", "addremove", "annotate", "archive", "backout", "bisect", "bookmarks",
    "branch", "branches", "bundle", "cat", "clone", "commit", "copy", "diff",
    "export", "forget", "grep", "heads", "help", "identify", "import",
    "incoming", "init", "locate", "log", "manifest", "merge", "outgoing",
    "parents", "paths", "pull", "push", "recover", "remove", "rename", "resolve",
    "revert", "rollback", "root", "serve", "showconfig", "status", "summary",
    "tag", "tags", "tip", "unbundle", "update", "verify", "version", "graft",
    "phases"
}

clink.arg.register_parser("hg", hg_tree)

-- vim: expandtab

--------------------------------------------------------------------------------
-- p4.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local p4_tree = {
    "add", "annotate", "attribute", "branch", "branches", "browse", "change",
    "changes", "changelist", "changelists", "client", "clients", "copy",
    "counter", "counters", "cstat", "delete", "depot", "depots", "describe",
    "diff", "diff2", "dirs", "edit", "filelog", "files", "fix", "fixes",
    "flush", "fstat", "grep", "group", "groups", "have", "help", "info",
    "integrate", "integrated", "interchanges", "istat", "job", "jobs", "label",
    "labels", "labelsync", "legal", "list", "lock", "logger", "login",
    "logout", "merge", "move", "opened", "passwd", "populate", "print",
    "protect", "protects", "reconcile", "rename", "reopen", "resolve",
    "resolved", "revert", "review", "reviews", "set", "shelve", "status",
    "sizes", "stream", "streams", "submit", "sync", "tag", "tickets", "unlock",
    "unshelve", "update", "user", "users", "where", "workspace", "workspaces"
}

clink.arg.register_parser("p4", p4_tree)

-- vim: expandtab

--------------------------------------------------------------------------------
-- powershell.lua
--

--
-- Copyright (c) 2013 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local function powershell_prompt_filter()
    local l, r, path = clink.prompt.value:find("([a-zA-Z]:\\.*)> $")
    if path ~= nil then
        clink.chdir(path)
    end
end

--------------------------------------------------------------------------------
if clink.get_host_process() == "powershell.exe" then
    clink.prompt.register_filter(powershell_prompt_filter, -493)
end

--------------------------------------------------------------------------------
-- self.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local inject_parser
local autorun_parser
local set_parser
local self_parser

inject_parser = clink.arg.new_parser()
inject_parser:set_flags(
    "--help",
    "--nohostcheck",
    "--pid",
    "--profile",
    "--quiet",
    "--scripts"
)

autorun_parser = clink.arg.new_parser()
autorun_parser:set_flags(
    "--help",
    "--install",
    "--uninstall",
    "--show",
    "--value"
)

set_parser = clink.arg.new_parser()
set_parser:disable_file_matching()
set_parser:set_flags("--help")
set_parser:set_arguments(
    {
        "ansi_code_support",
        "ctrld_exits",
        "esc_clears_line",
        "exec_match_style",
        "history_dupe_mode",
        "history_file_lines",
        "history_ignore_space",
        "history_io",
        "match_colour",
        "prompt_colour",
        "space_prefix_match_files",
        "strip_crlf_on_paste",
        "terminate_autoanswer",
        "use_altgr_substitute",
    }
)

self_parser = clink.arg.new_parser()
self_parser:set_arguments(
    {
        "inject" .. inject_parser,
        "autorun" .. autorun_parser,
        "set" .. set_parser,
    }
)

clink.arg.register_parser("clink", self_parser)

-- vim: expandtab

--------------------------------------------------------------------------------
-- set.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local function set_match_generator(word)
    -- Skip this generator if first is in the rvalue.
    local leading = rl_state.line_buffer:sub(1, rl_state.first - 1)
    if leading:find("=") then
        return false
    end

    -- Enumerate environment variables and check for potential matches.
    local matches = {}
    for _, name in ipairs(clink.get_env_var_names()) do
        if clink.is_match(word, name) then
            table.insert(matches, name:lower())
        end
    end

    clink.suppress_char_append()
    return matches
end

--------------------------------------------------------------------------------
clink.arg.register_parser("set", set_match_generator)

-- vim: expandtab

--------------------------------------------------------------------------------
-- svn.lua
--

--
-- Copyright (c) 2012 Martin Ridgers
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--------------------------------------------------------------------------------
local svn_tree = {
    "add", "blame", "praise", "annotate", "ann", "cat", "changelist", "cl",
    "checkout", "co", "cleanup", "commit", "ci", "copy", "cp", "delete", "del",
    "remove", "rm", "diff", "di", "export", "help", "h", "import", "info",
    "list", "ls", "lock", "log", "merge", "mergeinfo", "mkdir", "move", "mv",
    "rename", "ren", "propdel", "pdel", "pd", "propedit", "pedit", "pe",
    "propget", "pget", "pg", "proplist", "plist", "pl", "propset", "pset", "ps",
    "resolve", "resolved", "revert", "status", "stat", "st", "switch", "sw",
    "unlock", "update", "up"
}

clink.arg.register_parser("svn", svn_tree)

-- vim: expandtab
