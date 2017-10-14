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
	"--version", "-V",
	"--ansi",
	"--no-ansi",
	"--no-interaction", "-n",
	"--env",
	"--verbose", "-v", "-vv", "-vvv",
}

local artisan_basic_parser = clink.arg.new_parser()
artisan_basic_parser:set_flags(artisan_basic_options)
artisan_basic_parser:set_arguments({
	"clear-compiled",
	"down",
	"env",
	"help",
	"inspire",
	"list",
	"migrate",
	"optimize",
	"serve",
	"tinker",
	"up",
})

local artisan_command_parser = clink.arg.new_parser()
artisan_command_parser:set_arguments({
	"app:name" .. flags(artisan_basic_options),
	"auth:clear-resets" .. flags(artisan_basic_options),
	"cache:clear" .. flags(artisan_basic_options),
	"cache:table" .. flags(artisan_basic_options),
	"config:cache" .. flags(artisan_basic_options),
	"config:clear" .. flags(artisan_basic_options),
	"db:seed" .. flags(
						"--class",
						"--database",
						"--force",
						artisan_basic_options
						),
	"event:generate" .. flags(artisan_basic_options),
	"key:generate" .. flags(
						"--show",
						artisan_basic_options
						),
	"make:auth" .. flags(
						"--views",
						artisan_basic_options
						),
	"make:console" .. flags(
						"--command",
						artisan_basic_options
						),
	"make:controller" .. flags(
						"--resource",
						artisan_basic_options
						),
	"make:event" .. flags(artisan_basic_options),
	"make:job" .. flags(
						"--queued",
						artisan_basic_options
						),
	"make:listener" .. flags(
						"--event",
						"--queued",
						artisan_basic_options
						),
	"make:middleware" .. flags(artisan_basic_options),
	"make:migration" .. flags(
						"--create",
						"--table",
						artisan_basic_options
						),
	"make:model" .. flags(
						"--migration", "-m",
						"--table",
						artisan_basic_options
						),
	"make:policy" .. flags(artisan_basic_options),
	"make:provider" .. flags(artisan_basic_options),
	"make:request" .. flags(artisan_basic_options),
	"make:seeder" .. flags(artisan_basic_options),
	"make:test" .. flags(artisan_basic_options),
	"migrate:install" .. flags(
						"--database",
						artisan_basic_options
						),
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
	"migrate:status" .. flags(
						"--database",
						"--path",
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
	"queue:table" .. flags(artisan_basic_options),
	"queue:work" .. flags(
						"--queue",
						"--daemon",
						"--delay",
						"--force",
						"--memory",
						"--sleep",
						"--tries",
						artisan_basic_options),
	"route:cache" .. flags(artisan_basic_options),
	"route:clear" .. flags(artisan_basic_options),
	"route:list" .. flags(
						"--name",
						"--path",
						artisan_basic_options
						),
	"schedule:run" .. flags(artisan_basic_options),
	"session:table" .. flags(artisan_basic_options),
	"vendor:publish" .. flags(
						"--force",
						"--provider",
						"--tag",
						artisan_basic_options
						),
	"view:clear" .. flags(artisan_basic_options),
})

clink.arg.register_parser("artisan", artisan_basic_parser)
clink.arg.register_parser("artisan", artisan_command_parser)
