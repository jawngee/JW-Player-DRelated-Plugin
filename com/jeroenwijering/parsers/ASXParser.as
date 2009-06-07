/**
* Parse an ASX feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;
import com.jeroenwijering.parsers.ObjectParser;


public class ASXParser extends ObjectParser {


	/** Parse an ASX playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr:Array = new Array();
		var itm:Object = new Object();
		for each (var i:XML in dat.children()) {
			itm = ASXParser.parseItem(i);
			if(itm['type'] != undefined) {
				arr.push(itm);
			}
			itm = {};
		}
		return arr;
	};


	/** Translate ASX item to playlist item. **/
	public static function parseItem(obj:XML):Object {
		var itm:Object =  new Object();
		for each (var i:XML in obj.children()) {
			if(!i.localName()) { break; }
			switch(i.localName().toLowerCase()) {
				case 'ref':
					itm['file'] = i.@href.toString();
					break;
				case 'title':
					itm['title'] = i.text().toString();
					break;
				case 'moreinfo':
					itm['link'] = i.@href.toString();
					break;
				case 'abstract':
					itm['description'] = i.text().toString();
					break;
				case 'author':
					itm['author'] = i.text().toString();
					break;
				case 'duration':
					itm['duration'] = Strings.seconds(i.@value);
					break;
				case 'starttime':
					itm['start'] = Strings.seconds(i.@value);
					break;
				case 'param':
					itm[i.@name] = i.@value.toString();
					break;
			}
		}
		return ObjectParser.complete(itm);
	};


}


}