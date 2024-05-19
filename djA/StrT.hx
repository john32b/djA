/********************************************************************
* String Tools, General Purpose Helpers
*
*******************************************************************/
package djA;

@:dce
class StrT
{
	// Can be externally set.
	// Used in functions that can cut a string to fit to a space
	public static var OVERFLOW = "-";

	/**
	   Quick check
	**/
	public static function isEmpty(str:String):Bool
	{
		return (str==null || str.length==0);
	}//---------------------------------------------------;

	/**
	   Produce a line
	   DEV: ─ -
	**/
	inline public static function line(len:Int, symbol:String = '─'):String
	{
		return rep(len, symbol);
	}//---------------------------------------------------;

	/**
	 * Quick Repeat
	 **/
	public static function rep(len:Int, symbol:String):String
	{
		return StringTools.lpad('', symbol, len);
	}//---------------------------------------------------;


	/**
	 * Loops a string to itself, useful for scrolling effects
	 *
	 * @param	source The string to be looped
	 * @param	length The length which the source will be wrapped to
	 * @param	offset Offset for scrolling. no limit at the int.
	 * @return
	 */
	public static function loopString(source:String, length:Int, offset:Int):String
	{
		var str:String = "";
		var _loopCounter = 0;

		while (_loopCounter < length) {
			// I use Modulo to stay in bounds of the source string
			str += source.charAt((_loopCounter + offset) % source.length);
			_loopCounter++;
		}

		return str;
	}//---------------------------------------------------;


	/**
	 * Cut a string in lines that fit in a target width
	 * words that are too long will be trimmed
	 *
	 * e.g.
	 * ```
	 *   splitToLines("hello world this is a test",7) =
	 *                [ "hello","world","this is","a test" ]
	 * ```
	 *
	 * @param	str The string to be sliced
	 * @param	width Target line width
	 * @return  Array with lines
	 */
	public static function splitToLines(str:String, width:Int):Array<String>
	{
		// Replace /n with the custom placeholder string #nl#
		str = ~/(\n)/g.replace(str, " #nl# ");
		// Replace any whitespace with ' ' for safeguarding
		str = ~/(\s|\t)/g.replace(str, " ");

		// Break string to an array, for easy traversing
		var ar = str.split(" ");

		var result:Array<String> = [];

		// Helper vars
		var f = 0;
		var fmax = ar.length;
		var clen = 0;	// current temp line length
		var line = "";  // temp line
		var _ll = 0;	// current word length

		// Reduce redundancy by creating this internal function
		var ___ffpush = function(s:String) {
			result.push(s);
			clen = 0; line = "";
		};

		// Start processing all words in the array
		do {

			// if word is a new line, add a blank line to the array
			if (ar[f] == '#nl#') {
				___ffpush(line);
				continue;
			}

			_ll = ar[f].length;

			// if line length is less than target width, it fits ok.
			if ((_ll + clen) < width)
			{
				line += ar[f] + " ";
				clen += _ll + 1;
			}
			else if ((_ll + clen) > width)	// Longer than what line can fit
			{
				// Push current line, add the word that didn't fit to next line
				if (clen > 0)
				{
					result.push(line);
					line = ar[f] + " ";
					clen = _ll + 1;
				}else
				{
					// if a word is TOO BIG and can't fit, trim it.
					line = ar[f].substring(0, width - 1) + OVERFLOW;
					___ffpush(line);
				}
			}
			else // line is equal to target width, just add it with no blank space afterwards
			{
				___ffpush(line + ar[f]);
			}

		}while (++f < fmax); //-- end loop --//

		// post-loop check for any unprocessed data
		if (clen > 0) ___ffpush(line);

		return result;
	}//---------------------------------------------------;

	/**
		Fit a string to a width, will either TRIM or FILL
		- Hard trim
		- Right Pad, will fill string to the right
	**/
	public static function fit(str:String, len:Int, char:String = " "):String
	{
		if(str.length>len) return str.substr(0, len);
		return StringTools.rpad(str, char, len);
	}// -------------------------;

	/**
		Fit a string to a width, will either TRIM or FILL. More options than `fit()`
		- Supports alignment if string is shorter than target width
		- Appends an Overflow symbol when the string is cut. Stored in `StrT.OVERFLOW`, you can change it.
		@param str string
		@param len target length
		@param align `l,c,r` center, right align only when string fits into length
		@param char Character to pad the empty spaces. Default is space
	**/
	public static function fit2(str:String, len:Int, align:String = "l", char:String = " "):String
	{
		var b:Int = len - str.length;
		// String already in target length
		if (b == 0) return str;
		// The string needs to be cut
		if (b < 0) {
			return str.substr(0, len - 1) + OVERFLOW;
		}
		// The string needs to be padded
		switch (align) {
			case "r":
				str = StringTools.lpad(str, char, len);
			case "c":
				var _l = Math.ceil(b / 2);
				var _r = Math.floor(b / 2);
				str = 	StringTools.rpad("", char, _l ) +
						str +
						StringTools.rpad("", char, _r );
			default: 
				str = StringTools.rpad(str, char, len);
		}
		return str;
	}//---------------------------------------------------;


	/**
		Convert a Float to String and force the fraction digits
		*e.g. 23 -> "23.00"* Longer fractions are going to be cut
	**/
	public static function fraction(num:Float, digits:Int = 2):String
	{
		var s = '' + num;
		var i = s.indexOf('.');
		if (i < 0) {
			if (digits > 0)
				s += '.' + rep(digits, '0');
		}else{
			var f = s.split('.');
			s = f[0] + '.' + fit(f[1], digits, "0");
		}
		return s;
	}// -------------------------;

	@:deprecated("Use fit2()")
	public static function padString(str:String, length:Int, align:String = "l", char:String = " "):String
	{
		return fit2(str,length,align,char);
	}// -------------------------;

}//-- end --//
