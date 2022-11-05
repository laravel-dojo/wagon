return {
    exclude_files = { ".install", ".lua", ".luarocks", "modules/JSON.lua", "lua_modules" },
    files = {
        spec = { std = "+busted" },
    },
    globals = {
        "clink",
        "error",
        "log",
        "os.getcwd",
        "os.globfiles",
        "os.isdir",
        "os.setenv",
        "path",
        "pause",
        "rl",
        "rl_state",
        "settings",
        "string.explode",
    }
}
