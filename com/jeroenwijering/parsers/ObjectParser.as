/**
* Process a feeditem before adding to the feed.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class ObjectParser {


	/** All supported feeditem elements. **/
	protected static var ELEMENTS:Object = {
		'author':undefined,
		'date':undefined,
		'description':undefined,
		'duration':0,
		'file':undefined,
		'image':undefined,
		'link':undefined,
		'title':undefined,
		'start':0,
		'tags':undefined,
		'type':undefined
	};
	/** Idenifier of all supported mediatypes. **/
	protected static var TYPES:Object = {
		'camera':'',
		'image':'',
		'rtmp':'',
		'sound':'',
		'video':'',
		'youtube':''
	};
	/** File extensions of all supported mediatypes. **/
	protected static var EXTENSIONS:Object = {
		'3g2':'video',
		'3gp':'video',
		'aac':'video',
		'f4b':'video',
		'f4p':'video',
		'f4v':'video',
		'flv':'video',
		'gif':'image',
		'jpg':'image',
		'm4a':'video',
		'm4v':'video',
		'mov':'video',
		'mp3':'sound',
		'mp4':'video',
		'png':'image',
		'rbs':'sound',
		'sdp':'video',
		'swf':'image',
		'vp6':'video'
	};
	/** Mimetypes of all supported mediafiles. **/
	protected static var MIMETYPES:Object = {
		'application/x-fcs':'rtmp',
		'application/x-shockwave-flash':'image',
		'audio/aac':'video',
		'audio/m4a':'video',
		'audio/mp4':'video',
		'audio/mp3':'sound',
		'audio/mpeg':'sound',
		'audio/x-3gpp':'video',
		'audio/x-m4a':'video',
		'image/gif':'image',
		'image/jpeg':'image',
		'image/jpg':'image',
		'image/png':'image',
		'video/flv':'video',
		'video/3gpp':'video',
		'video/h264':'video',
		'video/mp4':'video',
		'video/x-3gpp':'video',
		'video/x-flv':'video',
		'video/x-m4v':'video',
		'video/x-mp4':'video'
	};


	/** 
	* Parse a generic object into a playlist item.
	* 
	* @param obj	A plain object with key:value pairs.
	* @return 		A playlist item (plain object with title,file,image,etc. entries)
	**/
	public static function parse(obj:Object):Object {
		var itm = new Object();
		for(var i:String in ObjectParser.ELEMENTS) {
			if(obj[i] != undefined) {
				itm[i] = Strings.serialize(obj[i]);
			}
		}
		return ObjectParser.complete(itm);
	};


	/** 
	* Complete a playlistitem object: add the correct mediatype and set a 0 duration/start.
	* 
	* @param itm	A playlist item (plain object with title,file,image,etc. entries)
	* @return 		A playlist item (plain object with title,file,image,etc. entries)
	**/
	public static function complete(itm:Object):Object {
		if(itm['type']) { 
			itm['type'] = itm['type'].toLowerCase(); 
		}
		if(itm['file'] == undefined) {
			delete itm['type'];
		} else if(ObjectParser.TYPES[itm['type']] != undefined) {
			// assume the developer knows what he does...
		} else if(ObjectParser.EXTENSIONS[itm['type']] != undefined) {
			itm['type'] = ObjectParser.EXTENSIONS[itm['type']];
		} else if(itm['file'].indexOf('youtube.com/watch') > -1 ||
			itm['file'].indexOf('youtube.com/v/') > -1) {
			itm['type'] = 'youtube';
		} else if(ObjectParser.MIMETYPES[itm['type']] != undefined) {
			itm['type'] = ObjectParser.MIMETYPES[itm['type']];
		} else {
			itm['type'] = undefined;
			for (var i:String in ObjectParser.EXTENSIONS) {
				if (itm['file'] && itm['file'].substr(-3).toLowerCase() == i) {
					itm['type'] = ObjectParser.EXTENSIONS[i];
					break;
				}
			}
		}
		if(!itm['duration']) { itm['duration'] = 0; }
		if(!itm['start']) { itm['start'] = 0; }
		return itm;
	};


}


}
