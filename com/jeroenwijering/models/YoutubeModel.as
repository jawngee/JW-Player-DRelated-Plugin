/**
* Wrapper for load and playback of Youtube videos.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import flash.display.Sprite;
import flash.display.Loader;
import flash.net.URLRequest;
import flash.events.*;
import flash.net.LocalConnection;
import flash.utils.setInterval;
import flash.utils.setTimeout;
import flash.utils.clearInterval;


public class YoutubeModel implements ModelInterface {


	/** Reference to the Model **/
	private var model:Model;
	/** Loader for loading the YouTube proxy **/
	private var loader:Loader;
	/** Connection towards the YT proxy. **/
	private var outgoing:LocalConnection;
	/** connection from the YT proxy. **/
	private var inbound:LocalConnection;
	/** Save that the meta has been sent. **/
	private var metasent:Boolean;
	/** Save that a load call has been sent. **/
	private var loading:Boolean;
	/** Save the connection state. **/
	private var connected:Boolean;


	/** Setup YouTube connections and load proxy. **/
	public function YoutubeModel(mod:Model):void {
		model = mod;
		outgoing = new LocalConnection();
		outgoing.allowDomain('*');
		outgoing.allowInsecureDomain('*');
		outgoing.addEventListener(StatusEvent.STATUS,onLocalConnectionStatusChange);
		inbound = new LocalConnection();
		inbound.allowDomain('*');
		inbound.allowInsecureDomain('*');
		inbound.addEventListener(StatusEvent.STATUS,onLocalConnectionStatusChange);
		inbound.client = this;
		try { 
			inbound.connect("_AS2_to_AS3");
			connected = true;
		} catch (err:Error) {
			stop();
			model.sendEvent(ModelEvent.ERROR,{message:"Cannot connect to Youtube. Only one YouTube connection per computer can be made!"});
		}
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		var url = model.skin.loaderInfo.url;
		var ytb = url.substr(0,url.lastIndexOf('/')+1)+'yt.swf';
		loader.load(new URLRequest(ytb));
	};


	/** Catch load errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** xtract the current ID from a youtube URL **/
	private function getID(url:String):String {
		var arr = url.split('?');
		var str = '';
		for (var i in arr) {
			if(arr[i].substr(0,2) == 'v=') {
				str = arr[i].substr(2);
			}
		}
		if(str == '') { str = url.substr(url.indexOf('/v/')+3); }
		if(str.indexOf('&') > -1) { 
			str = str.substr(0,str.indexOf('&'));
		}
		return str;
	};


	/** Load the YouTube movie. **/
	public function load():void {
		if(connected) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			loading = true;
			if(outgoing) {
				var gid = getID(model.playlist[model.config['item']]['file']);
				var stt = model.playlist[model.config['item']]['start'];
				outgoing.send("_AS3_to_AS2","loadVideoById",gid,stt);
				model.mediaHandler(loader);
			}
		}
	};


	/** Pause the YouTube movie. **/
	public function pause():void {
		outgoing.send("_AS3_to_AS2","pauseVideo");
	};



	/** Play or pause the video. **/
	public function play():void {
		outgoing.send("_AS3_to_AS2","playVideo");
	};


	/** SWF loaded; add it to the tree **/
	public function onSwfLoadComplete():void {
		outgoing.send("_AS3_to_AS2","setSize",320,240);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		if(loading) { load(); }
	};


	/** error was thrown without this handler **/
	public function onLocalConnectionStatusChange(evt:StatusEvent):void {
		// model.sendEvent(ModelEvent.META,{status:evt.code});
	};


	/** Catch youtube errors. **/
	public function onError(erc:String):void {
		var fil = model.playlist[model.config['item']]['file'];
		model.sendEvent(ModelEvent.ERROR,{message:"YouTube error (video not found?):\n"+fil});
		stop();
	};


	/** Catch youtube state changes. **/
	public function onStateChange(stt:Number):void {
		switch(Number(stt)) {
			case -1:
				// model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
				break;
			case 0:
				if(model.config['state'] != ModelStates.BUFFERING && model.config['state'] != ModelStates.IDLE) {
					model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
				}
				break;
			case 1:
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
				break;
			case 2:
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
				break;
			case 3:
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
				model.sendEvent(ModelEvent.BUFFER,{percentage:0});
				break;
		}
	};


	/** Catch Youtube load changes **/
	public function onLoadChange(ldd:Number,ttl:Number,off:Number):void {
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl,offset:off});
	};


	/** Catch Youtube position changes **/
	public function onTimeChange(pos:Number,dur:Number):void {
		model.sendEvent(ModelEvent.TIME,{position:pos,duration:dur});
		if(!metasent) {
			model.sendEvent(ModelEvent.META,{width:320,height:240,duration:dur});
			metasent = true;
		}
	};


	/** Toggle quality (perhaps access the H264 versions later?). **/
	public function quality(stt:Boolean):void {};


	/** Seek to position. **/
	public function seek(pos:Number):void {
		outgoing.send("_AS3_to_AS2","seekTo",pos);
		play();
	};


	/** Destroy the youtube video. **/
	public function stop():void {
		outgoing.send("_AS3_to_AS2","stopVideo");
	};



	/** Set the volume level. **/
	public function volume(pct:Number):void {
		outgoing.send("_AS3_to_AS2","setVolume",pct);
	};


}


}