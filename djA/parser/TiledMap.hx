/******************************************************************************
  TILED MAP LOADER 
  ----------------
  Loads and parses .TMX maps (tiled Editor)
  = NOT 100% Full featured, but the basics are there. 
  = Working with MAP VERSION == 1.4 (other version uncheched)
  
  What Works
  ----------
  
	- Requires:
		- Tile Format = CSV
  		- Infinite = False
  		- Tile Order = Right Down
  		- Orientation = Orthogonal
		
	- Reading <properties> from Map,Layers and Objects
	- Can read layers from within groups, BUT ONLY ONE LEVEL DEEP!!
    - Can Offset when multiple tileset GID , to base 1 (PARAM.offset_gid)
	- Reads all Object types along with their data for Text,PolyLine,Polygon
  
	
  Example
  -------
  
		var map = new djfl.util.TiledMap('assets/data/level_01.tmx');
		var level=map.getLayer('bgtiles');
		game.createMap(level);
		for (i in map.getObjLayer('Items')){
			game.addItem(i);
		}
		
  
******************************************************************************/

package djA.parser;

import djA.DataT;
import djA.types.SimpleCoords;


// Describes an <object> Object
// They are under <objectgroup> layers
// <objects> are polymorphic, they can be sprites, text, shapes, etc
typedef TiledObject = {
	id:Int,			// Uniqued TILED id
	x:Float,
	y:Float,
	?gid:Int,		// The Tile Index for the Graphic. Also check `PARAMS.offset_gid`
	?width:Float,
	?height:Float,
	?rotation:Float,
	?data:String,	// Depends on TYPE. [text] store the Text. [polygons] store the polygon string
	?name:String,	// Optional name
	?type:String,	// As it is defined in TILED
	?tag:String,	// [ellipse, polygon, polyline, text]
	?prop:Dynamic,	// Custom properties, Used in custom Types in the Editor
}

// Used internally
// Describes a <tileset> node
// <tileset firstgid="1" name="Blocks" tilewidth="16" tileheight="8" tilecount="128" columns="8">
private typedef TileSetXML = {
	firstgid:Int,
	count:Int,
	tw:Int,
	th:Int,
	name:String
}

	
class TiledMap 
{
	// TILE width,height
	public var tileW(default, null):Int;
	public var tileH(default, null):Int;
	
	// MAP width,height, in tiles
	public var mapW(default, null):Int;
	public var mapH(default, null):Int;
	
	// Background color read from the map
	public var bgColor(default, null):String;
	
	/** Map custom user properties */
	public var properties(default, null):Dynamic;
	
	// >> Tile Layers, in order from bottom to top (as they are declared on the .tmx)
	//    The Map Data is stored sequentially
	public var layers:Array<Array<Int>>;
	
	// >> Object Groups, in order from bottom to top (as they are declared in the .tmx)
	public var objects:Array<Array<TiledObject>>;
	
	/* - Tile+Object layer metadata
		  {
			name<String>	; name of layer
			_type<Int>		; 0:tile 1:object
			_index:<Int>	; Index on {layers} or {objects}?
			_parent<String>	; name of parent group or null
			
			?tintcolor		; For Tiles + Objects
			?color			; For Objects is built in (for Tiles, do it manually as a custom property)
			?custom properties ; Copied as they are read from Tiled Custom Properties
	*/
	var layers_meta:Array<Dynamic>;
	
	// List of tilesets declared
	// Used internally to apply fixes to GID and TileObject Height Orientation
	var tilesets:Array<TileSetXML>;
	
	// - Some extra parameters, set in the constructor
	var PARAMS = {
		// Offset every gid to start from 1 for each layer. This is when you have more than 1
		// tileset, the gid is being appended. e.g. The second layer, the first tile index will
		// not be 1, but rather start from total_gid.
		// Set this to true (default) to make all indexes and gids revert back to 1
		offset_gid:true,
		
		// TILED stores coordinates in (x,y) with y bottom up, 
		// meaning a (0,0) will be drawn off screen to the top
		// This fixes this and translates the coordinates to normal space
		// ! IMPORTANT ! :: For this to work Object Layers must only use tiles from ONE tileset !
		fix_object_y_pos:true,
		
		// If true will center the coordinates of all Tile Entities.
		// REQUIRES `fix_object_y_pos` to be true!
		// e.g. a 32x32 tile object placed at 0,0 will turn to ---> 16,16,width=1,height=1
		object_tiles_to_center_points:false,
	}
	//====================================================;
	

