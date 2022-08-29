/**
 * Geometry and Collision functions
 * ...
 */
 
package djA;

@:dce
class Geom
{
	
	public static function rectHasPoint(x0:Float, y0:Float, w:Float, h:Float, x:Float, y:Float):Bool
	{
		return (x >= x0 && y >= y0 && x <= (x0 + w) && y <= (y0 + h));
	}//---------------------------------------------------;
	
	
	public static function rectsOverlap(ax:Float, ay:Float, aw:Float, ah:Float, bx:Float, by:Float, bw:Float, bh:Float):Bool
	{
		return ((ax + aw > bx) &&
				(ax < bx + bw) &&
				(ay + ah > by) &&
				(ay < by + bh));
	}//---------------------------------------------------;
	
	
	// https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
	//
	public static var LI_X:Float;
	public static var LI_Y:Float;
	public static function linesIntersect(	p0_x:Float, p0_y:Float, p1_x:Float, p1_y:Float,
											p2_x:Float, p2_y:Float, p3_x:Float, p3_y:Float):Bool
	{
		var s1_x = p1_x - p0_x;
		var s1_y = p1_y - p0_y;
		var s2_x = p3_x - p2_x;    
		var s2_y = p3_y - p2_y;
		var dem = -s2_x * s1_y + s1_x * s2_y;
		var s = ( -s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / dem;
		var t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / dem;
		
		if (s >= 0 && s <= 1 && t >= 0 && t <= 1)
		{
			// Collision detected
			LI_X = p0_x + (t * s1_x); // Points of intersection
			LI_Y = p0_y + (t * s1_y);
			return true;
		}
		
		return false;
	}//---------------------------------------------------;
	
	
}// --