/**
* Interface for all display elements.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.Draw;
import com.jeroenwijering.utils.Strings;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.net.URLRequest;


public class Display implements PluginInterface {


	/** Reference to the MVC view. **/
	private var view:AbstractView;
	/** Reference to the display MC. **/
	private var display:MovieClip;
	/** Loader object for loading a logo. **/
	private var loader:Loader;
	/** The margins of the logo. **/
	private var margins:Array;
	/** The latest playback state **/
	private var state:String;
	/** A list of all the icons. **/
	private var ICONS:Array = new Array(
		'playIcon',
		'errorIcon',
		'bufferIcon',
		'linkIcon',
		'muteIcon',
		'fullscreenIcon',
		'nextIcon'
	);


	/** Constructor; add all needed listeners. **/
	public function Display():void {};


	/** Initialize the plugin. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.ERROR,errorHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,stateHandler);
		view.addModelListener(ModelEvent.BUFFER,bufferHandler);
		view.addModelListener(ModelEvent.ERROR,errorHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		display = view.skin['display'];
		display.media.mask = display.masker;
		display.mouseChildren = false;
		if(view.config['screencolor']) {
			var clr:ColorTransform = new ColorTransform();
			clr.color = uint('0x'+view.config['screencolor'].substr(-6));
			display.back.transform.colorTransform = clr;
		}
		if(view.config['displayclick'] != 'none') {
			display.addEventListener(MouseEvent.CLICK,clickHandler);
			display.buttonMode = true;
		}
		try {
			Draw.clear(display.logo);
			if(view.config['logo']) { setLogo(); }
		} catch (err:Error) {}
		stateHandler();
		resizeHandler();
	};


	/** Receive buffer updates. **/
	private function bufferHandler(evt:ModelEvent):void {
		var pct:String = '';
		if(evt.data.percentage > 0) {
			pct = Strings.zero(evt.data.percentage);
		}
		try {
			display.bufferIcon.txt.text = pct;
		} catch (err:Error) {}
	};


	/** Process a click on the display. **/
	private function clickHandler(evt:MouseEvent):void {
		view.sendEvent(view.config['displayclick']);
	};


	/** Receive and print errors. **/
	private function errorHandler(evt:Object):void {
		if(view.config['icons'] == true) { 
			try {
				setIcon('errorIcon');
				display.errorIcon.txt.text = evt.data.message;
			} catch (err:Error) {}
		}
	};


	/** Logo loaded; now position it. **/
	private function logoHandler(evt:Event):void {
		if(margins[0] > margins[2]) {
			display.logo.x = display.back.width- margins[2]-display.logo.width;
		} else {
			display.logo.x = margins[0];
		}
		if(margins[1] > margins[3]) {
			display.logo.y = display.back.height- margins[3]-display.logo.height;
		} else {
			display.logo.y = margins[1];
		}
	};


	/** Receive resizing requests **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		if(view.config['height'] > 0) { 
			display.visible = true;
		} else { 
			display.visible = false;
		}
		display.back.width  = view.config['width'];
		display.back.height = view.config['height'];
		try { 
			display.masker.width = view.config['width'];
			display.masker.height = view.config['height'];
		} catch (err:Error) {}
		for(var i:String in ICONS) {
			try { 
				display[ICONS[i]].x = Math.round(view.config['width']/2);
				display[ICONS[i]].y = Math.round(view.config['height']/2);
			} catch (err:Error) {}
		}
		if(view.config['logo']) {
			logoHandler(new Event(Event.COMPLETE));
		}
	};


	/** Set a specific icon in the display. **/
	private function setIcon(icn:String=undefined):void {
		for(var i:String in ICONS) {
			if(display[ICONS[i]]) { 
				if(icn == ICONS[i]) {
					display[ICONS[i]].visible = true; 
				} else {
					display[ICONS[i]].visible = false; 
				}
			}
		}
	};


	/** Setup the logo loading. **/
	private function setLogo():void {
		margins = new Array(
			display.logo.x,
			display.logo.y,
			display.back.width-display.logo.x-display.logo.width,
			display.back.height-display.logo.y-display.logo.height
		);
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE,logoHandler);
		display.logo.addChild(loader);
		loader.load(new URLRequest(view.config['logo']));
	};


	/** Handle a change in playback state. **/
	private function stateHandler(evt:Event=null):void {
		state = view.config['state'];
		if(state == ModelStates.PLAYING) {
			setIcon();
		} else if (state == ModelStates.BUFFERING && view.config['icons'] == true) {
			setIcon('bufferIcon');
		} else {
			switch(view.config.displayclick) {
				case 'none':
					setIcon();
					break;
				default:
					if(view.config['icons'] == true && view.playlist) {
						setIcon(view.config.displayclick+'Icon');
					} else { 
						setIcon();
					}
					break;
			}
		}
	};


};


}