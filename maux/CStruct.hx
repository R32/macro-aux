package maux;

#if (macro || display)
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
 using haxe.macro.Tools;

/*
 * This is used to construct a raw data block similar to the C language.
 *
 * ```haxe
 * #if !macro
 * @:build(maux.CStruct.build())
 * #end
 * extern abstract MyStruct(UnderlyingType) { // The underlying type necessitates the implementation of several methods.
 * 	var sign = int;       // Use "=" to mark the type, see "CStruct.intrins"
 * 	var cstr = char[32];  // Array type field will be discard, only "offset_cstr" and "count_cstr" are available.
 * 	var mat4 = f32[4][4];
 *
 * 	var cstr(get, never) : String; // the real field of "cstr"
 * 	private inline function get_cstr() : String {
 * 		return this.dummy_getstring(offset_cstr, count_cstr);
 * 	}
 *	inline function new() {
 *		this = dummy_alloc(CAPACITY); // CAPACITY == sizeof(MyStruct)
 * 	}
 * }
 * ```
 */
class CStruct {

	var flex : Field;
	var offset : Int;
	var result : Array<Field>;

	function new() {
		flex = null;
		offset = 0;
		result = [];
	}

	function make() {
		for (field in Context.getBuildFields()) {
			switch (field.kind) {
			case FVar(_, e):
				switch (e.expr) {
				case EConst(CIdent(i)):
					transform(field, i, 1);
				case EArray(a, int(_) => i):
					var acc = {id : null, count : i};
					acc_array(a, acc);
					transform(field, acc.id, acc.count);
					continue; // discard field if array
				default:
				}
			default:
			}
			add(field);
		}
		add( mk_static_inline("CAPACITY", offset, Context.currentPos()) );
		return result;
	}

	function acc_array( e : Expr, acc : {id : String, count : Int} ) {
		switch (e.expr) {
		case EArray(e, int(_) => i):
			acc.count *= i;
			acc_array(e, acc);
		case EConst(CIdent(id)):
			acc.id = id;
		default:
			fatal("invalid : " + e.toString(), e.pos);
		}
	}

	function transform( field : Field, id : String, count : Int ) {
		var intrin = intrins.get(id);
		if (intrin == null)
			return;

		if (this.flex != null)
			fatal("flexible array member should at the end : " + flex.name, flex.pos);

		var sizeof = intrin.base & 0xFF;
		offset_align(sizeof, field);

		switch (count) {
		case 0:
			this.flex = field;
		case 1:
			add_basic(field, intrin);
		default:
			add( mk_static_inline("count_" + field.name, count, field.pos) );
		}

		add( mk_static_inline("offset_" + field.name, offset, field.pos) );
		// next
		offset_next(sizeof * count);
	}

	inline function add( field : Field ) result.push(field);

	function add_basic( field : Field, intrin : Intrinsic ) {
		// build fields
		var get = intrin.sget;
		var set = intrin.sput;
		var get = macro return this.$get($v{ offset });
		var set = macro return this.$set($v{ offset }, v);
		var ct = intrin.base < 0xFF ? (macro :Int) : (macro :Float);
		var access = [APrivate, AInline];
		add({
			pos : field.pos,
			name : "get_" + field.name,
			access : access,
			kind : FFun({
				ret : ct,
				args : [],
				expr : get,
			}),
		});
		add({
			pos : field.pos,
			name : "set_" + field.name,
			access : access,
			kind : FFun({
				ret : ct,
				args : [{name : "v", type : ct}],
				expr : set,
			}),
		});
		field.kind = FProp("get", "set", ct);
	}

	function offset_next(size) {
		offset += size;
	}

	function offset_align( base : Int, field : Field ) {
		// @offset(offset, align)
		for (m in field.meta) {
			if (m.name != "offset")
				continue;
			switch (m.params) {
			case [int(_) => i]:
				offset += i;
			case [int(_) => i, int(_) => j]:
				offset += i;
				if (j < base || !ispot(j))
					fatal("invalid : ", m.params[1].pos);
				base = j;
			default:
			}
			break;
		}
		// apply
		if (offset & (base - 1) == 0)
			return;
		offset = ((offset - 1) | (base - 1)) + 1;
	}

	static function mk_static_inline<T>( name : String, i : T, pos : Position ) : Field {
		return {
			pos : pos,
			name : name,
			access : [APublic, AInline, AStatic],
			kind : FVar(null, macro $v{ i }),
		}
	}

	static function int( e : Expr ) {
		return switch (e.expr) {
		case EConst(CInt(i)):
			Std.parseInt(i);
		default:
			fatal("invalid : " + e.toString(), e.pos);
		}
	}

	// is pow of 2
	static function ispot( i : Int ) return ((i - 1) & i) == 0;

	static function fatal( msg : String, pos) {
		return Context.fatalError("[maux-cstruct] : " + msg, pos);
	}

	static inline function F(sizeof) return (1 << 8) + sizeof;

	static final U8  = {base :   1 , sget : "get"      , sput : "set"};
	static final U16 = {base :   2 , sget : "getUInt16", sput : "setUInt16"};
	static final I32 = {base :   4 , sget : "getInt32" , sput : "setInt32"};
	static final F32 = {base : F(4), sget : "getFloat" , sput : "setFloat"};
	static final F64 = {base : F(8), sget : "getDouble", sput : "setDouble"};
	static final intrins : Map<String, Intrinsic> = [
		"char"   => U8,  "byte" => U8, "u8" => U8,
		"short"  => U16, "u16"  => U16,
		"int"    => I32, "i32"  => I32,
		"float"  => F32, "f32"  => F32,
		"double" => F64, "f64"  => F64,
	];

	public static function build() {
		return new CStruct().make();
	}
}

typedef Intrinsic = {
	base : Int,
	sget : String,
	sput : String,
}

#else
extern class CStruct {}
#end
