/**
* Player that crunches through all media formats Flash can read.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.plugins.*;
import com.jeroenwijering.utils.Configger;
import flash.display.MovieClip;
import flash.events.Event;


public class Player extends MovieClip {


	/** All configuration values. Change them to hard-code your preferences. **/
	public var config:Object = {
		author:undefined,
		description:undefined,
		date:undefined,
		duration:0,
		file:undefined,
		image:undefined,
		link:undefined,
		start:0,
		tags:undefined,
		title:undefined,
		type:undefined,

		backcolor:undefined,
		frontcolor:undefined,
		lightcolor:undefined,
		screencolor:undefined,

		controlbar:'bottom',
		controlbarsize:20,
		height:300,
		playlist:'none',
		playlistsize:180,
		skin:undefined,
		width:400,

		autostart:false,
		bufferlength:1,
		displayclick:'play',
		icons:true,
		item:0,
		logo:undefined,
		mute:false,
		quality:true,
		repeat:'none',
		resizing:true,
		shuffle:false,
		state:'IDLE',
		stretching:'uniform',
		volume:90,

		abouttext:undefined,
		aboutlink:"http://www.jeroenwijering.com/?item=JW_FLV_Player",
		client:undefined,
		id:undefined,
		linktarget:'_blank',
		plugins:'d-related',
		file:'43.flv',
		//plugins:'viral-1',
		dxmlpath:'relatedclips.xml',
		dskin:'skins/grayskin.swf',
		streamer:undefined,
		token:undefined,
		tracecall:undefined,
		version:'4.2.90'
	};
	/** Reference to all stage graphics. **/
	public var skin:MovieClip;
	/** Object that loads all configuration variables. **/
	protected var configger:Configger;
	/** Object that load the skin and plugins. **/
	protected var loader:SPLoader;
	/** Reference to the Controller of the MVC cycle. **/
	protected var controller:Controller;
	/** Reference to the model of the MVC cycle. **/
	protected var model:Model;
	/** Reference to the View of the MVC cycle, which defines all API calls. **/
	public var view:View;


	/**
	* Constructor; initializes and starts the player.
	*
	* ADDED_TO_STAGE is needed when the player is loaded in Flex/Flash.
	* Otherwise the external flashvars and the stage aren't available yet.
	**/
	public function Player():void {
		visible = false;
		skin = this['player'];
		addEventListener(Event.ADDED_TO_STAGE,loadConfig);
	};


	/** When added to stage, the player loads configuration settings. **/
	protected function loadConfig(evt:Event=null):void { 
		configger = new Configger(this);
		configger.addEventListener(Event.COMPLETE,loadSkin);
		configger.load(config);
	};


	/** Config loading completed; now load the skin. **/
	protected function loadSkin(evt:Event=null):void {
		loader = new SPLoader(this);
		loader.addEventListener(SPLoaderEvent.SKIN,loadMVC);
		loader.loadSkin(config['skin']);
	};


	/** Skin loading completed, now load MVC. **/
	protected function loadMVC(evt:SPLoaderEvent=null):void {
		controller = new Controller(config,skin);
		model = new Model(config,skin,controller);
		view = new View(config,skin,controller,model,loader);
		controller.start(model,view);
		loadPlugins();
	};


	/** 
	* MVC inited; now load plugins.
	*
	* Built-in plugins are instantiated here. External plugins are loaded.
	* The controlbar is inited last, so it is show on top of all plugins.
	**/
	protected function loadPlugins():void {
		new Rightclick().initializePlugin(view);
		new Display().initializePlugin(view);
		new Playlist().initializePlugin(view);
		loader.addEventListener(SPLoaderEvent.PLUGINS,startPlayer);
		loader.loadPlugins(config['plugins']);
		new Controlbar().initializePlugin(view);
	};


	/**
	* Everything is now loaded. The player is shown and the file is loaded (when there).
	* 
	* The View will send a PlayerReady event to all plugins and javascript.
	* The player broadcasts a READY event here itself to actionscript.
	**/
	protected function startPlayer(evt:SPLoaderEvent=null) {
		loader.removeEventListener(SPLoaderEvent.PLUGINS,startPlayer);
		dispatchEvent(new PlayerEvent(PlayerEvent.READY));
		visible = true;
	};

}


}