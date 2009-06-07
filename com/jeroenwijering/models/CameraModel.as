/**
* This model implements the built-in webcam funcionality of the Flash Player.
* The webcam stream is shown in the display (nice for testing).
* If an rtmp server is provided in the 'streamer' flashvar, the stream will be published.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import flash.events.*;
import flash.media.*;
import flash.net.*;
import flash.utils.clearInterval;
import flash.utils.setInterval;


public class CameraModel implements ModelInterface {


	/** reference to the model. **/
	private var model:Model;
	/** Camera object to be instantiated. **/
	private var camera:Camera;
	/** Video object to be instantiated. **/
	private var video:Video;
	/** Microphone object to be instantiated. **/
	private var microphone:Microphone;
	/** NetConnection object for setup of the video stream. **/
	private var connection:NetConnection;
	/** NetStream instance that handles the stream IO. **/
	private var stream:NetStream;
	/** Interval ID for position counter. **/
	private var interval:Number;
	/** Current position. **/
	private var position:Number;


	public function CameraModel(mod:Model):void {
		model = mod;
		try {
			camera = Camera.getCamera();
			microphone = Microphone.getMicrophone();
			video = new Video(320,240);
		} catch(err:Error) {
			model.sendEvent(ModelEvent.ERROR,{message:'No webcam found on this computer.'});
		}
		connection = new NetConnection();
		connection.objectEncoding = ObjectEncoding.AMF0; 
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		quality(model.config['quality']);
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};



	/** Load the camera into the video **/
	public function load():void {
		position = model.playlist[model.config['item']]['start'];
		model.mediaHandler(video);
		if(model.config['streamer']) {
			connection.connect(model.config['streamer']);
		} else { 
			play();
		}
	};


	/** Pause playback. **/
	public function pause():void {
		video.attachCamera(null);
		if(stream) { 
			stream.publish(null);
			stream.attachAudio(null);
			stream.attachCamera(null); 
		}
		clearInterval(interval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Resume playback **/
	public function play():void {
		video.attachCamera(camera);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		interval = setInterval(timeInterval,100);
		if(stream) {
			stream.publish(model.playlist[model.config['item']]['file']);
			stream.attachAudio(microphone);
			stream.attachCamera(camera);
		}
	};


	/** Change the quality mode. **/
	public function quality(stt:Boolean):void {
		if(stt == true) {
			camera.setMode(480,360,25);
			video.smoothing = true;
			video.deblocking = 4;
			model.sendEvent(ModelEvent.META,{framerate:25,height:360,width:480});
		} else {
			camera.setMode(240,180,12);
			video.smoothing = false;
			video.deblocking = 1;
			model.sendEvent(ModelEvent.META,{framerate:12,height:180,width:240});
		}
	};


	/** Seek the camera timeline. **/
	public function seek(pos:Number):void {
		position = pos;
		clearInterval(interval);
		play();
	};


	/** Destroy the videocamera. **/
	public function stop():void {
		position = 0;
		video.attachCamera(null);
		clearInterval(interval);
		if(stream) { stream.publish(null); }
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		if(evt.info.code == "NetConnection.Connect.Success") {
			stream = new NetStream(connection);
			stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
			play();
		}
		model.sendEvent(ModelEvent.META,{info:evt.info.code});
	};


	/** Interval function that countdowns the time. **/
	private function timeInterval():void {
		position = Math.round(position*10+1)/10;
		var dur = model.playlist[model.config['item']]['duration'];
		if(dur > 0) {
			if(position >= dur) {
				clearInterval(interval);
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
			} else {
				model.sendEvent(ModelEvent.TIME,{position:position,duration:dur});
			}
		}
	};


	/** Volume setting **/
	public function volume(pct:Number):void {};


};


}