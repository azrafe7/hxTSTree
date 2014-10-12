package ds;

/**
 * ...
 * @author azrafe7
 */
class TSTree<T>
{

	public var ANY:String = "?";
	
	public var examinedNodes:Int = 0;
	
	
	public var root:Node<T> = null;
	
	
	public function new() 
	{
		
	}
	
	public function insert(word:String, data:T)
	{
		root = _recurInsert(root, word, data);
	}
	
	public function remove(word:String):Bool
	{
		var node = _getNodeFor(root, word);
		if (node != null) {
			node.splitChar = node.splitChar.substr(0, 1);
			return true;
		}
		return false;
	}
	
	public function contains(word:String):Bool
	{
		return _getNodeFor(root, word) != null;
	}
	
	public function prefixSearch(prefix:String, ?results:Array<String>):Array<String>
	{
		return _prefixSearch(root, prefix, results);
	}
	
	public function match(pattern:String, ?results:Array<String>):Array<String>
	{
		return _match(root, pattern, results);
	}
	
	public function nearest(word:String, distance:Int, ?results:Array<String>):Array<String>
	{
		if (distance > word.length) distance = word.length;
		return _nearest(root, word, distance, results);
	}
	
	public function getDataFor(word:String):T 
	{
		var node = _getNodeFor(root, word);
		return node != null ? node.data : null;
	}
	
	public function traverse(node:Node<T>, ?callback:Node<T>->Void):Void 
	{
		if (node == null) return;
		
		traverse(node.loKid);
		if (node.isWord) {
			trace(node.splitChar.substr(2) + ":" + node.data);
		} 
		traverse(node.eqKid);
		traverse(node.hiKid);
	}
	
	public function isEmpty():Bool
	{
		return root == null;
	}
	
	function _recurInsert(node:Node<T>, word:String, data:T, idx:Int = 0):Node<T>
	{
		if (node == null) {
			node = new Node();
			node.splitChar = word.charAt(idx);
		}
		
		var splitChar = node.splitChar.charAt(0);
		var char = word.charAt(idx);
		var len = word.length;
		if (char < splitChar) {
			node.loKid = _recurInsert(node.loKid, word, data, idx);
		} else if (char == splitChar) {
			if (idx == len - 1) {
				node.data = data;
				node.isWord = true;
				node.splitChar = char + "|" + word;
			} else {
				node.eqKid = _recurInsert(node.eqKid, word, data, ++idx);
			}
		} else {
			node.hiKid = _recurInsert(node.hiKid, word, data, idx);
		}
		
		return node;
	}
	
	function _getNodeFor(node:Node<T>, word:String):Node<T>
	{
		var idx:Int = 0;
		
		while (node != null) {
			var splitChar = node.splitChar.charAt(0);
			var char = word.charAt(idx);
			var len = word.length;
			
			if (char < splitChar) {
				node = node.loKid;
			} else if (char == splitChar) {
				if (idx == len - 1 && node.isWord) {
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
					if (node.isWord) {
						results.push(node.splitChar.substr(2));
					}
					_getAllWordsFrom(node.eqKid, results);
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
	
	function _getAllWordsFrom(node:Node<T>, ?results:Array<String>):Array<String>
	{
		if (results == null) results = [];

		if (node == null) return results;

		if (node.loKid != null) {
			_getAllWordsFrom(node.loKid, results);
		}
		if (node.isWord) {
			results.push(node.splitChar.substr(2));
		}
		if (node.eqKid != null) {
			_getAllWordsFrom(node.eqKid, results);
		}
		if (node.hiKid != null) {
			_getAllWordsFrom(node.hiKid, results);
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
		var isAny = char == ANY;
		
		if ((isAny || char < splitChar) && node.loKid != null) {
			_match(node.loKid, pattern, results, idx);
		} 
		if (isAny || char == splitChar) {
			if (idx < len - 1 && node.eqKid != null) {
				_match(node.eqKid, pattern, results, idx + 1);
			} else if (idx == len - 1 && node.isWord) {
				results.push(node.splitChar.substr(2));
			}
		}
		if ((isAny || char > splitChar) && node.hiKid != null) {
			_match(node.hiKid, pattern, results, idx);
		}
		
		return results;
	}
	
	function _nearest(node:Node<T>, word:String, distance:Int, ?results:Array<String>, idx:Int = 0):Array<String>
	{
		if (results == null) results = [];
		
		if (node == null || distance < 0) return results;
		
		examinedNodes++;
		var splitChar = node.splitChar.charAt(0);
		var char = word.charAt(idx);
		var len = word.length;
		var examineEqKid = true;
		
		if ((distance > 0 || char < splitChar) && node.loKid != null) {
			_nearest(node.loKid, word, distance, results, idx);
		}
		if (node.isWord) {
			var nodeWord = node.splitChar.substr(2);
			var lengthDiff = nodeWord.length - len;
			if (len - idx - 1 <= distance && lengthDiff == 0) {
				results.push(nodeWord);
			}
			examineEqKid = lengthDiff < 0;
		}
		if (node.eqKid != null && examineEqKid) {
			_nearest(node.eqKid, word, char == splitChar ? distance : distance - 1, results, len > 0 ? idx + 1 : idx);
		}
		if ((distance > 0 || char > splitChar) && node.hiKid != null) {
			_nearest(node.hiKid, word, distance, results, idx);
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
	public var isWord:Bool = false;
}
