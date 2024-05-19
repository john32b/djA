 /**
	General Purpose Data oriented Helpers
 **/

package djA;

@:dce
class DataT 
{

	/**
		- Copy an object's fields into target object. Overwrites the target object's fields. 
		- Works Recursively for objects inside objects
		- Can work with Static Classes as well (as destination)
			(you need to cast the returned object for this to work)
		@param	node The Source object to copy fields from
		@param	into The Target object to copy fields to
		@return	A new object
	 */
	public static function copyFields(from:Dynamic, into:Dynamic):Dynamic
	{
		if (from == null)
		{
			return copyDeep(into);
		}
		
		if (into == null) 
		{
			into = copyDeep(from);
		}else
		{
			for (f in Reflect.fields(from)) {
				if (Reflect.isObject(Reflect.field(from, f)) &&
					Type.getClass(Reflect.field(from, f)) == null) {
						// Devnote: ^checks to see if it is an anonymous object
						Reflect.setField(into, f, copyFields(Reflect.field(from, f), Reflect.field(into, f)));
					}else{
						Reflect.setField(into, f, Reflect.field(from, f));
					}
			}
		}
		
		return into;
	}//---------------------------------------------------;	
	
	
	/**
	   Return a deep copy of an anonymous object. 
	   *Will copy all sub-objects as well*
	   @param	o The object to clone
	   @return A new object
	**/
	public static function copyDeep(o:Dynamic):Dynamic
	{
		if(o==null) return null;
		return copyFields(o,{});
	}//---------------------------------------------------;


	/**
		Try to Parse a string as Int
		- Returns Int value
		- If cannot parse will return `0`
	**/
	public static function intOrZeroFromStr(str:String):Int
	{
		if (str == null) return 0;
		var RES = Std.parseInt(str);
		if (RES == null) return 0;
		return RES;
	}//---------------------------------------------------;
	

	/**
		Try to Parse a string as Float
		- Returns Float value
		- If cannot parse will return `0.0`
	**/
	public static function floatOrZeroFromStr(str:String):Float
	{
		if (str == null) return 0.0;
		var RES = Std.parseFloat(str);
		if (Math.isNaN(RES)) return 0.0;
		return RES;
	}//---------------------------------------------------;


	/**
	   Useful to get default values from object fields
	   @param	a Object Fields
	   @param	v Default Value
	   @return
	**/
	public static function existsOr(a:Dynamic, v:Any):Any
	{
		if (a == null) return v; return a;
	}//---------------------------------------------------;


	/**
	   Convert a CSV string to HashTable. 
	   - Supports flags,  `{type:10, flag01}`, then check with `.exists(...)`
	   - Supports whitespace between identifiers, e.g. `{  type  : 20,  lives   : 40    }` is valid
	   - *Note* Numeric values are parsed as strings!
	   e.g. `getCSVTable("lives:10,speed:30,flag01") ==> [ 'lives'=>'10', 'speed'=>'30', 'flag01'=>'' ]`
	   @param	csv Format `id:value,id2:value...`
	   @return	Map object
	**/
	public static function getCSVTable(csv:String):Map<String,String>
	{
		if (csv == null) return null;
		var M:Map<String,String> = [];
		var pairs = csv.split(',');
		for (p in pairs) {
			p = StringTools.trim(p);
			var d = p.split(':');
			if (d.length == 1){
				M.set(d[0], "");
			}else{
				M.set(d[0], d[1]);
			}
		}
		return M;
	}//---------------------------------------------------;
	

	/**
	   Convert a CSV string to an Dynamic Object
	   Values as strings
	   e.g. "getCSVObj("lives:10,speed:30") ==> { lives:'10', speed:'30' }
	   @param	csv
	   @return
	**/
	public static function getCSVObj(csv:String):Dynamic
	{
		if (csv == null) return null;
		var O:Dynamic = {};
		var pairs = csv.split(',');
		for (p in pairs) {
			var d = StringTools.trim(p).split(':');
			Reflect.setField(O, d[0], d[1]);
		}
		return O;
	}//---------------------------------------------------;
	
	
	/**
		Rounds a float with target precision
		Taken from Franco Ponticelli's THX library:
		https://github.com/fponticelli/thx/blob/master/src/Floats.hx#L206
	**/
	public static function roundFloat(number:Float, ?precision=2): Float
	{
		number *= Math.pow(10, precision);
		return Math.round(number) / Math.pow(10, precision);
	}//---------------------------------------------------;
	
	
	/**
		Get a random element from an array
	 */
	inline public static function randAr<T>(ar:Array<T>):T 
	{
		return ar[Std.random(ar.length)];
	}//---------------------------------------------------;

    /** 
		Get the last element of an array
     */
    inline public static function lastAr<T>(ar:Array<T>):T
    {
        return ar[ar.length - 1];
    }//---------------------------------------------------;

	
	/**
		Generate a GUID string
		https://github.com/jdegoes/stax/blob/master/src/main/haxe/haxe/util/Guid.hx
	**/
	 public static function getGUID(): String 
	 {
		var result = "";
		for (j in 0...32) {
		if ( j == 8 || j == 12 || j == 16 || j == 20) { result += "-"; }
		result += StringTools.hex(Math.floor(Math.random() * 16)); }	
		return result.toUpperCase();
	}//---------------------------------------------------;
	
	/**
		Converts bytes to megabytes. Useful for creating human readable filesizes.
		@param	bytes Number of bytes to convert
	 */
	public static function bytesToMBStr(bytes:Int):String {
		return Std.string( Math.ceil( bytes / (1024 * 1024)));
	}//---------------------------------------------------;
	

	@:deprecated("Use one of the StrT.hx functions")
	public static function padTrimString(str:String, size:Int, char:String = ".", leftPad:Bool = true):String
	{
	}//---------------------------------------------------;

}// --