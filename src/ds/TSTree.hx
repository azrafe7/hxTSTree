package ds;

import haxe.ds.ArraySort;
import haxe.unit.TestCase;
#if sys
import sys.io.File;
#end

/**
 * ...
 * @author azrafe7
 */
class TSTree<T>
{
	inline static public var MAX_INT:Int = 0x7FFFFFFF;
	var maxResults:Int = MAX_INT;
	
	public var ANY_CHAR(default, set):String = ".";
	private function set_ANY_CHAR(value:String):String 
	{
		if (value.length > 1) throw "`ANY_CHAR` must be a single character.";
		return ANY_CHAR = value;
	}
	
	public var numNodes(default, null):Int = 0;
	
	public var numKeys(default, null):Int = 0;
	
	public var examinedNodes(default, null):Int = 0;
	
	public var root:Node<T> = null;
	
	public function new() 
	{

	}
	
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
	
	public function bulkInsert(keys:Array<String>, ?values:Array<T>, isSorted:Bool = false):Void 
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
		
		// balanced insert
		var len = keys.length;
		var queue = new List();
		queue.add(0);
		queue.add(len);
		
		while (queue.length > 0) {
			var start = queue.first();
			queue.remove(start);
			var end = queue.first();
			queue.remove(end);
			var mid = ((end - start) >> 1) + start;
			
			var rightRange = end - mid;
			var leftRange = mid - start;
			
			insert(keys[indices[mid]], values != null ? values[indices[mid]] : null);
			if (leftRange == 1) insert(keys[indices[start]], values != null ? values[indices[start]] : null);
			if (rightRange == 1 && end < len) insert(keys[indices[end]], values != null ? values[indices[end]] : null);
			
			if (leftRange > 1) {
				queue.add(start);
				queue.add(mid - 1);
			}
			if (rightRange > 1) {
				queue.add(mid + 1);
				queue.add(end);
			}
		}
		indices = null;
	}
	
	public function bulkInsert2(keys:Array<String>, ?values:Array<T>, isSorted:Bool = false):Void 
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
		
		// balanced insert
		var len = keys.length;
		var queue = new List();
		queue.add(0);
		queue.add(len);
		
		var seq = [];
		while (queue.length > 0) {
			var start = queue.first();
			queue.remove(start);
			var end = queue.first();
			queue.remove(end);
			var mid = ((end - start) >> 1) + start;
			
			var rightRange = end - mid;
			var leftRange = mid - start;
			
			seq.push(indices[mid]);
			if (leftRange == 1) seq.push(indices[start]);
			if (rightRange == 1 && end < len) seq.push(indices[end]);
			
			if (leftRange > 1) {
				queue.add(start);
				queue.add(mid - 1);
			}
			if (rightRange > 1) {
				queue.add(mid + 1);
				queue.add(end);
			}
		}
		indices = null;
	}
	
	public function insert(key:String, ?data:T)
	{
		_insert(key, data);
	}
	
	public function remove(key:String):Bool
	{
		var node = _getNodeFor(root, key);
		if (node != null) {
			node.splitChar = node.splitChar.substr(0, 1);
			node.isKey = false;
			node.data = null;
			numKeys--;
			return true;
		}
		return false;
	}
	
	public function clear():Void 
	{
		root = null;
		numNodes = numKeys = 0;
	}
	
	public function hasKey(key:String):Bool
	{
		examinedNodes = 0;
		return _getNodeFor(root, key) != null;
	}
	
	public function prefixSearch(prefix:String, ?results:Array<String>, maxResults:Int = MAX_INT):Array<String>
	{
		examinedNodes = 0;
		this.maxResults = maxResults;
		return _prefixSearch(root, prefix, results);
	}
	
	public function match(pattern:String, ?results:Array<String>, maxResults:Int = MAX_INT):Array<String>
	{
		examinedNodes = 0;
		this.maxResults = maxResults;
		return _match(root, pattern, results);
	}
	
	public function nearest(key:String, distance:Int, ?results:Array<String>, maxResults:Int = MAX_INT):Array<String>
	{
		examinedNodes = 0;
		this.maxResults = maxResults;
		if (distance > key.length) distance = key.length;
		return _nearest(root, key, distance, results);
	}
	
	public function getDataFor(key:String):T 
	{
		examinedNodes = 0;
		var node = _getNodeFor(root, key);
		return node != null ? node.data : null;
	}
	
	public function traverse(node:Node<T>, callback:Node<T>->Void = null):Void 
	{
		if (node == null) return;
		
		traverse(node.loKid, callback);
		if (callback != null) callback(node);
		traverse(node.eqKid, callback);
		traverse(node.hiKid, callback);
	}
	
