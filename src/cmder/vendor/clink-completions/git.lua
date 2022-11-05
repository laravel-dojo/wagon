-- preamble: common routines

local path_module = require('path')
local git = require('gitutil')
local matchers = require('matchers')
local w = require('tables').wrap
local clink_version = require('clink_version')
local color = require('color')
require('arghelper')
local parser = function (...)
    local p = clink.arg.new_parser(...):setendofflags()
    p._deprecated = nil
    return p
end

if clink_version.supports_color_settings then
    settings.add('color.git.star', 'bright green', 'Color for preferred branch completions')
end

local file_matches = clink.filematches or matchers.files
local dir_matches = clink.dirmatches or matchers.dirs
local files_parser = parser({file_matches})
local dirs_parser = parser({dir_matches})

local looping_files_parser = clink.argmatcher and clink.argmatcher():addarg(clink.filematches):loop()

local map_file
if rl.getmatchcolor then
    map_file = function (file)
        return { match=file, display='\x1b[m'..rl.getmatchcolor(file, 'file')..file, type='arg' }
    end
else
    map_file = function (file)
        return { match=file, display='\x1b[m'..file, type='arg' }
    end
end

---
 -- Lists remote branches based on packed-refs file from git directory
 -- @param string [dir]  Directory where to search file for
 -- @return table  List of remote branches
local function list_packed_refs(dir, kind)
    local result = w()
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return result end

    kind = kind or "remotes"

    local packed_refs_file = io.open(git_dir..'/packed-refs')
    if packed_refs_file == nil then return {} end

    for line in packed_refs_file:lines() do
        -- SHA is 40 char length + 1 char for space
        if #line > 41 then
            local match = line:sub(41):match('refs/'..kind..'/(.*)')
            if match then table.insert(result, match) end
        end
    end

    packed_refs_file:close()
    return result
end

local function list_remote_branches(dir)
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return w() end

    return w(path_module.list_files(git_dir..'/refs/remotes', '/*',
        --[[recursive=]]true, --[[reverse_separator=]]true))
    :concat(list_packed_refs(git_dir))
    :sort():dedupe()
end

local function list_tags(dir)
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return w() end

    local result = w(path_module.list_files(git_dir..'/refs/tags', '/*',
        --[[recursive=]]true, --[[reverse_separator=]]true))
    :concat(list_packed_refs(git_dir, 'tags'))

    if string.comparematches then -- luacheck: no global
        table.sort(result, string.comparematches) -- luacheck: no global
    else
        result = result:sort()
    end
    return result
end

local function list_git_status_files(token, flags) -- luacheck: no unused args
    local result = w()
    local git_dir = git.get_git_common_dir()
    if git_dir then
        local f = io.popen("git status --porcelain "..(flags or "").." ** 2>nul")
        if f then
            if string.matchlen then -- luacheck: no global
                --[[
                token = path.normalise(token)
                --]]
                for line in f:lines() do
                    line = line:match("^.. (.+)$")
                    if line then
                        line = path.normalise(line)
                        --[[
                        -- TODO: Maybe use match display filtering to show the number of files in each dir?
                        local mlen = string.matchlen(line, token) -- luacheck: no global
                        if mlen < 0 then
                            table.insert(result, { match = line, type = "file" })
                        else
                            local dir = path.getdirectory(line:sub(1, mlen))
                            local child = line:sub(mlen + 1):match("^([^/\\]*[/\\]?)")
                            local m = dir and path.join(dir, child) or child
                            local isdir = m:sub(-1):find("[/\\]")
                            table.insert(result, { match = m, type = (isdir and "dir" or "file") })
                        end
                        --]]
                        table.insert(result, line)
                    end
                end
            else
                for line in f:lines() do
                    table.insert(result, line:sub(4))
                end
            end
            f:close()
        end
    end
    return result
end

---
 -- Lists local branches for git repo in git_dir directory.
 --
 -- @param string [dir]  Git directory, where to search for remote branches
 -- @return table  List of branches.
local function list_local_branches(dir)
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return w() end

    local result = w(path_module.list_files(git_dir..'/refs/heads', '/*',
        --[[recursive=]]true, --[[reverse_separator=]]true))

    return result
end

local function branches()
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    return list_local_branches(git_dir)
end

-- Function to get the list of git aliases.
local function get_git_aliases()
    local res = w()

    local git_dir = git.get_git_dir()
    if git_dir == nil then return res end

    local f = io.popen("git config --get-regexp alias 2>nul")
    if f == nil then return res end

    for line in f:lines() do
        local name, command = line:match("^alias.([^ ]+) +(.+)$")
        if name then
            table.insert(res, { name=name, command=command })
        end
    end

    f:close()

    return res
end

-- Function to generate completions for alias
local function alias(token) -- luacheck: no unused args
    local res = w()

    local aliases = get_git_aliases()
    if clink_version.supports_display_filter_description then
        for _, a in ipairs(aliases) do
            table.insert(res, { match=a.name, description="Alias: "..a.command })
        end
    else
        for _, a in ipairs(aliases) do
            table.insert(res, a.name)
        end
    end

    return res
end

local function remotes(token)  -- luacheck: no unused args
    local result = w()
    local git_dir = git.get_git_common_dir()
    if not git_dir then return result end

    local git_config = io.open(git_dir..'/config')
    -- if there is no gitconfig file (WAT?!), return empty list
    if git_config == nil then return result end

    for line in git_config:lines() do
        local remote = line:match('%[remote "(.*)"%]')
        if (remote) then
            table.insert(result, remote)
        end
    end

    git_config:close()
    return result
end

local function local_or_remote_branches(token)
    -- Try to resolve .git directory location
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    return list_local_branches(git_dir)
    :concat(list_remote_branches(git_dir))
    :filter(function(branch)
        return clink.is_match(token, branch)
    end)
end

local function add_spec_generator(token)
    return list_git_status_files(token, "-uall"):map(map_file)
end

local function checkout_spec_generator_049(token)
    local function is_token_match(value)
        return clink.is_match(token, value)
    end

    local git_dir = git.get_git_common_dir()

    local files = list_git_status_files(token, "-uno"):filter(is_token_match)
    local local_branches = branches():filter(is_token_match)
    local remote_branches = list_remote_branches(git_dir):filter(is_token_match)

    local predicted_branches = list_remote_branches(git_dir)
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(branch)
            return branch
                and clink.is_match(token, branch)
                -- Filter out those predictions which are already exists as local branches
                and not local_branches:contains(branch)
        end)

    if (#local_branches + #remote_branches + #predicted_branches) == 0 then return files end

    -- if there is any refspec that matches token then:
    --   * disable readline's filename completion, otherwise we'll get a list of these specs
    --     treated as list of files (without 'path' part), ie. 'some_branch' instead of 'my_remote/some_branch'
    --   * create display filter for completion table to append path separator to each directory entry
    --     since it is not added automatically by readline (see previous point)
    clink.matches_are_files(0)
    clink.match_display_filter = function ()
        local star = '*'
        if clink_version.supports_query_rl_var and rl.isvariabletrue('colored-stats') then
            star = color.get_clink_color('color.git.star')..star..color.get_clink_color('color.filtered')
        end
        return files:map(function(file)
            return clink.is_dir(file) and file..'\\' or file
        end)
        :concat(local_branches)
        :concat(predicted_branches:map(function(branch) return star..branch end))
        :concat(remote_branches)
    end

    return files
        :concat(local_branches)
        :concat(predicted_branches)
        :concat(remote_branches)
end

local function checkout_spec_generator_usedisplay(token)
    -- NOTE:  The only reason this needs to use clink.is_match() is because the
    -- match_display_filter function defined here ignores the list of matches it
    -- receives, which is already filtered correctly and has had duplicates
    -- removed.
    local function is_token_match(value)
        return clink.is_match(token, value)
    end

    local git_dir = git.get_git_common_dir()

    local files = list_git_status_files(token, "-uno"):filter(is_token_match)
    local local_branches = branches(token):filter(is_token_match)
    local remote_branches = list_remote_branches(git_dir):filter(is_token_match)

    local predicted_branches = list_remote_branches(git_dir)
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(branch)
            return branch
                and clink.is_match(token, branch)
                -- Filter out those predictions which are already exists as local branches
                and not local_branches:contains(branch)
        end)

    -- if there is any refspec that matches token then:
    --   * disable readline's filename completion, otherwise we'll get a list of these specs
    --     treated as list of files (without 'path' part), ie. 'some_branch' instead of 'my_remote/some_branch'
    --   * create display filter for completion table to append path separator to each directory entry
    --     since it is not added automatically by readline (see previous point)
    clink.match_display_filter = function ()
        local star = '*'
        if clink_version.supports_query_rl_var and rl.isvariabletrue('colored-stats') then
            star = color.get_clink_color('color.git.star')..star..color.get_clink_color('color.filtered')
        end
        return files:map(function(file) return '\x1b[m'..file end)
            :concat(local_branches:map(function(branch) return { match=branch } end))
            :concat(predicted_branches:map(function(branch) return { match=branch, display=star..branch } end))
            :concat(remote_branches:map(function(branch) return { match=branch } end))
    end

    return files
        :concat(local_branches)
        :concat(predicted_branches)
        :concat(remote_branches)
