/**
* Loads and manages a playlist. Can read ASX, RSS (itunes & media extensions), SMIL & XSPF.
**/
package com.jeroenwijering.utils {


import com.jeroenwijering.parsers.*;
import flash.events.*;
import flash.net.URLRequest;
import flash.net.URLLoader;


public class Playlister extends EventDispatcher {


	/** XML connect and parse object. **/
	private var loader:URLLoader;
	/** Status of the HTTP request. **/
	private var status:Number;
	/** The array the playlist is loaded into. **/
	private var _playlist:Array;


	/** Constructor. **/
	public function Playlister():void {
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,loaderHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);
	};


	/** Determine filetype and load file or list. **/
	public function load(obj:Object):void {
		if(typeof(obj) == 'string') {
			var obj:Object = {file:obj};
		} 
		if(obj['file']) {
			var itm:Object = ObjectParser.parse(obj);
			if (itm['type'] == undefined) {
				try {
					loader.load(new URLRequest(obj['file']));
				} catch (err:Error) {
					dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,err.message));
				}
			} else {
				_playlist = new Array(itm);
				dispatchEvent(new Event(Event.COMPLETE));
			}
		} else {
			_playlist = new Array();
			for each (var ent:Object in obj) {
				ent = ObjectParser.parse(ent);
				if(typeof(ent) == 'object' && ent['type']) {
					_playlist.push(ent);
				}
			}
			if(_playlist.length == 0) {
				var str:String = 'No playeable file found.';
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,str));
			} else { 
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
	};


	/** Catch security and io errors **/
	private function errorHandler(evt:ErrorEvent):void {
		dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,status+': '+evt.text));
	};


	/** Translate the XML object to the feed array. **/
	private function loaderHandler(evt:Event):void {
		try {
			var dat:XML = XML(evt.target.data);
		} catch (err:Error) {
			var str:String = status+': This playlist is not a valid XML file.';
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,str));
			return;
		}
		var fmt:String = dat.localName().toLowerCase();
		if( fmt == 'rss') {
			_playlist = RSSParser.parse(dat);
		} else if (fmt == 'playlist') { 
			_playlist = XSPFParser.parse(dat);
		} else if (fmt == 'asx') { 
			_playlist = ASXParser.parse(dat);
		} else if (fmt == 'smil') { 
			_playlist = SMILParser.parse(dat);
		} else if (fmt == 'feed') {
			_playlist = ATOMParser.parse(dat);
		} else {
			fmt = 'Unknown playlist format: '+fmt;
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,fmt));
			return;
		}
		if(_playlist.length == 0) { 
			fmt = 'No suitable mediafiles found in this feed.';
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR,false,false,fmt));
			
		} else {  
			dispatchEvent(new Event(Event.COMPLETE));
		}
	};


	/** Save the http status **/
	private function statusHandler(evt:HTTPStatusEvent):void {
		status = evt.status;
	};


	/** Return the playlist to external objects. **/
	public function get playlist():Array {
		return _playlist;
	};


	/** Handler for manually updating elements. **/
	public function update(itm:Number,elm:String,val:Object):void {
		if(_playlist[itm]) {
			_playlist[itm][elm] = val;
		}
	};


}


}