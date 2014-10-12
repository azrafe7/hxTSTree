package;

import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.system.System;
import ds.TSTree;


/**
 * 
 * @author azrafe7
 */
class TSTreeDemo extends Sprite {
	
	var dict = ["in", "john", "gin", "inn", "pin", "longjohn", "apple", "fin", "pint", "inner", "an"];
	
	public function new () 
	{
		super();
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		var tree = new TSTree<String>();
		
		for (s in dict) tree.insert(s, s);
		tree.insert("in", "overwritten");
		
		trace("all words");
		tree.traverse(tree.root);
		trace("\n");
		
		trace("contains");
		trace(tree.contains("i"));
		trace(tree.contains("inn"));
		trace(tree.contains("ohn"));
		trace(tree.contains(""));
		trace("\n");
		
		trace(tree.getDataFor("i"));
		trace(tree.getDataFor("inn"));
		trace(tree.getDataFor("ohn"));
		trace(tree.getDataFor(""));
		trace("\n");
		
		trace(tree.match("??n"));
		trace(tree.match("in"));
		trace(tree.match("in?"));
		trace(tree.match("?in"));
		trace(tree.match("?i?"));
		trace(tree.match("?ohn"));
		trace("\n");
		
		trace(tree.prefixSearch(""));
		trace(tree.prefixSearch("inn"));
		trace(tree.prefixSearch("i"));
		trace(tree.prefixSearch("p"));
		trace(tree.prefixSearch("a"));
		trace("\n");
		
		trace(tree.nearest("inn", 0));
		trace(tree.nearest("in", 1));
		trace(tree.nearest("in", 2));
		trace(tree.nearest("min", 0));
		trace(tree.nearest("min", 1));
		trace(tree.nearest("min", 2));
		trace(tree.nearest("mint", 2));
		trace(tree.nearest("hn", 3));
		trace("\n");
		
		quit();
	}
	
	public function onKeyDown(e:KeyboardEvent):Void 
	{
		if (e.keyCode == 27) {
			quit();
		}
	}
	
	public function quit():Void 
	{
	#if (flash || html5)
		System.exit(1);
	#else
		Sys.exit(1);
	#end
	}
}