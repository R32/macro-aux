package tools;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
 using Lambda;
 using StringTools;

/*
 * This routine will strip the module-level prefix of the field, to generate cleaner JavaScript code.
 *
 * **WARNING** : The generated code may be incorrect due to name conflicts.
 *
 * Strip the specified module-level prefixes:
 * ```
 * --macro tools.ModuleLevel.strip(['Main', 'org.Foo', ...])
 * ```
 *
 * Strip all module-level prefixes, including standard and third-party libraries:
 * ```
 * --macro tools.ModuleLevel.strip()
 * ```
 * TODO : Currently, there is no mechanism to distinguish between user-defined modules and standard library modules.
 *
 */
class ModuleLevel {

	public static function strip( ?args : Array<String> ) {
		Context.onGenerate(function( types : Array<Type> ) {
			if (args != null && args.length > 0)
				types = args.map( s -> Context.getModule(s) ).flatten();
			for (t in types) {
				switch (t) {
				case TInst(_.get() => c, _):
					switch (c.kind) {
					case KModuleFields(_):
						meta_name(c.statics.get());
					default:
					}
				default:
				}
			}
		});
	}

	public static function stripkg( pack : String ) {
		Context.onGenerate(function( types : Array<Type> ) {
			for (t in types) {
				switch (t) {
				case TInst(_.get() => c, _):
					switch (c.kind) {
					case KModuleFields(_) if (c.pack.join(".").startsWith(pack)):
						meta_name(c.statics.get());
					default:
					}
				default:
				}
			}
		});
	}

	static function meta_name( fields : Array<ClassField> ) {
		for (f in fields) {
			if (f.meta.has(":native"))
				continue;
			var expr = {expr : EConst(CString(f.name)), pos : f.pos};
			f.meta.add(":native", [expr], f.pos);
		}
	}
}