	#if openfl
		
		// Current assetName loaded
		public var assetLoaded(default, null):String = null;
		
		public function new(?asset:String, ?P:Dynamic) 
		{
			if (P != null) PARAMS = DataT.copyFields(P, PARAMS);
			if (asset != null) loadAsset(asset);
		}//---------------------------------------------------;
		
		public function loadAsset(asset:String)
		{
			assetLoaded = asset;
			loadData(openfl.utils.Assets.getText(asset));
		}//---------------------------------------------------;
	#else
		
		/**
		   @param	asset TMX file map data
		   @param	P Pameters, check `FLAGS` variable inside this class
		**/
		public function new(?P:Dynamic) 
		{
			if (P != null) PARAMS = DataT.copyFields(P, PARAMS);
		}//---------------------------------------------------;
		
	#end
	
	/**
	   Load a .TMX map data. @throws
	   @param	DATA Valid XML file as a string
	**/
	public function loadData(DATA:String)
	{
		layers = [];
		objects = [];
		tilesets = [];
		properties = {};
		layers_meta = [];
		
		// DEV: Firstelement fetches the whole <map> </map> Tag
		var xml = Xml.parse(DATA).firstElement();
		
		// :: Get Map Data
		tileW = xGetInt(xml, 'tilewidth');
		tileH = xGetInt(xml, 'tileheight');
		mapW = xGetInt(xml, 'width');
		mapH = xGetInt(xml, 'height');
		bgColor = xml.get('backgroundcolor');	// if not exists, null

		//var ver = Std.parseFloat(xml.get('version'));
		//if (ver < 1.2)
		//{
			//trace("Warning: Only Version 1.2 - 1.4 is tested !!!");
		//}
		
		// :: Get <properties>
		var p = xGetProperties(xml);
		if (p != null) properties = p;	// I need properties to be {} not null
		
		// :: Get <tileset> tags
		for (xl in xml.elementsNamed('tileset'))
		{
			tilesets.push({
				name:xl.get('name'),
				firstgid:xGetInt(xl, 'firstgid'),
				count:xGetInt(xl, 'tilecount'),
				tw:xGetInt(xl, 'tilewidth'),
				th:xGetInt(xl, 'tileheight')
			});
			
			#if debug
			if (xl.get('source') == 'null') {
				throw "Tilesets that reference external '.tsx' are not supported";
			}
			#end
		}
		
		// :: Get layers that have no parent
		xReadLayers(xml);
		
		// :: Get layers in Groups, first level only
		for (xl in xml.elementsNamed('group'))
		{
			xReadLayers(xl, xl.get('name'));
		}
		
		
	}//---------------------------------------------------;

	
	
