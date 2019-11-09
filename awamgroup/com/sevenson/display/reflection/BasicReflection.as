/**
 * com.sevenson.display.reflection.BasicReflection
 * 
 * 
 * @author Andrew Sevenson
 * @version 1.0
 * 
 * This is a basic reflection class. It takes a target display object and reflects
 * the bottom section of it.  It allows you to set up options such as how tall the
 * reflection should be, how much of an alpha it should have, and what ratios it 
 * should fade off like.
 * 
 * There is also the option of a timer that can be set up to auto refresh the
 * reflection.
 * 
*/

package com.sevenson.display.reflection
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	
	/**
	 * The BasicReflection class
	 */
	public class BasicReflection extends Sprite
	{
		
		// vars
		protected var _bmp:Bitmap;						// bmp holding the reflection
		protected var _bmpData:BitmapData;				// the data of the reflection
		protected var _target:DisplayObject;			// the object you are reflecting
		protected var _refreshRate:int = -1;			// how often this should auto refresh
		protected var _timer:Timer;						// controls when this reflection is updated
		protected var _gradient:Shape;
		protected var _gradientContainer:Sprite;
		protected var _init:Boolean = false;
		protected var _lastGradientBMP:BitmapData;		// holds the last graident used - so you can avoid re-creating all the tiem
		
		protected var _reflectionRect:Rectangle;
		protected var _startAlpha:Number = 0.5;			// 0 - 1
		protected var _startRatio:Number = 0x00;		// 0x00 - 0xff
		protected var _reflectionHeight:uint = 50;		// how big the reflection should be
		
		
		
		/**
		 * Creates a new instance of the BasicReflection class
		 */
		public function BasicReflection ($reflectionHeight:Number=50, $startAlpha:Number=0.5, $startRatio:Number=0x00)
		{
			reflectionHeight = $reflectionHeight;
			startAlpha = $startAlpha;
			startRatio = $startRatio;
			//
			setupTimer();
			setupBMP();
			generateGradient();
			//
		}
		
		
		// STATIC PUBLIC FUNCTIONS
		// ------------------------------------------------------------------------------------------
		
		
		// STATIC PRIVATE FUNCTIONS
		// ------------------------------------------------------------------------------------------
		
		
		// PUBLIC FUNCTIONS
		// ------------------------------------------------------------------------------------------
		/**
		 * A clean up routine that destroys all external references to prepare the class for garbage collection
		 */
		public function destroy () : void
		{
			_bmp.bitmapData = null;
			if (_lastGradientBMP) _lastGradientBMP.dispose();
			if (_bmpData) _bmpData.dispose();
			if (parent) parent.removeChild(this);
		}
		
		
		/**
		 * Trigger a refresh of the reflection
		 */
		public function refresh():void {
			updateReflection();
		}

		
		// PRIVATE FUNCTIONS
		// ------------------------------------------------------------------------------------------
		
		/**
		 * Sets up the timer used to auto refresh the bitmap
		 */
		protected function setupTimer():void {
			_timer = new Timer(1000);
			_timer.addEventListener(TimerEvent.TIMER, updateReflection, false, 0, true);
		}
		
		
		/**
		 * Sets up a mask to use with the reflection
		 */
		private function generateGradient():void{

			//get a reference to the movie clip - cast the DisplayObject that is returned as a MovieClip
			if (_gradientContainer == null) {
				_gradientContainer = new Sprite();
			}
			if (_gradient == null) {
				_gradient = new Shape();
				_gradientContainer.addChild(_gradient);
			}
			
			var fillType:String = GradientType.LINEAR;
			var colors:Array = [0x000000, 0xffffff];
			var alphas:Array = [_startAlpha, 0];
			var ratios:Array = [_startRatio, 0xFF];
			var matr:Matrix = new Matrix();
			matr.createGradientBox(100, 100, (-90/180)*Math.PI, 0, 0);
			var spreadMethod:String = SpreadMethod.PAD;
			
			var $g:Graphics = _gradient.graphics;
			$g.clear();
			$g.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
			$g.drawRect(0,0,100,100);
			
			// flag as initialised
			_init = true;
			
			// kill of the gradient
			if (_lastGradientBMP) _lastGradientBMP.dispose();
			_lastGradientBMP = null;
			
		}	
		
		
		/**
		 * Sets up the bitmap that is to be displayed
		 */
		protected function setupBMP():void {
			//
			_bmp = new Bitmap(_bmpData, "auto", true);
			//_bmp.cacheAsBitmap = true;
			_bmp.scaleY = -1;
			addChild(_bmp);
		}
		
		
		// EVENT HANDLERS
		// ------------------------------------------------------------------------------------------
		
		
		/**
		 * Updates the reflection graphic
		 * @param	e
		 */
		private function updateReflection(e:Event = null):void {
			// clear out the current reflection
			_bmp.bitmapData = null;
			if(_bmpData) _bmpData.dispose();
				
			// create the new reflection
			if (_target == null) return;
			
			// set up a working rect
			var $workingRect:Rectangle;
			
			// see if you are using a target rect, or if you have to generate your own area
			if(_reflectionRect==null) {
				// get the rect of the content
				var $contentRect:Rectangle = _target.getRect(_target);
				// figure out which height to use
				var $height:Number = (_target.height < _reflectionHeight) ? _target.height : _reflectionHeight;
				$height = Math.floor($height);
				// set teh working height to be similar to the content, but using only the 'reflection' height
				$workingRect = $contentRect.clone();
				$workingRect.top = $workingRect.bottom - $height;
				
			} else {
				// use the target rect as the working rect
				$workingRect = _reflectionRect;
			}
				
			// figure out the matrix to use for the draw method
			var $matr:Matrix = new Matrix(1, 0, 0, 1, -($workingRect.left), -$workingRect.top );
			
			// create a base bmp data
			var $baseBmpData:BitmapData = new BitmapData(Math.ceil($workingRect.width), $workingRect.height, true, 0x00ff0000);
			$baseBmpData.draw(_target, $matr, null, null, null, true);
			
			// figure out if you need to generate a new reflection bmp
			if ((_lastGradientBMP == null) || (_lastGradientBMP.width != $baseBmpData.width || _lastGradientBMP.height != $baseBmpData.height)) {
				if (_lastGradientBMP) _lastGradientBMP.dispose();
				// generate the gradient data
				_gradient.width = $baseBmpData.width;
				_gradient.height = $baseBmpData.height;
				_lastGradientBMP = new BitmapData($baseBmpData.width, $baseBmpData.height, true, 0x00000000);
				_lastGradientBMP.draw(_gradientContainer, null, null, null, null, true);
			}
			
			// create the final data
			_bmpData = new BitmapData($baseBmpData.width, $baseBmpData.height, true, 0xffffffff);
			_bmpData.copyPixels($baseBmpData, new Rectangle(0, 0, $baseBmpData.width, $baseBmpData.height), new Point(0, 0), _lastGradientBMP, new Point(0, 0), false);
			_bmp.bitmapData = _bmpData;
			
			// position the bmp
			_bmp.y = $workingRect.height;
			_bmp.x = int($workingRect.x);
			
			$baseBmpData.dispose();
			
		}
		
		
		
		// GETTERS & SETTERS
		// ------------------------------------------------------------------------------------------
		
		
		/**
		 * Sets the target display object that is reflected
		 */
		public function get target():DisplayObject { return _target; }
		public function set target(value:DisplayObject):void {
			_target = value;
			updateReflection();
		}		
		
		/**
		 * Sets how often the reflection auto updates
		 */
		public function get refreshRate():int { return _refreshRate; }
		public function set refreshRate(value:int):void {
			_refreshRate = value;
			_timer.stop();
			if (_refreshRate > 0) {
				_timer.delay = _refreshRate;
				_timer.start();
			}
		}
		
		
		/**
		 * How tall te reflection should be - ignored if using a target rect
		 */
		public function get reflectionHeight():uint { return _reflectionHeight; }
		public function set reflectionHeight(value:uint):void 
		{
			_reflectionHeight = value;
			if (_init) generateGradient();
		}
		
		/**
		 * What rectangle area to 'reflect' in the target
		 */
		public function get reflectionRect():flash.geom.Rectangle { return _reflectionRect; }
		public function set reflectionRect(value:flash.geom.Rectangle):void 
		{
			_reflectionRect = value;
		}		
		
		/**
		 * The start ratio of the reflection
		 */
		public function get startRatio():Number { return _startRatio; }
		public function set startRatio(value:Number):void 
		{
			_startRatio = value;
			if (_init) generateGradient();
		}
		
		/**
		 * The inital alpha value for the reflection
		 */
		public function get startAlpha():Number { return _startAlpha; }
		public function set startAlpha(value:Number):void 
		{
			_startAlpha = value;
			if (_init) generateGradient();
		}
		

		
		
		
	}
}