end

local function make_indexed_table(input)
    local output = {}
    for _, value in ipairs(input) do
        output[value] = true
    end
    return output
end

local function checkout_spec_generator_nosort(token)
    local git_dir = git.get_git_common_dir()

    local local_branches = branches(token)
    local local_branches_idx = make_indexed_table(local_branches)

    local remote_branches = list_remote_branches(git_dir)
    local remote_branches_idx = make_indexed_table(remote_branches)

    local predicted_branches = list_remote_branches(git_dir)
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(name)
            -- Filter out predictions that already exist as local branches.
            return not local_branches_idx[name]
        end)
    local predicted_branches_idx = make_indexed_table(predicted_branches)

    local tag_names = list_tags(git_dir)

    local files = list_git_status_files(token, "-uno")
        :filter(function(name)
            name = path.normalise(name, '/')
            return not predicted_branches_idx[name] and not remote_branches_idx[name] and not local_branches_idx[name]
        end)

    local filtered_color = color.get_clink_color('color.filtered')
    local local_pre = filtered_color
    local predicted_pre = '*'
    local remote_pre = filtered_color
    local tag_pre = color.get_clink_color('color.doskey')
    if clink_version.supports_query_rl_var and rl.isvariabletrue('colored-stats') then
        predicted_pre = color.get_clink_color('color.git.star')..predicted_pre..filtered_color
    end

    local mapped = {
        files:map(map_file),
        local_branches:map(function(branch) return { match=branch, display=local_pre..branch, type='arg' } end),
        predicted_branches:map(function(branch) return { match=branch, display=predicted_pre..branch, type='arg' } end),
        remote_branches:map(function(branch) return { match=branch, display=remote_pre..branch, type='arg' } end),
        tag_names:map(function(tag) return { match=tag, display=tag_pre..tag, type='arg' } end),
    }

    local result = {}
    for _, t in ipairs(mapped) do
        for _, m in ipairs(t) do
            table.insert(result, m)
        end
    end
    result.nosort = true
    return result
end

local function checkout_spec_generator(token)
    if clink_version.supports_argmatcher_nosort then
        return checkout_spec_generator_nosort(token)
    elseif clink_version.supports_display_filter_description then
        return checkout_spec_generator_usedisplay(token)
    else
        return checkout_spec_generator_049(token)
    end
end

local function checkout_dashdash(token)
    local status_files = list_git_status_files(token, "-uno")
    if clink_version.supports_display_filter_description then
        return status_files:map(function(file) return { match=file, display='\x1b[m'..file, type='arg' } end)
    else
        clink.matches_are_files(false)
        return status_files
    end
end

local function push_branch_spec(token)
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    local plus_prefix = token:sub(0, 1) == '+'
    -- cut out leading '+' symbol as it is a part of branch spec
    local branch_spec = plus_prefix and token:sub(2) or token
    -- check if there a local/remote branch separator
    local s, e = branch_spec:find(':')

    -- starting from here we have 2 options:
    -- * if there is no branch separator complete word with local branches
    if not s then
        -- setup display filter to prevent display '+' symbol in completion list
        if clink_version.supports_display_filter_description then
            local b = branches(branch_spec):map(function(branch)
                -- append '+' to results if it was specified
                return { match=plus_prefix and '+'..branch or branch, display=branch }
            end)
            clink.ondisplaymatches(function ()
                return b
            end)
            return b
        else
            local b = branches(branch_spec)
            clink.match_display_filter = function ()
                return b
            end
            return b:map(function(branch)
                -- append '+' to results if it was specified
                return plus_prefix and '+'..branch or branch
            end)
        end
    else
    -- * if there is ':' separator then we need to complete remote branch
        local local_branch_spec = branch_spec:sub(1, s - 1)
        local remote_branch_spec = branch_spec:sub(e + 1)

        -- TODO: show remote branches only for remote that has been specified as previous argument
        local b = w(clink.find_dirs(git_dir..'/refs/remotes/*'))
        :filter(function(remote) return path_module.is_real_dir(remote) end)
        :reduce({}, function(result, remote)
            return w(path_module.list_files(git_dir..'/refs/remotes/'..remote, '/*',
                --[[recursive=]]true, --[[reverse_separator=]]true))
            :filter(function(remote_branch)
                return clink.is_match(remote_branch_spec, remote_branch)
            end)
            :concat(result)
        end)

        -- setup display filter to prevent display '+' symbol in completion list
        if clink_version.supports_display_filter_description then
            b = b:map(function(branch)
                return {
                    match=(plus_prefix and '+'..local_branch_spec or local_branch_spec)..':'..branch,
                    display=branch
                }
            end)
            clink.ondisplaymatches(function ()
                return b
            end)
            return b
        else
            clink.match_display_filter = function ()
                return b
            end
            return b:map(function(branch)
                return (plus_prefix and '+'..local_branch_spec or local_branch_spec)..':'..branch
            end)
        end
    end
end

local stashes = function(token)  -- luacheck: no unused args

    local git_dir = git.get_git_dir()
    if not git_dir then return w() end

    local stash_file = io.open(git_dir..'/logs/refs/stash')
    -- if there is no stash file, return empty list
    if stash_file == nil then return w() end

    local stashes = {}
    -- make a dictionary of stash time and stash comment to
    -- be able to sort stashes by date/time created
    for stash in stash_file:lines() do
        local stash_time, stash_name = stash:match('(%d%d%d%d%d%d%d%d%d%d) [+-]%d%d%d%d%s+(.*)')
        if (stash_name and stash_name) then
            stashes[stash_time] = stash_name
        end
    end

    stash_file:close()

    -- get times for available stashes into separate table and sort it
    -- from newest to oldest. This is required because of stash@{0}
    -- represents _latest_ stash, not the last one in file
    local stash_times = {}
    for k in pairs(stashes) do
        table.insert(stash_times, k)
    end

    table.sort(stash_times, function (a, b)
        return a > b
    end)

    -- generate matches and match filter table
    local ret = {}
    local ret_filter = {}
    for i,v in ipairs(stash_times) do
        local match = "stash@{"..(i-1).."}"
        table.insert(ret, match)
        if clink_version.supports_display_filter_description then
            -- Clink now has a richer match interface.  By returning a table,
            -- the script is able to provide the stash name separately from the
            -- description.  If the script does so, then the popup completion
            -- window is able to show the stash name plus a dimmed description,
            -- but only insert the stash name.
            table.insert(ret_filter, { match=match, type="none", description=stashes[v] })
        else
            table.insert(ret_filter, match.."    "..stashes[v])
        end
    end

    local function filter()
        return ret_filter
    end

    if clink_version.supports_display_filter_description then
        clink.ondisplaymatches(filter)
    else
        clink.match_display_filter = filter
    end

    return ret
end

local function concept_guides()
    if clink_version.supports_display_filter_description then
        local r = io.popen("git help -g 2>nul")
        if r then
            local matches = {}
            local sgr = "\x1b[1m"
            local mark = " \x1b[22;32m*"
            for line in r:lines() do
                local guide, desc = line:match("^   ([^ ]+) +(.+)$")
                if guide then
                    table.insert(matches, { match=guide, display=sgr..guide..mark, description="Guide: "..desc } )
                end
            end
            r:close()
            return matches
        end
    end
    return {}
end

local function all_commands()
    if clink_version.supports_display_filter_description then
        local r = io.popen("git help -a 2>nul")
        if r then
            local matches = {}
            local prefix = "Command: "
            local sgr = ""
            for line in r:lines() do
                local command, desc = line:match("^   ([^ ]+) +(.+)$")
                if command then
                    table.insert(matches, { match=command, display=sgr..command, description=prefix..desc } )
                elseif line == "Command aliases" then
                    prefix = "Alias: "
                    sgr = "\x1b["..settings.get("color.doskey").."m"
                end
            end
            r:close()
            return matches
        end
    end
    return {}
end

-- luacheck: push
-- luacheck: no max line length

