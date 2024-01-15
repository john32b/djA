/**
   Custom Config (TYPE A) (Mednafen Style)
   ----------------------

   - Load a config file
   - Save a config file
   - Keeps the comment structure of fields when saving
   + Recommended file extention : ".cfg"

   + Build to read 'mednafen.cfg' files which has a format like:
		-	;cdplay, Built-In, Controller: Next Track 10
		-	cdplay.input.builtin.controller.next_track_10 keyboard 273


   + Config File Structure --------------------------------------

		# Comments are only valid if [ # ; ] are at the beginning of the line
		; Comment
		# Comment
		# Every field gets associated with all the comments above it

		# This Associates a value to a field
		# Accessible with "ConfigFile.data.field"

			field value

		# You can also declare fields in an object structure


		# The following will be represented as
		# "configfile.data.obj.field" == {a:"100", b:"200"}
			obj.field.a	100
			obj.field.b 200

		# All values are stored as string!
		# 2300 as string in the following example
			fieldB 2300

	+ ---------------------------------------------------------

	+ Use Example:

		var c = new ConfigFileA("settings.ini");
			c.load(); // You can now access "c.data"


		var c = new ConfigFileA("s.ini");
			c.data = { a:100, b:200, c:"hello"};
			c.save(); // will save the settings to "s.ini";

 =============================================================== */

package djA.parser;

import sys.FileSystem;
import sys.io.File;
using StringTools;


class ConfigFileA
{
	// The character to prefix fields that need to be renamed
	// I am choosing this, because you can access it as a variable name
	// e.g.  "data.psx.input._port4" <-> instead of "data.psx.input.port4"
	static inline var FX = "_";

	// The root for all variables on the config
	public var data:Dynamic;

	// FullField -> Comments
	// Useful to keep so I can save it again back
	// e.g. "psx.display.one" -> [ "comment 1", "comment 2"]
	public var comments:Map<String,Array<String>>;

	// This is the {data} object rendered to a text, (almost) ready to be
	// written to a file. Used in `renderNode()`
	// DEV: Is Global, because it is build from a recursive function
	var renderedText:Array<String>;

	// The file path to perform save/load
	public var workingFile(default, null):String;

	// In case of error, read this
	public var ERROR:String;

	//====================================================;

	public function new(?path:String)
	{
		workingFile = path;
		data = {};
		comments = [];
	}//---------------------------------------------------;

	/**
	   Save and overwrite the config file
	   @return
	**/
	public function save(?newFile:String):Bool
	{
		if (newFile != null) workingFile = newFile;
		if (workingFile == null) return err('No file set');
		trace('Saving config to file "$workingFile"');

		renderedText = [];
		renderNode(data);
		try{
			File.saveContent(workingFile, renderedText.join('\n'));
		}catch (e:Any)
		{
			return err('Cannot save "$workingFile" Does the folder exist? Do you have write access?');
		}
		return true;
	}//---------------------------------------------------;


	public function load(?newFile:String):Bool
	{
		if (newFile != null) workingFile = newFile;
		if (workingFile == null) return err('No file set');
		trace('Loading config from file "$workingFile"');

		if (!FileSystem.exists(workingFile))
		{
			return err('File "$workingFile" does not exist');
		}

		// File data
		var lines:Array<String> = File.getContent(workingFile).split('\n');
		var lineNo:Int = 0;

		// Current comments
		var com:Array<String> = [];

		for (l in lines)
		{
			lineNo++;
			l = l.trim();
			// - Empty lines
			if (l.length < 1) continue;
			// - Is it a comment line
			var fc = l.charAt(0);
			if (fc == "#" || fc == ";") {
				com.push(l);
				continue;
			}

			// Typical line should be like this:
			// 	 "psx.display screen1 screen2"
			// but also can have no values
			//   "psx.dbg_exe_cdpath"

			var L = l.split(' ');			// ["psx.display","screen1","screen2"]

			var FIELDS = L[0].split('.');	// I need the field in array format ["psx","display"]
			L.shift(); 						// remove first, since I got it

			var VAL = "";	// This is the rest of the values as a single string "screen1 screen2";
							// If no value it will be left as ""

			if (L.length > 0) VAL = L.join(' ');

			try{
				setFieldFromAr(FIELDS, VAL);
			}catch (e:Dynamic)
			{
				return err('Parse Error, File:$workingFile Line:$lineNo, $e');
			}

			// Write the comments
			comments.set(FIELDS.join('.'), com);

			com = [];

		}// -

		return true;

	}//---------------------------------------------------;

	/**
	   Return the current state of the data as a text document (In an Array, line by line)
	**/
	public function getDocument():Array<String>
	{
		renderedText = [];
		renderNode(data);
		return renderedText;
	}//---------------------------------------------------;

