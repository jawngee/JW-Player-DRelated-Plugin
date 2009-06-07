/**
* Wrap all views and plugins and provides them with MVC access pointers.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import flash.events.ContextMenuEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;


public class Rightclick implements PluginInterface {


	/** Reference to the MVC view. **/
	private var view:AbstractView;
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;


	/** Constructor. **/
	public function Rightclick():void {};


	/** Initialize the communication with the player. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		context = new ContextMenu();
		context.hideBuiltInItems();
		view.skin.contextMenu = context;
		qualityItem();
		try {
			if(view.skin.stage['displayState']) { fullscreenItem(); }
		} catch (err:Error) {}
		aboutItem();
	};



	/** Add a fullscreen menu item. **/
	private function aboutItem():void {
		var itm:ContextMenuItem = new ContextMenuItem('About JW Player '+view.config['version']+'...');
		if(view.config['abouttext']) {
			itm = new ContextMenuItem(view.config['abouttext']+'...');
		}
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,aboutSetter);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** jump to the about page. **/
	private function aboutSetter(evt:ContextMenuEvent):void {
		navigateToURL(new URLRequest(view.config['aboutlink']),'_blank');
	};


	/** Receive fullscreen changes. **/
	private function fullscreenHandler(evt:ControllerEvent):void {
		if(evt.data.fullscreen == false) { 
			context.customItems[1].caption = "Switch to fullscreen";
		} else {
			context.customItems[1].caption = "Return to normal screen";
		}
	};


	/** Add a fullscreen menu item. **/
	private function fullscreenItem():void {
		view.addControllerListener(ControllerEvent.RESIZE,fullscreenHandler);
		var itm:ContextMenuItem = new ContextMenuItem('Switch to fullscreen');
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,fullscreenSetter);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** Toggle the fullscreen mode. **/
	private function fullscreenSetter(evt:ContextMenuEvent):void { 
		view.sendEvent('fullscreen');
	};


	/** Receive Quality changes. **/
	private function qualityHandler(evt:ControllerEvent):void {
		if(evt.data.state == true) {
			context.customItems[0].caption = "Switch to low quality";
		} else {
			context.customItems[0].caption = "Switch to high quality";
		}
	};


	/** Add a quality menu item. **/
	private function qualityItem():void {
		view.addControllerListener(ControllerEvent.QUALITY,qualityHandler);
		var itm:ContextMenuItem = new ContextMenuItem('Switch to low quality');
		if(view.config['quality'] == false) {
			itm = new ContextMenuItem('Switch to high quality');
		}
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,qualitySetter);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** Toggle the quality mode. **/
	private function qualitySetter(evt:ContextMenuEvent):void { 
		view.sendEvent('quality');
	};


}


}