local mergesubtree_arg = parser({dir_matches})
local placeholder_required_arg = parser({})
-- Note: All these separate fromhistory parsers are necessary in order to
-- collect from history separately.
local batch_format_arg = parser({fromhistory=true, "%(objectname)", "%(objecttype)", "%(objectsize)", "%(objectsize:disk)", "%(deltabase)", "%(rest)"})
local clone_filter_arg = parser({fromhistory=true})
local color_opts = parser({"true", "false", "always"})
local commit_trailer_arg = parser({fromhistory=true})
local config_arg = parser({fromhistory=true})
local contextlines_arg = parser({fromhistory=true})
local depth_arg = parser({fromhistory=true})
local diff_filter_arg = parser({fromhistory=true})
local difftool_extcmd_arg = parser({fromhistory=true})
local gpg_keyid_arg = parser({fromhistory=true})
local merge_recursive_options = parser():_addexarg({
    --ort and recursive
    "ours", "theirs",
    "ignore-space-change", "ignore-all-space", "ignore-space-at-eol", "ignore-cr-at-eol",
    "renormalize", "no-renormalize",
    "find-renames",
    { "find-renames="..placeholder_required_arg, "n", "" },
    { "rename-threshold="..placeholder_required_arg, "n", "" },
    "subtree",
    { "subtree="..mergesubtree_arg, "path", "" },
    --recursive
    "patience",
    { "diff-algorithm="..parser({"patience", "minimal", "histogram", "myers"}), "algorithm", "" },
    "no-renames",
})
local merge_strategies = parser({"resolve", "recursive", "ours", "octopus", "subtree"})
local origin_arg = parser({fromhistory=true})
local person_arg = parser({fromhistory=true})
local pretty_formats_parser = parser({"oneline", "short", "medium", "full", "fuller", "reference", "email", "mboxrd", "raw", "format:"})
local receive_pack_arg = parser({fromhistory=true})
local regex_ignorelines_arg = parser({fromhistory=true})
local regex_refs_arg = parser({fromhistory=true})
local regex_worddiff_arg = parser({fromhistory=true})
local repo_arg = parser({fromhistory=true})
local shallow_since_arg = parser({fromhistory=true})
local summary_limit_arg = parser({fromhistory=true})
local untracked_files_arg = parser({"no", "normal", "all"})
local x_cmd_arg = parser({fromhistory=true})

local flag__abbrevequals = "--abbrev="..parser({5, 6, 8, 10, 12, 16, 20, 24, 32, 40})
local flag__colorequals = "--color="..parser({"always", "auto", "never"})
local flag__columnequals = "--column="..parser({"always", "auto", "never", "column", "row", "plain", "dense", "nodense"})
local flag__conflictequals = '--conflict='..parser({'merge', 'diff3', 'zdiff3'})
local flag__dateequals = "--date="..parser({"relative", "local", "iso", "iso-strict", "rfc", "short", "raw", "human", "unix", "default", "format:", "format-local:"})
local flag__encoding = "--encoding="..parser({fromhistory=true}) --parser("UTF-8", "none")
local flag__ignore_submodules = "--ignore-submodules="..parser({"none", "untracked", "dirty", "all"})
local flag__whitespaceequals = "--whitespace="..parser({"nowarn", "warn", "fix", "error", "error-all"})

local flagex__cleanupequals = { opteq=true, "--cleanup="..parser({"strip", "whitespace", "verbatim", "scissors", "default"}), 'option', '' }
local flagex_c_config = { '-c'..config_arg, ' key=value', '' }
local flagex__config = { '--config'..config_arg, ' key=value', '' }
local flagex__depthdepth = { opteq=true, '--depth'..depth_arg, ' depth', '' }
local flagex__gpgsignequals = { '--gpg-sign='..gpg_keyid_arg, 'keyid', '' }
local flagex_s_mergestrategy = { '-s' .. merge_strategies, ' strategy', '' }
local flagex__strategy = { opteq=true, '--strategy' .. merge_strategies, ' strategy', '' }
local flagex_u_uploadpack = { '-u'..placeholder_required_arg, ' upload-pack', '' }
local flagex__uploadpack = { opteq=true, '--upload-pack'..placeholder_required_arg, ' upload-pack', '' }
local flagex_X_strategyoption = { '-X'..merge_recursive_options, ' option', '' }
local flagex__strategyoption = { opteq=true, '--strategy-option'..merge_recursive_options, ' option', '' }

local git_options = {
    "core.editor",
    "core.pager",
    "core.excludesfile",
    "core.autocrlf"..parser({"true", "false", "input"}),
    "core.trustctime"..parser({"true", "false"}),
    "core.whitespace"..parser({
        "cr-at-eol",
        "-cr-at-eol",
        "indent-with-non-tab",
        "-indent-with-non-tab",
        "space-before-tab",
        "-space-before-tab",
        "trailing-space",
        "-trailing-space"
    }),
    "commit.template",
    "color.ui"..color_opts, "color.*"..color_opts, "color.branch"..color_opts,
    "color.diff"..color_opts, "color.interactive"..color_opts, "color.status"..color_opts,
    "help.autocorrect",
    "merge.tool", "mergetool.*.cmd", "mergetool.trustExitCode"..parser({"true", "false"}), "diff.external",
    "user.name", "user.email", "user.signingkey",
}

--------------------------------------------------------------------------------
-- Reusable groups of flags.

local log_flags = {
    "--decorate", "--decorate="..parser({"short", "full", "auto", "no"}), "--no-decorate",
    "--decorate-refs="..regex_refs_arg, "--decorate-refs-exclude="..regex_refs_arg,
    "--source",
    "--mailmap", "--no-mailmap",
    "--full-diff",
    "--log-size",
    { "-n"..placeholder_required_arg, " number", "" },
    { opteq=true, "--max-count="..placeholder_required_arg, "number", "" },
    { opteq=true, "--skip="..placeholder_required_arg, "number", "" },
    { opteq=true, "--since="..placeholder_required_arg, "date", "" },
    { opteq=true, "--after="..placeholder_required_arg, "date", "" },
    { opteq=true, "--until="..placeholder_required_arg, "date", "" },
    { opteq=true, "--before="..placeholder_required_arg, "date", "" },
    { opteq=true, "--author="..person_arg },
    { opteq=true, "--committer="..person_arg },
    { opteq=true, "--grep="..placeholder_required_arg },
    "--all-match",
    "--invert-grep",
    "-i", "--regexp-ignore-case",
    "--basic-regexp",
    "-E", "--extended-regexp",
    "-F", "--fixed-strings",
    "-P", "--perl-regexp",
    "--merges", "--no-merges",
    { opteq=true, "--min-parents="..placeholder_required_arg, "number", "" }, "--no-min-parents",
    { opteq=true, "--max-parents="..placeholder_required_arg, "number", "" }, "--no-max-parents",
    "--first-parent",
    "--not",
    "--all",
    "--branches", { "--branches="..placeholder_required_arg, "glob", "" },
    "--tags", { "--tags="..placeholder_required_arg, "glob", "" },
    "--remotes", { "--remotes="..placeholder_required_arg, "glob", "" },
    { opteq=true, "--glob="..placeholder_required_arg, "glob", "" },
    { opteq=true, "--exclude="..placeholder_required_arg, "glob", "" },
    "--single-worktree",
    "--ignore-missing",
    "--merge",
}

local log_history_flags = {
    "--follow",
    { "-L"..parser({fromhistory=true}), ":funcname:file|start,end:file", "" },
    { opteq=true, "--grep-reflog="..placeholder_required_arg, "pattern", "" },
    "--remove-empty",
    --"--reflog",
    --"--alternate-refs",
    "--bisect",
    "--stdin",
    "--cherry-mark",
    "--cherry-pick",
    "--left-only",
    "--right-only",
    "--cherry",
    "-g", "--walk-reflogs",
    "--boundary",
    "--simplify-by-decoration",
    "--show-pulls",
    "--full-history",
    "--dense",
    "--sparse",
    "--simplify-merges",
    "--ancestry-path",
    "--date-order",
    "--author-date-order",
    "--topo-order",
    "--reverse",
}

local commit_formatting_flags = {
    "--pretty",
    "--pretty="..pretty_formats_parser,
    "--format="..pretty_formats_parser,
    "--oneline",
    "--abbrev-commit",
    "--no-abbrev-commit",
    flag__encoding,
    { "--expand-tabs="..placeholder_required_arg, "n", "" },
    "--expand-tabs",
    "--no-expand-tabs",
    "--notes",
    { "--notes="..placeholder_required_arg, "ref", "" },
    "--no-notes",
    "--first-parent",
    flag__dateequals,
    "--parents",
    "--children",
    "--left-right",
    "--graph",
    "--show-linear-break",
    { "--show-linear-break="..placeholder_required_arg, "barrier", "" },
}

