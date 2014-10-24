package ds;

import haxe.ds.ArraySort;
import haxe.Serializer;
import haxe.Unserializer;
#if sys
import sys.io.File;
#end

/**
 * Ternary Search Tree implementation (https://github.com/azrafe7/hxTSTree).
 * 
 * Based on Dr. Dobbs article (http://www.drdobbs.com/database/ternary-search-trees/184410528)
 * 
 * Features:
 * 
 *  - Multiple search types (exact, prefix, pattern, hamming distance)
 *  - Multiple insert modes (sequential, random, balanced)
 *  - Serialization/Unserialization
 *  - Association of arbitrary data to keys (like a Map<String, T>)
 *  - Returned keys (/data) are given in sorted order
 * 
 * @author azrafe7
 */
class TSTree<T>
{
	inline static public var MAX_INT:Int = 0x7FFFFFFF;
	
	/** Char to use to indicate a "don't care" value in pattern search. */
	public var ANY_CHAR(default, set):String = ".";
	private function set_ANY_CHAR(value:String):String 
	{
		if (value.length > 1) throw "`ANY_CHAR` must be a single character.";
		return ANY_CHAR = value;
	}
	
	/** Number of nodes in the tree. */
	public var numNodes(default, null):Int = 0;
	
	/** Number of keys in the tree. */
	public var numKeys(default, null):Int = 0;
	
	/** Number of nodes examined during the last operation. */
	public var examinedNodes(default, null):Int = 0;
	
	
	var root:Node<T> = null;
	var maxResults:Int = MAX_INT;
	
	/** Constructor. */
	public function new() 
	{

	}
	
	/** Inserts key-value pairs in random order. */
	public function randomBulkInsert(keys:Array<String>, ?values:Array<T>):Void 
	{
		if (keys == null || keys.length <= 0) return;
		if (values != null && keys.length != values.length) throw "Number of `keys` and number of `values` must match.";
		
		var indices = [for (i in 0...keys.length) i];
		var currIdx = keys.length;
		var tmp, rndIdx;
		var tmpVal;
		
		// Knuth shuffle
		while (currIdx > 0) {
			rndIdx = Math.floor(Math.random() * currIdx);
			currIdx--;
			
			tmp = indices[currIdx];
			indices[currIdx] = indices[rndIdx];
			indices[rndIdx] = tmp;
		}
		
		for (i in 0...indices.length) {
			var idx = indices[i];
			insert(keys[idx], values != null ? values[idx] : null);
		}
		indices = null;
	}
	
	/** 
	 * Inserts key-value pairs in balanced order.
	 * 
	 * @param isSorted	if `false` the keys will be sorted first (not in place).
	 */
	public function balancedBulkInsert(keys:Array<String>, ?values:Array<T>, isSorted:Bool = false):Void 
	{
		if (keys == null || keys.length <= 0) return;
		if (values != null && keys.length != values.length) throw "Number of `keys` and number of `values` must match.";
		
		var indices = [for (i in 0...keys.length) i];
		if (!isSorted) { // sort lexicographically and store indices
			ArraySort.sort(indices, function (a:Int, b:Int):Int
			{
				var keyA:String = keys[a];
				var keyB:String = keys[b];
				return keyA > keyB ? 1 : keyA < keyB ? -1 : 0;
			});
		}
		
		var sequence = getBalancedIndices(indices);
		for (i in sequence) {
			insert(keys[i], values != null ? values[i] : null);
		}
		indices = null;
		sequence = null;
	}
	
	/** Inserts key-value pairs in sequential order. */
	public function bulkInsert(keys:Array<String>, ?values:Array<T>):Void 
	{
		if (keys == null || keys.length <= 0) return;
		if (values != null && keys.length != values.length) throw "Number of `keys` and number of `values` must match.";
		
		for (i in 0...keys.length) {
			_insert(keys[i], values != null ? values[i] : null);
		}
	}

