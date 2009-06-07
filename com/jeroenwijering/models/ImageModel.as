/**
* Wrapper for load and playback of images.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.*;
import flash.media.SoundMixer;
import flash.net.URLRequest;
import flash.utils.clearInterval;
import flash.utils.setInterval;


public class ImageModel implements ModelInterface {


	/** reference to the model. **/
	private var model:Model;
	/** Camera object to be instantiated. **/
	private var loader:Loader;
	/** Interval ID for the time. **/
	private var interval:Number;
	/** Current position in the time. **/
	private var position:Number;


	/** Constructor; sets up listeners **/
	public function ImageModel(mod:Model):void {
		model = mod;
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
		loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,progressHandler);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
	};


	/** load image into screen **/
	public function load():void {
		clearInterval(interval);
		position = model.playlist[model.config['item']]['start'];
		loader.load(new URLRequest(model.playlist[model.config['item']]['file']));
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		model.sendEvent(ModelEvent.BUFFER,{percentage:0});
	};


	/** Catch errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Load and place the image on stage. **/
	private function loaderHandler(evt:Event):void {
		model.mediaHandler(loader);
		quality(model.config['quality']);
		play();
		model.sendEvent(ModelEvent.META,{height:evt.target.height,width:evt.target.width});
		model.sendEvent(ModelEvent.LOADED,{loaded:evt.target.bytesLoaded,total:evt.target.bytesTotal});
	};


	/** Resume playback of the images **/
	public function play():void {
		interval = setInterval(timeInterval,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** Show or hide the camera. **/
	public function pause():void {
		clearInterval(interval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Send load progress to player. **/
	private function progressHandler(evt:ProgressEvent):void {
		var pct = Math.round(evt.bytesLoaded/evt.bytesTotal*100);
		model.sendEvent(ModelEvent.BUFFER,{percentage:pct});
	};


	/** Change the quality mode. **/
	public function quality(stt:Boolean):void {
		try {
			Bitmap(loader.content).smoothing = stt;
		} catch (err:Error) {}
	};


	/** Scrub the image to a certain position. **/
	public function seek(pos:Number):void {
		clearInterval(interval);
		position = pos;
		play();
	};


	/** Stop the image interval. **/
	public function stop():void {
		flash.media.SoundMixer.stopAll();
		clearInterval(interval);
		if(loader.contentLoaderInfo.bytesLoaded != loader.contentLoaderInfo.bytesTotal) { 
			loader.close();
		} else { 
			loader.unload();
		}
	};


	/** Interval function that countdowns the time. **/
	private function timeInterval():void {
		position = Math.round(position*10+1)/10;
		var dur = model.playlist[model.config['item']]['duration'];
		if(position >= dur && dur>0) {
			clearInterval(interval);
			flash.media.SoundMixer.stopAll();
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		} else if (dur>0) {
			model.sendEvent(ModelEvent.TIME,{position:position,duration:dur});
		}
	};


	/** Volume setting **/
	public function volume(pct:Number):void { };


};


}