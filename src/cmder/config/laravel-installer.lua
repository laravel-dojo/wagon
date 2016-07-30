--
-- Copyright (c) 2015 Shengyou Fan
--

--------------------------------------------------------------------------------
local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

local laravel_basic_options = {
	"--help", "-h",
	"--quiet", "-q",
	"--verbose", "-v", "-vv", "-vvv",
	"--version", "-V",
	"--ansi",
	"--no-ansi",
	"--no-interaction", "-n"
}

local laravel_basic_parser = clink.arg.new_parser()
laravel_basic_parser:set_flags(laravel_basic_options)
laravel_basic_parser:set_arguments({         
	"help" .. flags(
						"--xml",
						"--format",
						"--raw",
						laravel_basic_options
						),     
	"list" .. flags(
						"--xml",
						"--format",
						"--raw"
						), 
	"new" .. flags(laravel_basic_options)  
})

clink.arg.register_parser("laravel", laravel_basic_parser)
clink.arg.register_parser("laravel", laravel_basic_options)