	/**
	   Set a field with a format of "field.sub" on the data object
	**/
	public function set(field:String, v:String)
	{
		setFieldFromAr(field.split('.'), v, true);
	}//---------------------------------------------------;


	/**
	   Remove a field from the DB
	   @param	field Full Field name e.g. "psx.controller.one"
	   @return
	**/
	public function delete(field:String):Bool
	{
		var f = field.split('.'); // [psx, controller, one]
		var i = 0;
		var o = data;
		var sub = f[0];
		while (f.length > 1)
		{
			sub = f.shift();
			o = Reflect.field(o, sub);
			if (o == null) return false;
		}
		return Reflect.deleteField(o, sub);
	}//---------------------------------------------------;

	/**
	   Check if a field exists
	   @param	field Full Field name e.g. "psx.controller.one"
	   @return
	**/
	public function exists(field:String):Bool
	{
		var f = field.split('.');
		var i = 0;
		var o = data;
		while (i < f.length)
		{
			if (!Reflect.hasField(o, f[i])) return false;
			o = Reflect.field(o, f[i]);
			i++;
		}
		return true;
	}//---------------------------------------------------;
	
	/**
	   Get a field value. Null if field does not exist
	   @param	field Full Field name e.g. "psx.controller.one"
	   @return
	**/
	public function get(field:String):String
	{
		var f = field.split('.');
		var i = 0;
		var o = data;
		while (i < f.length)
		{
			if (!Reflect.hasField(o, f[i])) return null;
			o = Reflect.field(o, f[i]);
			i++;
		}
		return o;
	}//---------------------------------------------------;

	/**
	   Clear memory config, does not affect the file.
	**/
	public function clear():Void
	{
		data = {};
		comments = [];
	}//---------------------------------------------------;

	/**
	   PRE: ar length >= 1
	   Translate Array from fields to actual data
		["psx","display","one"] -> object.psx.display.one
	   @param	ar Layout of fields
	   @param	v Value
	**/
	function setFieldFromAr(ar:Array<String>, v:String, overwrite:Bool = false)
	{
		var o:Dynamic = data; // Just a Pointer. Starts pointing to ROOT but can then point to branches
		var i = 0;
		while (i < ar.length - 1)
		{
			var f = Reflect.field(o, ar[i]);
			if (f == null)
			{
				Reflect.setField(o, ar[i], {});
			}
			else if (Std.is(f, String))
			{
				// It already exists and it is string value e.g. "pcfx.input.port4 gamepad"
				// I am going to convert it to "pcfx.input._port4 gamepad"
				// so that the new {} can be written in its place
				Reflect.setField(o, FX + ar[i], f);
				Reflect.setField(o, ar[i], {});
			}

			o = Reflect.field(o, ar[i]);	// Point to the branch now
			i++;
		}

		if (overwrite)
		{
			Reflect.setField(o, ar[i], v);
			return;
		}
		
		// There is a chance this is already an {}
		// So like before, put it in a field with a "_" prefix
		if (Reflect.field(o, ar[i]) == null){
			Reflect.setField(o, ar[i], v);
		}else{
			Reflect.setField(o, FX + ar[i], v);
		}
	}//---------------------------------------------------;


	/**
	   Fills 'renderedText', so make sure to zero it out before calling
	   Translates the data back to full printable config
	   - Also produces field comments that were read from the file
	   - Recursive Function
	**/
	function renderNode(o:Dynamic, path:String = "")
	{
		var f = Reflect.fields(o);
		var i = 0;
		while (i < f.length)
		{
			var v:Dynamic = Reflect.field(o, f[i]);
			var dot = (path.length == 0?"":".");
			if (Std.is(v,String))
			{
				// These are the special fields where {} fields with the same name exist, so they had to be renamed
				// Remove the initial "_"
				if (f[i].charAt(0) == FX) {
					f[i] = f[i].substr(1);
				}
				var str = '$path$dot${f[i]}';
				var com = comments.get(str);
				if (com != null) for (c in com) renderedText.push(c);
				renderedText.push('$str $v');
				// No new line?
			}else{
				renderNode(v, path + dot + f[i]);
			}
			i++;
		}
	}//---------------------------------------------------;


	#if debug
	public function info()
	{
		renderedText = [];
		renderNode(data);
		for (i in renderedText) trace(i);
	}//---------------------------------------------------;
	#end

	// Error Helper
	function err(e:String):Bool
	{
		ERROR = e;
		trace('ERROR : ConfigFileA.hx : ' + e);
		return false;
	}//---------------------------------------------------;

}// --