local diff_flags = {
    "-p", "-u", "--patch",
    "-s", "--no-patch",
    "-U", "--unified",
    { opteq=true, "--output="..files_parser },
    { opteq=true, "--output-indicator-new="..placeholder_required_arg, "char", "" },
    { opteq=true, "--output-indicator-old="..placeholder_required_arg, "char", "" },
    { opteq=true, "--output-indicator-context="..placeholder_required_arg, "char", "" },
    "--raw",
    "--patch-with-raw",
    "--indent-heuristic",
    "--no-indent-heuristic",
    "--minimal",
    "--patience",
    "--histogram",
    { opteq=true, "--anchored="..placeholder_required_arg, "text", "" },
    { opteq=true, "--diff-algorithm="..parser({"patience", "minimal", "histogram", "default", "myers"}) },
    "--stat",
    { "--stat="..placeholder_required_arg, "width[,name-width[,count]]", "" },
    "--compact-summary",
    "--numstat",
    "--shortstat",
    "-X", "--dirstat",
    "--dirstat="..parser({"changes", "lines", "files", "cumulative", "noncumulative", "{LIMIT_PERCENT}"}),
    "--cumulative",
    "--dirstat-by-file",
    "--dirstat-by-file="..parser({"cumulative", "noncumulative", "{LIMIT_PERCENT}"}),
    "--summary",
    "--patch-with-stat",
    "-z",
    "--name-only",
    "--name-status",
    "--color",
    flag__colorequals,
    "--no-color",
    "--color-moved",
    "--color-moved="..parser({"no", "default", "plain", "blocks", "zebra", "dimmed-zebra"}),
    "--no-color-moved",
    "--color-moved-ws="..parser({"no", "ignore-space-at-eol", "ignore-space-change", "ignore-all-space", "allow-indentation-change"}),
    "--no-color-moved-ws",
    "--word-diff",
    "--word-diff="..parser({"color", "plain", "porcelain", "none"}),
    { opteq=true, "--word-diff-regex="..regex_worddiff_arg },
    "--color-words", --"--color-words="..regex_worddiff_arg,
    "--no-renames",
    "--rename-empty",
    "--no-rename-empty",
    "--check",
    "--ws-error-highlight="..parser({"context", "old", "new", "all", "default"}),
    "--full-index",
    "--binary",
    "--abbrev",
    flag__abbrevequals,
    { "-B", "[n][/m]", "" },
    "--break-rewrites",
    { "--break-rewrites="..placeholder_required_arg, "[n]/[/m]", "" },
    { "-M", "n", "" },
    "--find-renames",
    { "--find-renames="..placeholder_required_arg, "n", "" },
    { "-C", "n", "" },
    "--find-copies",
    { "--find-copies="..placeholder_required_arg, "n", "" },
    "--find-copies-harder",
    "-D", "--irreversible-delete",
    { "-l", "n", "" },
    { opteq=true, "--diff-filter="..diff_filter_arg, "[ACDMRTUXB...*]", "" },
    --{ "-S", "string", "" },
    --{ "-G", "regex", "" },
    { opteq=true, "--find-object="..placeholder_required_arg, "objid", "" },
    "--pickaxe-all", "--pickaxe-regex",
    "-O",
    { opteq=true, "--skip-to="..files_parser },
    { opteq=true, "--rotate-to="..files_parser },
    "-R",
    "--relative",
    "--relative="..dirs_parser,
    "--no-relative",
    "-a", "--text",
    "--ignore-cr-at-eol",
    "--ignore-space-at-eol",
    "-b", "--ignore-space-change",
    "-w", "--ignore-all-space",
    "--ignore-blank-lines",
    "-I", { "--ignore-matching-lines="..regex_ignorelines_arg, "regex", "" },
    { "--inter-hunk-context="..contextlines_arg, "numlines", "" },
    "-W", "--function-context",
    "--exit-code",
    "--quiet",
    "--ext-diff", "--no-ext-diff",
    "--text-conv", "--no-text-conv",
    "--ignore-submodules",
    flag__ignore_submodules,
    "--submodule", "--submodule="..parser({"short", "log", "diff"}),
    { opteq=true, "--src-prefix="..parser({fromhistory=true}), "prefix", "" },
    { opteq=true, "--dst-prefix="..parser({fromhistory=true}), "prefix", "" },
    "--no-prefix",
    { opteq=true, "--line-prefix="..parser({fromhistory=true}), "prefix", "" },
    "--ita-invisible-in-index",
    "-1", "--base",
    "-2", "--ours",
    "-3", "--theirs",
    "-0",
    { opteq=true, "--diff-merges="..parser({"off", "none", "on", "first-parent", "1", "separate", "m", "combined", "c", "dense-combined", "cc"}) },
    "--no-diff-merges",
    "-c", "--cc",
    "-m",
    "-t",
    "--combined-all-paths",
}

local fetch_flags = {
    '--all',
    '-a', '--append',
    '--atomic',
    { opteq=true, '--depth='..placeholder_required_arg, 'depth', '' },
    { opteq=true, '--deepen='..placeholder_required_arg, 'depth', '' },
    { opteq=true, '--shallow-since='..shallow_since_arg, 'date', '' },
    { opteq=true, '--shallow-exclude='..placeholder_required_arg, 'rev', '' },
    '--unshallow',
    '--update-shallow',
    { opteq=true, '--negotiation-tip='..placeholder_required_arg, 'commit|glob', '' },
    '--negotiate-only',
    '--dry-run',
    '-f', '--force',
    '-k', '--keep',
    '--prefetch',
    '-p', '--prune',
    '--no-tags',
    { opteq=true, '--refmap='..placeholder_required_arg, 'refspec', '' },
    '-t', '--tags',
    '-j', { opteq=true, '--jobs='..placeholder_required_arg, 'n', '' },
    '--set-upstream',
    flagex__uploadpack,
    --'--progress',
    '--no-progress',
    --'-o'..placeholder_required_arg, '--server-option='..placeholder_required_arg,
    '--show-forced-updates',
    '--no-show-forced-updates',
    '-4', '--ipv4',
    '-6', '--ipv6',
}

local merge_flags_common = {
    flagex_s_mergestrategy,
    flagex__strategy,
    flagex_X_strategyoption,
    flagex__strategyoption,
    "-S", "--gpg-sign", "--no-gpg-sign",
    flagex__gpgsignequals,
    --"--verify",
    "--no-verify",
    "--verify-signatures", "--no-verify-signatures",
    --"--progress",
    "--no-progress",
    "--autostash", "--no-autostash",
    "-n", "--stat", "--no-stat",
}

local merge_flags = {
    "--continue",
    "--abort",
    "--quit",
    '-i', '--interactive',
    "-q", "--quiet",
    "-v", "--verbose",
    "--rerere-autoupdate", "--no-rerere-autoupdate",
}

--------------------------------------------------------------------------------
-- Command parsers.

local add_parser = parser()
:addarg(add_spec_generator)
:_addexflags({
    "-n", "--dry-run",
    "-v", "--verbose",
    "-i", "--interactive",
    "-p", "--patch",
    "-e", "--edit",
    "-f", "--force",
    "-u", "--update",
    "--renormalize",
    "-N", "--intent-to-add",
    "-A", "--all",
    "--no-all",
    "--ignore-removal",
    "--no-ignore-removal",
    "--refresh",
    "--ignore-errors",
    "--ignore-missing",
    "--sparse",
    { opteq=true, "--chmod="..parser({"+x", "-x"}) },
    { opteq=true, "--pathspec-from-file="..files_parser },
    "--pathspec-file-nul",
})

local apply_parser = parser()
:_addexflags({
    "--stat",
    "--numstat",
    "--summary",
    "--check",
    "--index",
    "--cached",
    "--intent-to-add",
    "-3", "--3way",
    { opteq=true, "--build-fake-ancestor="..files_parser, "tmpfile", "" },
    "-R", "--reverse",
    "--reject",
    "-z",
    { "-p", "n", "" },
    { "-C", "n", "" },
    "--unidiff-zero",
    "--apply",
    "--no-add",
    "--allow-binary-replacement", "--binary",
    { opteq=true, "--exclude="..files_parser, "glob", "" },
    { opteq=true, "--include="..files_parser, "glob", "" },
    "--ignore-space-change", "--ignore-whitespace",
    flag__whitespaceequals,
    "--inaccurate-eof",
    "-v", "--verbose",
    "--recount",
    { opteq=true, "--directory="..dirs_parser },
    "--unsafe-paths",
    "--allow-empty",
})

local blame_parser = parser()
:addarg(file_matches)
:_addexflags({
    "--incremental",
    "-b",
    "--root",
    "--show-stats",
    --"--progress",
    "--no-progress",
    "--score-debug",
    "-f", "--show-name",
    "-n", "--show-number",
    "-p", "--porcelain",
    "--line-porcelain",
    "-c", "-t", "-l", "-s",
    "-e", "--show-email",
    "-w",
    "--ignore-rev",
    { opteq=true, "--ignore-revs-file="..files_parser, "file", "" },
    "--color-lines",
    "--color-by-age",
    "--minimal",
    { "-S"..files_parser, " revs-file", "" },
    { opteq=true, "--contents="..files_parser, "file", "" },
    { "-C", "n", "" },
    { "-M", "n", "" },
    { "-L"..placeholder_required_arg, " :funcname|start,end", "" },
    "--abbrev",
    flag__abbrevequals,
    "-l",
    "-t",
    { opteq=true, "--reverse="..placeholder_required_arg, "rev..rev", "" },
})
:_addexflags(commit_formatting_flags)