	/** Rebalances the tree by extracting all nodes and reinserting them in balanced order. */
	public function rebalance():Void 
	{
		var keys = getAllKeys();
		var values = getAllData();
		clear();
		balancedBulkInsert(keys, values);
	}
	
	/** Returns an array containing balanced indices for `sortedKeys`. */
	public function getBalancedIndices(sortedKeys:Array<Dynamic>):Array<Int>
	{
		var len = sortedKeys.length;
		var indices = [for (i in 0...sortedKeys.length) i];
		
		// build balanced sequence
		var queue = new List();
		queue.add(0);
		queue.add(len);
		
		var sequence = [];
		while (queue.length > 0) {
			var start = queue.first();
			queue.remove(start);
			var end = queue.first();
			queue.remove(end);
			var mid = ((end - start) >> 1) + start;
			
			var rightRange = end - mid;
			var leftRange = mid - start;
			
			sequence.push(indices[mid]);
			if (leftRange == 1) sequence.push(indices[start]);
			if (rightRange == 1 && end < len) sequence.push(indices[end]);
			
			if (leftRange > 1) {
				queue.add(start);
				queue.add(mid - 1);
			}
			if (rightRange > 1) {
				queue.add(mid + 1);
				queue.add(end);
			}
		}
		
		return sequence;
	}

	/** Inserts `key` into the tree and associates `data` to it. */
	public function insert(key:String, ?data:T)
	{
		_insert(key, data);
	}
	
	/**
	 * Removes `key` from the tree.
	 * 
	 * (actually the corresponding nodes are not deleted - as this
	 * would be a very expensive operation - so the key is simply
	 * marked to not be used and the associated data is set to null)
	 */
	public function remove(key:String):Bool
	{
		var node = getNodeFor(root, key);
		if (node != null) {
			node.key = null;
			node.isKey = false;
			node.data = null;
			numKeys--;
			return true;
		}
		return false;
	}
	
	/** Removes all keys from the tree. */
	public function clear():Void 
	{
		root = null;
		numNodes = numKeys = 0;
	}
	
	/** Checks if the given `key` is present in the tree. */
	public function hasKey(key:String):Bool
	{
		examinedNodes = 0;
		return getNodeFor(root, key) != null;
	}
	
	/**
	 * Searches the tree for keys that start with the given `prefix`.
	 * 
	 * @param	results		Matching keys will be appended to this array.
	 * @param	maxResults	Max number of results allowed.
	 */
	public function prefixSearch(prefix:String, ?results:Array<String>, maxResults:Int = MAX_INT):Array<String>
	{
		examinedNodes = 0;
		this.maxResults = maxResults;
		return _prefixSearch(root, prefix, results);
	}
	
	/**
	 * Searches the tree for keys matching the given `pattern`.
	 * 
	 * i.e. a pattern of ".a.a.a" will match "banana", "pajama", etc.
	 * 
	 * @param	results		Matching keys will be appended to this array.
	 * @param	maxResults	Max number of results allowed.
	 */
	public function patternSearch(pattern:String, ?results:Array<String>, maxResults:Int = MAX_INT):Array<String>
	{
		examinedNodes = 0;
		this.maxResults = maxResults;
		return _patternSearch(root, pattern, results);
	}
	
	/**
	 * Searches the tree for keys within Hamming `distance` from `key`.
	 * 
	 * @see http://en.wikipedia.org/wiki/Hamming_distance
	 * 
	 * @param	results		Matching keys will be appended to this array.
	 * @param	maxResults	Max number of results allowed.
	 */
	public function distanceSearch(key:String, distance:Int, ?results:Array<String>, maxResults:Int = MAX_INT):Array<String>
	{
		examinedNodes = 0;
		this.maxResults = maxResults;
		if (distance < 0) distance = 0;
		if (distance > key.length) distance = key.length;
		return _distanceSearch(root, key, distance, results);
	}
	
