/********************************************************************
 * Various Helper Math Functions
 * 
 *******************************************************************/
package djA;

@:dce
class MathT
{

	public static function randInt(a:Int, b:Int):Int
	{
		return (Math.floor(Math.random() * (b - a + 1)) + a);
	}//---------------------------------------------------;
	
	
	public static function randFloat(a:Float, b:Float):Float
	{
		return (Math.random() * (b - a)) + a;
	}//---------------------------------------------------;
	
	/**
	 * Return a random number which is in between a range
	 * @param	from Minimum
	 * @param	to Maximum
	 */
	public static inline function randomRange(from:Int, to:Int):Int
	{
		return Math.ceil(Math.random() * (to - from)) + from;
	}//---------------------------------------------------;
	
	/** 
	    Round a float to a specific precision
	    Taken from Franco Ponticelli's THX library:
		https://github.com/fponticelli/thx/blob/master/src/Floats.hx#L206
	**/
	public static function roundFloat(number:Float, ?precision=2):Float
	{
		number *= Math.pow(10, precision);
		return Math.round(number) / Math.pow(10, precision);
	}//---------------------------------------------------;
	
	
	/**
	   Clamp Number (n) between (a) and (b)
	**/
	public static function clampFloat(n:Float, a:Float, b:Float):Float
	{
		if(n < a) return a;
		if(n > b) return b;
		return n;
	}//---------------------------------------------------;


	/**
		Get fraction digits len of a number
	**/
	public static function fractionLen(num:Float):Int
	{
		var s = '$num'.split('.');
		return (s[1]==null)?0:s[1].length;
	}// -------------------------;
	
	/**
	   Clamp INT to be inside Array Length
	**/
	public static function clampArrayLen<T>(n:Int, ar:Array<T>):Int
	{
		if (n < 0) return 0;
		if (n >= ar.length) return ar.length - 1;
		return n;
	}//---------------------------------------------------;
	
	/**
		Imprecise method, does not guarantee v = v1 when t = 1, due to floating-point arithmetic error.
	 */
	public static function lerp(a:Float, b:Float, t:Float):Float
	{
		return a + ((b - a) * t);
	}//---------------------------------------------------;
	
	/**
		Precise method, which guarantees v = v1 when t = 1.
	**/
	public static function lerp2(a:Float, b:Float, t:Float):Float
	{
		return a * (1 - t) + t * b;
	}//---------------------------------------------------;
	
	
	public static inline function toDegr(v:Float):Float
	{
		return v * (180 / Math.PI);
	}

	public static inline function toRads(v:Float):Float
	{
		return v * (Math.PI / 180);
	}
	
}//-- end class --//