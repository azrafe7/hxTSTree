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
	
	var TEXT_COLOR:Int = 0xFFFFFFFF;
	var TEXT_INPUT_BG:Int = 0xFF605050;
	var TEXT_INPUT_WIDTH:Int = 140;
	var TEXT_INPUT_BORDER:Int = 0xFF202020;
	var TEXT_FONT:String = "_typewriter";
	var TEXT_SIZE:Float = 12;
	var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 2, 2, 6);
	var MAX_RESULTS:Int = 15;
	
	var dict = ["in", "john", "gin", "inn", "pin", "longjohn", "apple", "fin", "pint", "inner", "an"];
	var fps:FPS;
	var statsText:TextField;
	var prefixInput:TextField;
	var prefixResults:TextField;
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
		
		var dictText = Assets.getText("dict.txt");
		var dictWords:Array<String> = dictText.split("\r\n");
		
		prefixInput = getTextField("prefixSearch", 50, 50, null, true);
		addChild(prefixInput);
		prefixInput.addEventListener(Event.CHANGE, onPrefixChange);
		prefixResults = getTextField("", prefixInput.x, prefixInput.y + 20);
		addChild(prefixResults);
		onPrefixChange();
		
		fps = new FPS(0, 0, 0xFFFFFF);
		fps.visible = false;
		statsText = getTextField("prefixResults", 0, 0);
		addChild(statsText);
		
		tree.clear();
		
		for (word in dictWords) {
			tree.insert(word.trim(), null);
		}
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		//quit();
	}
	
	public function onPrefixChange(?e:Event):Void 
	{
		var results = tree.prefixSearch(prefixInput.text);
		prefixResults.text = '[${results.length} results]\n';
		for (i in 0...results.length) {
			if (i > MAX_RESULTS) {
				prefixResults.appendText("...");
				break;
			} else {
				prefixResults.appendText(results[i] + "\n");
			}
		}
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
	
	public function getTextField(text:String = "", x:Float, y:Float, ?size:Float, inputType:Bool = false):TextField
	{
		var tf:TextField = new TextField();
		var fmt:TextFormat = new TextFormat(TEXT_FONT, null, TEXT_COLOR);
		fmt.align = TextFormatAlign.LEFT;
		fmt.size = size == null ? TEXT_SIZE : size;
		if (inputType) {
			tf.type = TextFieldType.INPUT;
			tf.background = true;
			tf.backgroundColor = TEXT_INPUT_BG;
			tf.border = true;
			tf.borderColor = TEXT_INPUT_BORDER;
			tf.width = TEXT_INPUT_WIDTH;
			tf.multiline = false;
			tf.height = tf.textHeight + 4;
		} else {
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.multiline = true;
			tf.filters = [TEXT_OUTLINE];
		}
		tf.defaultTextFormat = fmt;
		tf.selectable = inputType;
		tf.x = x;
		tf.y = y;
		tf.text = text;
		return tf;
	}

	public static inline function toFixed(num:Float, precision:Int):Float
	{
		var exp:Float = Math.pow(10, precision);
		return Math.round(num * exp) / exp;
	}
}