	/** Returns the data associated with `key` (or null if `key` is not found). */
	public function getDataFor(key:String):T 
	{
		examinedNodes = 0;
		var node = getNodeFor(root, key);
		return node != null ? node.data : null;
	}
	
	/** Returns an array containing all the key-value pairs in the tree. */
	public function getAll():Array<{key:String, data:T}>
	{
		var results = [];
		traverse(root, function (node:Node<T>):Void 
		{
			if (node.isKey) {
				results.push({key:node.key, data:node.data});
			}
		});
		
		return results;
	}
	
	/** Returns an array containing all the keys in the tree. */
	public function getAllKeys():Array<String>
	{
		var results = [];
		traverse(root, function (node:Node<T>):Void 
		{
			if (node.isKey) {
				results.push(node.key);
			}
		});
		
		return results;
	}
	
	/** Returns an array containing all the data values in the tree. */
	public function getAllData():Array<T>
	{
		var results = [];
		traverse(root, function (node:Node<T>):Void 
		{
			if (node.isKey) {
				results.push(node.data);
			}
		});
		
		return results;
	}
	
	/** Writes a DOT file representing the tree (for visualization with tools like GraphViz. */
	public function writeDotFile(path:String, ?label:String, maxNodes:Int = MAX_INT):Void 
	{
	#if !sys
		trace("Cannot write to file in non-system platform!");
	#else
		trace('Writing dot file in "$path"...');
		var stringBuf = new StringBuf();
		stringBuf.add('digraph TSTree {\n\tnode [shape=record, fontname=Courier]\n\tgraph [fontname=Courier, style=bold]\n');
		
		var countNodes = 0;
		var indexQueue = new List();
		indexQueue.add(0);
		var queue = new List();
		queue.add(root);
		while (root != null && queue.length > 0 && maxNodes > 0) {
			var idx = indexQueue.first();
			indexQueue.remove(idx);
			var node = queue.first();
			queue.remove(node);
			maxNodes--;
			countNodes++;
			
			var curr = '"${idx}" ';
			if (node.isKey) curr += '[label="${node.splitChar}|${node.key}", color=red]';
			else curr += '[label="${node.splitChar}"]';
			
			// curr node
			stringBuf.add('\t${curr}\n');
			
			var loKid = node.loKid;
			var eqKid = node.eqKid;
			var hiKid = node.hiKid;
			var hasChildren = (loKid != null || eqKid != null || hiKid != null);
			
			// loKid
			if (hasChildren && maxNodes > 0) {
				stringBuf.add('\t"${idx}" -> "${idx * 3 + 1}"\n');
				if (loKid != null) {
					indexQueue.add(idx * 3 + 1);
					queue.add(loKid);
				} else {
					stringBuf.add('\t"${idx * 3 + 1}" [shape=point]\n');
				}
			}
			
			// eqKid
			if (hasChildren && maxNodes > 0) {
				stringBuf.add('\t"${idx}" -> "${idx * 3 + 2}" [style=dotted]\n');
				if (eqKid != null) {
					indexQueue.add(idx * 3 + 2);
					queue.add(eqKid);
				} else {
					stringBuf.add('\t"${idx * 3 + 2}" [shape=point]\n');
				}
			}
			
			// hiKid
			if (hasChildren && maxNodes > 0) {
				stringBuf.add('\t"${idx}" -> "${idx * 3 + 3}"\n');
				if (hiKid != null) {
					indexQueue.add(idx * 3 + 3);
					queue.add(hiKid);
				} else {
					stringBuf.add('\t"${idx * 3 + 3}" [shape=point]\n');
				}
			}
		}
		if (label == null) label = '<b>$path ($countNodes nodes)</b>';
		stringBuf.add('\tlabelloc="t"\n\tlabel=<<b>$label</b>>\n');
		stringBuf.add("}\n");
		
		sys.io.File.saveContent(path, stringBuf.toString());
		trace('Done (${stringBuf.length} bytes written)');
	#end
	}

