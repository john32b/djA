/**
   Custom Config (TYPE B) (Ini Style)
 ===============================

 - Parser only, you need to load the file yourself

 - Check the example file "docs/ConfigFile_Example.ini"

  == Development TODO:
	- Arrays ?

  == Example:

	var INI = new ConfigFile("assets\config.ini");
	var settings = INI.getObjEx('settings');
		trace(settings.volume);
		trace(settings.musicEnabled);
		trace(settings.fullscreen);

 == NOTE:
	- Currently works with just parsing the data, you have to load files yourself outside of this class
	- Remember the data object is readable, so I can do this: data.get('settings'); // And it will give me a MAP

 =============================================================== */

package djA.cfg;

class ConfigFileB
{
	static inline var OBJEX_NUM_SYMBOL = "#";
	static inline var STRING_TERMINATOR = "\\e";
	static inline var FORCE_EMPTYLINES = "\\l";

	static var NEWLINES = ["\n", "\r", "r\n"];		// These are for checks only. New newlines are "\n"
	static var COMMENTS = ["#", ";"];
	static var NO_NEW_LINE = "\\";

	static var reg_section:EReg = ~/^\[([^\]]+)\]/;			// Capture []
	static var reg_def:EReg = ~/^([^(){}:=]+)[:=](.*)/;		// Capture something=value

	public var data(default, null):Map<String, Map<String, String>>;	// [section] => { field=value }

	//====================================================;

	public function new(cont:String=null)
	{
		data = new Map();
		if (cont != null) parse(cont);
	}//---------------------------------------------------;

	public function parse(contents:String)
	{
		var cSect:String = null;	// Currently open section
		var v1:String = null;
		var v2:String = null;
		var isMultiLine = false;

		// Save (Key->Value) to the DB based on current cSect and (v1,v2)
		var _saveKeyVal = ()->{
			var b:Map<String,String>;
			if (!data.exists(cSect)) {
				b = [];
				data.set(cSect, b);
			}else {
				b = data.get(cSect);
			}
			b.set(v1, v2); // Will write back to data, since this is a pointer
		}// --

		// Loop for every line
		for (line in contents.split('\n'))
		{
			// ALL lines trim left and right
			var lineT = StringTools.trim(line);
			if (lineT.length == 0){
				if (isMultiLine){
					v2 += '\n';
				}
				continue;
			}

			if (COMMENTS.indexOf(lineT.charAt(0)) >= 0) continue;

			// :: Match [SECTION]
			if (reg_section.match(lineT))
			{
				if (cSect != null) {
					// Save the previous KEY in section
					if (v1 != null) {
						if (v2 == null) throw 'Key "$v1" does not have a value defined';
						_saveKeyVal();
					}
				}

				cSect = reg_section.matched(1);
				v1 = v2 = null;
				isMultiLine = false;
				continue;
			}

			// :: Match "KEY=VALUE"
			if (reg_def.match(lineT))
			{
				if (cSect == null) {
					throw "Parse Error, Variable needs to be in a [section]";
				}

				// Save the previous KEY in section
				if (v1 != null) {
					if (v2 == null) throw 'Parse Error: Key "$v1" does not have a value defined';
					_saveKeyVal();
				}

				v1 = reg_def.matched(1);
				v2 = reg_def.matched(2);
				v1 = StringTools.rtrim(v1);	// It was trimmed on the left, when the line got trimmed
				v2 = StringTools.ltrim(v2);	// It was trimmed on the right, when the line got trimmed
				isMultiLine = false;

				if (v2 == FORCE_EMPTYLINES){
					isMultiLine = true;
					v2 = "";	// Remove the symbol
				}
				continue;
			}

			// :: Neither [section] nor [key=val]
			//    So it must be a plain text line

			if (v1 == null) {
				throw 'Parse Error: Value defined outside of a key ($line)';
			}

			isMultiLine = true;

			// This is when a definition is empty like "lives=" and the next line should have something
			if (v2 == null || v2.length == 0) {
				v2 = StringTools.rtrim(line);
				continue;
			}

			if (lineT == STRING_TERMINATOR)	{
				// end parsing
				// :this will make emptylines skip from the next line
				isMultiLine = false;
				continue;
			}


			// V2 is not null, and is probably TEXT so::
			if (v2.charAt(v2.length - 1) == NO_NEW_LINE) {
				v2 = v2.substr(0, -1);	// remove last character
				v2 = v2 + lineT;	// I want left trim and right trim is always, so put the full trimmed line there
			}else{
				// Left whitespace stays, trim the right only
				v2 = v2 + '\n' + StringTools.rtrim(line);
			}

		}// -- end loop

		if (v1 != null) {
			if (v2 == null) throw 'Parse Error: Key "$v1" does not have a value defined';
			_saveKeyVal();
		}

	}//---------------------------------------------------;

	public function exists(section:String, key:String):Bool
	{
		return data.exists(section) && data[section].exists(key);
	}//---------------------------------------------------;

	/**
	   Get a SECTION/KEY value. If Something does not exist null is returned
	**/
	public function get(section:String, key:String):String
	{
		var s = data.get(section);
		if (s != null) return s.get(key);
		return null;
	}//---------------------------------------------------;

	/**
	   Return a text field of multiple lines as an Array
	   @param	section
	   @param	key
	   @return
	**/
	public function getTextArray(section:String, key:String):Array<String>
	{
		if (!exists(section, key)) return null;
		var raw = get(section, key).split('\n');
		var res:Array<String> = [];
		for (l in raw){
			var line = StringTools.trim(l);
			if (line.length == 0) continue;
			res.push(line);
		}
		return res;
	}//---------------------------------------------------;

	/**
	   Fill an object with fields of a section
	   - All fields are written as string
	   - Works ok in most cases, You can assign strings to float or ints in some functions
	   - If you pass an object it will overwrite the new fields it discovers
	**/
	public function getObj(section:String, ?obj:Dynamic):Dynamic
	{
		if (obj == null) obj = {};
		var sect = data.get(section);
		for (k => v in sect) {
			Reflect.setField(obj, k, v);
		}
		return obj;
	}//---------------------------------------------------;


	/**
	   Fill an object with fields of a section, but this time will set the type to FLOAT or INT
	   for fields you have declared as numbers. Put a # in front of a number to force Number mode
	   Float/Int will automatically be determined
		number_int = #5
		number_float = #5.5
		number_float2 = #1.0 // It has a dot, so parsed as float
		string = string
		string2= 230-stringalso
		bool1 = true
	**/
	public function getObjEx(section:String, ?obj:Dynamic):Dynamic
	{
		if (obj == null) obj = {};
		var TF = ["true", "false"];
		var sect = data.get(section);

		for (k => v in sect) {
			if (v.charAt(0) == OBJEX_NUM_SYMBOL) { // :: Number, need to try int or float
				var str = v.substr(1);
				var num:Float = Std.parseFloat(str);
				if (num % 1 != 0){
					// FLOAT
					Reflect.setField(obj, k, num);
				}else{
					// INT
					Reflect.setField(obj, k, Std.int(num));
				}
			}else{ // :: It is BOOL or a STRING

				if (v == "true") { Reflect.setField(obj, k, true); } else
				if (v == "false") { Reflect.setField(obj, k, false); } else
				Reflect.setField(obj, k, v);
			}
		}
		return obj;
	}//---------------------------------------------------;

}// --