	/**
	   Get TileData layer by Name, If your layer is in a group,
	   give also the group title. Else it will return the first 
	   layer name it encounters
	   @param	name Name of the <layer> layer
	   @param	group Name of the <group> the layer belongs to OPTIONAL
	   @return
	**/
	public function getLayer(name:String, ?group:String):Array<Int>
	{
		for (m in layers_meta)
		{
			if (m.name == name && m._type==0)
			{
				if ( group == null || (group == m._parent)) {
					return layers[m._index];
				}
			}
		}
		return null;
	}//---------------------------------------------------;
	
	
	/**
	   Get ObjectData layer by Name, If your layer is in a group,
	   give also the group title. Else it will return the first 
	   layer name it encounters
	   @param	name Name of the <objectgroup> layer
	   @param	group Name of the <group> the layer belongs to OPTIONAL
	   @return
	**/
	public function getObjLayer(name:String, ?group:String):Array<TiledObject>
	{
		for (m in layers_meta)
		{
			if (m.name == name && m._type==1)
			{
				if ( group == null || (group == m._parent)) {
					return objects[m._index];
				}
			}
		}
		return null;
	}//---------------------------------------------------;
	
	
	/**
	   Gets all Objects with their {name} field set and puts them into a 
	   map with name being the key.
	   Make sure the names of the objects are unique.
	   @param	name Name of the Object layer
	   @return
	**/
	public function getObjMap(name:String,?group:String):Map<String,TiledObject>
	{
		var l = getObjLayer(name, group);
		if (l == null) return null;
		var M:Map<String,TiledObject> = [];
		for (o in l) {
			if (o.name != null) M.set(o.name, o);
		}
		return M;
	}//---------------------------------------------------;
	
	
	// Parse <layer> and <objectgroup> nodes 
	// This is to read data from groups
	function xReadLayers(X:Xml, ?groupName:String)
	{
		// Fill an object with a property only if it exists
		function objProp(_x:Xml, _o:Dynamic, _n:String, _fl:Bool = false) {
			var _val = _x.get(_n);
			if (_val != null)
			Reflect.setField(_o, _n, (_fl?Std.parseFloat(_val):_val));
		}// --
		
		// :: Get <layer> tags
		for (xl in X.elementsNamed('layer'))
		{
			var meta:Dynamic = {
				_type:0,
				_parent:groupName,
				name:xl.get('name'),
			};
			
			objProp(xl, meta, 'opacity', true);
			objProp(xl, meta, 'tintcolor');
			
			// Get the <properties> tag if any
			var p = xGetProperties(xl, true);
			if (p != null) DataT.copyFields(p, meta);
			
			var x = xl.firstElement();
			
			#if debug
			if (x.nodeName != "data") {
				throw 'No data tag in the Tile Layer : ${meta.name}';
			}
			if (x.get("encoding") != "csv") throw "Only CSV data is supported";
			#end
			
			layers.push(xConvertCsvToArInt(x.firstChild().nodeValue));
			meta._index = layers.length - 1;
			layers_meta.push(meta);
			
		}// -- end Tile Layer Parsing
		
		
		// :: Get Objects Data
		for (xl in X.elementsNamed('objectgroup'))
		{
			var meta:Dynamic = {
				_type:1,
				_parent:groupName,
				name:xl.get('name'),
			};
			
			objProp(xl, meta, 'opacity', true);
			objProp(xl, meta, 'tintcolor'); // Set these fields, only if they exist
			objProp(xl, meta, 'color');
			
			// Get the <properties> tag if any
			var p = xGetProperties(xl, true);
			if (p != null) DataT.copyFields(p, meta);
			
			var offs_gid:Int = PARAMS.offset_gid? -1:0;		// -1 Means to check at first encounter. Negative offset
			var offs_y:Int = PARAMS.fix_object_y_pos? -1:0;	// -1 Means to check at first encounter. Negative offset
			
			// Shared for all objects in objectgroup. Inited at the first object that requires it
			var batchTileset:TileSetXML = null;
			
			var OBJ:Array<TiledObject> = [];	// The objects that are being read
			
			for (x in xl.elements())
			{
				#if debug
				if (x.nodeName != "object") {
					trace('Warning: Unsupported node in Tile Layer ${meta.name}');
					continue;
				}
				#end
				
				/**
				   x is an <object> tag
				   e.g  <object id="25" x="37.8717" y="-53.0179" width="83" height="40.2982">
							<text fontfamily="Leelawadee UI" pixelsize="13" wrap="1" halign="center" valign="center">Level 1, hello how are you?</text>
						</object>
				**/

				// The Object that is being read, all values to be overwritten
				var O:TiledObject = { x: -1, y: -1, id: -1}; 
				
				var po = xGetProperties(x, true);
				if (po != null) O.prop = po;
				
				// :: Get Special Child Tags
				//     : <properties> tag was parsed and removed
				//     : so it would only be a <text> or <polygon>
				var f1 = x.firstElement();
				if (f1 != null) {
					O.tag = f1.nodeName;
					// These have extra data I need to get
					if (O.tag == "text") {	// Entity is TEXT
						O.data = f1.firstChild().nodeValue;
					}else
					if (O.tag.substr(0, 4) == "poly") { // Entity is `polyline` or `polygon`
						O.data = f1.get('points');
					}
				}
					
				// :: Get attributes
				for (at in x.attributes())
				{
					// new, (to work for static targets)
					var V = x.get(at);
					Reflect.setField(O, at, switch(at){
						case "gid", "id": Std.parseInt(V);
						case "x", "y", "width", "height", "rotation" : Std.parseFloat(V);
						case _ : V; // String for everything else
					});
				}
				
				// DEV: I only need to check {offsets} once per object group
				//		gid check to make sure this is a tile, not a shape
				if (Reflect.hasField(O, 'gid'))
				{
					if (batchTileset == null) {
						batchTileset = _getTilesetOfGID(O.gid);
					}
					
					if (offs_gid < 0) { // One time init
						offs_gid = _calculateGIDOffset(O.gid);
					}
					
					if (offs_y < 0) { // One time init
						offs_y = batchTileset.th;
					}
					
					O.gid -= offs_gid;	// Either 0 or a real value
					O.y -= offs_y;		// Either 0 or a real value
					
					if (PARAMS.object_tiles_to_center_points)
					{
						O.x = O.x + (batchTileset.tw / 2);
						O.y = O.y + (batchTileset.th / 2);
						O.width = 0;
						O.height = 0;
					}
				}
					
				OBJ.push(cast O);
			}// - end <objects>
				
			objects.push(OBJ);
			meta._index = objects.length - 1;
			layers_meta.push(meta);
			
		}// -- End object Layer parsing	
		
	}//---------------------------------------------------;
	
	
	// Quick get INT from xml attribute
	function xGetInt(x:Xml,att:String):Int
	{
		return Std.parseInt(x.get(att));
	}//---------------------------------------------------;
	
