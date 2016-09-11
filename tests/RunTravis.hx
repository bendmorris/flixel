package;

@:enum
abstract Target(String) from String to String
{
	var FLASH = "flash";
	var NEKO = "neko";
	var CPP = "cpp";
	var HTML5 = "html5";
}

@:enum
abstract Command(String) from String to String
{
	var OPENFL = "openfl";
	var NME = "nme";
}

@:enum
abstract ExitCode(Int) from Int to Int
{
	var SUCCESS = 0;
	var FAILURE = 1;
}

class RunTravis
{
	static var importantDemos = ["Mode"];
	static var dryRun:Bool;

	public static function main():Void
	{
		var target:Target = Sys.args()[0];
		if (target == null)
			target = Target.FLASH;
		var command:Command = Sys.args()[1];
		if (command == null)
			command = Command.OPENFL;

		trace(target);
		trace(command);
		
		dryRun = Sys.args().indexOf("-dry-run") != -1;
	
		Sys.exit(getResult([
			generateMunit(),
			setupHxcpp(target),
			runUnitTests(target, command),
			buildCoverageTests(target, command),
			buildSwfVersionTests(target, command),
			buildDemos(target, command),
			buildNextDemos(target, command),
			buildMechanicsDemos(target, command)
		]));
	}
	
	static function generateMunit():ExitCode
	{
		return runInDir("unit", function()
			return haxelibRun(["munit", "gen"])
		);
	}
	
	static function setupHxcpp(target:Target):ExitCode
	{
		if (target != Target.CPP)
			return ExitCode.SUCCESS;

		#if (haxe_ver >= "3.3")
		var hxcppDir = Sys.getEnv("HOME") + "/haxe/lib/hxcpp/git/";
		return getResult([
			runCommand("haxelib", ["git", "hxcpp", "https://github.com/HaxeFoundation/hxcpp"]),
			runCommandInDir(hxcppDir + "tools/run", "haxe", ["compile.hxml"]),
			runCommandInDir(hxcppDir + "tools/hxcpp", "haxe", ["compile.hxml"]),
			runCommandInDir(hxcppDir + "project", "neko", ["build.n"])
		]);
		#else
		return runCommand("haxelib", ["install", "hxcpp"]);
		#end
	}
	
	static function runCommandInDir(dir:String, cmd:String, args:Array<String>):ExitCode
	{
		return runInDir(dir, function() return runCommand(cmd, args));
	}
	
	static function runUnitTests(target:Target, command:Command):ExitCode
	{
		if (target == Target.FLASH || target == Target.HTML5)
		{	
			// can't run / display results without a browser,
			// this at least checks if the tests compile
			Sys.println("Building unit tests...\n");
			return build("unit", target, command);
		}
		else
		{
			Sys.println("Running unit tests...\n");
			return runOpenFL("test", "unit", target, command);
		}
	}
	
	static function buildCoverageTests(target:Target, command:Command):ExitCode
	{
		Sys.println("\nBuilding coverage tests...\n");
		return getResult([
			build("coverage", target, command, "coverage1"),
			build("coverage", target, command, "coverage2")
		]);
	}
	
	static function buildDemos(target:Target, command:Command):ExitCode
	{
		Sys.println("\nBuilding demos...\n");
		var demos = [];
		if (target == Target.CPP)
			demos = importantDemos;
		return buildProjects(target, command, demos);
	}
	
	static function buildNextDemos(target:Target, command:Command):ExitCode
	{
		if (target != Target.NEKO)
			return ExitCode.SUCCESS;
		
		Sys.println("\nBuilding demos for OpenFL Next...\n");
		return buildProjects(target, command, importantDemos.concat(["-Dnext"]));
	}
	
	static function buildMechanicsDemos(target:Target, command:Command):ExitCode
	{
		if (target == Target.CPP)
			return ExitCode.SUCCESS;
		
		Sys.println("\nBuilding mechanics demos...\n");
		runCommand("git", ["clone", "https://github.com/HaxeFlixel/haxeflixel-mechanics"]);
		
		return buildProjects(target, command, ["-dir", "haxeflixel-mechanics"]);
	}
	
	static function buildProjects(target:Target, command:Command, args:Array<String>):ExitCode
	{
		if (command == Command.OPENFL)
		{
			return haxelibRun(["flixel-tools", "bp", target].concat(args));
		}
		else
		{
			Sys.println('\nWARNING: building demos is not currently supported with $command\n');
			return ExitCode.SUCCESS;
		}
	}
	
	static function buildSwfVersionTests(target:Target, command:Command):ExitCode
	{
		if (target == Target.FLASH)
		{
			Sys.println("\nBuilding swf version tests...\n");
			return getResult([
				build("swfVersion/11", target, command),
				build("swfVersion/11_2", target, command)
			]);
		}
		else return ExitCode.SUCCESS;
	}
	
	static function build(path:String, target:Target, command:Command, ?define:String):ExitCode
	{
		return runOpenFL("build", path, target, command, define);
	}
	
	static function runOpenFL(operation:String, path:String, target:Target, command:Command, ?define:String):ExitCode
	{
		var args:Array<String> = [command, operation, path, target];
		if (define != null)
			args.push('-D$define');
		return haxelibRun(args);
	}
	
	static function haxelibRun(args:Array<String>):ExitCode
	{
		return runCommand("haxelib", ["run"].concat(args));
	}
	
	static function getResult(results:Array<ExitCode>):ExitCode
	{
		for (result in results)
			if (result != ExitCode.SUCCESS)
				return ExitCode.FAILURE;
		return ExitCode.SUCCESS;
	}
	
	static function runInDir(dir:String, func:Void->ExitCode):ExitCode
	{
		var oldCwd = Sys.getCwd();
		cd(dir);
		var result = func();
		cd(oldCwd);
		return result;
	}
	
	static function cd(dir:String)
	{
		Sys.println("cd " + dir);
		if (!dryRun)
			Sys.setCwd(dir);
	}
	
	static function runCommand(cmd:String, args:Array<String>):ExitCode
	{
		Sys.println(cmd + " " + args.join(" "));
		if (dryRun)
			return ExitCode.SUCCESS;
		return Sys.command(cmd, args);
	}
}
