package maux;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
 using haxe.macro.Tools;
#end

class ES {

	/*
	 * Simply reference to .innerText
	 *
	 * ```
	 * var label = document.querySelector("label");
	 * console.log(TEXT(label));
	 * TEXT(label) = "Bob";
	 * ```
	 */
	macro public static function TEXT(node) return macro ($node: js.html.Element).innerText;

	/*
	 * Uses native ".bind" to instead of haxe $bind
	 *
	 * ```haxe
	 * btn.onclick = BIND(onClick);
	 * ```
	 *
	 * output :
	 *
	 * ```js
	 * btn.onclick = this.onClick.bind(this);
	 * ```
	 */
	macro public static function BIND(func) {
		if (Context.definedValue("target.name") != "js")
			return func;
		var pos = Context.currentPos();
		var exp = Context.getExpectedType();
		if (exp != null && !Context.unify(Context.typeof(func), exp))
			Context.fatalError(func.toString() + " should be " + exp.toString(), pos);
		var ctx : Expr;
		var name : String;
		var type : haxe.macro.Type;
		switch(func.expr) {
		case EConst(CIdent(i)):
			ctx = macro this;
			name = i;
			type = Context.getLocalType();
			if (type == null)
				return func;
		case EField(e, field):
			ctx = e;
			name = field;
			type = Context.typeof(ctx);
		default:
			Context.fatalError("UnSupported: " + func.toString(), func.pos);
		}
		// add :keep
		switch (type) {
		case TInst(_.get() => c, _):
			for (f in c.fields.get()) {
				if (f.name == name) {
					f.meta.add(":keep", [], f.pos);
					break;
				}
			}
		default:
		}
		return macro @:pos(pos) ($ctx:Dynamic).$name.bind($ctx);
	}
}
