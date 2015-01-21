--
-- Copyright (c) 2015 Shengyou Fan
--

--------------------------------------------------------------------------------
local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

local envoy_basic_options = {
	"--help", "-h",
	"--quiet", "-q",
	"--verbose", "-v", "-vv", "-vvv",
	"--version", "-V",
	"--ansi",
	"--no-ansi",
	"--no-interaction", "-n"
}

local envoy_basic_parser = clink.arg.new_parser()
envoy_basic_parser:set_flags(envoy_basic_options)
envoy_basic_parser:set_arguments({         
	"help" .. flags(
						"--xml",
						"--format",
						"--raw",
						envoy_basic_options
						), 
	"init" .. flags(envoy_basic_options),         
	"list" .. flags(
						"--xml",
						"--format",
						"--raw"
						), 
	"run" .. flags(
						"--pretend",
						envoy_basic_options
						),    	
	"ssh" .. flags(
						"--user",
						envoy_basic_options
						)  
})

clink.arg.register_parser("envoy", envoy_basic_parser)
clink.arg.register_parser("envoy", envoy_basic_options)