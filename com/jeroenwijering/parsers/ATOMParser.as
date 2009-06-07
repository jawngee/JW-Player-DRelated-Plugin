/**
* Parse an ATOM feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.parsers.MediaParser;
import com.jeroenwijering.parsers.ObjectParser;
import com.jeroenwijering.utils.Strings;


public class ATOMParser extends ObjectParser {


	/** Parse an RSS playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr:Array = new Array();
		var itm:Object = new Object();
		for each (var i:XML in dat.children()) {
			if (i.localName() == 'entry') {
				itm = ATOMParser.parseItem(i);
			}
			if(itm['type'] != undefined) {
				arr.push(itm);
			}
			itm = {};
		}
		return arr;
	};


	/** Translate ATOM item to playlist item. **/
	public static function parseItem(obj:XML):Object {
		var itm =  new Object();
		for each (var i:XML in obj.children()) {
			switch(i.localName()) {
				case 'author':
					itm['author'] = i.children()[0].text().toString();
					break;
				case 'title':
					itm['title'] = i.text().toString();
					break;
				case 'summary':
					itm['description'] = i.text().toString();
					break;
				case 'link':
					if(i.@rel == 'alternate') {
						itm['link'] = i.@href.toString();
					} else {
						var pt1:RegExp = /^(.+)#(.+)$/g;
						var pt2:RegExp = /^(.+)\.(.+)$/g;
						var nam:String = i.@rel.toString().replace(pt1,"$2").replace(pt2,'$2');
						itm[nam] = i.@href.toString();
					}
					break;
				case 'published':
					itm['date'] = i.text().toString();
					break;
				case 'group':
					itm = MediaParser.parseGroup(i,itm);
					break;
			}
		}
		itm = MediaParser.parseGroup(obj,itm);
		return ObjectParser.complete(itm);
	};


}


}