/**
* Object that catches and forwards calls invoked by NetStream / NetConnection.
**/
package com.jeroenwijering.utils {


public class NetClient {


	/** Function to callback all events to **/
	private var callback:Object;


	/** Constructor. **/
	public function NetClient(cbk:Object):void {
		callback = cbk;
	};


	/** Forward calls to callback **/
	private function forward(dat:Object,typ:String):void {
		dat['type'] = typ;
		callback.onData(dat);
	};


	/** Checking the available bandwidth. **/
	public function onBWCheck(... rest):Number {
		return 0;
	};


	/** Receiving the bandwidth check result. **/
	public function onBWDone(... rest):void {
		if (rest.length > 0) {
			forward({bandwidth:rest[0]},'bandwidth');
		}
	};


	/** Captionate caption handler. **/
	public function onCaption(cps:String,spk:Number):void {
		forward({captions:cps,speaker:spk},'caption');
	};


	/** Captionate metadata handler. **/
	public function onCaptionInfo(obj:Object):void {
		forward(obj,'captioninfo');
	};


	/** Cuepoint handler. **/
	public function onCuePoint(obj:Object):void {
		forward(obj,'cuepoint');
	};


	/** CDN subscription handler. **/
	public function onFCSubscribe(obj:Object):void {
		forward(obj,'fcsubscribe');
	};


	/** Image data (iTunes-style) handler. **/
	public function onImageData(obj:Object):void {
		forward(obj,'imagedata');
	};


	/** Lastsecond call handler. **/
	public function onLastSecond(obj:Object):void {
		forward(obj,'lastsecond');
	};


	/** Get metadata information from netstream class. **/
	public function onMetaData(obj:Object):void {
		forward(obj,'metadata');
	};


	/** Receive NetStream playback codes. **/
	public function onPlayStatus(dat:Object):void {
		if(dat.code == "NetStream.Play.Complete") {
			forward(dat,'complete');
		} else { 
			forward(dat,'playstatus');
		}
	};


	/** RTMP Sample handler (what is this for?). **/
	public function RtmpSampleAccess(obj:Object):void {
		forward(obj,'rtmpsampleaccess');
	};


	/** Textdata handler (MP4 text tracks). **/
	public function onTextData(obj:Object):void {
		forward(obj,'textdata');
	};


};


}