package com;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.InterpolationMethod;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.Memory;
import flash.utils.ByteArray;
import openfl.Assets;
import openfl.display.FPS;


/**
 * ...
 * original author Bruce
 * 2013/03/16, Ported to HaXe NME from the Alchemy example by
 * Ralph Hauwert: http://unitzeroone.com/blog/2009/04/06/more-play-with-alchemy-lookup-table-effects/
 * Ref: http://stackoverflow.com/questions/10157787/haxe-nme-fastest-method-for-per-pixel-bitmap-manipulation
 * ported to openfl, putting line drawing method by Samir
 */

class Main extends Sprite
{
    var ScreenData:BitmapData;
    var Screen:Bitmap;
    var rect:Rectangle;
    var timeStamp:Int;
    var resX:Int; 
    var resY:Int;
    //table
    var mLUT:Array<Int>;
  
	var _iii:Int;

    public function new() 
	{
	    super();
	    timeStamp = 0;
	    resX = 512;
	    resY = 512;
	    mLUT = [];
	    ScreenData = new BitmapData(resX, resY, false, 0x0);
	    Screen = new Bitmap(ScreenData);
	    rect = ScreenData.rect;
	    start();
    }
   
    var VirtualRAM:ByteArray;
    function initializeDiffuseBuffer():Void
    {
	
	// The virtual memory space, for screen buffer (0-resX*resY) and texture data (resX*resY-)
	VirtualRAM = new ByteArray();
	// 32bits integer = 4 bytes
	// CPP does not support setting the length property directly
	#if (cpp) VirtualRAM.setLength((resX*resY + resX*resY) * 4);
	#else VirtualRAM.length = (resX*resY + resX*resY) * 4;
	#end
	    // Write the texture data into RAM
	    VirtualRAM.position = resX*resY*4;
	
		
	    // Select the memory space (call it once, not every frame)
	    // "Selecting different memory blocks in cycles may lead to a performance loss!"
	    Memory.select(VirtualRAM);
    }
		
    public function start() {
	initializeDiffuseBuffer();
	addChild(Screen);
	addChild(new FPS(50, 50, 0xffffff));
	addEventListener(Event.ENTER_FRAME, rasterize);
    }
	
    function rasterize(event:Event):Void
    {
    
	// Clear the RAM space for Screen Buffer
	for (zz in 0...resX*resY) {
	    Memory.setI32(zz*4, 0x0);
	}
	
	var lpos:Int,u:Int,v:Int,tpos:Int,opos:Int,j:Int,i:Int,jpos:Int,juvpos:Int;
	timeStamp+=1;

	var last_x:Int, last_y:Int;
	last_x = 0;
	last_y =  Std.int( resY * 0.5 ) ;
	
	for (i in 0...resX) {
		var r:Float = Math.abs(Math.cos((i+timeStamp) * Math.PI* 2 / 180));
		var j:Int = Std.int( ( resY * 0.5 ) + (Math.cos((i+timeStamp) * Math.PI * 7 / 180) * 50 * r));
		
		for (bx in 0...1)
		for (by in 0...1)
		bresenhamInt(last_x+bx, last_y+by, i+bx, j+by, 0x00ff00);
		
		last_x = i;
		last_y = j;
	}
	
	// Render the BitmapData
	ScreenData.lock();
	VirtualRAM.position = 0;
	ScreenData.setPixels(rect, VirtualRAM);
	ScreenData.unlock();	
    }
	
	public function bresenhamInt(
         x0 : Int
        , y0 : Int
        , x1 : Int
        , y1 : Int
        , c : UInt
    ) {
		var lpos:Int,u:Int,v:Int,tpos:Int,opos:Int,j:Int,i:Int,jpos:Int,juvpos:Int;
        var steep : Bool = Math.abs( y1 - y0 ) > Math.abs( x1 - x0 );
        var tmp : Int;
        if ( steep ) {
            // swap x and y
            tmp = x0; x0 = y0; y0 = tmp; // swap x0 and y0
            tmp = x1; x1 = y1; y1 = tmp; // swap x1 and y1
        }
        if ( x0 > x1 ) {
            // make sure x0 < x1
            tmp = x0; x0 = x1; x1 = tmp; // swap x0 and x1
            tmp = y0; y0 = y1; y1 = tmp; // swap y0 and y1
        }
        var deltax : Int = x1 - x0;
        var deltay : Int = Math.floor( Math.abs( y1 - y0 ) );
        var error  : Int = Math.floor( deltax / 2 ); // this is a little hairy
        var y      : Int = y0;
        var ystep  : Int = if ( y0 < y1 ) 1 else -1;
        for ( x in x0 ... x1 ) {
            if ( steep ) {
				jpos = resX*x;
				opos = (jpos + y);
				Memory.setI32(opos*4, c);
                //bitmapData.setPixel( y, x, c ) ;
            } else {
				jpos = resX*y;
				opos = (jpos + x);
				Memory.setI32(opos*4, c);
                //bitmapData.setPixel( x, y, c );
            }
            error -= deltay;
            if ( error < 0 ) {
                y = y + ystep;
                error = error + deltax;
            }
        }
    }
	
	
	
	
}
