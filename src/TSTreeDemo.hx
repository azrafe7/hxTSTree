package;

import haxe.unit.TestCase;
import openfl.Assets;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.filters.GlowFilter;
import openfl.system.System;
import ds.TSTree;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

using StringTools;


/**
 * 
 * @author azrafe7
 */
class TSTreeDemo extends Sprite {
	
	
	var dict = ["in", "john", "gin", "inn", "pin", "longjohn", "apple", "fin", "pint", "inner", "an", "pit"];
	//var dict = ["gin", "inn", "pin", "pit"];
	
	var fps:FPS;
	var statsText:TextField;
	
	var prefixBox:TextBox;
	var matchBox:TextBox;
	var containsBox:TextBox;
	var nearestBox:TextBox;

	var tree:TSTree<String>;
	var dictWords:Array<String>;
	
	public function new()
	{
		super();
		
		tree = new TSTree<String>();
		
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
		
		trace(tree.match("..n"));
		trace(tree.match("in"));
		trace(tree.match("in."));
		trace(tree.match(".in"));
		trace(tree.match(".i."));
		trace(tree.match(".ohn"));
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
		
		loadDictionary();
		
		
		containsBox = new TextBox("contains", 50, 50, 0, onContainsChange);
		containsBox.text = "well";
		onContainsChange();
		addChild(containsBox);
		
		prefixBox = new TextBox("prefix", 200, 50, 15, onPrefixChange);
		prefixBox.text = "war";
		onPrefixChange();
		addChild(prefixBox);
		
		matchBox = new TextBox("match", 350, 50, 15, onMatchChange);
		matchBox.text = "w...d";
		onMatchChange();
		addChild(matchBox);
		
		nearestBox = new TextBox("nearest (dist = 2)", 500, 50, 15, onNearestChange);
		nearestBox.text = "world";
		onNearestChange();
		addChild(nearestBox);
		
		
		
		fps = new FPS(0, 0, 0xFFFFFF);
		fps.visible = false;
		statsText = TextBox.getTextField("prefixResults", 0, 0);
		addChild(statsText);
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		//quit();
	}
	
	public function loadDictionary():Void 
	{
		var dictText = Assets.getText("dict.txt");
		var dictWords:Array<String> = dictText.split("\r\n");
		
		tree.clear();
		
		for (word in dictWords) {
			tree.insert(word.trim(), null);
		}
	}
	
	public function onContainsChange(?e:Event):Void 
	{
		var result = tree.contains(containsBox.text);
		containsBox.results = [Std.string(result)];
	}
	
	public function onPrefixChange(?e:Event):Void 
	{
		var results = tree.prefixSearch(prefixBox.text);
		prefixBox.results = results;
	}
	
	public function onMatchChange(?e:Event):Void 
	{
		var results = tree.match(matchBox.text);
		matchBox.results = results;
	}
	
	public function onNearestChange(?e:Event):Void 
	{
		var results = tree.nearest(nearestBox.text, 2);
		nearestBox.results = results;
	}
	
	public function onEnterFrame(e:Event):Void 
	{
		var mem = toFixed(System.totalMemory / 1024 / 1024, 2);
		statsText.text = 'FPS: ${fps.currentFPS} MEM: $mem';
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
	
	public static inline function toFixed(num:Float, precision:Int):Float
	{
		var exp:Float = Math.pow(10, precision);
		return Math.round(num * exp) / exp;
	}
}