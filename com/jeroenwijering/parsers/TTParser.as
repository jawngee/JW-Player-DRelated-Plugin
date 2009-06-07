/**
* Parse a TimedText XML and return an array of captions.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class TTParser {


	/** 
	* Parse the captions XML.
	*
	* @param dat	The loaded XML, which must be in W3C TimedText format.
	* @return		An array with captions. 
	* 				Each caption is an object with 'begin', 'end' and 'text' parameters.
	**/
	public static function parseCaptions(dat:XML):Array {
		var arr:Array = new Array();
		for each (var i:XML in dat.children()) {
			if(i.localName() == "body") {
				for each (var j:XML in i.children()) {
					for each (var k:XML in j.children()) {
						if(k.localName() == 'p') {
							arr.push(TTParser.parseCaption(k));
						}
					}
				}
			}
		}
		return arr;
	};


	/** Parse a single captions entry. **/
	private static function parseCaption(dat:XML):Object {
		var obj:Object = {
			begin:Strings.seconds(dat.@begin),
			dur:Strings.seconds(dat.@dur),
			end:Strings.seconds(dat.@end),
			text:Strings.replace(dat.children().toString(),"\n","")
		};
		if(obj['dur']) {
			obj['end'] = obj['begin'] + obj['dur'];
			delete obj['dur'];
		}
		return obj;
	};


}


}