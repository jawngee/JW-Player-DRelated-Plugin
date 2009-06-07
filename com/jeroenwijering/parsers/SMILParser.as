/**
* Parse an SMIL feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;
import com.jeroenwijering.parsers.ObjectParser;


public class SMILParser extends ObjectParser {


	/** Parse an SMIL playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr:Array = new Array();
		var itm:Object = new Object();
		var elm:XML = dat.children()[1].children()[0];
		if(elm.localName().toLowerCase() == 'seq') {
			for each (var i:XML in elm.children()) {
				itm = SMILParser.parseSeq(i);
				if(itm['type'] != undefined) {
					arr.push(itm);
				}
				itm = {};
			}
		} else {
			arr.push(SMILParser.parsePar(elm));
		}
		return arr;
	};


	/** Translate SMIL sequence item to playlistitem. **/
	public static function parseSeq(obj:Object):Object {
		var itm:Object =  new Object();
		switch (obj.localName().toLowerCase()) {
			case 'par':
				itm = SMILParser.parsePar(obj);
				break;
			case 'img':
			case 'video':
			case 'audio':
				itm = SMILParser.parseAttributes(obj,itm);
				break;
			default:
				break;
		}
		return ObjectParser.complete(itm);
	};


	/** Translate a SMIL par group to playlistitem **/
	public static function parsePar(obj:Object):Object {
		var itm:Object =  new Object();
		for each (var i:XML in obj.children()) {
			switch (i.localName()) {
				case 'anchor':
					itm['link'] = i.@href.toString();
					break;
				case 'textstream':
					itm['captions'] = i.@src.toString();
					break;
				case 'img':
				case 'video':
				case 'audio':
					itm[i.localName()] = i.@src.toString();
					itm = SMILParser.parseAttributes(i,itm);
					break;
				default:
					break;
			}
		}
		if(itm['video']) {
			itm['file'] = itm['video'];
			delete itm['video'];
		} else if (itm['audio']) {
			itm['file'] = itm['audio'];
			delete itm['audio'];
		} else if(itm['img']) {
			itm['file'] = itm['img'];
			delete itm['audio'];
		}
		if (itm['img']) {
			itm['image'] = itm['img'];
			delete itm['img'];
		}
		return itm;
	};


	/** Get attributes from a SMIL element. **/
	public static function parseAttributes(obj:Object,itm:Object):Object {
		for(var i:Number=0; i<obj.attributes().length(); i++) {
			var att:String = obj.attributes()[i].name().toString();
			switch(att) {
				case 'begin':
					itm['start'] = Strings.seconds(obj.@begin);
					break;
				case 'src':
					itm['file'] = obj.@src.toString();
					break;
				case 'dur':
					itm['duration'] = Strings.seconds(obj.@dur);
					break;
				case 'alt':
					itm['description'] = obj.@alt.toString();
					break;
				default:
					itm[att] = obj.attributes()[i].toString();
					break;
			}
		}
		return itm;
	}

}


}