	/** Serializes the whole tree (keys + data) to a string. */
	public function serialize():String
	{
		var serializer = new Serializer();
		serializer.serialize(numNodes);
		serializer.serialize(numKeys);
		var keyDataPairs = getAll();
		
		var sequence = getBalancedIndices(keyDataPairs);
		
		// serialize keyValuePairs in sequence order
		for (i in 0...sequence.length) {
			serializer.serialize(keyDataPairs[sequence[i]]);
		}
		sequence = null;
		
		return serializer.toString();
	}

	/** Unserializes a string obtained with serialize() into a new TSTree. */
	static public function unserialize<T>(buf:String):TSTree<T>
	{
		var unserializer = new Unserializer(buf);
		var tree = new TSTree();
		
		var numNodes = unserializer.unserialize();
		var numKeys = unserializer.unserialize();
		
		for (i in 0...numKeys) {
			var pair = unserializer.unserialize();
			tree._insert(pair.key, pair.data);
		}
		
		return tree;
	}
	
	/** Checks if the tree is empty. */
	public function isEmpty():Bool
	{
		return root == null;
	}
	
	/** In-order tree traversal (callback will be called on every encountered node). */
	function traverse(node:Node<T>, callback:Node<T>->Void):Void 
	{
		if (node == null) return;
		
		traverse(node.loKid, callback);
		callback(node);
		traverse(node.eqKid, callback);
		traverse(node.hiKid, callback);
	}
	
	inline function createNode(char:String):Node<T>
	{
		numNodes++;
		return new Node(char);
	}
	
	function _recurInsert(node:Node<T>, key:String, data:T, idx:Int = 0):Node<T>
	{
		if (node == null) {
			node = createNode(key.charAt(idx));
		}
		
		var splitChar = node.splitChar;
		var char = key.charAt(idx);
		var len = key.length;
		
		if (char < splitChar) {
			node.loKid = _recurInsert(node.loKid, key, data, idx);
		} else if (char == splitChar) {
			if (idx == len - 1) {
				node.data = data;
				if (!node.isKey) numKeys++;
				node.isKey = true;
				node.key = key;
			} else {
				node.eqKid = _recurInsert(node.eqKid, key, data, ++idx);
			}
		} else {
			node.hiKid = _recurInsert(node.hiKid, key, data, idx);
		}
		
		return node;
	}
	
