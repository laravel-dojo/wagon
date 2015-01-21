--
-- Copyright (c) 2014 Shengyou Fan
--

--------------------------------------------------------------------------------
local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

local artisan_basic_options = {
	"--help", "-h",
	"--quiet", "-q",
	"--verbose", "-v", "-vv", "-vvv",
	"--version", "-V",
	"--ansi",
	"--no-ansi",
	"--no-interaction", "-n",
	"--env"
}

local artisan_basic_parser = clink.arg.new_parser()
artisan_basic_parser:set_flags(artisan_basic_options)
artisan_basic_parser:set_arguments({
	"changes",
	"clear-compiled",
	"down",
	"dump-autoload",
	"env",
	"help",
	"list",
	"migrate",
	"optimize",
	"routes",
	"serve",
	"tail",
	"tinker",
	"up",
	"workbench",
})

local artisan_command_parser = clink.arg.new_parser()
artisan_command_parser:set_arguments({
	"asset:publish" .. flags(artisan_basic_options),
	"auth:clear-reminders" .. flags(artisan_basic_options),
	"auth:reminders-controller" .. flags(artisan_basic_options),
	"auth:reminders-table" .. flags(artisan_basic_options),
	"cache:clear" .. flags(artisan_basic_options),
	"cache:table" .. flags(artisan_basic_options),
	"command:make" .. flags(
						"--command",
						"--path",
						"--namespace",
						artisan_basic_options
						),
	"config:publish" .. flags(
						"--path",
						"--force",
						artisan_basic_options
						),
	"controller:make" .. flags(
						"--bench",
						"--only",
						"--except",
						"--path",
						artisan_basic_options
		),
	"db:seed" .. flags(
						"--class",
						"--database",
						"--force",
						artisan_basic_options
						),
	"key:generate" .. flags(artisan_basic_options),
	"migrate:install" .. flags(
						"--database",
						artisan_basic_options
						),
	"migrate:make" .. flags(
						"--bench",
						"--create",
						"--package",
						"--path",
						"--table",
						artisan_basic_options
						),
	"migrate:publish" .. flags(artisan_basic_options),
	"migrate:refresh" .. flags(
						"--database",
						"--force",
						"--seed",
						"--seeder",
						artisan_basic_options
						),
	"migrate:reset" .. flags(
						"--database",
						"--force",
						"--pretend",
						artisan_basic_options
						),
	"migrate:rollback" .. flags(
						"--database",
						"--force",
						"--pretend",
						artisan_basic_options
						),
	"queue:failed" .. flags(artisan_basic_options),
	"queue:failed-table" .. flags(artisan_basic_options),
	"queue:flush" .. flags(artisan_basic_options),
	"queue:forget" .. flags(artisan_basic_options),
	"queue:listen" .. flags(
						"--queue",
						"--delay",
						"--memory",
						"--timeout",
						"--sleep",
						"--tries",
						artisan_basic_options),
	"queue:restart" .. flags(artisan_basic_options),
	"queue:retry" .. flags(artisan_basic_options),
	"queue:subscribe" .. flags(
						"--type",
						artisan_basic_options
						),
	"queue:work" .. flags(
						"--queue",
						"--daemon",
						"--delay",
						"--force",
						"--memory",
						"--sleep",
						"--tries",
						artisan_basic_options),
	"session:table" .. flags(artisan_basic_options),
	"view:publish" .. flags(
						"--path",
						artisan_basic_options
						),
})

clink.arg.register_parser("artisan", artisan_basic_parser)
clink.arg.register_parser("artisan", artisan_command_parser)
