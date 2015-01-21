--
-- Copyright (c) 2015 Shengyou Fan
--

--------------------------------------------------------------------------------
local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

local homestead_basic_options = {
	"--help", "-h",
	"--quiet", "-q",
	"--verbose", "-v", "-vv", "-vvv",
	"--version", "-V",
	"--ansi",
	"--no-ansi",
	"--no-interaction", "-n"
}

local homestead_basic_parser = clink.arg.new_parser()
homestead_basic_parser:set_flags(homestead_basic_options)
homestead_basic_parser:set_arguments({         
	"destroy" .. flags(homestead_basic_options),
	"edit" .. flags(homestead_basic_options),         
	"halt" .. flags(homestead_basic_options),
	"help" .. flags(
						"--xml",
						"--format",
						"--raw",
						homestead_basic_options
						),    	
	"init" .. flags(homestead_basic_options),  
	"list" .. flags(
						"--xml",
						"--format",
						"--raw"
						),          
	"resume" .. flags(homestead_basic_options),
	"ssh" .. flags(homestead_basic_options),  
	"status" .. flags(homestead_basic_options),
	"suspend" .. flags(homestead_basic_options),         
	"up" .. flags(homestead_basic_options),
	"update" .. flags(homestead_basic_options)    
})

clink.arg.register_parser("homestead", homestead_basic_parser)
clink.arg.register_parser("homestead", homestead_basic_options)