#if sys
	public function writeDotFile(path:String, ?label:String, maxNodes:Int = MAX_INT):Void 
	{
		trace('Writing dot file in "$path"...');
		var stringBuf = new StringBuf();
		stringBuf.add('digraph TSTree {\n\tnode [shape=record, fontname=Courier]\n\tgraph [fontname=Courier, style=bold]\n');
		
		var countNodes = 0;
		var indexQueue = new List();
		indexQueue.add(0);
		var queue = new List();
		queue.add(root);
		while (root != null && queue.length > 0 && maxNodes > 0) 
		{
			var idx = indexQueue.first();
			indexQueue.remove(idx);
			var node = queue.first();
			queue.remove(node);
			maxNodes--;
			countNodes++;
			
			var curr = '"${idx}" ';
			if (node.isKey) curr += '[label="${node.splitChar.charAt(0)}|${node.splitChar.substr(1)}", color=red]';
			else curr += '[label="${node.splitChar}"]';
			
			// curr node
			stringBuf.add('\t${curr}\n');
			
			var hasChildren = (node.loKid != null || node.eqKid != null || node.hiKid != null);
			
			// loKid
			if (hasChildren && maxNodes > 0) {
				stringBuf.add('\t"${idx}" -> "${idx * 3 + 1}"\n');
				if (node.loKid != null) {
					indexQueue.add(idx * 3 + 1);
					queue.add(node.loKid);
				} else {
					stringBuf.add('\t"${idx * 3 + 1}" [shape=point]\n');
				}
			}
			
			// eqKid
			if (hasChildren && maxNodes > 0) {
				stringBuf.add('\t"${idx}" -> "${idx * 3 + 2}" [style=dotted]\n');
				if (node.eqKid != null) {
					indexQueue.add(idx * 3 + 2);
					queue.add(node.eqKid);
				} else {
					stringBuf.add('\t"${idx * 3 + 2}" [shape=point]\n');
				}
			}
			
			// hiKid
			if (hasChildren && maxNodes > 0) {
				stringBuf.add('\t"${idx}" -> "${idx * 3 + 3}"\n');
				if (node.hiKid != null) {
					indexQueue.add(idx * 3 + 3);
					queue.add(node.hiKid);
				} else {
					stringBuf.add('\t"${idx * 3 + 3}" [shape=point]\n');
				}
			}
		}
		if (label == null) label = '<<b>file:$path (nodes shown: $countNodes)</b>>';
		stringBuf.add('\tlabelloc="t"\n\tlabeljust="l"\n\tlabel=<<b>$label</b>>\n');
		stringBuf.add("}\n");
		
		sys.io.File.saveContent(path, stringBuf.toString());
		trace('Done (${stringBuf.length} bytes written)');
	}
