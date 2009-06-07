/**
* Wrapper for playback of video streamed over RTMP.
* 
* All playback functionalities are cross-server (FMS, Wowza, Red5), with the exception of:
* - The SecureToken functionality (Wowza).
* - The FCSubscribe functionality (Limelight/Akamai FMS).
* - getStreamLength / checkBandwidth / getReferrer / getPageUrl (FMS3).
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.NetClient;
import com.meychi.ascript.TEA;
import flash.display.DisplayObject;
import flash.events.*;
import flash.media.*;
import flash.net.*;
import flash.utils.*;


public class RTMPModel implements ModelInterface {


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
	/** Timeout ID for live stream subscription pings. **/
	private var timeout:Number;
	/** Metadata have been received. **/
	private var metadata:Boolean;


	/** Constructor; sets up the connection and display. **/
	public function RTMPModel(mod:Model):void {
		model = mod;
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		connection.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,metaHandler);
		connection.objectEncoding = ObjectEncoding.AMF0;
		connection.client = new NetClient(this);
		video = new Video(320,240);
		quality(model.config['quality']);
		transform = new SoundTransform();
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** xtract the current Stream from an RTMP URL **/
	private function getID(url:String):String {
		if(url.substr(-4) == '.mp3') {
			url = 'mp3:'+url.substr(0,url.length-4);
		} else if(url.substr(-4) == '.mp4' || url.substr(-4) == '.mov' || 
			url.substr(-4) == '.aac' || url.substr(-4) == '.m4a') {
			url = 'mp4:'+url.substr(0,url.length-4);
		} else if (url.substr(-4) == '.flv'){
			url = url.substr(0,url.length-4);
		}
		return url;
	};


	/** Load content. **/
	public function load():void {
		model.mediaHandler(video);
		connection.connect(model.config['streamer']);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
	};


	/** Catch noncritical errors. **/
	private function metaHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.META,{error:evt.text});
	};


	/** Get metadata information from netstream class. **/
	public function onData(dat:Object):void {
		if(dat.type == 'metadata' && !metadata) {
			if(dat.width) {
				video.width = dat.width;
				video.height = dat.height;
			}
			if(model.playlist[model.config['item']]['start'] > 0) {
				seek(model.playlist[model.config['item']]['start']);
			}
			metadata = true;
		} else if(dat.type == 'complete') {
			clearInterval(timeinterval);
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		} else if(dat.type == 'fcsubscribe') {
			if(dat.code == "NetStream.Play.StreamNotFound" ) {
				stop();
				model.sendEvent(ModelEvent.ERROR,{message:"Subscription failed: "+model.playlist[model.config['item']]['file']});
			}else if(dat.code == "NetStream.Play.Start") {
				setStream();
			}
			clearInterval(timeout);
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
		clearTimeout(timeout);
		clearInterval(timeinterval);
		stream.resume();
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		timeinterval = setInterval(timeHandler,100);
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
		clearTimeout(timeout);
		clearInterval(timeinterval);
		if(model.config['state'] == ModelStates.PAUSED) {
			stream.resume();
		} else {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		stream.seek(pos);
	};


	/** Set streaming object **/
	public function setStream():void {
		var url = getID(model.playlist[model.config['item']]['file']);
		stream = new NetStream(connection);
		stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		stream.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,metaHandler);
		stream.bufferTime = model.config['bufferlength'];
		stream.client = new NetClient(this);
		video.attachNetStream(stream);
		stream.soundTransform = transform;
		stream.play(url);
		var res:Responder = new Responder(streamlengthHandler);
		var rs2:Responder = new Responder(referrerHandler);
		var rs3:Responder = new Responder(pageURLHandler);
		connection.call("getStreamLength",res,url);
		connection.call("getReferrer",rs2,url);
		connection.call("getPageUrl",rs3,url);
		connection.call("checkBandwidth",null);
		clearInterval(timeinterval);
		timeinterval = setInterval(timeHandler,100);
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		if(evt.info.code == "NetConnection.Connect.Success") {
			if (evt.info.secureToken != undefined) {
				connection.call("secureTokenResponse",null,
					TEA.decrypt(evt.info.secureToken,model.config['token']));
			}
			if(model.config['subscribe']) {
				timeout = setInterval(subscribe,2000,model.playlist[model.config['item']]['file']);
			} else {
				setStream();
			}
		} else if(evt.info.code == "NetStream.Seek.Notify") {
			clearInterval(timeinterval);
			timeinterval = setInterval(timeHandler,100);
		} else if(evt.info.code == "NetStream.Play.StreamNotFound" || 
			evt.info.code == "NetConnection.Connect.Rejected" || 
			evt.info.code == "NetConnection.Connect.Failed") {
			stop();
			model.sendEvent(ModelEvent.ERROR,{message:"Stream not found: "+
				model.playlist[model.config['item']]['file']});
		} else { 
			model.sendEvent(ModelEvent.META,{info:evt.info.code});
		}
	};


	/** Destroy the stream. **/
	public function stop():void {
		clearInterval(timeinterval);
		connection.close();
		if(stream) { stream.close(); }
		video.attachNetStream(null);
	};


	/** Get the streamlength returned from the connection. **/
	private function streamlengthHandler(len:Number):void {
		onData({type:'streamlength',duration:len});
	};


	/** Get the streamlength returned from the connection. **/
	private function referrerHandler(ref:String):void {
		onData({type:'referrer',url:ref});
	};


	/** Get the streamlength returned from the connection. **/
	private function pageURLHandler(url:String):void {
		onData({type:'pageurl',url:url});
	};


	/** Akamai & Limelight subscribes. **/
	private function subscribe(nme:String):void {
		connection.call("FCSubscribe",null,nme);
	};


	/** Interval for the position progress **/
	private function timeHandler():void {
		var bfr = Math.round(stream.bufferLength/stream.bufferTime*100);
		var pos = Math.round(stream.time*10)/10;
		var dur = model.playlist[model.config['item']]['duration'];
		if(bfr < 100 && pos < Math.abs(dur-stream.bufferTime-1)) {
			model.sendEvent(ModelEvent.BUFFER,{percentage:bfr});
			if(model.config['state'] != ModelStates.BUFFERING) {
				connection.call("checkBandwidth",null);
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
		if(stream) { 
			stream.soundTransform = transform;
		}
	};


};


}