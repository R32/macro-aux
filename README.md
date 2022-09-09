macro tools
------

A collection of haxe macro utilities

## tools

- [x] `GitVersion`: Retrieves the git hash string from current directory.

  ```haxe
  var version = tools.GitVersion.get(true);
  ```
  js output:

  ```js
  var version = "master@b3bc166";
  ```