local branch_parser = parser()
:_addexflags({
    "-v", "--verbose", --"--vv",
    "-q", "--quiet",
    "-t", "--track", "--track="..parser({"direct", "inherit"}), "--no-track",
    "--set-upstream",
    "-u", "--set-upstream-to", "--set-upstream-to="..placeholder_required_arg,
    "--unset-upstream",
    "--color", flag__colorequals, "--no-color",
    "-r", "--remotes",
    { opteq=true, "--contains"..placeholder_required_arg, " commit", "" },
    { opteq=true, "--no-contains"..placeholder_required_arg, " commit", "" },
    "--abbrev", flag__abbrevequals, "--no-abbrev",
    "-a", "--all",
    { "-d" .. parser({branches}):loop(1), " branch", "" },
    { opteq=true, "--delete" .. parser({branches}):loop(1), " branch", "" },
    { "-D" .. parser({branches}):loop(1), " branch", "" },
    "-m", "--move", "-M",
    "-c", "--copy", "-C",
    "-i", "--ignore-case",
    "-l", "--list",
    "--show-current",
    "--create-reflog",
    "--edit-description",
    "-f", "--force",
    { opteq=true, "--merged"..placeholder_required_arg, " commit", "" },
    { opteq=true, "--no-merged"..placeholder_required_arg, " commit", "" },
    "--column",
    flag__columnequals,
    "--no-column",
    { "--sort="..placeholder_required_arg, "key", "" },
    { opteq=true, "--points-at", " object", "" },
    { opteq=true, "--format"..placeholder_required_arg, " format", "" },
})

local catfile_parser = parser()
:_addexflags({
    '-t',
    '-s',
    '-e',
    '-p',
    '--textconv',
    '--filters',
    { opteq=true, '--path='..files_parser, 'path', '' },
    '--batch',
    { '--batch='..batch_format_arg, 'format', '' },
    '--batch-check',
    { '--batch-check='..batch_format_arg, 'format', '' },
    '--batch-all-objects',
    '--buffer',
    '--unordered',
    '--allow-unknown-type',
    '--follow-symlinks',
})

local checkout_parser = parser()
:addarg(checkout_spec_generator)
:_addexflags({
    '-q', '--quiet',
    --'--progress',
    '--no-progress',
    { '-b'..placeholder_required_arg, ' new-branch', '' },
    { '-B'..placeholder_required_arg, ' new-branch', '' },
    '-l',
    '-d', '--detach',
    '-t', '--track', '--track='..parser({'direct', 'inherit'}), '--no-track',
    '--guess', '--no-guess',
    { opteq=true, '--orphan'..placeholder_required_arg, ' new-branch', '' },
    '-2', '--ours',
    '-3', '--theirs',
    '-f', '--force',
    '-m', '--merge',
    --'--overwrite-ignore',
    '--no-overwrite-ignore',
    '--recurse-submodules', '--no-recurse-submodules',
    --'--overlay',
    '--no-overlay',
    flag__conflictequals,
    '-p', '--patch',
    '--ignore-skip-worktree-bits',
    '--ignore-other-worktrees',
    '--pathspec-from-file='..files_parser,
    '--pathspec-file-nul',
    '--'..parser({checkout_dashdash}),
})

local cherrypick_parser = parser()
:_addexflags({
    "-e", "--edit",
    flagex__cleanupequals,
    "-x",
    "-r",
    { "-m"..placeholder_required_arg, " parent-number", "" },
    { opteq=true, "--mainline"..placeholder_required_arg, " parent-number", "" },
    "-n", "--no-commit",
    "-s", "--signoff",
    "-S", "--gpg-sign", "--no-gpg-sign",
    flagex__gpgsignequals,
    "--ff",
    "--allow-empty",
    "--allow-empty-message",
    "--keep-redundant-commits",
    flagex_s_mergestrategy,
    flagex__strategy,
    flagex_X_strategyoption,
    flagex__strategyoption,
    "--rerere-autoupdate", "--no-rerere-autoupdate",
    "--continue",
    "--skip",
    "--quit",
    "--abort",
})

local clone_parser = parser()
:_addexflags({
    { opteq=true, '--template'..dirs_parser, ' dir', '' },
    '-l', '--local',
    '-s', '--shared',
    '--no-hardlinks',
    '-q', '--quiet',
    '-v', '--verbose',
    '-n', '--no-checkout',
    --'--progress',
    --'--server-option='..placeholder_required_arg,
    '--reject-shallow', '--no-reject-shallow',
    '--bare',
    '--sparse',
    { opteq=true, '--filter='..clone_filter_arg, 'filter-spec', '' },
    '--mirror',
    '-o'..origin_arg, { opteq=true, '--origin='..origin_arg },
    { '-b'..placeholder_required_arg, ' name', '' },
    { opteq=true, '--branch'..placeholder_required_arg, ' name', '' },
    flagex_u_uploadpack,
    flagex__uploadpack,
    { opteq=true, '--reference'..files_parser, ' repo', '' },
    { opteq=true, '--reference-if-able'..files_parser, 'repo', '' },
    '--dissociate',
    '--remote-submodules', '--no-remote-submodules',
    { opteq=true, '--separate-git-dir='..dirs_parser },
    flagex_c_config,
    flagex__config,
    flagex__depthdepth,
    { opteq=true, '--shallow-since='..shallow_since_arg, 'date', '' },
    { opteq=true, '--shallow-exclude='..placeholder_required_arg, 'rev', '' },
    '--single-branch', '--no-single-branch',
    '--no-tags',
    '--recurse-submodules',
    { '--recurse-submodules='..files_parser, 'pathspec', '' },
    '--shallow-submodules', '--no-shallow-submodules',
    { '-j'..placeholder_required_arg, ' n', '' },
    { opteq=true, '--jobs'..placeholder_required_arg, ' n', '' },
})

local commit_parser = parser()
:_addexflags({
    "-a", "--all",
    "-p", "--patch",
    { "-C"..placeholder_required_arg, " commit", "" },
    { opteq=true, "--reuse-message="..placeholder_required_arg, "commit", "" },
    { "-c"..placeholder_required_arg, " commit", "" },
    { opteq=true, "--reedit-message="..placeholder_required_arg, "commit", "" },
    { opteq=true, "--fixup="..parser({'amend:', 'reword:'}) },
    { opteq=true, "--squash="..placeholder_required_arg, 'commit', '' },
    "--reset-author",
    "--short",
    "--branch",
    "--porcelain",
    "--long",
    "-z",
    "--null",
    { "-F"..files_parser, " file", "" },
    { opteq=true, "--file="..files_parser, "file", "" },
    { opteq=true, "--author="..person_arg },
    { opteq=true, "--date="..placeholder_required_arg, "date", "" },
    { "-m"..placeholder_required_arg, " msg", "" },
    { opteq=true, "--message="..placeholder_required_arg, "msg", "" },
    { "-t"..files_parser, " file", "" },
    { opteq=true, "--template="..files_parser, "file", "" },
    "-s", "--signoff", "--no-signoff",
    { opteq=true, "--trailer"..commit_trailer_arg, " token[:value]", "" },
    --"--verify",
    "-n", "--no-verify",
    "--allow-empty",
    "--allow-empty-message",
    flagex__cleanupequals,
    "-e", "--edit", "--no-edit",
    "--amend",
    "--no-post-rewrite",
    "-i", "--include",
    "-o", "--only",
    '--pathspec-from-file='..files_parser,
    '--pathspec-file-nul',
    "-u", "-uno", "-uall", "--untracked-files", "--untracked-files="..untracked_files_arg,
    "-v", "--verbose",
    "-q", "--quiet",
    "--dry-run",
    "--status",
    "--no-status",
    "-S", "--gpg-sign",
    flagex__gpgsignequals,
    "--no-gpg-sign",
    "--",
})

local config_parser = parser()
:addarg(git_options)
:_addexflags({
    "--replace-all",
    "--add",
    "--get",
    "--get-all",
    "--get-regexp",
    { opteq=true, "--get-urlmatch"..placeholder_required_arg, " name URL", "" },
    "--global",
    "--system",
    "--local",
    "--worktree",
    { "-f"..files_parser, " config-file", "" },
    { opteq=true, "--file"..files_parser, " config-file", "" },
    { opteq=true, "--blob"..placeholder_required_arg, " blob", "" },
    "--remove-section",
    "--rename-section",
    "--unset",
    "--unset-all",
    "-l", "--list",
    "--fixed-value",
    { opteq=true, "--type="..parser({"bool", "int", "bool-or-int", "path", "expiry-date", "color"}) },
    "--no-type",
    --"--bool",
    --"--int",
    --"--bool-or-int",
    --"--path",
    --"--expiry-date",
    "-z", "--null",
    "--name-only",
    "--show-origin",
    "--show-scope",
    { opteq=true, "--get-color"..placeholder_required_arg, " name [default]", "" },
    { opteq=true, "--get-colorbool"..placeholder_required_arg, " name", "" },
    "-e", "--edit",
    "--includes", "--no-includes",
    { opteq=true, "--default"..placeholder_required_arg, " value", "" },
})

local diff_parser = parser()
:addarg(local_or_remote_branches, file_matches)
:_addexflags(diff_flags)

local difftool_parser = parser()
:_addexflags({
    '-d', '--dir-diff',
    '-y', '--no-prompt', '--prompt',
    '--rotate-to='..files_parser,
    '--skip-to='..files_parser,
    '-t', '--tool='..placeholder_required_arg, -- TODO: complete tool (take from config)
    '--tool-help',
    '--symlinks', '--no-symlinks',
    { '-x'..difftool_extcmd_arg, ' command', '' },
    { '--extcmd='..difftool_extcmd_arg, ' command', '' },
    '-g', '--gui', '--no-gui',
    '--trust-exit-code', '--no-trust-exit-code',
})

