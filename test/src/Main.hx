package;

import maux.ES.*;

class Main {

	var count = 0;

	public function new() {
		var doc = js.Browser.document;
		var div = doc.createElement("div");
		doc.body.appendChild(div);

		TEXT(div) = maux.GitVersion.get(true);
		trace(TEXT(div));
		div.onclick = BIND(log);
	}

	function log() {
		trace(count++);
	}

	static function bitfield() {
		var error = new js.lib.Error("bitFields Error");
		for(i in 0...101) {
			var rand = Std.random(0xFFFFFF + 1);
			var r = rand >> 16 & 0xFF;
			var g = rand >>  8 & 0xFF;
			var b = rand >>  0 & 0xFF;
			var rgb = new RGB(r, g, b);
			if (!(rgb.r == r && rgb.g == g && rgb.b == b))
				throw error;
			// swap
			rgb.r = b;
			rgb.g = r;
			rgb.b = g;
			if (!(rgb.r == b && rgb.g == r && rgb.b == g))
				throw error;
		}
	}

	static function cstruct() {
		var joj = new JoJ();
		assert(JoJ.offset_sign == 0);
		assert(JoJ.offset_size == 4);
		assert(JoJ.offset_rand == 8);
		assert(JoJ.offset_name == 12);
		assert(JoJ.offset_ucs  == 12 + (32));
		assert(JoJ.offset_mat  == 12 + 32 + 32 * 2);
		assert(JoJ.CAPACITY    == JoJ.offset_flex);
		trace(joj.sign); // Error
		joj.size = JoJ.CAPACITY;
		trace(joj.size);
		trace(joj.ucs);
	}

	static function assert( v : Bool, ?pos : haxe.PosInfos ) {
		if (!v)
			throw pos;
	}

	static function main() {
		var main = new Main();
		bitfield();
		try cstruct() catch(e) js.Browser.console.log(e);
	}
}

#if !macro
@:build(maux.BitFields.build())
#end
extern abstract RGB(Int) {

	var b : _8;
	var g : _8;
	var r : _8;

	inline function new( r : Int, g : Int, b : Int ) {
		this = r << r_offset | g << g_offset | b << b_offset;
	}
}


#if !macro
@:build(maux.CStruct.build())
#end
extern abstract JoJ(Dynamic) {

	var sign = short;     // offset :   0, sizeof :  2
	var size = int;       // offset :   4, sizeof :  4, (aligns to 4)
	var rand = f32;       // offset :   8, sizeof :  4
	var name = char[32];  // sizeof(32 x 1)
	var ucs  = u16[32];   // sizeof(32 x 2)
	var mat  = f32[4][4]; // sizeof(4 x 4 x 4)
	var flex = f64[0];    // offset will aligns to 8.

	var ucs(get, never) : String;
	inline function get_ucs() : String {
		return this.dummy_get_string(offset_ucs, count_ucs);
	}

	public inline function new() this = [CAPACITY]; // fake code
}
