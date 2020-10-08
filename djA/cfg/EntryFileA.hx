/********************************************************************
 * Entry File Parser Type A
 * -------------------------
 * 
 * . Parses custom entry files, with entries separated with a '-----' line
 * . Dash line can be of variable length (min 2)
 * . AutoTrimmed left/right
 * . Entries are stored in an Array of Array<String>
 * . Can also save back to the file
 * . Comments read are saved back at the beginning of the file
 * 
 ** Example: ******************************************************* 
	
	# Comment Line ignored
	Entry Title
		Line 1
		%line 2
		$valid line
		-valid line. because it starts with a single '-'
		// note that ----- is a separator to the next entry
	-----
	
	Entry 02
		%userprofile%\AppData\appfolder\test
		#this comment line will be ignored
		001 ; value
		003 # This is not a comment, a comment should be at the start of a line
		- NOTE : All lines are AUTO-TRIMMED, left and right,
	-----
	
*******************************************************************/

package djA.cfg;

import Array;
import String;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
using StringTools;

class EntryFileA 
{
	// The file associated with the this object
	var pathFile:String;
	var DB_COMMENTS:Array<String>;	// Holds all the comments that are read
	
	public var DB:Array<Array<String>>;	// You an directly write to this, but be careful
	
	// In case of error, read this
	public var ERROR:String = "";
	
	public function new(P:String) 
	{
		pathFile = P;
		DB = [];
		DB_COMMENTS = [];
	}//---------------------------------------------------;
	
	
	/**
	   Add an entry to the DB
	   @param	a Array of strings.
	**/
	public function add(a:Array<String>)
	{
		DB.push(a);
	}//---------------------------------------------------;
	
	
	/**
	   Saves current DB state to the associated file
	   @return success
	**/
	public function save():Bool
	{
		if (DB.length == 0)
		{
			trace("Warning: No entries to save"); return true;
		}
		
		trace('Saving to `$pathFile`');
		
		// File Contents to be written:
		var FC:String = DB_COMMENTS.join('\n');
			FC += '\n\n';
			
		for (entry in DB) {
			// Dev I want to limit the times 'D' gets written, for speed
			var p = "";
			for (line in entry)	{
				p += line;
				p += '\n';	
			}
			p += '--------\n';
			FC += p;
		}
		
		try{
			File.saveContent(pathFile, FC);
		}catch (e:Dynamic){
			trace(e);
			return err('Cannot write to file `$pathFile`');
		}
		
		return true;
	}//---------------------------------------------------;
	
	
	/**
	   Load the Entry File and Parse it into the DB variable
	   @param	path
	   @return Success
	**/
	public function load():Bool
	{
		if (!FileSystem.exists(pathFile))
		{
			return err('File "$pathFile" does not exist');
		}
		
		trace('Loading `$pathFile`');
		
		var lines:Array<String> = File.getContent(pathFile).split('\n');
		var lineNo:Int = 0;
		// Current entry being read
		var entr:Array<String> = [];
		for (l in lines)
		{
			lineNo++;
			l = l.trim();
			if (l.length < 1 ) continue;			// empty lines
			if (l.charAt(0) == "#") 				// comments
			{
				DB_COMMENTS.push(l);
				continue;
			}
			
			if (l.substr(0, 2) == '--') // Next Entry
			{
				// If current game has data, push it 
				if (entr.length > 0) {
					DB.push(entr);
					entr = [];
				}
				continue;
			}
			
			entr.push(l);
		}
		
		// - Check if user forgot to put (----) after the last entry
		if (entr.length > 0)
		{
			DB.push(entr);
		}
		
		trace('Parsed [OK]. Entries = `${DB.length}`');
		
		return true;
	}//---------------------------------------------------;
	
	// Error Helper
	function err(e:String):Bool
	{
		ERROR = e;
		trace('ERROR : EntryFileA.hx : ' + e);
		return false;
	}//---------------------------------------------------;
	
}// --