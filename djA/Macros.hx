package djA;

@:dce
class Macros
{
	public static macro function getProjectPath() {
		return macro $v{ Sys.getCwd() };
    }
	
	// :: 
	// https://code.haxe.org/category/macros/get-compiler-define-value.html	
	// You can set values in project.xml with <haxedef>
	// e.g. <define name="GAME_VER" value="0.1.2" />
	//      djA.Macros.getDefine("GAME_VER") == "0.1.2"
	
	/** Shorthand for retrieving compiler flag values. */
	public static macro function getDefine(key : String) : haxe.macro.Expr {
		return macro $v{haxe.macro.Context.definedValue(key)};
	}

	/** Shorthand for setting compiler flags. */
	public static macro function setDefine(key : String, value : String) : haxe.macro.Expr {
		haxe.macro.Compiler.define(key, value);
		return macro null;
	}

	/** Shorthand for checking if a compiler flag is defined. */
	public static macro function isDefined(key : String) : haxe.macro.Expr {
		return macro $v{haxe.macro.Context.defined(key)};
	}

	/**
	   Adds a null check to a function call
	   SafeCall (shortened)
	**/
	macro public static function sCall(cb:haxe.macro.Expr, ar:Array<haxe.macro.Expr>)
	{
		var e:haxe.macro.Expr = {
			expr:ECall(cb, ar),
			pos:haxe.macro.Context.currentPos()
		};
		
		return macro { if ($cb != null) $e; };
	}//---------------------------------------------------;

}// --