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
@:access(ds.TSTree)
class TSTreeDemo extends Sprite {
	
	inline static var BOX_WIDTH:Int = 150;
	inline static var BOX_GAP:Int = 10;
	inline static var START_X:Int = 10;
	inline static var START_Y:Int = 50;
	
	var fps:FPS;
	var statsText:TextField;
	var perfText:TextField;
	var dictInfo:TextField;
	static var time:Float = 0;
	
	var hasKeyBox:TextBox;
	var prefixBox:TextBox;
	var patternBox:TextBox;
	var hammingBox:TextBox;
	var levenshteinBox:TextBox;
	var prevKeyBox:TextBox;
	var nextKeyBox:TextBox;

	var tree:TSTree<String>;
	var dictWords:Array<String>;
	var hammingDistance:Int = 2;
	var levenshteinDistance:Int = 2;
	
	public function new()
	{
		super();
		
		Tests.run();
		
		tree = new TSTree<String>();
		
		dictInfo = TextBox.getTextField("", getXForBox(1), 0);
		addChild(dictInfo);
		loadDictionary();
		
		perfText = TextBox.getTextField("", 0, stage.stageHeight - 18);
		addChild(perfText);
		
		hasKeyBox = new TextBox("hasKey", getXForBox(0), START_Y, 0, onHasKeyChange);
		hasKeyBox.text = "well";
		onHasKeyChange();
		addChild(hasKeyBox);
		
		prefixBox = new TextBox("prefix", getXForBox(1), START_Y, 15, onPrefixChange);
		prefixBox.text = "war";
		onPrefixChange();
		addChild(prefixBox);
		
		patternBox = new TextBox("pattern", getXForBox(2), START_Y, 15, onPatternChange);
		patternBox.text = "w...d";
		onPatternChange();
		addChild(patternBox);
		
		hammingBox = new TextBox('hamming ($hammingDistance)', getXForBox(3), START_Y, 15, onHammingDistanceChange);
		hammingBox.text = "world";
		onHammingDistanceChange();
		addChild(hammingBox);
		
		levenshteinBox = new TextBox('levenshtein ($levenshteinDistance)', getXForBox(4), START_Y, 15, onLevenshteinDistanceChange);
		levenshteinBox.text = "world";
		onLevenshteinDistanceChange();
		addChild(levenshteinBox);
		
		prevKeyBox = new TextBox("prevKey", getXForBox(0), START_Y + 80, 0, onPrevKeyChange);
		prevKeyBox.text = "warden";
		onPrevKeyChange();
		addChild(prevKeyBox);
		
		nextKeyBox = new TextBox("nextKey", getXForBox(0), START_Y + 160, 0, onNextKeyChange);
		nextKeyBox.text = "warden";
		onNextKeyChange();
		addChild(nextKeyBox);
		
		
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
		var isOptimized = dictPath.indexOf("optimized_") >= 0;
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
				tree.insert(word, word);
			}*/
			if (isOptimized) {
				tree.bulkInsert(dictWords, dictWords);
			} else {
				//tree.bulkInsert(dictWords, dictWords);
				//tree.randomBulkInsert(dictWords, dictWords);
				tree.balancedBulkInsert(dictWords, dictWords, false);
			}
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
	
	public function generateDOTFiles<T>(t:TSTree<T>, maxNodes:Int = 200):Void 
	{
	#if sys
		trace("Generating graphviz graphs...");
		t.clear();
		t.bulkInsert(dictWords, null);
		t.writeDotFile("bulkInsert.dot", null, maxNodes);
		
		t.clear();
		t.randomBulkInsert(dictWords, null);
		t.writeDotFile("randomBulkInsert.dot", null, maxNodes);
		
		t.clear();
		t.balancedBulkInsert(dictWords, null, false);
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
	
	public function onPrevKeyChange(?e:Event):Void 
	{
		stopWatch();
		var result = tree.prevOf(prevKeyBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		prevKeyBox.results = [Std.string(result)];
	}
	
	public function onNextKeyChange(?e:Event):Void 
	{
		stopWatch();
		var result = tree.nextOf(nextKeyBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		nextKeyBox.results = [Std.string(result)];
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
	
	public function onHammingDistanceChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.hammingSearch(hammingBox.text, hammingDistance);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		hammingBox.results = results;
	}
	
	public function onLevenshteinDistanceChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.levenshteinSearch(levenshteinBox.text, levenshteinDistance);
		perfText.text = 'last search executed in ${stopWatch()}s (${tree.examinedNodes} nodes examined)';
		levenshteinBox.results = results;
	}
	
	public function changeHammingDistance(newDistance:Int):Void 
	{
		if (newDistance < 0) hammingDistance = 0;
		else if (newDistance > 5) hammingDistance = 5;
		else hammingDistance = newDistance;
		hammingBox.label = 'hamming ($hammingDistance)';
		onHammingDistanceChange();
	}
	
	public function changeLevenshteinDistance(newDistance:Int):Void 
	{
		if (newDistance < 0) levenshteinDistance = 0;
		else if (newDistance > 5) levenshteinDistance = 5;
		else levenshteinDistance = newDistance;
		levenshteinBox.label = 'levenshtein ($levenshteinDistance)';
		onLevenshteinDistanceChange();
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
			if (e.shiftKey) {
				changeLevenshteinDistance(levenshteinDistance + 1);
			} else {
				changeHammingDistance(hammingDistance + 1);
			}
		} else if (e.keyCode == 40) {	// DOWN
			if (e.shiftKey) {
				changeLevenshteinDistance(levenshteinDistance - 1);
			} else {
				changeHammingDistance(hammingDistance - 1);
			}
		}
	}
	
	static public function stopWatch():Float 
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
	
	public function getXForBox(n:Int):Float 
	{
		return START_X + (n * (BOX_WIDTH + BOX_GAP));
	}
	
	static public inline function toFixed(num:Float, precision:Int):Float
	{
		var exp:Float = Math.pow(10, precision);
		return Math.round(num * exp) / exp;
	}
}