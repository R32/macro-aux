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

	function bitfield() {
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
	static function main() {
		var main = new Main();
		main.bitfield();
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
