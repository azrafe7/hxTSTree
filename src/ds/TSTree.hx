package ds;
import haxe.ds.ArraySort;

/**
 * ...
 * @author azrafe7
 */
class TSTree<T>
{

	public var ANY_CHAR(default, set):String = ".";
	private function set_ANY_CHAR(value:String):String 
	{
		if (value.length > 1) throw "`ANY_CHAR` must be a single character.";
		return ANY_CHAR = value;
	}
	
	public var examinedNodes:Int = 0;
	
	
	public var root:Node<T> = null;
	
	
	public function new() 
	{
		
	}
	
	public function randomBulkInsert(keys:Array<String>, values:Array<T>):Void 
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
			insert(keys[idx], values[idx]);
		}
			
/*		while (currIdx > 0) {
			rndIdx = Math.floor(Math.random() * currIdx);
			currIdx--;
			
			tmp = keys[currIdx];
			tmpVal = values[currIdx];
			keys[currIdx] = keys[rndIdx];
			keys[rndIdx] = tmp;
			values[currIdx] = values[rndIdx];
			values[rndIdx] = tmpVal;
		}
		
		for (i in 0...keys.length) {
			insert(keys[i], values[i]);
		}
*/	}
	
	public function bulkInsert(keys:Array<String>, ?values:Array<T>, isSorted:Bool = false):Void 
	{
		if (keys == null || keys.length <= 0) return;
		if (values != null && keys.length != values.length) throw "Number of `keys` and number of `values` must match.";
		var indices = [for (i in 0...keys.length) i];
		if (!isSorted) {
			ArraySort.sort(indices, function (a:Int, b:Int):Int
			{
				var keyA:String = keys[a];
				var keyB:String = keys[b];
				return keyA > keyB ? 1 : keyA < keyB ? -1 : 0;
			});
		}
		trace(indices);
		trace(indices.map(function (i):String 
			{
				return keys[i];
			})
		);
		var m = keys.length >> 1;
		var stack = [indices[m]];
		/*while (stack.length > 0) {
			var idx = stack.pop();
			insert(keys[idx], values != null ? values[idx] : null);
			stack.push(idx - 1);
			stack.push(idx + 1);
		}*/
	}
	
	public function insert(key:String, data:T)
	{
		_insert(key, data);
	}
	
	public function remove(key:String):Bool
	{
		var node = _getNodeFor(root, key);
		if (node != null) {
			node.splitChar = node.splitChar.substr(0, 1);
			return true;
		}
		return false;
	}
	
	public function clear():Void 
	{
		root = null;
	}
	
	public function exactSearch(key:String):Bool
	{
		return _getNodeFor(root, key) != null;
	}
	
	public function prefixSearch(prefix:String, ?results:Array<String>):Array<String>
	{
		return _prefixSearch(root, prefix, results);
	}
	
	public function match(pattern:String, ?results:Array<String>):Array<String>
	{
		return _match(root, pattern, results);
	}
	
	public function nearest(key:String, distance:Int, ?results:Array<String>):Array<String>
	{
		if (distance > key.length) distance = key.length;
		return _nearest(root, key, distance, results);
	}
	
	public function getDataFor(key:String):T 
	{
		var node = _getNodeFor(root, key);
		return node != null ? node.data : null;
	}
	
	public function traverse(node:Node<T>, ?callback:Node<T>->Void):Void 
	{
		if (node == null) return;
		
		traverse(node.loKid);
		if (node.isKey) {
			trace(node.splitChar.substr(2) + ":" + node.data);
		} 
		traverse(node.eqKid);
		traverse(node.hiKid);
	}
	
	public function isEmpty():Bool
	{
		return root == null;
	}
	
	function _recurInsert(node:Node<T>, key:String, data:T, idx:Int = 0):Node<T>
	{
		if (node == null) {
			node = new Node(key.charAt(idx));
		}
		
		var splitChar = node.splitChar.charAt(0);
		var char = key.charAt(idx);
		var len = key.length;
		
		if (char < splitChar) {
			node.loKid = _recurInsert(node.loKid, key, data, idx);
		} else if (char == splitChar) {
			if (idx == len - 1) {
				node.data = data;
				node.isKey = true;
				node.splitChar = char + "|" + key;
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
		var idx = 0;
		var node = root;
		while (idx < key.length) {
			if (root == null) {
				root = node = new Node(key.charAt(idx));
			}
			
			var splitChar = node.splitChar.charAt(0);
			var char = key.charAt(idx);
			var len = key.length;
			
			if (char < splitChar) {
				if (node.loKid == null) node.loKid = new Node(char);
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1) {
					node.data = data;
					node.isKey = true;
					node.splitChar = char + "|" + key;
				} else {
					if (node.eqKid == null) node.eqKid = new Node(key.charAt(idx + 1));
					node = node.eqKid;
				}
				idx++;
			} else {
				if (node.hiKid == null) node.hiKid = new Node(char);
				node = node.hiKid;
			}
		}
	}
	
	function _getNodeFor(node:Node<T>, key:String):Node<T>
	{
		var idx:Int = 0;
		
		while (node != null) {
			var splitChar = node.splitChar.charAt(0);
			var char = key.charAt(idx);
			var len = key.length;
			
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

		while (node != null) {
			var splitChar = node.splitChar.charAt(0);
			var char = prefix.charAt(idx);
			var len = prefix.length;
			
			if (char < splitChar) {
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1) {
					if (node.isKey) {
						results.push(node.splitChar.substr(2));
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

		if (node == null) return results;

		if (node.loKid != null) {
			_getAllKeysFrom(node.loKid, results);
		}
		if (node.isKey) {
			results.push(node.splitChar.substr(2));
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
		
		if (node == null) return results;
		
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
				results.push(node.splitChar.substr(2));
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
		
		if (node == null || distance < 0) return results;
		
		examinedNodes++;
		var splitChar = node.splitChar.charAt(0);
		var char = key.charAt(idx);
		var len = key.length;
		var examineEqKid = true;
		
		if ((distance > 0 || char < splitChar) && node.loKid != null) {
			_nearest(node.loKid, key, distance, results, idx);
		}
		if (node.isKey) {
			var nodeKey = node.splitChar.substr(2);
			var lengthDiff = nodeKey.length - len;
			var dist = distance - (char != splitChar ? 1 : 0);
			if (len - idx - 1 <= dist && lengthDiff == 0) {
				results.push(nodeKey);
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
