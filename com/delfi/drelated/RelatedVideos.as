/**
* Show a YouTube searchbar that loads the results into the player.
**/
package com.delfi.drelated{


import com.jeroenwijering.events.*;
import flash.display.*;
//import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.net.*;
import flash.xml.*;
import flash.utils.*;
import flash.geom.*;

import fl.transitions.*; 
import fl.transitions.easing.*; 

public class RelatedVideos extends MovieClip implements PluginInterface {


	/** Reference to the View of the player. **/
	private var view:AbstractView;
	/** Reference to the graphics. **/
	private var clip:MovieClip;	
	/** initialize call for backward compatibility. **/
	public var initialize:Function = initializePlugin;
	
	public var XMLLoader:URLLoader;
	private var VideoXML:XML;
	
	/** List with configuration settings. **/
	public var config:Object = {
		file:undefined,
		fullscreen:false,
		state:true
	};	
	 
      private var _container:Object;
	  private var ShuffleLeft:Object;
      private var ShuffleRight:Object;
      private var Cover:Object;
	  private var InfoElement:Object;
      private var Bg:Object;
      private var TemplateClass:Object;
	  private var SampleItem:Object;
	  private var SpaceFromSides:int;
	  private var ClipsVisible:int;
	  private var ClipWidth:int;
	  private var targX:int;
	  private var shuffleBounds:Array;
	  private var mySkin:Object;
	  private var maxw:int;
	  private var maxh:int;
	
	private var _items:Array=new Array();
	 	  
      
	
	/** Constructor; nothing going on. **/
	public function RelatedVideos() {
		clip = this;
	};


	/** The initialize call is invoked by the player View. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		
		//set the original position of the thumbs
		targX = 0;
		
		//If the custom skin is defined, load it in
		if(view.config['drelated.skin']!=undefined){
			loadMySkin();
		}
		//Otherwise move on to resizing stuff to match the clips measurements and load the thumbs
		else{			
			resizeMe();
			getRelatedClips(view.config['drelated.xmlpath']);		
		}
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);		
	};
	
	/** Initialize the skin swf loading **/	
	private function loadMySkin():void{
		var skinloader:Loader = new Loader();
		skinloader.contentLoaderInfo.addEventListener(Event.COMPLETE,displaySkin);
		skinloader.load(new URLRequest(view.config['drelated.skin']));
		
	}
	
	/** The skin was loaded, display it, stretch it, and load the thumbs. **/	
	private function displaySkin(e:Event):void{		
		mySkin = e.target.content;
		/**If the skin is defined, load the elements from the skin movieclip. 
		The bits and pieces are:
			Bg - the large semitransparent layer that's stretched to exact same size and video
			Cover - the smaller semitransparent layer to bring out the thumbrow and controls;
			shuffle_left, shuffle_right - buttons to scroll the thumbrow to the left or to the right
			infoelement - MovieClip containing textfield with the title for the clips shown
			template - Videoitem
		**/
		if(view.config['drelated.skin']!=undefined){
			Bg = clip.addChild(mySkin.Bg);
			Cover = clip.addChild(mySkin.Cover);		
			ShuffleLeft = clip.addChild(mySkin.shuffle_left);
			ShuffleRight = clip.addChild(mySkin.shuffle_right);
			InfoElement = clip.addChild(mySkin.infoelement);
			TemplateClass = mySkin.template.constructor;
		}
		//Otherwise create class instances from the documents own library
		else{
			var BgClass:Object = getDefinitionByName ("background") as Class;
			Bg = clip.addChild(DisplayObject(new BgClass()));
			var CoverClass:Object = getDefinitionByName ("cover") as Class;
			Cover = clip.addChild(DisplayObject(new CoverClass()));
			var ShuffleLeftClass:Object = getDefinitionByName ("shuffleLeft") as Class;
			ShuffleLeft = clip.addChild(DisplayObject(new ShuffleLeftClass()));
			var ShuffleRightClass:Object = getDefinitionByName ("shuffleRight") as Class;
			ShuffleRight = clip.addChild(DisplayObject(new ShuffleRightClass()));
			TemplateClass = getDefinitionByName ("Template") as Class;		
			var InfoClass:Object = getDefinitionByName ("infoelement") as Class;
			InfoElement = clip.addChild(DisplayObject(new InfoClass()));
		}
		
		//Create a sample of the clip template for measuring sake
		SampleItem = DisplayObject(new TemplateClass());
		//Create a container object for the clips
		var ContainerClass:Object = getDefinitionByName ("Container") as Class;
		_container = clip.addChild(DisplayObject(new ContainerClass()));

		resizeMe();
		getRelatedClips(view.config['drelated.xmlpath']);		
	}
	
	
	/** Upon resize, check for fullscreen switches. Switch the state if so. **/
	private function resizeHandler(evt:ControllerEvent):void {
		if(view.config['state'] != ModelStates.IDLE) {
			resizeMe();
			
			switch(view.config['state'])
			{
				case ModelStates.PLAYING:
					trace('playing');
					clip.x=-this.stage.stageWidth;
					break;
				default:
					trace('not playing');
					clip.x=0;
					break;
			}
		}
	};

	
	/** Place the elements on stage, stretch and position them to meet our measurements. **/	
	private function resizeMe():void{
/*		Bg.width=this.stage.stageWidth;
		Cover.width=this.stage.stageWidth;
*/		
		maxw = SampleItem.thmask.width;
	  	maxh = SampleItem.thmask.height;

		
		trace(stage);
		
		//Place the clip left from the stage
		clip.x = -this.stage.stageWidth;
		clip.y = 0;
		
		// Stretch the bg
		Bg.width = this.stage.stageWidth;
		Bg.height = this.stage.stageHeight;		
		Bg.x = 0;
		Bg.y = 0;
		
		
		//Analyse the dposition flashvar and place the elements according to it.
		switch(view.config['drelated.position']) {
			case 'bottom':
				_container.y = this.stage.stageHeight-SampleItem.height-view.config['drelated.height_offset'];
				Cover.y = this.stage.stageHeight-SampleItem.height-5-InfoElement.height-view.config['drelated.height_offset'];
				InfoElement.y = this.stage.stageHeight-SampleItem.height-5-InfoElement.height-view.config['drelated.height_offset'];
				ShuffleLeft.y = this.stage.stageHeight-SampleItem.height-view.config['drelated.height_offset'];
				ShuffleRight.y = this.stage.stageHeight-SampleItem.height-view.config['drelated.height_offset'];
				break;
			case 'center':
				_container.y = (this.stage.stageHeight/2)-(SampleItem.height/2);
				Cover.y = (this.stage.stageHeight/2)-(SampleItem.height/2)-5-InfoElement.height;
				InfoElement.y = (this.stage.stageHeight/2)-(SampleItem.height/2)-5-InfoElement.height
				ShuffleLeft.y = (this.stage.stageHeight/2)-(SampleItem.height/2);
				ShuffleRight.y = (this.stage.stageHeight/2)-(SampleItem.height/2);
				break;
			default:
				_container.y = 5+InfoElement.height;				
				Cover.y = 0;
				InfoElement.y = 0;
				ShuffleLeft.y = 5+InfoElement.height
				ShuffleRight.y = 5+InfoElement.height
				break;			
		}
		
/*		for(var i=0; i<_items.length;i++) {_items[i].y=(view.config['fullscreen'] ? SampleItem.height : 0); trace(i+":"+_items[i].y); }*/
		
		//Add some cursors and events to the buttons
		ShuffleLeft.buttonMode = true;
		ShuffleRight.buttonMode = true;
		ShuffleLeft.x = 0;
		ShuffleLeft.addEventListener(MouseEvent.CLICK,shuffleleft)
		ShuffleRight.x = this.stage.stageWidth;
		ShuffleRight.addEventListener(MouseEvent.CLICK,shuffleright)
		
		//Stretch the cover
		Cover.height = SampleItem.height+5+InfoElement.height+view.config['drelated.height_offset'];
		Cover.width = this.stage.stageWidth;//view.config['drelated.width'];
		
		// Do some calculations to decide how many clips can we display at once and make sure they are aligned center
		ClipWidth = SampleItem.thmask.width+5;
		var Space:int = this.stage.stageWidth-ShuffleRight.width-ShuffleLeft.width;
		ClipsVisible = Math.floor(Space/(ClipWidth));
		var SpaceNeeded:int = ClipsVisible*(ClipWidth);
		SpaceFromSides = (this.stage.stageWidth-SpaceNeeded)/2;
		
		//Mask the clipcontainer object
		var square:Sprite = new Sprite();
		square.graphics.beginFill(0xFF0000);
		square.graphics.drawRect(SpaceFromSides, 0, SpaceNeeded, this.stage.stageHeight);
		clip.addChild(square);			
		_container.mask = square;
	}
	
	/** Slide the plugin to the center stage when the movie is paused or complete. **/	
	private function SlideMe(showMe:Boolean):void{
		var targetX:int;
		if(showMe==true){
			targetX = 0;
		}
		else{
			targetX = -this.stage.stageWidth;//view.config['drelated.width'];		
		}
		var myTween:Object = new Tween(clip, "x", None.easeIn ,this.x,targetX,0.5,true)				
	}
	
	/** Load the XML for the related clips. **/		
	private function getRelatedClips(path:String):void{
		XMLLoader = new URLLoader();
		XMLLoader.addEventListener(Event.COMPLETE,parseXML);
		XMLLoader.load(new URLRequest(path));
	}
	
	/** Parse the XML and do some magic with it. **/	
	private function parseXML(e:Event):void {
		VideoXML = new XML(e.target.data);
		InfoElement["text"].text = VideoXML.title;
		var VideoList:XMLList = VideoXML.video;
		var i:int = 0
		
		//For each clip in xml, place an instance of the template to the container
		for each(var video:XML in VideoList){
			var VideoItem:Object = _container.addChild(DisplayObject(new TemplateClass()));
			trace("itemcount:"+_items.push(VideoItem));
			VideoItem["test"].text = video.title;
			VideoItem.x = i*(VideoItem.thmask.width+5)+SpaceFromSides;			
		
			//Load the thumbnail
			var thumbloader:Loader = new Loader();
			thumbloader.contentLoaderInfo.addEventListener(Event.COMPLETE,resizeThumbs);
			thumbloader.load(new URLRequest(video.thumb));			
			VideoItem["holder_mc"].addChild(thumbloader);			
			
			//Make the clip remember what URL it should go to when clicked on
			VideoItem.cliptarget = video.url;

			//Make the clip remember what URL it should go to when clicked on
			VideoItem.clippreview = video.preview;
			VideoItem.clipfiletarget = video.file;
			
			//Make the clickable area clickable
			VideoItem.clickable.buttonMode = true;
			VideoItem.clickable.addEventListener(MouseEvent.CLICK,playClip)
			i++;
		}
		// Set the min/max bounds for the shufflebuttons
		shuffleBounds = [0-(i-4)*ClipWidth, 0]
		
		// Add the container enterframe event listner to move the clips when targX is changed
		_container.addEventListener(Event.ENTER_FRAME,shiftClips);
	}
	
	//Make the loaded thumb images smaller if it's ridiculously big
	private function resizeThumbs(e:Event):void{		
		if(e.target.width > maxw || e.target.height > maxh){
		  	var ratio_x:Number = maxw/e.target.width;
		  	var ratio_y:Number = maxh/e.target.height;
		  	if(ratio_x>ratio_y){
			  	e.target.content.width = e.target.width*ratio_x;
			  	e.target.content.height = e.target.height*ratio_x;
		  	}
		  	else{
			  	e.target.content.width = e.target.width*ratio_y;
			  	e.target.content.height = e.target.height*ratio_y;
		  	}
			
	  	}
	}
	// Guide the viewer to the link playing related clip when the clip thumb is clicked 
	private function playClip(e:MouseEvent):void{
		trace('fuckbuck');
		if ((view.config['dreleated.dynamic']) && (e.target.parent.clipfiletarget))
		{
			view.config['autostart'] = true;
			view.config['file'] = e.target.parent.clipfiletarget;
			view.config['start'] = 0;
			view.sendEvent('LOAD',view.config);
		}
		else
		{
			var request:URLRequest = new URLRequest(e.target.parent.cliptarget);

			if(view.config['drelated.target']!=undefined){
				try {
				  navigateToURL(request, view.config['drelated.target']); 
				} catch (e:Error) {
				  trace("Error occurred!");
				}
			}
			else{
				try {
				  navigateToURL(request); 
				} catch (e:Error) {
				  trace("Error occurred!");
				}
			}
		}
		
		
	}
	
	// Make the clips slide smoothly when shuffled
	private function shiftClips(e:Event):void{
		e.target.x -= (e.target.x-targX)/5;
	}
	
	/** Slide the plugin in when movie complete or paused. **/
	private function stateHandler(evt:ModelEvent):void { 
		switch(evt.data.newstate) {
			case ModelStates.BUFFERING:
			case ModelStates.PLAYING:
				SlideMe(false);
				break;
			case ModelStates.PAUSED:
				SlideMe(true);
				break;
			case ModelStates.COMPLETED:
				SlideMe(true);
				break;			
		}	
	}
	
	//Shuffle left;
	function shuffleleft(e:MouseEvent):void{
		targX += ClipWidth;
		if (targX > shuffleBounds[1]){
			targX = shuffleBounds[1]
			if(targX>0){
				targX = 0;
			}
		}		
	}
	
	//Shuffle right
	function shuffleright(e:MouseEvent):void{
		targX -= ClipWidth;
		if (targX < shuffleBounds[0]){			
			targX = shuffleBounds[0]
			if(targX>0){
				targX = 0;
			}
		}		
	}

}


}