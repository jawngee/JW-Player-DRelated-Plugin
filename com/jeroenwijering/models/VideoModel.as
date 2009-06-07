/**
* Wrapper for playback of progressively downloaded video.
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


public class VideoModel implements ModelInterface {


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
	/** Metadata received switch. **/
	private var metadata:Boolean;


	/** Constructor; sets up the connection and display. **/
	public function VideoModel(mod:Model):void {
		model = mod;
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		connection.objectEncoding = ObjectEncoding.AMF0;
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
		quality(model.config['quality']);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Load content. **/
	public function load():void {
		model.mediaHandler(video);
		stream.play(model.playlist[model.config['item']]['file']);
		loadinterval = setInterval(loadHandler,100);
		timeinterval = setInterval(timeHandler,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
	};


	/** Interval for the loading progress **/
	private function loadHandler():void { 
		var ldd = stream.bytesLoaded;
		var ttl = stream.bytesTotal;
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl});
		if(ldd == ttl && ldd > 0) {
			clearInterval(loadinterval);
		}
	};


	/** Catch noncritical errors. **/
	private function metaHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.META,{error:evt.text});
	};


	/** Get metadata information from netstream class. **/
	public function onData(dat:Object):void {
		if(dat.type == 'metadata' && !metadata) {
			metadata = true;
			if(dat.width) {
				video.width = dat.width;
				video.height = dat.height;
			}
			if(model.playlist[model.config['item']]['start'] > 0) {
				seek(model.playlist[model.config['item']]['start']);
			}
		}
		model.sendEvent(ModelEvent.META,dat);
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
	public function quality(qua:Boolean):void {
		if(qua == true) { 
			video.smoothing = true;
			video.deblocking = 3;
		} else { 
			video.smoothing = false;
			video.deblocking = 1;
		}
	};


	/** Change the smoothing mode. **/
	public function seek(pos:Number):void {
		clearInterval(timeinterval);
		stream.seek(pos);
		play();
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		if(evt.info.code == "NetStream.Play.Stop" && stream.bytesLoaded == stream.bytesTotal) {
			clearInterval(timeinterval);
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		} else if (evt.info.code == "NetStream.Play.StreamNotFound") {
			stop();
			model.sendEvent(ModelEvent.ERROR,{message:'Video not found: '+model.playlist[model.config['item']]['file']});
		}
		model.sendEvent(ModelEvent.META,{info:evt.info.code});
	};


	/** Destroy the video. **/
	public function stop():void {
		if(stream.bytesLoaded != stream.bytesTotal) {
			stream.close();
		}
		stream.pause();
		metadata = false;
		clearInterval(loadinterval);
		clearInterval(timeinterval);
	};


	/** Interval for the position progress **/
	private function timeHandler():void {
		var bfr = Math.round(stream.bufferLength/stream.bufferTime*100);
		var pos = Math.round(stream.time*10)/10;
		var dur = model.playlist[model.config['item']]['duration'];
		if(bfr < 100 && pos < Math.abs(dur-stream.bufferTime*2)) {
			model.sendEvent(ModelEvent.BUFFER,{percentage:bfr});
			if(model.config['state'] != ModelStates.BUFFERING && bfr < 10) {
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