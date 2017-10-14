--
-- Copyright (c) 2014 Shengyou Fan
--

--------------------------------------------------------------------------------
local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

local composer_basic_options = {
	"--help", "-h",
	"--quiet", "-q",
	"--verbose", "-v", "-vv", "-vvv",
	"--version", "-V",
	"--ansi",
	"--no-ansi",
	"--no-interaction", "-n",
	"--profile", "--no-plugins",
	"--working-dir" , "-d"
}

local composer_basic_parser = clink.arg.new_parser()
composer_basic_parser:set_flags(composer_basic_options)
composer_basic_parser:set_arguments({
	"about" .. flags(composer_basic_options),            
	"archive" .. flags(
						"--format", "-f",
						"--dir",
						composer_basic_options
						),          
	"browse" .. flags(
						"--homepage", "-H",
						"--show", "-s",
						composer_basic_options
						),           
	"clear-cache" .. flags(composer_basic_options),      
	"clearcache" .. flags(composer_basic_options),       
	"config" .. flags(
						"--global", "-g",
						"--editor", "-e",
						"--auth", "-a",
						"--unset",
						"--list", "-l",
						"--file", "-f",
						"--absolute",
						composer_basic_options
						),           
	"create-project" .. flags(
						"--stability", "-s",
						"--prefer-source",
						"--prefer-dist",
						"--repository-url",
						"--dev",
						"--no-dev",
						"--no-plugins",
						"--no-custom-installers",
						"--no-scripts",
						"--no-progress",
						"--keep-vcs",
						"--no-install",
						"--ignore-platform-reqs",
						composer_basic_options
						),   
	"depends" .. flags(
						"--link-type",
						composer_basic_options
						),          
	"diagnose" .. flags(composer_basic_options),         
	"dump-autoload" .. flags(
						"--optimize", "-o",
						"--no-dev",
						composer_basic_options
						),    
	"dumpautoload" .. flags(
						"--optimize", "-o",
						"--no-dev",
						composer_basic_options
						),
	"exec" .. flags(
						"--list", "-l",
						composer_basic_options
						),
	"global" .. flags(composer_basic_options),           
	"help" .. flags(
						"--xml",
						"--format",
						"--raw",
						composer_basic_options
						),             
	"home" .. flags(
						"--homepage", "-H",
						"--show", "-s",
						composer_basic_options
						),
	"info" .. flags(
						"--installed", "-i",
						"--platform", "-p",
						"--available", "-a",
						"--self", "-s",
						"--name-only", "-N",
						"--path", "-P",
						composer_basic_options
						), 
	"init" .. flags(
						"--name",
						"--description",
						"--author",
						"--type",
						"--homepage",
						"--require",
						"--require-dev",
						"--stability", "-s",
						"--license", "-l",
						composer_basic_options
						),             
	"install" .. flags(
						"--prefer-source",
						"--prefer-dist",
						"--dry-run",
						"--dev",
						"--no-dev",
						"--no-plugins",
						"--no-custom-installers",
						"--no-scripts",
						"--no-progress",
						"--optimize-autoloader", "-o",
						"--ignore-platform-reqs",
						composer_basic_options
						),          
	"licenses" .. flags(
						"--format", "-f",
						"--no-dev",
						composer_basic_options
						),         
	"list" .. flags(
						"--xml",
						"--format",
						"--raw"
						),
	"outdated" .. flags(
						"--outdated", "-o",
						"--all", "-a",
						"--direct", "-D",
						composer_basic_options
						),      
	"prohibits" .. flags(
						"--recursive", "-r",
						"--tree", "-t",
						composer_basic_options
						),
	"remove" .. flags(
						"--dev",
						"--no-progress",
						"--no-update",
						"--update-no-dev",
						"--update-with-dependencies",
						"--ignore-platform-reqs",
						composer_basic_options
						),           
	"require" .. flags(
						"--dev",
						"--prefer-source",
						"--prefer-dist",
						"--no-progress",
						"--no-update",
						"--update-no-dev",
						"--update-with-dependencies",
						"--ignore-platform-reqs",
						"--sort-packages",
						composer_basic_options
						),          
	"run-script" .. flags(
						"--dev",
						"--no-dev",
						"--list", "-l",
						composer_basic_options
						),       
	"search" .. flags(
						"--only-name","-N",
						composer_basic_options
						),           
	"self-update" .. flags(
						"--rollback","-r",
						"--clean-backups",
						"--no-progress",
						composer_basic_options
						),      
	"selfupdate" .. flags(
						"--rollback","-r",
						"--clean-backups",
						"--no-progress",
						composer_basic_options
						),       
	"show" .. flags(
						"--installed","-i",
						"--platform","-p",
						"--available","-a",
						"--self","-s",
						"--name-only","-N",
						"--path","-P",
						composer_basic_options
						),             
	"status" .. flags(composer_basic_options),     
	"suggests" .. flags(
      					"--by-package",
      					"--by-suggestion",
      					"--no-dev",
						composer_basic_options
						),
	"update" .. flags(
						"--prefer-source",
						"--prefer-dist",
						"--dry-run",
						"--dev",
						"--no-dev",
						"--lock",
						"--no-plugins",
						"--no-custom-installers",
						"--no-autoloader",
						"--no-scripts",
						"--no-progress",
						"--with-dependencies",
						"--optimize-autoloader","-o",
						"--ignore-platform-reqs",
						"--prefer-stable",
						"--prefer-lowest",
						composer_basic_options
						),           
	"validate" .. flags(
						"--no-check-all",
						"--no-check-publish",
						composer_basic_options
						),
	"why" .. flags(
						"--recursive", "-r",
						"--tree", "-t",
						composer_basic_options
						),
	"why-not" .. flags(
						"--recursive", "-r",
						"--tree", "-t",
						composer_basic_options
						)
})

clink.arg.register_parser("composer", composer_basic_parser)
clink.arg.register_parser("composer", composer_basic_options)