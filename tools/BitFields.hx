package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

/**

A simple bit fileds macro tool.

example:

```haxe
#if !macro
@:build(tools.BitFields.build())
#end
abstract RGB(Int) {

	var b : _8; // low bits
	var g : _8;
	var r : _8; // high bits

	// The macro will automatically generate additional "name_offset", "name_mask" fields
	inline function new( r : Int, g : Int, b : Int ) {
		this = r << r_offset | g << g_offset | b << b_offset;
	}
}
// ...
var rgb = new RGB(0x60, 0x70, 0x80);
assert(rgb.r == 0x60);  // getter
rgb.r = 0xFF;           // setter
assert(rgb.r == 0xFF);
```
*/
class BitFields {
#if macro
	public static function build() {
		var clst : ClassType = Context.getLocalClass().get();
		switch (clst.kind) {
		case KAbstractImpl(_.get() => t) if (Context.unify(t.type, Context.getType("Int"))):
		default:
			Context.fatalError("UnSupported Type: " + clst.name, clst.pos);
		}

		var offset = 0;
		var fields = Context.getBuildFields();
		// NOTE: The "fields" will be pushed in loop
		var i = 0;
		var limit = fields.length;
		while (i < limit) {
			var f = fields[i++];
			var bits = 0;
			switch (f.kind) {
			case FVar(TPath({pack: [], name: name}), _) if (name.charCodeAt(0) == '_'.code):
				var n = Std.parseInt(name.substring(1));
				if (n != null)
					bits = n;
			default:
			}
			if (bits == 0)
				continue;

			var pos = f.pos;
			var name = f.name;
			if (offset + bits > 32)
				Context.fatalError("[BitFields]: 32 bit exceeded: " + name, pos);

			var mask = (1 << bits) - 1;
			var erase = ~(mask << offset);
			var ctype = macro :Int;
			var access = [AExtern, APrivate, AInline];
			f.kind = FProp("get", "set", ctype);
			fields.push({
				name : "get_" + name,
				access : access,
				pos : pos,
				kind : FFun({
					args : [],
					ret : ctype,
					expr : macro return (this >> $v{ offset }) & $v{ mask }
				})
			});
			fields.push({
				name : "set_" + name,
				access : access,
				pos : pos,
				kind : FFun({
					args : [{ name : "v", type : ctype }],
					ret : ctype,
					expr : macro {
						this = (this & $v{ erase }) | (v << $v{ offset });
						return v;
					}
				})
			});
			var access = [AExtern, APublic, AStatic, AInline];
			fields.push({
				name : name + "_offset",
				access: access,
				pos : pos,
				kind: FVar(null, macro $v{ offset })
			});
			fields.push({
				name : name + "_mask",
				access: access,
				pos : pos,
				kind: FVar(null, macro $v{ mask })
			});

			offset += bits;
		}
		return fields;
	}
#else
	public static inline function build() return null;
#end
}