local fetch_parser = parser()
:addarg(remotes)
:_addexflags({
    '--write-fetch-head', '--no-write-fetch-head',
    '--multiple',
    '--auto-maintenance', '--no-auto-maintenance',
    --'--auto-gc', '--no-auto-gc',
    '--no-write-commit-graph',
    '-P', '--prune-tags',
    '-n', '--no-tags',
    '--recurse-submodules',
    '--recurse-submodules='..parser({'yes', 'on-demand', 'no'}),
    '--no-recurse-submodules',
    { opteq=true, '--submodule-prefix='..placeholder_required_arg, 'prefix', '' },
    --'--recurse-submodules-default='..parser({'yes', 'on-demand'}),
    '-u', '--update-head-ok',
    '-q', '--quiet',
    '-v', '--verbose',
    '--stdin',
})
:_addexflags(fetch_flags)

local help_parser = parser()
:_addexflags({
    { "-a",                             "Print all available commands" },
    { "--all",                          "Print all available commands" },
    --"--verbose",
    { "-c",                             "List all available config variables" },
    { "--config",                       "List all available config variables" },
    { "-g",                             "Print a list of git concept guides" },
    { "--guides",                       "Print a list of git concept guides" },
    --"-i",
    --"--info",
    { "-m",                             "Display manual page for the command in the man format" },
    { "--man",                          "Display manual page for the command in the man format" },
    { "-w",                             "Display manual page for the command in HTML format" },
    { "--web",                          "Display manual page for the command in HTML format" },
})
if help_parser.setdelayinit then
    help_parser:addarg({delayinit=function (argmatcher) -- luacheck: no unused args
        local matches = all_commands() or {}
        local guides = concept_guides() or {}
        for _,g in ipairs(guides) do
            table.insert(matches, g)
        end
        return matches
    end})
else
    help_parser:addarg(concept_guides, all_commands)
end

local log_parser = parser()
:_addexflags(log_flags)
:_addexflags(log_history_flags)
:_addexflags(diff_flags)
:_addexflags(commit_formatting_flags)

local merge_parser = parser()
:addarg(local_or_remote_branches)
:_addexflags({
    "--commit", "--no-commit",
    "--edit", "-e", "--no-edit",
    flagex__cleanupequals,
    "--ff", "--no-ff", "--ff-only",
    "--log", "--no-log",
    { "--log="..placeholder_required_arg, "n", "" },
    "--signoff", "--no-signoff",
    "--squash", "--no-squash",
    "--summary", "--no-summary",
    "--allow-unrelated-histories",
    { "-m"..placeholder_required_arg, ' message', '' },
    { opteq=true, "--into-name"..parser({branches}), ' branch', '' },
    { "-F"..files_parser, ' file', '' },
    { opteq=true, "--file="..files_parser, 'file', '' },
    "--overwrite-ignore", "--no-overwrite-ignore",
})
:_addexflags(merge_flags_common)
:_addexflags(merge_flags)

local pull_parser = parser()
:addarg(remotes)
:addarg(branches)
:_addexflags({
    "-q", "--quiet",
    "-v", "--verbose",
    "--recurse-submodules",
    "--recurse-submodules="..parser({'yes', 'on-demand', 'no'}),
    "--no-recurse-submodules",
        -- Options related to merging...
    "--commit", "--no-commit",
    "-e", "--edit", "--no-edit",
    flagex__cleanupequals,
    "--ff", "--no-ff", "--ff-only",
    "--log", "--no-log",
    { "--log="..placeholder_required_arg, "n", "" },
    "--signoff", "--no-signoff",
    "--squash", "--no-squash",
    "--summary", "--no-summary",
    "--allow-unrelated-histories",
    "-r", "--no-rebase",
    { opteq=true, "--rebase="..parser({'false', 'true', 'merges', 'interactive'}) },
})
:_addexflags(merge_flags_common)
:_addexflags(fetch_flags)

local push_parser = parser()
:addarg(remotes)
:addarg(push_branch_spec)
:_addexflags({
    '--all',
    '--prune',
    '--mirror',
    '-n', '--dry-run',
    '--porcelain',
    '-d', '--delete',
    '--tags',
    '--follow-tags',
    '--signed', '--signed='..parser({'true', 'false', 'if-asked'}), '--no-signed',
    '--atomic', '--no-atomic',
    --'-o'..placeholder_required_arg, '--server-option='..placeholder_required_arg,
    { opteq=true, '--receive-pack='..receive_pack_arg, 'git-receive-pack', '' },
    { opteq=true, '--exec='..receive_pack_arg, 'git-receive-pack', '' },
    '--force-with-lease', '--no-force-with-lease',
    { '--force-with-lease='..placeholder_required_arg, 'refname[:expect]', '' },
    '-f', '--force',
    '--force-if-includes', '--no-force-if-includes',
    { opteq=true, '--repo='..repo_arg },
    '-u', '--set-upstream',
    '--thin', '--no-thin',
    '-q', '--quiet',
    '-v', '--verbose',
    --'--progress',
    '--no-recurse-submodules',
    { opteq=true, '--recurse-submodules='..parser({'check', 'on-demand', 'only', 'no'}) },
    --'--verify',
    '--no-verify',
    '-4', '--ipv4',
    '-6', '--ipv6',
})

local rebase_parser = parser()
:addarg(local_or_remote_branches)
:addarg(branches)
:_addexflags({
    { opteq=true, '--onto' .. parser({branches}), ' newbase', '' },
    '--keep-base',
    '--continue',
    '--abort',
    '--quit',
    '--apply',
    { opteq=true, '--empty='..parser({'drop', 'keep', 'ask'}) },
    '--keep-empty', '--no-keep-empty',
    '--reapply-chery-picks', '--no-reapply-chery-picks',
    '--allow-empty-message',
    '--skip',
    '--edit-todo',
    '--show-current-patch',
    '-m', '--merge',
    { '-C', 'n', '' },
    '--no-ff',
    '-f', '--force-rebase',
    '--fork-point', '--no-fork-point',
    '--ignore-whitespace',
    flag__whitespaceequals,
    '--committer-date-is-author-date',
    '--ignore-date', '--reset-author-date',
    '--signoff',
    '-r', { opteq=true, '--rebase-merges='..parser({'rebase-cousins', 'no-rebase-cousins'}) },
    { '-x'..x_cmd_arg, ' command', '' },
    { opteq=true, '--exec='..x_cmd_arg, 'command', '' },
    '--root',
    '--autosquash', '--no-autosquash',
    '--reschedule-failed-exec', '--no-reschedule-failed-exec',
})
:_addexflags(merge_flags_common)
:_addexflags(merge_flags)

local remote_parser = parser()
:addarg(
    "add" ..parser(
        "-t"..parser({branches}),
        "-m"..placeholder_required_arg,
        "-f",
        "--mirror="..parser({"fetch", "push"}),
        "--tags", "--no-tags"
    ),
    "rename"..parser({remotes}),
    "remove"..parser({remotes}),
    "rm"..parser({remotes}),
    "set-head"..parser({remotes}, {branches},
        "-a", "--auto",
        "-d", "--delete"
    ),
    "set-branches"..parser("--add", {remotes}, {branches}),
    "get-url"..parser({remotes}, "--push", "--all"),
    "set-url"..parser(
        "--add"..parser("--push", {remotes}),
        "--delete"..parser("--push", {remotes})
    ),
    "show"..parser("-n", {remotes}),
    "prune"..parser("-n", "--dry-run", {remotes}),
    "update"..parser({remotes}, "-p", "--prune")
)
:addflags(
    "-v",
    "--verbose"
)

local reset_parser = parser()
:addarg(local_or_remote_branches)   -- TODO: Add commit completions
:_addexflags({
    "-q",
    "-p", "--patch",
    { opteq=true, "--pathspec-from-file="..files_parser }, --"--stdin",
    "--pathspec-file-nul", --"-z",
    "--soft", "--mixed", "--hard",
    "--merge", "--keep", "--no-recurse-submodules"
})

local restore_parser = parser()
:addarg(file_matches)
:_addexflags({
    "-s", "--source",
    "-p", "--patch",
    "-W", "--worktree",
    "-S", "--staged",
    "-q", "--quiet",
    --"--progress",
    "--no-progress",
    "--ours", "--theirs",
    "-m", "--merge",
    flag__conflictequals,
    "--ignore-unmerged",
    "--ignore-skip-worktree-bits",
    "--recurse-submodules", "--no-recurse-submodules",
    "--overlay",
     --"--no-overlay",
    { opteq=true, "--pathspec-from-file="..files_parser },
    "--pathspec-file-nul"
})

