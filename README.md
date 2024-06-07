macro tools
------

A collection of haxe macro utilities

## tools

### GitVersion

Retrieves the git hash string from current directory.

```haxe
var version = tools.GitVersion.get(true);

// js output:
var version = "master@b3bc166";
```

### BitFields

A simple bit fileds build tool.

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

### ModuleLevel

It's used to strip the module-level prefix of the field, to generate cleaner JavaScript code.

Main.hx :

```haxe
function foo() {
	trace("hello world!");
}
function main() {
	foo();
}
```

build.hxml :

```bash
-main Main
-lib macro-tools-ya
--macro tools.ModuleLevel.strip()
--js main.js
```

Generated main.js :

```js
function foo() {
	console.log("src/Main.hx:2:","hello world!");
}
function main() {
	foo();
}
main();
```
