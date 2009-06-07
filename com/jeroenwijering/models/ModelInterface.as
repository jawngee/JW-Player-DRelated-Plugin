/**
* Wrapper for playback of progressively downloaded video.
**/
package com.jeroenwijering.models {


import flash.display.DisplayObject;


public interface ModelInterface {

	/** Load a file into the model. **/
	function load():void;
	/** Playback resume directive. **/
	function play():void;
	/** Playback pause directive. **/
	function pause():void;
	/** Playback seeking directive. **/
	function seek(pos:Number):void;
	/** Stop the item altogether. **/
	function stop():void;
	/** Set or toggle the playback quality. **/
	function quality(stt:Boolean):void;
	/** Change the volume. **/
	function volume(vol:Number):void;


};


}