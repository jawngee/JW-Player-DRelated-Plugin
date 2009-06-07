/**
* Parse an Subrip caption file and return an array of captions.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class SRTParser {


	/** 
	* Parse the captions textblob into an array.
	*
	* @param dat	The loaded captions text, which must be in SubRip (.srt) format.
	* @return		An array with captions.
	* 				Each caption is an object with 'begin', 'end' and 'text' parameters.
	**/
	public static function parseCaptions(dat:String):Array {
		var arr:Array = new Array();
		var lst:Array = dat.split("\r\n\r\n");
		if(lst.length == 1) { lst = dat.split("\n\n"); }
		for(var i:Number=0; i<lst.length; i++) {
				var obj:Object = SRTParser.parseCaption(lst[i]);
			if(obj['end']) { arr.push(obj); }
		}
		return arr;
	};


	/** Parse a single captions entry. **/
	private static function parseCaption(dat:String):Object {
		var obj:Object = new Object();
		var arr:Array = dat.split("\r\n");
		if(arr.length == 1) { arr = dat.split("\n"); }
		try { 
			var idx:Number = arr[1].indexOf(' --> ');
			obj['begin'] = Strings.seconds(arr[1].substr(0,idx));
			obj['end'] = Strings.seconds(arr[1].substr(idx+5));
			obj['text'] = arr[2];
			if(arr[3]) { obj['text'] += '<br />'+arr[3]; }
		} catch (err:Error) {}
		return obj;
	};


}


}