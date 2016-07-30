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
	"help" .. flags(
						"--format",
						"--raw",
						homestead_basic_options
						),
	"list" .. flags(
						"--format",
						"--raw"
						),
	"make" .. flags(
						"--name",
						"--hostname",
      					"--ip",
      					"--after",
      					"--aliases",
      					"--example"
						)
})

clink.arg.register_parser("homestead", homestead_basic_parser)
clink.arg.register_parser("homestead", homestead_basic_options)