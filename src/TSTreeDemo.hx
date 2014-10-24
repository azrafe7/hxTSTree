package;

import haxe.Resource;
import haxe.Serializer;
import haxe.Timer;
import haxe.unit.TestCase;
import haxe.Unserializer;
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
#if sys
import sys.io.File;
#end

using StringTools;


/**
 * 
 * @author azrafe7
 */
class TSTreeDemo extends Sprite {
	
	var fps:FPS;
	var statsText:TextField;
	var perfText:TextField;
	var dictInfo:TextField;
	var time:Float = 0;
	
	var prefixBox:TextBox;
	var patternBox:TextBox;
	var hasKeyBox:TextBox;
	var distanceBox:TextBox;

	var tree:TSTree;
	var dictWords:Array<String>;
	var distance:Int = 2;
	
	public function new()
	{
		super();
		
		Tests.run();
		
		tree = new TSTree();
		
		dictInfo = TextBox.getTextField("", 150, 0);
		addChild(dictInfo);
		loadDictionary();
		
		perfText = TextBox.getTextField("", 0, stage.stageHeight - 18);
		addChild(perfText);
		
		hasKeyBox = new TextBox("hasKey", 50, 50, 0, onHasKeyChange);
		hasKeyBox.text = "well";
		onHasKeyChange();
		addChild(hasKeyBox);
		
		prefixBox = new TextBox("prefix", 200, 50, 15, onPrefixChange);
		prefixBox.text = "war";
		onPrefixChange();
		addChild(prefixBox);
		
		patternBox = new TextBox("pattern", 350, 50, 15, onPatternChange);
		patternBox.text = "w...d";
		onPatternChange();
		addChild(patternBox);
		
		distanceBox = new TextBox('distance ($distance)', 500, 50, 15, onDistanceChange);
		distanceBox.text = "world";
		onDistanceChange();
		addChild(distanceBox);
		
		
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
		tree.clear();
		
		stopWatch();
		var dictPath:String = "assets/dict_350k.txt";
		var isSerialized = dictPath.indexOf("serialized_") >= 0;	
	#if sys	
		var dictText:String = sys.io.File.getContent("../../../../" + dictPath);
	#else
		var dictText:String = Macros.readFile("assets/dict_350k.txt");
	#end
		//var dictText = haxe.Resource.getString("dictionary");
		if (!isSerialized) dictWords = dictText.split("\r\n");
		
		var loadTime = stopWatch();
		
		if (!isSerialized) {
			/*for (word in dictWords) {
				tree.insert(word);
			}*/
			tree.bulkInsert(dictWords);
			//tree.randomBulkInsert(dictWords);
			//tree.balancedBulkInsert(dictWords, false);
			//trace(tree.getBalancedIndices(dictWords));
		} else {
			tree = TSTree.unserialize(dictText);
			trace("from serialized");
		}
		var insertTime = stopWatch();
		dictInfo.text = 'Dictionary: ${tree.numKeys} words loaded in ${loadTime}s, inserted in ${insertTime}s (${tree.numNodes} nodes)';
		
	#if sys
		//generateDOTFiles(tree);
		//if (!isSerialized) serialize(dictPath);
		//tree.writeOptimizedDict("../../../../" + dictPath, "optimized_" + dictPath.substr(dictPath.lastIndexOf("/") + 1));
	#end
		//quit();
	}
	
	public function serialize(dictPath:String):Void 
	{
	#if sys
		var filename = "serialized_" + dictPath.substr(dictPath.lastIndexOf("/") + 1);
		
		trace("Serializing");
		stopWatch();
		var str = tree.serialize();
		trace(stopWatch(), str.length);
		sys.io.File.saveContent(filename, str);
	
		trace("Unserializing");
		str = sys.io.File.getContent(filename);
		stopWatch();
		var uTree = TSTree.unserialize(str);
		trace(stopWatch(), uTree.numKeys);
		tree = uTree;
	#end
	}
	
	public function generateDOTFiles<T>(t:TSTree, maxNodes:Int = 200):Void 
	{
	#if sys
		trace("Generating graphviz graphs...");
		t.clear();
		t.bulkInsert(dictWords);
		t.writeDotFile("bulkInsert.dot", null, maxNodes);
		
		t.clear();
		t.randomBulkInsert(dictWords);
		t.writeDotFile("randomBulkInsert.dot", null, maxNodes);
		
		t.clear();
		t.balancedBulkInsert(dictWords);
		t.writeDotFile("balancedBulkInsert.dot", null, maxNodes);
		
		
		trace("Done");
	#end
	}
	
	public function onHasKeyChange(?e:Event):Void 
	{
		stopWatch();
		var result = tree.hasKey(hasKeyBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		hasKeyBox.results = [Std.string(result)];
	}
	
	public function onPrefixChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.prefixSearch(prefixBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		prefixBox.results = results;
	}
	
	public function onPatternChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.patternSearch(patternBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		patternBox.results = results;
	}
	
	public function onDistanceChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.distanceSearch(distanceBox.text, distance);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		distanceBox.results = results;
	}
	
	public function changeHammingDistance(newDistance:Int):Void 
	{
		if (newDistance < 0) distance = 0;
		else if (newDistance > 5) distance = 5;
		else distance = newDistance;
		distanceBox.label = 'distance ($distance)';
		onDistanceChange();
	}
	
	public function onEnterFrame(e:Event):Void 
	{
		var mem = toFixed(System.totalMemory / 1024 / 1024, 2);
		statsText.text = 'FPS: ${fps.currentFPS} MEM: $mem';
	}
	
	public function onKeyDown(e:KeyboardEvent):Void 
	{
		if (e.keyCode == 27) {	// ESC
			quit();
		} else if (e.keyCode == 38) {	// UP
			changeHammingDistance(distance + 1);
		} else if (e.keyCode == 40) {	// DOWN
			changeHammingDistance(distance - 1);
		}
	}
	
	public function stopWatch():Float 
	{
		var delta = Timer.stamp() - time;
		time = Timer.stamp();
		return toFixed(delta, 2);
	}
	
	static public function quit():Void 
	{
	#if (flash || html5)
		System.exit(1);
	#else
		Sys.exit(1);
	#end
	}
	
	static public inline function toFixed(num:Float, precision:Int):Float
	{
		var exp:Float = Math.pow(10, precision);
		return Math.round(num * exp) / exp;
	}
}