local revert_parser = parser()
:_addexflags({
    "-e", "--edit",
    "-m", "--mainline",
    "--no-edit",
    flagex__cleanupequals,
    "-n", "--no-commit",
    "-S", "--gpg-sign",
    "--no-gpg-sign",
    "-s", "--signoff",
    flagex__strategy,
    flagex_X_strategyoption,
    flagex__strategyoption,
    "--rerere-autoupdate",
    "--no-rerere-autoupdate",
    "--continue",
    "--skip",
    "--quit",
    "--abort",
})

local show_parser = parser()
:_addexflags(diff_flags)
:_addexflags(commit_formatting_flags)

local stash_parser = parser()
:addarg(
    "push"..parser():_addexflags({
        "-p", "--patch",
        "-S", "--staged",
        "-k", "--no-keep-index", "--keep-index",
        "-u", "--include-untracked",
        "-a", "--all",
        "-q", "--quiet",
        { "-m"..placeholder_required_arg, " message", "" },
        { opteq=true, "--message"..placeholder_required_arg, " message", "" },
        { opteq=true, "--pathspec-from-file="..files_parser },
        "--pathspec-file-nul",
    }),
    --[["save"..parser(
        "-p", "--patch",
        "-k", "--no-keep-index", "--keep-index",
        "-q", "--quiet",
        "-u", "--include-untracked",
        "-a", "--all"
        ),]]
    "list"..parser():_addexflags(commit_formatting_flags):_addexflags(diff_flags):_addexflags(log_flags),
    "show"..parser({stashes}, "-u", "--include-untracked", "--only-untracked"):_addexflags(diff_flags),
    "pop"..parser({stashes}, "--index", "-q", "--quiet"),
    "apply"..parser({stashes}, "--index", "-q", "--quiet"),
    "branch"..parser({branches}, {stashes}),
    "clear",
    "drop"..parser({stashes}, "-q", "--quiet")
)

local status_parser = parser()
:_addexflags({
    '-s', '--short',
    '-b', '--branch',
    '--show-stash',
    '--porcelain', '--porcelain='..parser({'v1', 'v2'}),
    --'--long',
    '-v', '--verbose',
    '-u', '-uno', '-uall', '--untracked-files', '--untracked-files='..untracked_files_arg,
    "--ignore-submodules",
    flag__ignore_submodules,
    '--ignored',
    '--ignored='..parser({'traditional', 'no', 'matching'}),
    '-z',
    '--column', '--no-column',
    flag__columnequals,
    '--ahead-behind', '--no-ahead-behind',
    '--renames', '--no-renames',
    --'--lock-index', '--no-lock-index',
    --'--find-renames='..placeholder_required_arg,
    { '-M', 'n', '' },
    '--find-renames',
    { '--find-renames='..placeholder_required_arg, 'n', '' },
})

local submodule_parser = parser()
:_addexarg({
    'add'..parser():_addexflags({
        { '-b'..placeholder_required_arg, ' branch', '' },
        '-f', '--force',
        { opteq=true, '--name'..placeholder_required_arg, ' name', '' },
        { opteq=true, '--reference'..placeholder_required_arg, ' repo_url', '' },
        { opteq=true, '--depth'..placeholder_required_arg, ' depth', '' },
    }),
    'status'..parser('--cached', '--recursive'),
    'init',
    'deinit'..parser('-f', '--force', '--all'),
    'update'..parser():_addexflags({
        '--init',
        '--remote',
        '-N', '--no-fetch',
        '--recommend-shallow', '--no-recommend-shallow',
        '-f', '--force',
        '--checkout', '--rebase', '--merge',
        { opteq=true, '--reference'..placeholder_required_arg, ' repo_url', '' },
        { opteq=true, '--depth'..placeholder_required_arg, ' depth', '' },
        '--recursive',
        { opteq=true, '--jobs'..placeholder_required_arg, ' n', '' },
        '--single-branch', '--no-single-branch',
    }),
    'set-branch'..parser():_addexflags({
        { '-b'..placeholder_required_arg, ' branch', '' },
        { opteq=true, '--branch'..placeholder_required_arg, ' branch', '' },
        '-d', '--default',
    }),
    'set-url'..parser():addarg(file_matches):addarg(placeholder_required_arg):nofiles(),
    'summary'..parser():_addexflags({
        '--cached',
        '--files',
        { '-n'..summary_limit_arg, ' n', '' },
        { opteq=true, '--summary-limit'..summary_limit_arg, ' n', '' },
    }),
    { 'foreach'..parser('--recursive'):addarg({fromhistory=true}), ' shell_command', '' },
    'sync'..parser('--recursive'),
    'absorbgitdirs',
})
:addflags('--quiet')

local svn_parser = parser()
:addarg(
    "init"..parser("-T", "--trunk", "-t", "--tags", "-b", "--branches", "-s", "--stdlayout",
        "--no-metadata", "--use-svm-props", "--use-svnsync-props", "--rewrite-root",
        "--rewrite-uuid", "--username", "--prefix"..parser({"origin"}), "--ignore-paths",
        "--include-paths", "--no-minimize-url"),
        "fetch"..parser({remotes}, "--localtime", "--parent", "--ignore-paths", "--include-paths",
        "--log-window-size"),
        "clone"..parser("-T", "--trunk", "-t", "--tags", "-b", "--branches", "-s", "--stdlayout",
        "--no-metadata", "--use-svm-props", "--use-svnsync-props", "--rewrite-root",
        "--rewrite-uuid", "--username", "--prefix"..parser({"origin"}), "--ignore-paths",
        "--include-paths", "--no-minimize-url", "--preserve-empty-dirs",
        "--placeholder-filename"),
        "rebase"..parser({local_or_remote_branches}, {branches}),
    "dcommit"..parser("--no-rebase", "--commit-url", "--mergeinfo", "--interactive"),
    "branch"..parser("-m","--message","-t", "--tags", "-d", "--destination",
                     "--username", "--commit-url", "--parents"),
    "log"..parser("-r", "--revision", "-v", "--verbose", "--limit",
                  "--incremental", "--show-commit", "--oneline"),
    "find-rev"..parser("--before", "--after"),
    "reset"..parser("-r", "--revision", "-p", "--parent"),
    "tag",
    "blame",
    "set-tree",
    "create-ignore",
    "show-ignore",
    "mkdirs",
    "commit-diff",
    "info",
    "proplist",
    "propget",
    "show-externals",
    "gc"
)

local switch_parser = parser()
:addarg(local_or_remote_branches)
:_addexflags({
    { '-c'..placeholder_required_arg, ' new-branch', '' },
    { opteq=true, '--create'..placeholder_required_arg, ' new-branch', '' },
    { '-C'..placeholder_required_arg, ' new-branch', '' },
    { opteq=true, '--force-create'..placeholder_required_arg, ' new-branch', '' },
    '-d', '--detach',
    '--guess', '--no-guess',
    '-f', '--force', '--discard-changes',
    '-m', '--merge',
    flag__conflictequals,
    '-q', '--quiet',
    --'--progress',
    '--no-progress',
    '-t', '--track', '--track='..parser({'direct', 'inherit'}), '--no-track',
    { opteq=true, '--orphan'..placeholder_required_arg, ' new-branch', '' },
    '--ignore-other-worktrees',
    '--recurse-submodules', '--no-recurse-submodules',
})

local worktree_parser = parser()
:addarg(
    "add"..parser(
        {dir_matches},
        {branches}
    ):_addexflags({
        "-f", "--force",
        "--detach",
        "--checkout",
        "--lock",
        { opteq=true, "--reason"..placeholder_required_arg, " string", "" },
        { "-b"..parser({branches}), " new-branch", "" },
    }),
    "list"..parser("-v", "--porcelain"),
    "lock"..parser():_addexflags({
        { opteq=true, "--reason"..placeholder_required_arg, " string", "" },
    }),
    "move",
    "prune"..parser():_addexflags({
        "-n", "--dry-run",
        "-v", "--verbose",
        { "--expire", " expire", "" },
    }),
    "remove"..parser("-f", "--force"),
    "unlock"
)

--------------------------------------------------------------------------------
-- The main git command parser.

-- This is the set of git commands with custom parsers.  It exists as a separate
-- table so that aliases can be linked to the associated parser for the command
-- they alias.
local linked_parsers = {
    ["add"]                 = add_parser,
    ["annotate"]            = blame_parser,
    ["apply"]               = apply_parser,
    ["blame"]               = blame_parser,
    ["branch"]              = branch_parser,
    ["cat-file"]            = catfile_parser,
    ["checkout"]            = checkout_parser,
    ["cherry-pick"]         = cherrypick_parser,
    ["clone"]               = clone_parser,
    ["commit"]              = commit_parser,
    ["config"]              = config_parser,
    ["diff"]                = diff_parser,
    ["difftool"]            = difftool_parser,
    ["fetch"]               = fetch_parser,
    ["help"]                = help_parser,
    ["log"]                 = log_parser,
    ["merge"]               = merge_parser,
    ["pull"]                = pull_parser,
    ["push"]                = push_parser,
    ["rebase"]              = rebase_parser,
    ["remote"]              = remote_parser,
    ["reset"]               = reset_parser,
    ["restore"]             = restore_parser,
    ["revert"]              = revert_parser,
    ["show"]                = show_parser,
    ["stash"]               = stash_parser,
    ["status"]              = status_parser,
    ["submodule"]           = submodule_parser,
    ["svn"]                 = svn_parser,
    ["switch"]              = switch_parser,
    ["worktree"]            = worktree_parser,
}

