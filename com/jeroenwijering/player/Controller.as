/**
* Process all input from the views and modifies the model.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.*;
import flash.display.MovieClip;
import flash.events.*;
import flash.geom.Rectangle;
import flash.net.*;
import flash.system.Capabilities;


public class Controller extends EventDispatcher {


	/** Configuration object **/
	private var config:Object;
	/** Reference to the skin; for stage event subscription. **/
	private var skin:MovieClip;
	/** Object that manages the playlist. **/
	private var playlister:Playlister;
	/** Reference to the player's model. **/
	private var model:Model;
	/** Reference to the player's view. **/
	private var view:View;
	/** object that provides randomization. **/
	private var randomizer:Randomizer;


	/** Constructor, set up stage and playlist listeners. **/
	public function Controller(cfg:Object,skn:MovieClip):void {
		config = cfg;
		skin = skn;
		playlister = new Playlister();
		playlister.addEventListener(Event.COMPLETE,playlistHandler);
		playlister.addEventListener(ErrorEvent.ERROR,errorHandler);
		config['controlbarsize'] = skin.controlbar.height;
		redrawHandler();
	};


	/** Register view and model with controller, start loading playlist. **/
	public function start(mdl:Model,vie:View):void {
		model= mdl;
		model.addEventListener(ModelEvent.META,metaHandler);
		model.addEventListener(ModelEvent.TIME,metaHandler);
		model.addEventListener(ModelEvent.STATE,stateHandler);
		view = vie;
		view.addEventListener(ViewEvent.FULLSCREEN,fullscreenHandler);
		view.addEventListener(ViewEvent.ITEM,itemHandler);
		view.addEventListener(ViewEvent.LINK,linkHandler);
		view.addEventListener(ViewEvent.LOAD,loadHandler);
		view.addEventListener(ViewEvent.MUTE,muteHandler);
		view.addEventListener(ViewEvent.NEXT,nextHandler);
		view.addEventListener(ViewEvent.PLAY,playHandler);
		view.addEventListener(ViewEvent.PREV,prevHandler);
		view.addEventListener(ViewEvent.QUALITY,qualityHandler);
		view.addEventListener(ViewEvent.REDRAW,redrawHandler);
		view.addEventListener(ViewEvent.SEEK,seekHandler);
		view.addEventListener(ViewEvent.STOP,stopHandler);
		view.addEventListener(ViewEvent.VOLUME,volumeHandler);
	};



	/** Catch errors dispatched by the playlister. **/
	private function errorHandler(evt:ErrorEvent):void {
		dispatchEvent(new ControllerEvent(ControllerEvent.ERROR,{message:evt.text}));
	};


	/** Switch fullscreen state. **/
	private function fullscreenHandler(evt:ViewEvent):void {
		if(skin.stage['displayState'] == 'fullScreen') {
			skin.stage['displayState'] = 'normal';
		} else {
			fullscreenrect();
			skin.stage['displayState'] = 'fullScreen';
		}
	};


	/** Set the fullscreen rectangle **/
	private function fullscreenrect():void {
		try { 
			skin.stage["fullScreenSourceRect"] = new Rectangle(skin.x,skin.y,
				Capabilities.screenResolutionX/2,Capabilities.screenResolutionY/2);
		} catch (err:Error) {}
	};


	/** Jump to a userdefined item in the playlist. **/
	private function itemHandler(evt:ViewEvent):void {
		var itm:Number = evt.data.index;
		if (itm < 0) {
			playItem(0);
		} else if (itm > playlist.length-1) { 
			playItem(playlist.length-1);
		} else if (!isNaN(itm)) {
			playItem(itm);
		}
	};


	/** Jump to the link of a playlistitem. **/
	private function linkHandler(evt:ViewEvent):void {
		var itm:Number = config['item'];
		if(evt.data.index) { itm = evt.data.index; }
		var lnk:String = playlist[itm]['link'];
		if(lnk != null) {
			navigateToURL(new URLRequest(lnk),config['linktarget']);
		}
	};


	/** Load a new playlist. **/
	private function loadHandler(evt:ViewEvent):void {
		stopHandler();
		try {
			playlister.load(evt.data.object);
		} catch (err:Error) {
			dispatchEvent(new ControllerEvent(ControllerEvent.ERROR,{message:err.message}));
		}
	};



	/** Update playlist item duration. **/
	private function metaHandler(evt:ModelEvent):void {
		if(evt.data.duration) {
			var dur:Number = Math.round(evt.data.duration*10)/10
			playlister.update(config['item'],'duration',dur);
		}
	};


	/** Save new state of the mute switch and send volume. **/
	private function muteHandler(evt:ViewEvent):void {
		if(evt.data.state) {
			if(evt.data.state == config['mute']) {
				return;
			} else { 
				config['mute'] = evt.data.state;
			}
		} else {
			config['mute'] = !config['mute'];
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.MUTE,{state:config['mute']}));
	};


	/** Jump to the next item in the playlist. **/
	private function nextHandler(evt:ViewEvent):void {
		if(playlist && config['shuffle'] == true) { 
			playItem(randomizer.pick());
		} else if (playlist && config['item'] == playlist.length-1) {
			playItem(0);
		} else if (playlist) { 
			playItem(config['item']+1);
		}
	};


	/** Change the playback state. **/
	private function playHandler(evt:ViewEvent):void {
		if(playlist) {
			if(evt.data.state != false && config['state'] == ModelStates.PAUSED) {
				dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:true}));
			} else if (evt.data.state != false && config['state'] == ModelStates.COMPLETED) {
				dispatchEvent(new ControllerEvent(ControllerEvent.SEEK,{position:playlist[config['item']]['start']}));
			} else if(evt.data.state != false && config['state'] == ModelStates.IDLE) {
				playItem();
			} else if (evt.data.state != true &&
				(config['state'] == ModelStates.PLAYING || config['state'] == ModelStates.BUFFERING)) {
				dispatchEvent(new ControllerEvent(ControllerEvent.PLAY,{state:false}));
			}
		}
	};


	/** Direct the model to play a new item. **/
	private function playItem(nbr:Number=undefined):void {
		if(nbr > -1) {
			if(playlist[nbr]['file'] == playlist[config['item']]['file']) {
				playlist[nbr]['duration'] = playlist[config['item']]['duration'];
			}
			config['item'] = nbr;
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.ITEM,{index:config['item']}));
	};


	/** Manage loading of a new playlist. **/
	private function playlistHandler(evt:Event):void {
		if(config['shuffle'] == true) {
			randomizer = new Randomizer(playlist.length);
			config['item'] = randomizer.pick();
		} else if (config['item'] > playlist.length) {
			config['item'] = playlist.length-1;
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.PLAYLIST,{playlist:playlist}));
		if(config['autostart'] == true) {
			playItem();
		}
	};


	/** Jump to the previous item in the playlist. **/
	private function prevHandler(evt:ViewEvent):void {
		if (config['item'] == 0) {
			playItem(playlist.length-1);
		} else { 
			playItem(config['item']-1);
		}
	};


	/** Switch playback quality. **/
	private function qualityHandler(evt:ViewEvent=null):void {
		if(evt.data.state != undefined) {
			if(evt.data.state == config['quality']) {
				return;
			} else { 
				config['quality'] = evt.data.state;
			}
		} else {
			config['quality'] = !config['quality'];
		}
		dispatchEvent(new ControllerEvent(ControllerEvent.QUALITY,{state:config['quality']}));
	};


	/** Forward a resizing of the stage. **/
	private function redrawHandler(evt:ViewEvent=null):void {
		var dat:Object = new Object();
		try { 
			var dps:String = skin.stage['displayState'];
		} catch (err:Error) {}
		if(dps == 'fullScreen') {
			dat.fullscreen = true;
			dat.width = skin.stage.stageWidth;
			dat.height = skin.stage.stageHeight;
		} else if(config['resizing']) {
			dat.fullscreen = false;
			dat.width = skin.stage.stageWidth;
			dat.height = skin.stage.stageHeight;
			if(config['controlbar'] == 'bottom') {
				dat.height -= config['controlbarsize'];
			}
			if(config['playlist'] == 'right') {
				dat.width -= config['playlistsize'];
			} else if(config['playlist'] == 'bottom') {
				dat.height -= config['playlistsize'];
			}
		} else { 
			dat.fullscreen = false;
			dat.width = config['width'];
			dat.height = config['height'];
		}
		config['width'] = dat.width;
		config['height'] = dat.height;
		dispatchEvent(new ControllerEvent(ControllerEvent.RESIZE,dat));
	};


	/** Seek to a specific part in a mediafile. **/
	private function seekHandler(evt:ViewEvent):void {
		if(config['state'] != ModelStates.IDLE && playlist[config['item']]['duration'] > 0) {
			var pos:Number = evt.data.position;
			if(pos < 2) { 
				pos = 0;
			} else if (pos > playlist[config['item']]['duration']-2) { 
				pos = playlist[config['item']]['duration']-2;
			}
			dispatchEvent(new ControllerEvent(ControllerEvent.SEEK,{position:pos}));
		}
	};


	/** Stop all playback and buffering. **/
	private function stopHandler(evt:ViewEvent=undefined):void {
		dispatchEvent(new ControllerEvent(ControllerEvent.STOP));
	};


	/** Manage playback state changes. **/
	private function stateHandler(evt:ModelEvent):void {
		if(evt.data.newstate == ModelStates.COMPLETED && (config['repeat'] == 'always' ||
			(config['repeat'] == 'list' && config['shuffle'] == true && randomizer.length > 0) || 
			(config['repeat'] == 'list' && config['shuffle'] == false && config['item'] < playlist.length-1))) {
			if(config['shuffle'] == true) {
				playItem(randomizer.pick());
			} else if(config['item'] == playlist.length-1) {
				playItem(0);
			} else {
				playItem(config['item']+1);
			}
		}
	};


	/** Save new state of the mute switch and send volume. **/
	private function volumeHandler(evt:ViewEvent):void {
		var vol:Number = evt.data.percentage;
		if (vol < 1) {
			muteHandler(new ViewEvent(ViewEvent.MUTE,{state:true}));
		} else if (!isNaN(vol) && vol < 101) {
			if(config['mute'] == true) { 
				muteHandler(new ViewEvent(ViewEvent.MUTE,{state:false}));
			}
			config['volume'] = vol;
			dispatchEvent(new ControllerEvent(ControllerEvent.VOLUME,{percentage:vol}));
		}
	}; 


	/** Getter for the playlist. **/
	public function get playlist():Array {
		return playlister.playlist;
	};


}


}