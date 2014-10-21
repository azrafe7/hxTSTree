package ;

import ds.TSTree;
import flash.Lib;
import haxe.ds.ArraySort;
import haxe.ds.GenericStack;
import haxe.Log;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;


using StringTools;

/**
 * ...
 * @author azrafe7
 */
class Tests extends TestCase
{

	var dict = ["in", "John", "gin", "inn", "pin", "longjohn", "apple", "fin", "pint", "inner", "an", "pit"];
	var tree:TSTree<String>;
	
	
	public function new()
	{
		super();
		
		tree = new TSTree<String>();		
		for (s in dict) tree.insert(s, s);
		
		tree.clear();
		tree.bulkInsert(dict, dict, false);
        //var indices = [for (i in 0...10) String.fromCharCode("0".code + i)];
        //rinsall(indices, indices.length, tree);
        //insall(indices);
		//TSTreeDemo.quit();
    }
    
    static function rinsall(arr:Array<Dynamic>, n:Int, tree:TSTree<String>) {
        var m:Int;
        if (n < 1) return;
        m = n >> 1;
        trace(arr[m]);
		tree.insert(arr[m], arr[m]);
        rinsall(arr, m, tree);
		rinsall(arr.slice(m + 1), n - m - 1, tree);
    }

	static function insall(arr:Array<Dynamic>):Void 
	{
		var len = arr.length;
		var mid = len >> 1;
		var queue = [mid];
		while (queue.length > 0) {
			var m = queue.pop();
			if (m < 0 || m > len) continue;
			trace(arr[m]);
			if (m > 0 && m < mid) {
				queue.push(mid + (m >> 1));
				queue.push(mid - (m >> 1));
			}
			//base = m + 1;
			//stack.push(n - m - 1); 
		}
	}
	
	public function testContains():Void 
	{
		assertFalse(tree.hasKey(""));
		assertTrue(tree.hasKey("in"));
		assertTrue(tree.hasKey("inn"));
		assertFalse(tree.hasKey("john"));
	}
	
	public function testGetData():Void 
	{
		assertTrue(tree.getDataFor("John") == "John");
		assertTrue(tree.getDataFor("") == null);
		assertTrue(tree.getDataFor("pit") == "pit");
		assertTrue(tree.getDataFor("in") == "in");
		tree.insert("in", "overwritten");
		assertTrue(tree.getDataFor("in") == "overwritten");
	}
	
	public function testPrefixSearch():Void 
	{
		assertTrue(tree.prefixSearch("").length == 0);
		assertEquals("[pin,pint,pit]", Std.string(tree.prefixSearch("p")));
		assertEquals("[in,inn,inner]", Std.string(tree.prefixSearch("in")));
	}
	
	public function testMatchSearch():Void 
	{
		assertTrue(tree.match("").length == 0);
		assertEquals("[fin,gin,pin]", Std.string(tree.match(".in")));
		assertEquals("[pin,pit]", Std.string(tree.match("p..")));
	}
	
	public function testNearestSearch():Void 
	{
		assertTrue(tree.nearest("", 3).length == 0);
		assertEquals("[]", Std.string(tree.nearest("min", 0)));
		assertEquals("[pin]", Std.string(tree.nearest("pin", 0)));
		assertEquals("[fin,gin,pin]", Std.string(tree.nearest("min", 1)));
		assertEquals("[fin,gin,inn,pin,pit]", Std.string(tree.nearest("min", 2)));
		assertEquals("[an,in]", Std.string(tree.nearest("io", 5)));
		assertEquals("[an,in]", Std.string(tree.nearest("_n", 1)));
	}
	
	static public function run():Void 
	{
		var runner = new CustomTestRunner();
		runner.add(new Tests());
		var success = runner.run();
	}
}


private class CustomTestRunner extends TestRunner {
	
#if flash
	var stringBuffer:StringBuf;
	
	override public function run():Bool 
	{
		var oldPrint = TestRunner.print;
		stringBuffer = new StringBuf();
		
		TestRunner.print = function (v:Dynamic):Void {
			stringBuffer.add(Std.string(v));
		};
		
		var result = super.run();
		flash.Lib.trace(stringBuffer.toString());
		TestRunner.print = oldPrint;
		
		return result;
	}
#end
}