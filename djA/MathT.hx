/********************************************************************
 * Various Helper Math Functions
 * 
 *******************************************************************/
package djA;

@:dce
class MathT
{
	/**
	 * Return a random number which is in between a range
	 * 
	 * @param	from Minimum
	 * @param	to Maximum
	 */
	public static inline function randomRange(from:Int, to:Int):Int
	{
		return Math.ceil(Math.random() * (to - from)) + from;
	}//---------------------------------------------------;
	
	
	// Taken from Franco Ponticelli's THX library:
	// https://github.com/fponticelli/thx/blob/master/src/Floats.hx#L206
	public static function roundFloat(number:Float, ?precision=2):Float
	{
		number *= Math.pow(10, precision);
		return Math.round(number) / Math.pow(10, precision);
	}//---------------------------------------------------;
	
}//-- end class --//