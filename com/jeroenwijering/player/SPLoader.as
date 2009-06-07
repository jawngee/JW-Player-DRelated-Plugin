/**
* Loads external SWF skins and plugins.
**/


package com.jeroenwijering.player {


import com.jeroenwijering.events.SPLoaderEvent;
import com.jeroenwijering.utils.Draw;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.system.*;


public class SPLoader extends EventDispatcher {


	/** Reference to the player itself. **/
	private var player:MovieClip;
	/** SWF loader reference **/
	private var loader:Loader;
	/** Base directory for the plugins. **/
	private var basedir:String = 'http://plugins.longtailvideo.com/';
	/** Number of plugns that are done loading. **/
	private var done:Number;


	/**
	* Constructor.
	*
	* @param ply	The player instance.
	**/
	public function SPLoader(ply:MovieClip):void {
		player = ply;
	};


	/** 
	* Load a list of SWF plugins.
	*
	* @prm pgi	A commaseparated list with plugins.
	**/
	public function loadPlugins(pgi:String=null):void {
		if(pgi) {
			var arr:Array = pgi.split(',');
			done = arr.length;
			for(var i:Number=0; i<arr.length; i++) {
				loadSWF(arr[i],false);
			}
		} else {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.PLUGINS));
		}
	};


	/**
	* Start the loading process.
	*
	* @param cfg	Object that contains all configuration parameters.
	**/
	public function loadSkin(skn:String=null):void {
		if(skn) {
			loadSWF(skn,true);
		} else {
			hideElements(player.skin);
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.SKIN));
		}
	};


	/** Load a particular SWF file. **/
	public function loadSWF(str:String,skn:Boolean):void {
		if(str.substr(-4) != '.swf') { str += '.swf'; }
		var ldr:Loader = new Loader();
		if(skn) {
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,skinError);
			ldr.contentLoaderInfo.addEventListener(Event.INIT,skinHandler);
		} else {
			player.skin.addChild(ldr);
			ldr.visible = false;
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,pluginError);
			ldr.contentLoaderInfo.addEventListener(Event.INIT,pluginHandler);
		}
		if(player.loaderInfo.url.indexOf('http') == 0) {
			var ctx:LoaderContext = new LoaderContext(true,ApplicationDomain.currentDomain,
				SecurityDomain.currentDomain);
			if(skn) { 
				ldr.load(new URLRequest(str),ctx);
			} else if (str.indexOf('http://') == 0) {
				ldr.load(new URLRequest(str),ctx);
			} else {
				ldr.load(new URLRequest(basedir+str),ctx);
			}
		} else {
			ldr.load(new URLRequest(str));
		}
	};


	/** SWF loading failed. **/
	private function pluginError(evt:IOErrorEvent):void {
		player.view.sendEvent('TRACE',' plugin: '+evt.text);
		done--;
		if(done == 0) {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.PLUGINS));
		}
	};


	/** Plugin loading completed; add to stage and populate. **/
	private function pluginHandler(evt:Event):void {
		try { 
			evt.target.content.initializePlugin(player.view);
			evt.target.loader.visible = true;
		} catch(err:Error) { 
			player.view.sendEvent('TRACE',' plugin: '+err.message);
		}
		done--;
		if(done == 0) {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.PLUGINS));
		}
	};


	/** SWF loading failed; use default skin. **/
	private function skinError(evt:IOErrorEvent=null):void {
		player.skin = player['player'];
		hideElements(player.skin);
		dispatchEvent(new SPLoaderEvent(SPLoaderEvent.SKIN));
	};


	/** Skin loading completed; add to stage and populate. **/
	private function skinHandler(evt:Event):void {
		if(evt.target.content['player']) {
			player.skin = MovieClip(evt.target.content['player']);
			Draw.clear(player);
			player.addChild(player.skin);
			hideElements(player.skin);
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.SKIN));
		} else {
			skinError();
		}
	};

	/** Hide al elements in the player, so parts for which no plugin is available won't show up unused. **/
	private function hideElements(skn:MovieClip):void {
		for (var i:Number=0; i<skn.numChildren; i++) {
			skn.getChildAt(i).visible = false;
		}
	};


}


}