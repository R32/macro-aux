package tools;

#if macro
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
#end

class GitVersion {

	/**
	* Retrieves the git hash string from current directory.
	*/
	macro static public function get( branch : Bool = false, len : Int = 7 ) {
		var unknown = "unkown";
		var pos = Context.currentPos();
		#if display
		return macro $v{ unknown };
		#end
		var info = gitHashInfo();
		var desc = (branch ? info.branch + "@" : "") + info.hash.substr(0, len);
		return macro @:pos(pos) $v{ desc };
	}

#if macro
	static function gitHashInfo() {
		var path = gitDirectory(".");
		var head = File.getContent(path + "/" + "HEAD");
		var dest = head.split("\n")[0].split(": ")[1];
		var hash = File.getContent(path + "/" + dest);
		var curr = dest.split("/").pop();
		return {branch : curr, hash : hash};
	}

	static function gitDirectory( dir : String, rec = 8 ) : String {
		if (rec == 0)
			Context.fatalError("[macro-tools]: No git repository.", Context.currentPos());

		var char = dir.charCodeAt(dir.length - 1);

		var slash = char == "/".code || char == "\\".code ? "" : "/";

		var ret = dir + slash + ".git";

		if (FileSystem.exists(ret))
			return ret;

		return gitDirectory(dir + slash + "..", rec - 1);
	}
#end
}
