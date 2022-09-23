package;

class Main {
	static function main() {
		var version = tools.GitVersion.get(true);
		trace(version);

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
		trace("bitFields done!");
	}
}

#if !macro
@:build(tools.BitFields.build())
#end
extern abstract RGB(Int) {

	var b : _8;
	var g : _8;
	var r : _8;

	inline function new( r : Int, g : Int, b : Int ) {
		this = r << r_offset | g << g_offset | b << b_offset;
	}
}
