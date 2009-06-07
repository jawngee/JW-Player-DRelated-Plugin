/**
* Wrapper for playback of http 'streaming' video.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.NetClient;
import flash.events.*;
import flash.display.DisplayObject;
import flash.media.SoundTransform;
import flash.media.Video;
import flash.net.*;
import flash.utils.clearInterval;
import flash.utils.setInterval;


public class HTTPModel implements ModelInterface {


	/** reference to the model. **/
	private var model:Model;
	/** Video object to be instantiated. **/
	private var video:Video;
	/** NetConnection object for setup of the video stream. **/
	private var connection:NetConnection;
	/** NetStream instance that handles the stream IO. **/
	private var stream:NetStream;
	/** Sound control object. **/
	private var transform:SoundTransform;
	/** Interval ID for the time. **/
	private var timeinterval:Number;
	/** Interval ID for the loading. **/
	private var loadinterval:Number;
	/** Object with keyframe times and positions. **/
	private var keyframes:Object;
	/** Offset byteposition to start streaming. **/
	private var offset:Number;
	/** Offset timeposition for lighttpd streaming. **/
	private var timeoffset:Number;
	/** switch for h264 streaming **/
	private var h264:Boolean;
	/** Byteposition to which the file has been loaded. **/
	private var loaded:Number;


	/** Constructor; sets up the connection and display. **/
	public function HTTPModel(mod:Model):void {
		model = mod;
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
		connection.connect(null);
		stream = new NetStream(connection);
		stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		stream.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,metaHandler);
		stream.bufferTime = model.config['bufferlength'];
		stream.client = new NetClient(this);
		video = new Video(320,240);
		video.attachNetStream(stream);
		transform = new SoundTransform();
		stream.soundTransform = transform;
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		quality(model.config['quality']);
		offset = timeoffset = 0;
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Return a keyframe byteoffset or timeoffset. **/
	private function getOffset(pos:Number,tme:Boolean=false):Number {
		for (var i=0; i< keyframes.times.length; i++) {
			if((keyframes.times[i] <= pos) && (keyframes.times[i+1] >= pos || !keyframes.times[i+1])) {
				if(tme == true) {
					return keyframes.times[i];
				} else { 
					return keyframes.filepositions[i];
				}
			}
		}
		return 0;
	};


	/** Returns a key to add to the stream. **/
	private function getToken():String {
		return model.config['token'];
	};


	/** Load content. **/
	public function load():void {
		model.mediaHandler(video);
		if(stream.bytesLoaded != stream.bytesTotal) {
			stream.close();
		}
		var url = model.playlist[model.config['item']]['file'];
		if(model.config["streamer"] == "lighttpd") {
			if(h264) {
				url +='?start='+timeoffset;
			} else {
				url += '?start='+offset;
			}
		} else {
			if(model.config["streamer"].indexOf('?') > -1) { 
				url = model.config["streamer"]+"&file="+url+'&start='+offset;
			} else {
				url = model.config["streamer"]+"?file="+url+'&start='+offset;
			}
		}
		url += '&id='+model.config['id'];
		url += '&client='+encodeURI(model.config['client']);
		url += '&version='+encodeURI(model.config['version']);
		url += '&width='+model.config['width'];
		if(getToken()) { url += '&token='+getToken(); }
		stream.play(url);
		clearInterval(loadinterval);
		clearInterval(timeinterval);
		loadinterval = setInterval(loadHandler,100);
		timeinterval = setInterval(timeHandler,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
	};


	/** Interval for the loading progress **/
	private function loadHandler():void {
		loaded = stream.bytesLoaded;
		var ttl = stream.bytesTotal;
		if(loaded >= ttl && loaded > 0) {
			clearInterval(loadinterval);
		}
		model.sendEvent(ModelEvent.LOADED,{loaded:loaded,total:ttl+offset,offset:offset});
	};


	/** Catch noncritical errors. **/
	private function metaHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.META,{error:evt.text});
	};


	/** Get metadata information from netstream class. **/
	public function onData(dat:Object):void {
		if(dat.type == 'metadata' && !h264) {
			if(dat.width) {
				video.width = dat.width;
				video.height = dat.height;
			}
			if(dat.seekpoints) {
				h264 = true;
				keyframes = new Object();
				keyframes.times = new Array();
				keyframes.filepositions = new Array();
				for (var j in dat.seekpoints) {
					keyframes.times[j] = Number(dat.seekpoints[j]['time']);
					keyframes.filepositions[j] = Number(dat.seekpoints[j]['offset']);
				}
			} else if(dat.keyframes) {
				keyframes = dat.keyframes;
			}
			if(model.playlist[model.config['item']]['start'] > 0) {
				seek(model.playlist[model.config['item']]['start']);
			}
			model.sendEvent(ModelEvent.META,dat);
		} else if(dat.type != 'metadata') {
			model.sendEvent(ModelEvent.META,dat);
		}
	};


	/** Pause playback. **/
	public function pause():void {
		clearInterval(timeinterval);
		stream.pause();
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Resume playing. **/
	public function play():void {
		stream.resume();
		timeinterval = setInterval(timeHandler,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** Change the smoothing mode. **/
	public function seek(pos:Number):void {
		clearInterval(timeinterval);
		var off = getOffset(pos);
		if(off < offset || off > offset+loaded) {
			offset = off;
			timeoffset = getOffset(pos,true);
			load();
		} else {
			if(h264) {
				stream.seek(pos-timeoffset);
			} else { 
				stream.seek(pos)
			}
			play();
		}
	};


	/** Change the smoothing mode. **/
	public function quality(qua:Boolean):void {
		if(qua == true) { 
			video.smoothing = true;
			video.deblocking = 3;
		} else { 
			video.smoothing = false;
			video.deblocking = 1;
		}
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		if(evt.info.code == "NetStream.Play.Stop") {
			if(model.config['state'] != ModelStates.COMPLETED) { 
				clearInterval(timeinterval);
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
			}
		} else if(evt.info.code == "NetStream.Play.StreamNotFound") {
			stop();
			model.sendEvent(ModelEvent.ERROR,{message:"Video stream not found: " +
				model.playlist[model.config['item']]['file']});
		} else { 
			model.sendEvent(ModelEvent.META,{info:evt.info.code});
		}
	};


	/** Destroy the HTTP stream. **/
	public function stop():void {
		clearInterval(loadinterval);
		clearInterval(timeinterval);
		offset = timeoffset = 0;
		h264 = false;
		keyframes = undefined;
		if(stream.bytesLoaded != stream.bytesTotal) {
			stream.close();
		}
		stream.pause();
	};


	/** Interval for the position progress **/
	private function timeHandler():void {
		var bfr = Math.round(stream.bufferLength/stream.bufferTime*100);
		var pos = Math.round(stream.time*10)/10;
		if (h264) { pos += timeoffset; }
		var dur = model.playlist[model.config['item']]['duration'];
		if(bfr<100 && pos < Math.abs(dur-stream.bufferTime*2)) {
			model.sendEvent(ModelEvent.BUFFER,{percentage:bfr});
			if(model.config['state'] != ModelStates.BUFFERING  && bfr < 10) {
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			}
		} else if (model.config['state'] == ModelStates.BUFFERING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if(dur > 0) {
			model.sendEvent(ModelEvent.TIME,{position:pos,duration:dur});
		}
	};


	/** Set the volume level. **/
	public function volume(vol:Number):void {
		transform.volume = vol/100;
		stream.soundTransform = transform;
	};


};


}