-- Commands with descriptions.
-- Each entry must be a table containing two strings:  { command, description }.
--
-- NOTE:  These are added in the order listed; they are not auto-sorted.
local main_commands = {
    nosort=true,
    { "add",                "Add file contents to the index" },
    { "annotate",           "Annotate file lines with commit information" },
    { "apply",              "Apply a patch to files and/or to the index" },
    { "blame",              "Show last modify info for lines of a file" },
    { "branch",             "List, create, or delete branches" },
    { "cat-file",           "Provide content or type and size info for repo objects" },
    { "checkout",           "Switch branches or restore working tree files" },
    { "cherry-pick",        "Apply changes introduced by some existing commits" },
    { "clone",              "Clone a repository into a new directory" },
    { "commit",             "Record changes to the repository" },
    { "config",             "Get and set repository or global options" },
    { "diff",               "Show changes between commits, trees, tags, etc" },
    { "difftool",           "Show changes using common diff tools" },
    { "fetch",              "Download objects and refs from another repository" },
    { "help",               "Print help on a command or topic" },
    { "log",                "Show commit logs" },
    { "merge",              "Join two or more development histories together" },
    { "pull",               "Fetch from and integrate with another repo or local branch" },
    { "push",               "Update remote refs along with associated objects" },
    { "rebase",             "Reapply commits on top of another base tip" },
    { "remote",             "Manage set of tracked repositories" },
    { "reset",              "Reset current HEAD to the specified state" },
    { "restore",            "Restore working tree files" },
    { "revert",             "Revert some existing commits" },
    { "show",               "Show various types of objects" },
    { "stash",              "Stash the changes in a dirty working directory away" },
    { "status",             "Show the working tree status" },
    { "submodule",          "Initialize, update or inspect submodules" },
    { "switch",             "Switch branches" },
    { "worktree",           "Manage multiple working trees" },
}

-- Commands without descriptions.
-- This is a table of just command name strings.
--
-- NOTE:  These are added in the order listed; they are not auto-sorted.
local other_commands = {
    "add--interactive",
    "am",
    "archive",
    "bisect",
    "bisect--helper",
    "bundle",
    "check-attr",
    "check-ignore",
    "check-mailmap",
    "check-ref-format",
    "checkout-index",
    "cherry",
    "citool",
    "clean",
    "column",
    "commit-tree",
    "count-objects",
    "credential",
    "credential-store",
    "credential-wincred",
    "daemon",
    "describe",
    "diff-files",
    "diff-index",
    "diff-tree",
    "difftool--helper",
    "fast-export",
    "fast-import",
    "fetch-pack",
    "filter-branch",
    "fmt-merge-msg",
    "for-each-ref",
    "format-patch",
    "fsck",
    "fsck-objects",
    "gc",
    "get-tar-commit-id",
    "grep",
    "gui",
    "gui--askpass",
    "gui--askyesno",
    "gui.tcl",
    "hash-object",
    "http-backend",
    "http-fetch",
    "http-push",
    "imap-send",
    "index-pack",
    "init",
    "init-db",
    "lost-found",
    "ls-files",
    "ls-remote",
    "ls-tree",
    "mailinfo",
    "mailsplit",
    "merge-base",
    "merge-file",
    "merge-index",
    "merge-octopus",
    "merge-one-file",
    "merge-ours",
    "merge-recursive",
    "merge-resolve",
    "merge-subtree",
    "merge-tree",
    "mergetool",
    "mergetool--lib",
    "mktag",
    "mktree",
    "mv",
    "name-rev",
    "notes",
    "p4",
    "pack-objects",
    "pack-redundant",
    "pack-refs",
    "parse-remote",
    "patch-id",
    "peek-remote",
    "prune",
    "prune-packed",
    "quiltimport",
    "read-tree",
    "receive-pack",
    "reflog",
    "remote-ext",
    "remote-fd",
    "remote-ftp",
    "remote-ftps",
    "remote-hg",
    "remote-http",
    "remote-https",
    "remote-testsvn",
    "repack",
    "replace",
    "repo-config",
    "request-pull",
    "rerere",
    "rev-list",
    "rev-parse",
    "rm",
    "send-email",
    "send-pack",
    "sh-i18n",
    "sh-i18n--envsubst",
    "sh-setup",
    "shortlog",
    "show-branch",
    "show-index",
    "show-ref",
    "stage",
    "stripspace",
    "subtree",
    "svn",
    "symbolic-ref",
    "tag",
    "tar-tree",
    "unpack-file",
    "unpack-objects",
    "update-index",
    "update-ref",
    "update-server-info",
    "upload-archive",
    "upload-pack",
    "var",
    "verify-pack",
    "verify-tag",
    "web--browse",
    "whatchanged",
    "write-tree",
}

-- This is the set of flags for git itself (versus flags for commands in git).
local git_flags = {
    { "--version",                          "Print the git suite version" },
    { "--help"..help_parser, " [...]",      "Print general help, or help on a topic" },
    { "-C"..dirs_parser, " path",           "Run as if git was started in PATH" },
    { "-c"..placeholder_required_arg, " name=value", "Pass a configuration parameter, overriding config files" },
    { "--exec-path",                        "Print where the core git programs are stored" },
    { "--exec-path="..dirs_parser, "path",  "Override path to the core git programs" },
    { "--html-path",                        "Print where git's HTML documentation is stored" },
    --"--man-path",
    --"--info-path",
    { "-p",                                 "Pipe all output into less" },
    { "--paginate",                         "Pipe all output into less" },
    { "--no-pager",                         "Do not pipe git output into a pager" },
    { "--no-replace-objects",               "Do not use replacement refs to replace git objects" },
    { "--bare",                             "Treat the repository as a bare repository" },
    { "--git-dir="..dirs_parser, "path",    "Set the path to the repo ('.git' directory)" },
    { "--work-tree="..dirs_parser, "path",  "Set the path to the working tree" },
    { "--namespace="..placeholder_required_arg, "path", "Set the git namespace" },
    { "--literal-pathspecs",                "Treat pathspecs literally (no globbing, magic, etc)" },
    { "--glob-pathspecs",                   "Apply 'glob' magic to all pathspecs" },
    { "--no-glob-pathspecs",                "Add 'literal' magic to all pathspecs" },
    { "--icase-pathspecs",                  "Add 'icase' magic to all pathspecs" },
    { "--no-optional-locks",                "Do not perform optional operations that require locks" },
}

-- luacheck: pop

-- Initialize the argmatcher.  This may be called repeatedly.
local function init(argmatcher, full_init)
    -- When doing a full init, must reset in order to maintain the sort order.
    -- Full init is used from the setdelayinit callback function, for an alias
    -- to be able to parse arguments for the command it aliases.
    if full_init then
        argmatcher:reset()
    end

    -- Build a table that will be used to (re)initialize the git parser.
    local commands = { nosort=true }

    -- First the main commands, with descriptions.
    for _,x in ipairs(main_commands) do
        local linked = linked_parsers[x[1]]
        if linked then
            table.insert(commands, { x[1]..linked, x[2] })
        elseif looping_files_parser then
            table.insert(commands, x..looping_files_parser)
        else
            table.insert(commands, x)
        end
    end

    -- Then the function to get all aliases.  This only affects generating
    -- completions; it doesn't affect input line parsing or coloring.
    table.insert(commands, alias)

    -- Then aliases with linked argmatchers.  By coming after the alias
    -- function, the sort order when displaying completions is defined by the
    -- alias function.  But these do affect input line parsing and coloring.
    local aliases = get_git_aliases()
    for _, a in ipairs(aliases) do
        local linked = linked_parsers[a.command]
        if linked then
            table.insert(commands, a.name..linked)
        end
    end

    -- Finally other commands.
    for _,x in ipairs(other_commands) do
        local linked = linked_parsers[x]
        if linked then
            table.insert(commands, x..linked)
        elseif looping_files_parser then
            table.insert(commands, x..looping_files_parser)
        else
            table.insert(commands, x)
        end
    end

    -- Initialize the argmatcher.
    argmatcher:_addexarg(commands)
    argmatcher:_addexflags(git_flags)
end

local cached_cwd
local cached_repo

local git_parser = parser()
init(git_parser, false--[[full_init]])
if git_parser.setdelayinit then
    git_parser:setdelayinit(function (argmatcher)
        local cwd = os.getcwd()
        if cached_cwd ~= cwd then               -- No-op unless cwd changes.
            cached_cwd = cwd
            local repo = git.get_git_dir()
            if cached_repo ~= repo then         -- No-op unless repo changes.
                cached_repo = repo
                if repo and repo ~= "" then     -- No-op unless in a repo.
                    init(argmatcher, true--[[full_init]])
                end
            end
        end
    end)
end

clink.arg.register_parser("git", git_parser)
