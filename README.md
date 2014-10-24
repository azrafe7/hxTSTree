hxTSTree
========

A Ternary Search Tree in Haxe 3.1+.

![](screenshot.png)

[online swf demo](https://dl.dropboxusercontent.com/u/32864004/dev/FPDemo/hxTSTreeDemo.swf)

Based on Dr. Dobbs article ([http://www.drdobbs.com/database/ternary-search-trees/184410528](http://www.drdobbs.com/database/ternary-search-trees/184410528)).

**Features:**

 - Multiple search types (exact, prefix, pattern, [Hamming distance](http://en.wikipedia.org/wiki/Hamming_distance))
 - Multiple insert modes (sequential, random, balanced)
 - Serialization/Unserialization
 - Association of arbitrary data to keys (like a Map<String, T>)
 - Returned keys (/data) are given in sorted order
 - DOT format file writer (for visualization with tools like [Graphviz](http://www.graphviz.org/)) 

## Internal representation (with [`fruit.txt`](assets/fruit.txt) word list)

**TSTree.bulkInsert() - sequential**

![](bulkInsert.png)


**TSTree.randomBulkInsert() - random**

![](randomBulkInsert.png)


**TSTree.balancedBulkInsert() - balanced**

![](balancedBulkInsert.png)

## License

**hxTSTree** is developed by Giuseppe Di Mauro (azrafe7) and released under the MIT license. See the [LICENSE](LICENSE) file for details. 