	// Quick get FLOAT or 0 if null , from xml attribute
	function xGetFl(x:Xml,att:String):Float
	{
		var s = x.get(att);
		if (s == null) return 0;
		return Std.parseFloat(s); 
	}//---------------------------------------------------;
	
	/**
	   Fix and Parse the CSV map data into an int Array
	   @param	s The data as it is on the TMX file
	   @return
	**/
	function xConvertCsvToArInt(s:String):Array<Int>
	{
		#if debug
			if (s == null || s.length == 0) throw "CSV has no data";
		#end
		
		// DEV:
		//  Iterate through the string, and store the characters into (b) for every until (,)
		//  I had problems using s.split('\n').join(''), since it didn't work for all linebreaks ??
		//  So I decided to make this this way and I think this is faster, since it only iterates the array once

		var offs = 0;	
		var offsF = PARAMS.offset_gid;
		var a:Array<Int> = [];	// Final Result
		var c = 0;	// Counter
		var b = "";	// Temp number build
		var t = "";	// Temp value read at each iteration
		while (c < s.length) {
			t = s.charAt(c);
			if (t == ",") {
				var val = Std.parseInt(b);
				if (offsF && val > 0) { // Do it once
					offs = _calculateGIDOffset(val);
					offsF = false;
				}
				if (val > 0) val -= offs;
				a.push(val);
				b = "";
			}else{
				b += t;
			}
			c++;
		}
		// Check for the final Tile ID, which does not have an ending ','
		// It SHOULD have data, else the map is broken
		c = Std.parseInt(b);
		if (c > 0) c -= offs;
		a.push(c);
		return a;
	}//---------------------------------------------------;
	
	
	// Get all the <properties> from a node, then delete it
	function xGetProperties(X:Xml, remove:Bool = false):Dynamic
	{
		for (x in X.elementsNamed('properties'))
		{
			var O = {};
			for (prop in x.elementsNamed('property')){
					var v = prop.get("value");
					Reflect.setField(O, prop.get("name"), switch(prop.get("type")){
						case "int": Std.parseInt(v);
						case "float": Std.parseFloat(v);
						case "bool": v == "true";
						default: v;
					});
			}
			
			// there should not be other <properties> tags
			if(remove) X.removeChild(x);
			return O;
		}
		
		return null;
	}//---------------------------------------------------;
	
	
	function _getTilesetOfGID(gid:Int):TileSetXML
	{
		for (t in tilesets) {
			if (gid >= t.firstgid && gid < (t.firstgid + t.count)) {
				return t;
			}
		}
		throw 'Could not get a tileset for GID [$gid], There is something wrong with the map';
		return null;
	}//---------------------------------------------------;
	
	function _calculateGIDOffset(val:Int):Int
	{
		return _getTilesetOfGID(val).firstgid - 1;
	}//---------------------------------------------------;
	
	
	
	public function debug_info()
	{
		trace(	' ==== Tiled Map Infos ====');
		#if openfl
		trace(	' Loaded Asset:"$assetLoaded"');
		#end
		trace(	' Map Size:($mapW,$mapH) TileSize:($tileW,$tileH)');
		if (bgColor != null)
			trace(  '== BG Color : $bgColor');
		trace(  '== Properties :', properties);
		trace(  '== TileSets : ', tilesets);
		// --
		trace(	'== Layers:(${layers.length})' );
		for (m in layers_meta)
			if (m._type == 0)
			trace(	'  name:"${m.name}", dataLen:${layers[m._index].length}',m);
		// --
		trace(  '== Object Layers:(${objects.length})');
		for (m in layers_meta)
			if (m._type == 1)
			trace(	'  name:"${m.name}", dataLen:${objects[m._index].length}',m);
	}//---------------------------------------------------;

}// --