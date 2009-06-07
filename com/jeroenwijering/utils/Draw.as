/**
* Functions for drawing commonly used elements.
**/
package com.jeroenwijering.utils {


import flash.display.*;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;


public class Draw {


	/** 
	* Completely clear the contents of a displayobject.
	*
	* @param tgt	Displayobject to clear.
	**/
	public static function clear(tgt:Sprite):void {
		var len:Number = tgt.numChildren;
		for(var i:Number=0; i<len; i++) {
			tgt.removeChildAt(0);
		}
		tgt.scaleX = tgt.scaleY = 1;
	};


	/** 
	* Clone a displayobject.
	*
	* @param tgt	Displayobject to clone.
	* @param adc	Add as child to the parent displayobject.
	*
	* @return		The clone; not yet added to the displaystack.
	**/
	public static function clone(tgt:MovieClip,adc:Boolean=false):MovieClip {
		var cls:Class = Object(tgt).constructor;
		var dup:MovieClip = new cls();
		dup.transform = tgt.transform;
		dup.filters = tgt.filters;
		dup.cacheAsBitmap = tgt.cacheAsBitmap;
		dup.opaqueBackground = tgt.opaqueBackground;
		if(adc == true) {
			var idx = tgt.parent.getChildIndex(tgt);
			tgt.parent.addChildAt(dup,idx+1);
		}
	    return dup;
	};


	/** 
	* Draw a rectangle on stage.
	*
	* @param tgt	Displayobject to add the rectangle to.
	* @param col	Color of the rectangle.
	* @param wid	Width of the rectangle.
	* @param hei	Height of the rectangle.
	* @param xps	X offset of the rectangle, defaults to 0.
	* @param yps	Y offset of the rectangle, defaults to 0.
	**/
	public static function rect(tgt:Sprite,col:String,wid:Number,hei:Number,xps:Number=0,yps:Number=0,alp:Number=1):Sprite {
		var rct:Sprite = new Sprite();
		rct.x = xps;
		rct.y = yps;
		rct.graphics.beginFill(uint(col),alp);
		rct.graphics.drawRect(0,0,wid,hei);
		tgt.addChild(rct);
		return rct;
	};


	/** 
	* Draw a textfield on stage.
	*
	* @param tgt	Displayobject to add the textfield to.
	* @param col	Color of the text.
	* @param xps	X offset of the rectangle.
	* @param yps	Y offset of the rectangle.
	* @param txt	Text string to print.
	* @param ats	Textfield autosize direction, defaults to left.
	* @param siz	Font size, defaults to 12.
	*
	* @return		A reference to the textfield.
	**/
	public static function text(tgt:Sprite,col:String,xps:Number,yps:Number,txt:String,ats:String='left',siz:Number=12,fnt:String='Arial'):TextField {
		var tfd:TextField = new TextField();
		var fmt:TextFormat = new TextFormat();
		tfd.autoSize = ats;
		tfd.selectable = false;
		fmt.font = fnt;
		fmt.color = col;
		fmt.size = siz;
		fmt.underline = false;
		tfd.defaultTextFormat = fmt;
		tfd.x = xps;
		tfd.y = yps;
		tfd.text = txt;
		tgt.addChild(tfd);
		return tfd;
	};


}


}