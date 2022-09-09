package;

class Main {
	static function main() {
		var version = tools.GitVersion.get(true);
		trace(version);
	}
}
