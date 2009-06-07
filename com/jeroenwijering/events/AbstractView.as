/**
* Abstract superclass for the View. Defines all methods accessible to plugins.
*
* Import this class into your project/plugin for strong-typed api references.
**/
package com.jeroenwijering.events {


import flash.events.EventDispatcher;
import flash.display.MovieClip;


public class AbstractView extends EventDispatcher {


	/** Constructor. **/
	public function AbstractView() {};


	/**  Getter for config, the hashmap with configuration settings. **/
	public function get config():Object { return new Object(); };
	/** Getter for playlist, an array of hashmaps (file,link,image,etc) for each entry. **/
	public function get playlist():Array { return new Array(); };
	/** Getter for skin, the on-stage player graphics. **/ 
	public function get skin():MovieClip { return new MovieClip(); };


	/**
	* Subscribe to events fired by the Controller (seek,load,resize,etc).
	* 
	* @param typ	The specific event to listen to.
	* @param fcn	The function that will handle the event.
	* @see 			ControllerEvent
	**/
	public function addControllerListener(typ:String,fcn:Function):void {};


	/**
	* Subscribe to events fired by the Model (time,state,meta,etc).
	* 
	* @param typ	The specific event to listen to.
	* @param fcn	The function that will handle the event.
	* @see 			ModelEvent
	**/
	public function addModelListener(typ:String,fcn:Function):void {};


	/**
	* Subscribe to events fired from the View (play,mute,stop,etc).
	* All events fired by plugins or the actionscript/javascript API flow through the View.
	* 
	* @param typ	The specific event to listen to.
	* @param fcn	The function that will handle the event.
	* @see 			ViewEvent
	**/
	public function addViewListener(typ:String,fcn:Function):void {};


	/**
	* Dispatch an event. The event will be serialized and fired by the View.
	*
	* @param typ	The specific event to fire to.
	* @param prm	The accompanying parameter. Some events require one, others not.
	* @see 			ViewEvent
	**/
	public function sendEvent(typ:String,prm:Object=undefined):void { };


}


}