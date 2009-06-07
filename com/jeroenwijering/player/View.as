/**
* Wrap all views and plugins and provides them with MVC access pointers.
**/
package com.jeroenwijering.player {


import com.carlcalderon.arthropod.Debug;
import com.jeroenwijering.events.*;
import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.Strings;
import flash.display.MovieClip;
import flash.events.*;
import flash.external.ExternalInterface;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.*;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import flash.utils.setTimeout;


public class View extends AbstractView {


	/** Object with all configuration parameters **/
	private var _config:Object;
	/** Reference to all stage graphics. **/
	private var _skin:MovieClip;
	/** Object that load the skin and plugins. **/
	private var loader:SPLoader;
	/** Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Model of the MVC cycle. **/
	private var model:Model;
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;
	/** A list with all javascript listeners. **/
	private var listeners:Array;


	/** Constructor, save references and subscribe to events. **/
	public function View(cfg:Object,skn:MovieClip,ctr:Controller,mdl:Model,ldr:SPLoader):void {
		Security.allowDomain("*");
		_config = cfg;
		_config['client'] = 'FLASH '+Capabilities.version;
		_skin = skn;
		if(_config['resizing']) {
			_skin.stage.scaleMode = "noScale";
			_skin.stage.align = "TL";
			_skin.stage.addEventListener(Event.RESIZE,resizeHandler);
		}
		loader = ldr;
		controller = ctr;
		model = mdl;
		setListening();
		if(ExternalInterface.available && _skin.loaderInfo.url.indexOf('http') == 0) {
			listeners = new Array();
			setJavascript();
			setTimeout(playerReady,50);
		}
		if(config['file']) {
			setTimeout(sendEvent,200,ViewEvent.LOAD,config);
		}
	};


	/**  Getters for the config parameters, skinning parameters and playlist. **/
	override public function get config():Object { return _config; };
	override public function get playlist():Array { return controller.playlist; };
	override public function get skin():MovieClip { return _skin; };


	/** 
	* Javascript getters for the config and playlist. 
	* Since parameters with alphanumerical characters tend to crash AS <> JS, they are removed.
	**/
	private function getConfig():Object {
		var cfg:Object = new Object();
		for(var itm:String in _config) { 
			if(itm.indexOf('.') == -1) { 
				cfg[itm] = _config[itm];
			}
		}
		return cfg; 
	};
	private function getPlaylist():Array { 
		return controller.playlist; 
	};


	/**  Subscribers to the controller, model and view. **/
	override public function addControllerListener(typ:String,fcn:Function):void {
		controller.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSControllerListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'CONTROLLER',type:typ.toUpperCase(),callee:fcn});
		return true;
	};
	override public function addModelListener(typ:String,fcn:Function):void {
		model.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSModelListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'MODEL',type:typ.toUpperCase(),callee:fcn});
		return true;
	};
	override public function addViewListener(typ:String,fcn:Function):void {
		this.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSViewListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'VIEW',type:typ.toUpperCase(),callee:fcn});
		return true;
	};


	/** Send event to listeners and tracers. **/
	private function forward(tgt:String,typ:String,dat:Object):void {
		var prm:String = '';
		for (var i:String in dat) { prm += i+':'+dat[i]+','; }
		if(prm.length > 0) {
			prm = '('+prm.substr(0,prm.length-1)+')';
		}
		if(config['tracecall'] == 'arthropod') {
			var obj:Object = {CONTROLLER:'0xFF6666',VIEW:'0x66FF66',MODEL:'0x6666FF'};
			Debug.log(typ+' '+prm,obj[tgt]);
		} else if(config['tracecall']) { 
			ExternalInterface.call(config['tracecall'],tgt+': '+typ+' '+prm);
		} else {
			trace(tgt+': '+typ+' '+prm);
		}
		if(!dat) { dat = new Object(); }
	 	dat.id = ExternalInterface.objectID;
		dat.client = config['client'];
		dat.version = config['version'];
		for (var itm:String in listeners) {
			if(listeners[itm]['target'] == tgt && listeners[itm]['type'] == typ) {
				ExternalInterface.call(listeners[itm]['callee'],dat);
			}
		}
	};


	/** 
	* Load a plugin into the player at runtime.
	*
	* @prm pgi	The name of the plugin to load.
	* @prm str	A string of additional flashvars (separated by & and = signs).
	* 
	* @return	Boolean true if succeeded.
	**/
	public function loadPlugin(pgi:String,str:String=null):Boolean {
		if(str != null && str != '') {
			var ar1:Array = str.split('&');
			for(var i:String in ar1) {
				var ar2:Array = ar1[i].split('=');
				_config[ar2[0]] = Strings.serialize(ar2[1]); }
		}
		loader.loadPlugins(pgi);
		return true;
	};


	/** Send a call to javascript that the player is ready. **/
	private function playerReady():void {
		if(ExternalInterface.available) {
			var dat:Object = {id:config['id'],client:config['client'],version:config['version']};
			try {
				ExternalInterface.call("playerReady",dat);
			} catch (err:Error) {}
		}
	};


	/** Send a redraw request when the stage is resized. **/
	private function resizeHandler(evt:Event=undefined):void {
		dispatchEvent(new ViewEvent(ViewEvent.REDRAW));
	};


	/**  Dispatch events. **/
	override public function sendEvent(typ:String,prm:Object=undefined):void {
		typ = typ.toUpperCase();
		var dat:Object = new Object();
		switch(typ) {
			case 'TRACE':
				dat['message'] = prm;
				break;
			case 'LINK':
				if (prm != null) {
					dat['index'] = prm;
				}
				break;
			case 'LOAD':
				dat['object'] = prm;
				break;
			case 'ITEM':
				if (prm > -1) {
					dat['index'] = prm;
				}
				break;
			case 'SEEK':
				dat['position'] = prm;
				break;
			case 'VOLUME':
				dat['percentage'] = prm;
				break;
			default:
				if(prm!=null && prm != '') {
					if(prm == true || prm == 'true') {
						dat['state'] = true;
					} else if(prm == false || prm == 'false') {
						dat['state'] = false;
					}
				}
				break;
		}
		dispatchEvent(new ViewEvent(typ,dat));
	};


	/** Forward events to tracer and subscribers. **/
	private function setController(evt:ControllerEvent):void { forward('CONTROLLER',evt.type,evt.data); };
	private function setModel(evt:ModelEvent):void { forward('MODEL',evt.type,evt.data); };
	private function setView(evt:ViewEvent):void { forward('VIEW',evt.type,evt.data); };


	/** Setup javascript API. **/
	private function setJavascript() {
		try {
			if(ExternalInterface.objectID) {
				_config['id'] = ExternalInterface.objectID;
			}
			ExternalInterface.addCallback("getConfig",getConfig);
			ExternalInterface.addCallback("getPlaylist",getPlaylist);
			ExternalInterface.addCallback("addControllerListener",addJSControllerListener);
			ExternalInterface.addCallback("addModelListener",addJSModelListener);
			ExternalInterface.addCallback("addViewListener",addJSViewListener);
			ExternalInterface.addCallback("sendEvent",sendEvent);
			ExternalInterface.addCallback("loadPlugin",loadPlugin);
		} catch (err:Error) {}
	};


	/** Setup listeners to all events for tracing / javascript. **/
	private function setListening():void {
		if(config['tracecall'] == 'arthropod') { Debug.clear(); }
		addControllerListener(ControllerEvent.ERROR,setController);
		addControllerListener(ControllerEvent.ITEM,setController);
		addControllerListener(ControllerEvent.MUTE,setController);
		addControllerListener(ControllerEvent.PLAY,setController);
		addControllerListener(ControllerEvent.PLAYLIST,setController);
		addControllerListener(ControllerEvent.QUALITY,setController);
		addControllerListener(ControllerEvent.RESIZE,setController);
		addControllerListener(ControllerEvent.SEEK,setController);
		addControllerListener(ControllerEvent.STOP,setController);
		addControllerListener(ControllerEvent.VOLUME,setController);
		addModelListener(ModelEvent.BUFFER,setModel);
		addModelListener(ModelEvent.ERROR,setModel);
		addModelListener(ModelEvent.LOADED,setModel);
		addModelListener(ModelEvent.META,setModel);
		addModelListener(ModelEvent.STATE,setModel);
		addModelListener(ModelEvent.TIME,setModel);
		addViewListener(ViewEvent.FULLSCREEN,setView);
		addViewListener(ViewEvent.ITEM,setView);
		addViewListener(ViewEvent.LINK,setView);
		addViewListener(ViewEvent.LOAD,setView);
		addViewListener(ViewEvent.MUTE,setView);
		addViewListener(ViewEvent.NEXT,setView);
		addViewListener(ViewEvent.PLAY,setView);
		addViewListener(ViewEvent.PREV,setView);
		addViewListener(ViewEvent.QUALITY,setView);
		addViewListener(ViewEvent.REDRAW,setView);
		addViewListener(ViewEvent.SEEK,setView);
		addViewListener(ViewEvent.STOP,setView);
		addViewListener(ViewEvent.TRACE,setView);
		addViewListener(ViewEvent.VOLUME,setView);
	};


}


}