	function _insert(key:String, data:T):Void
	{
	#if debug
		if (key == null || key.length < 1) throw "Cannot insert empty or null string as key.";
	#end	
		var idx = 0;
		var node = root;
		var len = key.length;
		while (idx < len) {
			if (root == null) {
				root = node = createNode(key.charAt(idx));
			}
			
			var splitChar = node.splitChar;
			var char = key.charAt(idx);
			
			if (char < splitChar) {
				if (node.loKid == null) node.loKid = createNode(char);
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1) {
					node.data = data;
					if (!node.isKey) numKeys++;
					node.isKey = true;
					node.key = key;
				} else {
					if (node.eqKid == null) node.eqKid = createNode(key.charAt(idx + 1));
					node = node.eqKid;
				}
				idx++;
			} else {
				if (node.hiKid == null) node.hiKid = createNode(char);
				node = node.hiKid;
			}
		}
	}
	
	function getNodeFor(node:Node<T>, key:String):Node<T>
	{
		var idx:Int = 0;
		var len = key.length;
		
		while (node != null) {
			examinedNodes++;
			var splitChar = node.splitChar;
			var char = key.charAt(idx);
			
			if (char < splitChar) {
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1 && node.isKey) {
					return node;
				}
				node = node.eqKid;
				idx++;
			} else {
				node = node.hiKid;
			}
		}
		
		return null;
	}
	
	function _prefixSearch(node:Node<T>, prefix:String, ?results:Array<String>, idx:Int = 0):Array<String>
	{
		if (results == null) results = [];

		var len = prefix.length;
		while (node != null && maxResults > 0) {
			examinedNodes++;
			var splitChar = node.splitChar;
			var char = prefix.charAt(idx);
			
			if (char < splitChar) {
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1) {
					if (node.isKey && maxResults > 0) {
						results.push(node.key);
						maxResults--;
					}
					getAllKeysFrom(node.eqKid, results);
					break;
				}
				node = node.eqKid;
				idx++;
			} else {
				node = node.hiKid;
			}
		}
		
		return results;
	}
	
	function getAllKeysFrom(node:Node<T>, ?results:Array<String>):Array<String>
	{
		if (results == null) results = [];

		if (node == null || maxResults <= 0) return results;

		examinedNodes++;
		if (node.loKid != null) {
			getAllKeysFrom(node.loKid, results);
		}
		if (node.isKey) {
			if (maxResults > 0) results.push(node.key);
			maxResults--;
		}
		if (node.eqKid != null) {
			getAllKeysFrom(node.eqKid, results);
		}
		if (node.hiKid != null) {
			getAllKeysFrom(node.hiKid, results);
		}
		
		return results;
	}
	
	function _patternSearch(node:Node<T>, pattern:String, ?results:Array<String>, idx:Int = 0):Array<String>
	{
		if (results == null) results = [];
		
		if (node == null || maxResults <= 0) return results;
		
		examinedNodes++;
		var splitChar = node.splitChar;
		var char = pattern.charAt(idx);
		var len = pattern.length;
		var isAny = char == ANY_CHAR;
		
		if ((isAny || char < splitChar) && node.loKid != null) {
			_patternSearch(node.loKid, pattern, results, idx);
		} 
		if (isAny || char == splitChar) {
			if (idx < len - 1 && node.eqKid != null) {
				_patternSearch(node.eqKid, pattern, results, idx + 1);
			} else if (idx == len - 1 && node.isKey) {
				if (maxResults > 0) results.push(node.key);
				maxResults--;
			}
		}
		if ((isAny || char > splitChar) && node.hiKid != null) {
			_patternSearch(node.hiKid, pattern, results, idx);
		}
		
		return results;
	}
	
	function _distanceSearch(node:Node<T>, key:String, distance:Int, ?results:Array<String>, idx:Int = 0):Array<String>
	{
		if (results == null) results = [];
		
		if (node == null || distance < 0 || maxResults <= 0) return results;
		
		examinedNodes++;
		var splitChar = node.splitChar;
		var char = key.charAt(idx);
		var len = key.length;
		var examineEqKid = true;
		
		if ((distance > 0 || char < splitChar) && node.loKid != null) {
			_distanceSearch(node.loKid, key, distance, results, idx);
		}
		if (node.isKey) {
			var nodeKey = node.key;
			var lengthDiff = nodeKey.length - len;
			var dist = distance - (char != splitChar ? 1 : 0);
			if (len - idx - 1 <= dist && lengthDiff == 0) {
				if (maxResults > 0) results.push(nodeKey);
				maxResults--;
			}
			examineEqKid = lengthDiff < 0;
		}
		if (node.eqKid != null && examineEqKid) {
			_distanceSearch(node.eqKid, key, char == splitChar ? distance : distance - 1, results, idx + 1);
		}
		if ((distance > 0 || char > splitChar) && node.hiKid != null) {
			_distanceSearch(node.hiKid, key, distance, results, idx);
		} 
		
		return results;
	}
}

private class Node<T>
{
	public var splitChar:String;
	public var loKid:Node<T> = null;
	public var eqKid:Node<T> = null;
	public var hiKid:Node<T> = null;
	public var data:T;
	public var key:String;
	public var isKey:Bool = false;
	
	public function new(char:String):Void 
	{
		this.splitChar = char;
	}
}
