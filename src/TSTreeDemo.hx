package;

import haxe.Resource;
import haxe.Timer;
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
	
	var fps:FPS;
	var statsText:TextField;
	var perfText:TextField;
	var dictInfo:TextField;
	var time:Float = 0;
	
	var prefixBox:TextBox;
	var matchBox:TextBox;
	var exactBox:TextBox;
	var nearestBox:TextBox;

	var tree:TSTree<String>;
	var dictWords:Array<String>;
	
	
	public function new()
	{
		super();
		
		Tests.run();
		
		tree = new TSTree<String>();
		
		dictInfo = TextBox.getTextField("", 200, 0);
		addChild(dictInfo);
		loadDictionary();
		//quit();
		
		perfText = TextBox.getTextField("", 0, stage.stageHeight - 18);
		addChild(perfText);
		
		exactBox = new TextBox("hasKey", 50, 50, 0, onExactChange);
		exactBox.text = "well";
		onExactChange();
		addChild(exactBox);
		
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
		tree.clear();
		
		stopWatch();
		var dictText = Macros.readFile("assets/dict_25k.txt");
		//var dictText = haxe.Resource.getString("dictionary");
		var dictWords:Array<String> = dictText.split("\r\n");
		var loadTime = stopWatch();
		/*for (word in dictWords) {
			tree.insert(word, word);
		}*/
		//tree.randomBulkInsert(dictWords, dictWords);
		tree.bulkInsert(dictWords, dictWords, true);
		
		var insertTime = stopWatch();
		dictInfo.text = 'Dictionary: ${dictWords.length} words loaded in ${loadTime}s, inserted in ${insertTime}s';
		//trace('Dictionary: ${dictWords.length} words loaded in ${delta}s');
		//quit();
	}
	
	public function onExactChange(?e:Event):Void 
	{
		stopWatch();
		var result = tree.hasKey(exactBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s';
		exactBox.results = [Std.string(result)];
	}
	
	public function onPrefixChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.prefixSearch(prefixBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s';
		prefixBox.results = results;
	}
	
	public function onMatchChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.match(matchBox.text);
		perfText.text = 'last search executed in ${stopWatch()}s';
		matchBox.results = results;
	}
	
	public function onNearestChange(?e:Event):Void 
	{
		stopWatch();
		var results = tree.nearest(nearestBox.text, 2);
		perfText.text = 'last search executed in ${stopWatch()}s';
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