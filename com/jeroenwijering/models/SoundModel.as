/**
* Wrapper for playback of mp3 sounds.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.ModelInterface;
import com.jeroenwijering.player.Model;
import flash.events.*;
import flash.media.*;
import flash.net.URLRequest;
import flash.utils.clearInterval;
import flash.utils.setInterval;


public class SoundModel implements ModelInterface {


	/** reference to the model. **/
	private var model:Model;
	/** sound object to be instantiated. **/
	private var sound:Sound;
	/** Sound control object. **/
	private var transform:SoundTransform;
	/** Sound channel object. **/
	private var channel:SoundChannel;
	/** Sound context object. **/
	private var context:SoundLoaderContext;
	/** Interval ID for the time. **/
	private var interval:Number;
	/** Current position. **/
	private var position:Number;
	/** Estimated duration. **/
	private var duration:Number;


	/** Constructor; sets up the connection and display. **/
	public function SoundModel(mod:Model):void {
		model = mod;
		transform = new SoundTransform();
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		context = new SoundLoaderContext(model.config['bufferlength']*1000);
	};


	/** Sound completed; send event. **/
	private function completeHandler(evt:Event):void {
		clearInterval(interval);
		position = model.playlist[model.config['item']]['start']; 
		model.sendEvent(ModelEvent.TIME,{position:position,duration:duration});
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
	};


	/** Catch errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
		stop();
	};


	/** Forward ID3 data from the sound. **/
	private function id3Handler(evt:Event):void {
		try {
			var id3:ID3Info = sound.id3;
			var obj = {
				type:'id3',
				album:id3.album,
				artist:id3.artist,
				comment:id3.comment,
				genre:id3.genre,
				songName:id3.songName,
				track:id3.track,
				year:id3.year
			}
			model.sendEvent(ModelEvent.META,obj);
		} catch (err:Error) {}
	};


	/** Load the sound. **/
	public function load():void {
		position = model.playlist[model.config['item']]['start'];
		duration = model.playlist[model.config['item']]['duration'];
		sound = new Sound();
		sound.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		sound.addEventListener(ProgressEvent.PROGRESS,progressHandler);
		sound.addEventListener(Event.ID3,id3Handler);
		sound.load(new URLRequest(model.playlist[model.config['item']]['file']),context);
		play();
	};


	/** Pause the sound. **/
	public function pause():void {
		clearInterval(interval);
		channel.stop();
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Play the sound. **/
	public function play():void {
		channel = sound.play(position*1000,0,transform);
		channel.removeEventListener(Event.SOUND_COMPLETE,completeHandler);
		channel.addEventListener(Event.SOUND_COMPLETE,completeHandler);
		interval = setInterval(timeHandler,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** Interval for the loading progress **/
	private function progressHandler(evt:ProgressEvent):void {
		var ldd = evt.bytesLoaded;
		var ttl = evt.bytesTotal;
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl});
	};


	/** Change quality setting. **/
	public function quality(typ:Boolean):void {};


	/** Seek in the sound. **/
	public function seek(pos:Number):void {
		clearInterval(interval);
		position = pos;
		channel.stop();
		play();
	};


	/** Destroy the sound. **/
	public function stop():void {
		clearInterval(interval);
		if(channel) { channel.stop(); }
		try {
			sound.close();
		} catch (err:Error) {}
	};


	/** Interval for the position progress **/
	private function timeHandler():void {
		position = Math.round(channel.position/100)/10;
		var dur = Math.round(sound.length*sound.bytesTotal/sound.bytesLoaded/100)/10;
		if(sound.isBuffering == true && sound.bytesTotal > sound.bytesLoaded) {
			if(model.config['state'] != ModelStates.BUFFERING) {
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			} else {
				var pct = Math.floor(sound.length/(channel.position+model.config['bufferlength']*1000)*100);
					model.sendEvent(ModelEvent.BUFFER,{percentage:pct});
			}
		} else if (model.config['state'] == ModelStates.BUFFERING && sound.isBuffering == false) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if(dur > position) {
			model.sendEvent(ModelEvent.TIME,{position:position,duration:dur});
		}
		if(dur != duration && !isNaN(dur)) {
			duration = dur;
			model.sendEvent(ModelEvent.META,{duration:duration});
		}
	};


	/** Set the volume level. **/
	public function volume(vol:Number):void {
		transform.volume = vol/100;
		if(channel) {
			channel.soundTransform = transform;
		}
	};


};


}