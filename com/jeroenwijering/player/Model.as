/**
* Wrap all media API's and manage playback.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.*;
import flash.display.*;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.URLRequest;


public class Model extends EventDispatcher {


	/** Object with all configuration variables. **/
	public var config:Object;
	/** Reference to the skin MovieClip. **/
	public var skin:MovieClip;
	/** Reference to the player's controller. **/
	private var controller:Controller;
	/** The list with all active models. **/
	private var models:Object;
	/** Currently active model. **/
	private var currentModel:String;
	/** Currently active mediafile. **/
	private var currentURL:String;
	/** Loader for the preview image. **/
	private var thumb:Loader;
	/** Save the current image to prevent overloading. **/
	private var image:String;


	/** Constructor, save arrays and set currentItem. **/
	public function Model(cfg:Object,skn:MovieClip,ctr:Controller):void {
		config = cfg;
		if(config['streamscript']) { config['streamer'] = config['streamscript']; }
		skin = skn;
		Draw.clear(skin.display.media);
		controller = ctr;
		controller.addEventListener(ControllerEvent.ITEM,itemHandler);
		controller.addEventListener(ControllerEvent.MUTE,muteHandler);
		controller.addEventListener(ControllerEvent.PLAY,playHandler);
		controller.addEventListener(ControllerEvent.PLAYLIST,playlistHandler);
		controller.addEventListener(ControllerEvent.QUALITY,qualityHandler);
		controller.addEventListener(ControllerEvent.RESIZE,resizeHandler);
		controller.addEventListener(ControllerEvent.SEEK,seekHandler);
		controller.addEventListener(ControllerEvent.STOP,stopHandler);
		controller.addEventListener(ControllerEvent.VOLUME,volumeHandler);
		thumb = new Loader();
		thumb.contentLoaderInfo.addEventListener(Event.INIT,thumbHandler);
		skin.display.addChildAt(thumb,skin.display.getChildIndex(skin.display.media));
		models = new Object();
	};


	/** Item change: switch the curently active model if there's a new URL **/
	private function itemHandler(evt:ControllerEvent):void {
		var typ:String = playlist[evt.data.index]['type'];
		var url:String = playlist[evt.data.index]['file'];
		if(models[typ] && typ == currentModel) {
			if(url == currentURL && typ != 'rtmp') {
				models[typ].seek(playlist[evt.data.index]['start']);
			} else {
				models[typ].stop();
				currentURL = url;
				models[typ].load();
			}
		} else {
			if(currentModel) {
				models[currentModel].stop();
			}
			if(!models[typ]) {
				loadModel(typ); 
			}
			currentModel = typ;
			currentURL = url;
			models[typ].load();
		}
		thumbLoader();
	};


	/** Setup a new model. **/
	private function loadModel(typ:String):void {
		switch(typ) {
			case 'camera':
				models[typ] = new CameraModel(this);
				break;
			case 'image':
				models[typ] = new ImageModel(this);
				break;
			case 'sound':
				if(config['streamer'] && config['streamer'].substr(0,4) == 'rtmp') {
					models[typ] = new RTMPModel(this);
				} else { 
					models[typ] = new SoundModel(this);
				}
				break;
			case 'video':
				if(config['streamer']) {
					if(config['streamer'].substr(0,4) == 'rtmp') {
						models[typ] = new RTMPModel(this);
					} else {
						models[typ] = new HTTPModel(this);
					}
				} else {
					models[typ] = new VideoModel(this);
				}
				break;
			case 'youtube':
				models[typ] = new YoutubeModel(this);
				break;
		}
	};


	/** Place a loaded mediafile on stage **/
	public function mediaHandler(chd:DisplayObject=undefined):void {
		Draw.clear(skin.display.media);
		skin.display.media.addChild(chd);
		resizeHandler();
	};


	/** Load the configuration array. **/
	private function muteHandler(evt:ControllerEvent):void {
		if(currentModel && evt.data.state == true) {
			models[currentModel].volume(0); 
		} else if(currentModel && evt.data.state == false) {
			models[currentModel].volume(config['volume']);
		}
	};


	/** Togge the playback state. **/
	private function playHandler(evt:ControllerEvent):void {
		if(currentModel) {
			if(evt.data.state == true) {
				models[currentModel].play();
			} else { 
				models[currentModel].pause();
			}
		}
	};


	/** Send an idle with new playlist. **/
	private function playlistHandler(evt:ControllerEvent):void {
		if(currentModel) { 
			stopHandler();
		} else {
			sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
		}
		thumbLoader();
	};


	/** Toggle the playback quality. **/
	private function qualityHandler(evt:ControllerEvent):void {
		if(currentModel) {
			models[currentModel].quality(evt.data.state);
		}
	};


	/** Resize the media and thumb. **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		Stretcher.stretch(skin.display.media,config['width'],config['height'],config['stretching']);
		if(thumb.width > 0) {
			Stretcher.stretch(thumb,config['width'],config['height'],config['stretching']);
		}
	};


	/** Seek inside a file. **/
	private function seekHandler(evt:ControllerEvent):void {
		if(currentModel) {
			models[currentModel].seek(evt.data.position);
		}
	};


	/** Load the configuration array. **/
	private function stopHandler(evt:ControllerEvent=undefined):void {
		currentURL = undefined;
		if(currentModel) {
			models[currentModel].stop();
		}
		sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/**  Dispatch events. State switch is saved. **/
	public function sendEvent(typ:String,dat:Object):void {
		if(typ == ModelEvent.STATE && dat.newstate != config['state']) {
			switch(dat.newstate) {
				case ModelStates.IDLE:
				case ModelStates.COMPLETED:
					sendEvent(ModelEvent.TIME,{
						position:playlist[config['item']]['start'],
						duration:playlist[config['item']]['duration']
					});
					thumb.visible = true;
					skin.display.media.visible = false;
					break;
				case ModelStates.BUFFERING:
				case ModelStates.PLAYING:
					var ext:String = playlist[config['item']]['file'].substr(-3);
					if(ext != 'aac' && ext != 'mp3' && ext != 'm4a') {
						thumb.visible = false;
						skin.display.media.visible = true;
					} else { 
						thumb.visible = true;
						skin.display.media.visible = false;
					}
					break;
				default:
					break;
			}
			dat.oldstate = config['state'];
			config['state'] = dat.newstate;
			dispatchEvent(new ModelEvent(typ,dat));
		} else if (typ != ModelEvent.STATE) {
			dispatchEvent(new ModelEvent(typ,dat));
		}
		if(typ == ModelEvent.META && dat.width) {
			resizeHandler();
		}
	};


	/** Load a thumb on stage. **/
	private function thumbHandler(evt:Event):void {
		try {
			Bitmap(thumb.content).smoothing = true;
		} catch (err:Error) {}
		resizeHandler();
	};


	/** Load a thumb on stage. **/
	private function thumbLoader():void {
		var img:String = playlist[config['item']]['image'];
		if(img != image) {
			image = img;
			thumb.load(new URLRequest(img));
		}
	};


	/** Load the configuration array. **/
	private function volumeHandler(evt:ControllerEvent):void {
		if(currentModel) {
			models[currentModel].volume(evt.data.percentage);
		}
	};


	/** Getter for the playlist **/
	public function get playlist():Array {
		return controller.playlist;
	};


}


}