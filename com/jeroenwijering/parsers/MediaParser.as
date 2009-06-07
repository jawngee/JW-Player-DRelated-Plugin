/**
* Parse a MRSS group into a playlistitem (used in RSS and ATOM).
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.parsers.ObjectParser;
import com.jeroenwijering.utils.Strings;


public class MediaParser extends ObjectParser {

	/** Parse an MRSS group. **/
	public static function parseGroup(obj:XML,itm:Object):Object { 
		for each (var i:XML in obj.children()) {
			switch(i.localName()) {
				case 'content':
					if(!itm['file'] && ObjectParser.MIMETYPES[i.@type.toString()]) {
						itm['file'] = i.@url.toString();
						itm['type'] = i.@type.toString();
						if(i.@duration) {
							itm['duration'] = Strings.seconds(i.@duration);
						}
						if(i.@start) {
							itm['start'] = Strings.seconds(i.@start);
						}
					}
					if(i.children().length() >0) {
						itm = parseGroup(i,itm);
					}
					break;
				case 'description':
					itm['description'] = i.text().toString();
					break;
				case 'thumbnail':
					itm['image'] = i.@url.toString();
					break;
				case 'credit':
					itm['author'] = i.text().toString();
					break;
				case 'keywords':
					itm['tags'] = i.text().toString();
					break;
			}
		}
		return itm;
	}


}


}