#end

	public function isEmpty():Bool
	{
		return root == null;
	}
	
	function _recurInsert(node:Node<T>, key:String, data:T, idx:Int = 0):Node<T>
	{
		if (node == null) {
			node = newNode(key.charAt(idx));
		}
		
		var splitChar = node.splitChar.charAt(0);
		var char = key.charAt(idx);
		var len = key.length;
		
		if (char < splitChar) {
			node.loKid = _recurInsert(node.loKid, key, data, idx);
		} else if (char == splitChar) {
			if (idx == len - 1) {
				node.data = data;
				if (!node.isKey) numKeys++;
				node.isKey = true;
				node.splitChar = char + key;
			} else {
				node.eqKid = _recurInsert(node.eqKid, key, data, ++idx);
			}
		} else {
			node.hiKid = _recurInsert(node.hiKid, key, data, idx);
		}
		
		return node;
	}
	
	inline function newNode(char:String):Node<T>
	{
		numNodes++;
		return new Node(char);
	}
	
	function _insert(key:String, data:T):Void
	{
		var idx = 0;
		var node = root;
		var len = key.length;
		while (idx < len) {
			if (root == null) {
				root = node = newNode(key.charAt(idx));
			}
			
			var splitChar = node.splitChar.charAt(0);
			var char = key.charAt(idx);
			
			if (char < splitChar) {
				if (node.loKid == null) node.loKid = newNode(char);
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1) {
					node.data = data;
					if (!node.isKey) numKeys++;
					node.isKey = true;
					node.splitChar = char + key;
				} else {
					if (node.eqKid == null) node.eqKid = newNode(key.charAt(idx + 1));
					node = node.eqKid;
				}
				idx++;
			} else {
				if (node.hiKid == null) node.hiKid = newNode(char);
				node = node.hiKid;
			}
		}
	}
	
	function _getNodeFor(node:Node<T>, key:String):Node<T>
	{
		var idx:Int = 0;
		var len = key.length;
		
		while (node != null) {
			examinedNodes++;
			var splitChar = node.splitChar.charAt(0);
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
			var splitChar = node.splitChar.charAt(0);
			var char = prefix.charAt(idx);
			
			if (char < splitChar) {
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1) {
					if (node.isKey && maxResults > 0) {
						results.push(node.splitChar.substr(1));
						maxResults--;
					}
					_getAllKeysFrom(node.eqKid, results);
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
	
	function _getAllKeysFrom(node:Node<T>, ?results:Array<String>):Array<String>
	{
		if (results == null) results = [];

		if (node == null || maxResults <= 0) return results;

		examinedNodes++;
		if (node.loKid != null) {
			_getAllKeysFrom(node.loKid, results);
		}
		if (node.isKey) {
			if (maxResults > 0) results.push(node.splitChar.substr(1));
			maxResults--;
		}
		if (node.eqKid != null) {
			_getAllKeysFrom(node.eqKid, results);
		}
		if (node.hiKid != null) {
			_getAllKeysFrom(node.hiKid, results);
		}
		
		return results;
	}
	
	function _match(node:Node<T>, pattern:String, ?results:Array<String>, idx:Int = 0):Array<String>
	{
		if (results == null) results = [];
		
		if (node == null || maxResults <= 0) return results;
		
		examinedNodes++;
		var splitChar = node.splitChar.charAt(0);
		var char = pattern.charAt(idx);
		var len = pattern.length;
		var isAny = char == ANY_CHAR;
		
		if ((isAny || char < splitChar) && node.loKid != null) {
			_match(node.loKid, pattern, results, idx);
		} 
		if (isAny || char == splitChar) {
			if (idx < len - 1 && node.eqKid != null) {
				_match(node.eqKid, pattern, results, idx + 1);
			} else if (idx == len - 1 && node.isKey) {
				if (maxResults > 0) results.push(node.splitChar.substr(1));
				maxResults--;
			}
		}
		if ((isAny || char > splitChar) && node.hiKid != null) {
			_match(node.hiKid, pattern, results, idx);
		}
		
		return results;
	}
	
	function _nearest(node:Node<T>, key:String, distance:Int, ?results:Array<String>, idx:Int = 0):Array<String>
	{
		if (results == null) results = [];
		
		if (node == null || distance < 0 || maxResults <= 0) return results;
		
		examinedNodes++;
		var splitChar = node.splitChar.charAt(0);
		var char = key.charAt(idx);
		var len = key.length;
		var examineEqKid = true;
		
		if ((distance > 0 || char < splitChar) && node.loKid != null) {
			_nearest(node.loKid, key, distance, results, idx);
		}
		if (node.isKey) {
			var nodeKey = node.splitChar.substr(1);
			var lengthDiff = nodeKey.length - len;
			var dist = distance - (char != splitChar ? 1 : 0);
			if (len - idx - 1 <= dist && lengthDiff == 0) {
				if (maxResults > 0) results.push(nodeKey);
				maxResults--;
			}
			examineEqKid = lengthDiff < 0;
		}
		if (node.eqKid != null && examineEqKid) {
			_nearest(node.eqKid, key, char == splitChar ? distance : distance - 1, results, idx + 1);
		}
		if ((distance > 0 || char > splitChar) && node.hiKid != null) {
			_nearest(node.hiKid, key, distance, results, idx);
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
	public var isKey:Bool = false;
	
	public function new(char:String):Void 
	{
		this.splitChar = char;
	}
}
