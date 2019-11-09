/**
* Fade In Out Slideshow - Flabell.com Product, November 2009
* @author Vuzum, LLC.
* @version 1; 
* http://www.vuzum.com
* email: office@vuzum.com
*/

package com.vuzum.fadeinout 
{
	import flash.events.MouseEvent;	
	import flash.events.Event;	
	import flash.display.MovieClip;
	
	import caurina.transitions.*;
	import caurina.transitions.properties.*;
	

	// OTHER'S IMPORTS	
	import caurina.transitions.properties.ColorShortcuts;
	import caurina.transitions.properties.FilterShortcuts;
	//
	import com.zorked.URLNavigator;
	
	
	// MY IMPORTS
	import com.vuzum.utils.*;
	

	public class FadeInOut extends MovieClip 
	{
		// COMPONENTS INSIDE
		public var mcMask : MovieClip;
		public var mcAllItems : MovieClip;
		public var mcBack : MovieClip;
		public var mcLoader : MovieClip;
		
		// HANDLERS EVENTS
		private var currPressedObject : MovieClip;
		
		// INTERNAL MEMBERS
		
		// component vars
		public var componentWidth : Number;
		public var componentHeight : Number;
		public var pathToFiles : String = "";
		public var xmlPath : String;
		
		
		// data vars
		public var itemsArray : Array;
		public var randomizedArray : Array;
		
		private var selectedImage : Number = 0;
		private var previousImage : Number;
		
		
		// XML VARS
		private var startWith : Number;
		private var selector : Number;
		
		private var backgroundColor : Number;
		private var backgroundTransparency : Number;
		
		
		// AUX VARS
		private var count : Number = 0;
		private var nrFrames : Number = 30;
		private var isPlaying2 : Boolean = true;
		private var tempVar : *;
		private var isRandom : Boolean = false;
		private var loop : Boolean = false;
		
		private var nowLoading : Number = 0;
		private var transitionSpeed : Number = .2;
		

		// CONSTRUCTOR
		public function FadeInOut()
		{
			// PROTOTYPES init			
			new Prototypes();
			
			// TWEENER inits
			ColorShortcuts.init();
			FilterShortcuts.init();
			
			// items holder
			mcAllItems.mask = mcMask;
			mcAllItems.mcItem.visible = false;
       	 	
       	 	randomizedArray = new Array();
       	 	
       	 	show(false);
		}
		
		
		// show/hide all components
		public function show(flag : Boolean = true) : void
		{
			mcLoader.visible = !flag;
				
			mcAllItems.visible = flag;	
			mcBack.visible = flag;	
		}
		
		
		/*
		 * recreates the zoom gallery depending on the param xml path and dimensions
		 */
		public function init(pComponentWidth : Number = NaN, pComponentHeight : Number = NaN, pPathToFiles : String = "", pXmlPath : String = "") : void
		{
			// hide everything
			show(false);
			
			// read the params
			componentWidth = pComponentWidth;
			componentHeight = pComponentHeight;
			
			// path
			pathToFiles = Prototypes.readPathTo(pPathToFiles, pathToFiles);
			xmlPath = Prototypes.readAssetPath(pXmlPath, pathToFiles);
			
			mcLoader.centerOn(!isNaN(componentWidth) ? componentWidth : stage.stageWidth, !isNaN(componentHeight) ? componentHeight : stage.stageHeight);
			
			// read the xml file
			Prototypes.loadXML(xmlPath, xmlLoaded);
		}
		
		
		public function xmlLoaded(xmlObject : XML) : void			
		{
			// read COMPONENT DIMENSIONS if they were not defined in flash vars
			if(isNaN(componentWidth)) componentWidth = Prototypes.readNumberVar(xmlObject.@width, stage.stageWidth);
			if(isNaN(componentHeight)) componentHeight = Prototypes.readNumberVar(xmlObject.@height, stage.stageHeight);
			
			
			// colors
			backgroundColor = Prototypes.readNumberVar(xmlObject.@backgroundColor, backgroundColor);
			backgroundTransparency = Prototypes.readNumberVar(xmlObject.@backgroundTransparency, backgroundTransparency)/100;
			
			
			// settings
			startWith = Prototypes.readNumberVar(xmlObject.@startWith, startWith);
			isRandom = Prototypes.readBooleanVar(xmlObject.@randomSlideshow, isRandom);
			loop = Prototypes.readBooleanVar(xmlObject.@loop, loop);
			
			
			// items
			var itemsNode : XMLList = (xmlObject.children());
					
			// read the LIST OF IMAGES
			itemsArray = new Array();
			for(var i : uint = 0; i < itemsNode.length() - 1; i++)
			{
				itemsArray[i] = new Object();
				itemsArray[i].imagePath = Prototypes.readAssetPath(itemsNode[i].path, pathToFiles); // trace(itemsArray[i].imagePath);
				itemsArray[i].link = Prototypes.readStringVar(itemsNode[i].link);
				itemsArray[i].target = Prototypes.readStringVar(itemsNode[i].target);
				
				itemsArray[i].transitionTime = Prototypes.readNumberVar(itemsNode[i].transitionTime);
				itemsArray[i].slideShowTime = Prototypes.readNumberVar(itemsNode[i].slideShowTime);
			}
			
			// START THE COMPONENT
			start();
		}
			
		

		/*
		 * Loads all images in an array of movie clips 
		 */
		public function start() : void
		{
			// resize the component
			resize(componentWidth, componentHeight);
			
			// BACKGROUND
			mcBack.alpha = backgroundTransparency;
			Tweener.addTween(mcBack, {_color : backgroundColor, time : 0});
			mcBack.visible = true;
			
			
			selector = startWith - 1;
			
			if(isRandom)
			{
				randomizedArray = Prototypes.randoMix(itemsArray.length);
				selectedImage = randomizedArray[selector];
			}
			else
			{
				selectedImage = selector;
			}	
			
			
			// LIST OF IMAGES AND THUMBS
			for(var i : uint = 0; i < itemsArray.length; i++)
			{
				// IMAGE ITEMS
				var mc : MovieClip = mcAllItems.duplicateMovieClip(new mcImageItem(), "mcItem" + i);
				
				itemsArray[i].item = mc;
				mc.index = i;
				
				mc.mcHolder.alpha = 0;
			}
			
			
			itemsArray[nowLoading].item.mcHolder.loadContent(itemsArray[nowLoading].imagePath, completeListener, null, false);
		}
		
		/*
		 * resizes the banner depending on the params dimensions
		 */
		public function resize(w : Number, h : Number) : void
		{
			mcBack.width = w;
			mcBack.height = h;
			
			mcMask.width = w;
			mcMask.height = h;
		}	
		
		
		/*
		 * resets the banner to the initial state
		 */
		public function resetBanner() : void
		{
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			
			previousImage = selectedImage;
			selectedImage = 0;
			
			selectImage();
		}
		
	
		/*
		 * ON LOAD COMPLETE AN IMAGE
		 */
		public function completeListener(pTarget : MovieClip) : void
		{
			if(itemsArray[nowLoading].link) 
				pTarget.addEvents(this);
				
			nowLoading++;
			
			// resize and reposition image
			pTarget.fitToRect(componentWidth, componentHeight);
					
			if(nowLoading < itemsArray.length)	
			{
				itemsArray[nowLoading].item.mcHolder.loadContent(itemsArray[nowLoading].imagePath, completeListener, null, false);
			}
			else
			{
				// all images loaded
				show();
				
				// display the first image
				selectImage();		
			}
		}
		
		
		
		/***** NAVIGATE THROUGH IMAGES *****/
		/*
		 * moves to next image
		 */		 
		public function nextImage() : void
		{
			if(isRandom)
			{
				selector++;
				
				if(selector >= itemsArray.length && loop) 
				{
					selector = 0;
				}
				
				selectedImage = randomizedArray[selector];
				
				if(selector < itemsArray.length) selectImage();
			}
			else
			{
				selectedImage++;
				
				if(selectedImage >= itemsArray.length && loop) 
				{
					selectedImage = 0;
				}
				
				if(selectedImage < itemsArray.length) selectImage();
			}
		}
		
		
		
		/*
		 * moves to previous image
		 */
		public function prevImage() : void
		{
			if(isRandom)
			{
				selector--;
				
				if(selector < 0) 
				{
					selector = itemsArray.length - 1;
				}
				
				
				selectedImage = randomizedArray[selector];
			}
			else
			{
				selectedImage--;
			
				if(selectedImage < 0) selectedImage = itemsArray.length - 1;
			}
			
			selectImage();
		}
		
		
		/*
		 * play / pause slideshow
		 */
		public function toggleSlideshow() : void
		{
			isPlaying2 = !isPlaying2;
			
			if(isPlaying2)
			{
				if(itemsArray[selectedImage].slideShowTime != 0) this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
			else
			{
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);	
			}
		}
		
		// start / stop slideshow
		public function stopSlideshow(pValue : Boolean = true) : void
		{
			isPlaying2 = pValue;
			toggleSlideshow();
		}
		
		/*
		 * selects the current image
		 */
		public function selectImage(id : Number = NaN) : void
		{
			var sel : Number;
			if(!isNaN(id)) sel = id;
			else sel = selectedImage;
			
			// RESET TIMER
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			count = 0;
			
			// put image on highest depth
			mcAllItems.setChildIndex(itemsArray[sel].item, mcAllItems.numChildren - 1);
			
			//fade in new image
			Tweener.addTween(itemsArray[sel].item.mcHolder, {alpha : 1, time : itemsArray[sel].transitionTime, transition : "linear", onComplete : function() : void
			{
				// reset alpha value of image underneath
				if(!isNaN(previousImage))
				{ 
					Tweener.addTween(itemsArray[previousImage].item.mcHolder, {alpha : 0, time : transitionSpeed, transition : "linear"});
				}
			
				previousImage = sel;
				selectedImage = sel;
				
				// COUNT NEXT IMAGE
				if(itemsArray.length && isPlaying2) 
					countTime();
			}});
			
		}
		
		/***************************************************
		 * 
		 *  			  EVENT HANDLERS
		 * 				
		 ***************************************************/
		
		/**
		 * ENTER FRAME event handler
		 */
		 public function enterFrameHandler(event : Event) : void
		{
			count++;	
			
			if (count / nrFrames >= itemsArray[selectedImage].slideShowTime)
			{
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				nextImage();
			}
		}

		public function countTime() : void
		{
			isPlaying = true;
			
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			count = 0;
			
			if(itemsArray[selectedImage].slideShowTime != 0) 
				this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}

		
		/**
		 * OVER EVENT HANDLER
		 */
		public function overHandler(event : MouseEvent) : void
		{
		}


		/**
		 * OUT EVENT HANDLER
		 */
		public function outHandler(event : MouseEvent) : void
		{
		}


		/**
		 * PRESS EVENT HANDLER
		 */
		public function pressHandler(event : MouseEvent) : void
		{
			var item : MovieClip = MovieClip(event.currentTarget);
			
			// set pressed the new item
			this.currPressedObject = item;
			
			// add the release event on stage
			stage.addEventListener(MouseEvent.MOUSE_UP, releaseOutsideHandler);
			stage.addEventListener(Event.MOUSE_LEAVE, releaseOutsideHandler);
		}
		
		
		/**
		 * RELEASE OUTSIDE EVENT HANDLER
		 */
		public function releaseOutsideHandler(e : MouseEvent) : void 
		{
			// remove the stage listeners
	        stage.removeEventListener(MouseEvent.MOUSE_UP, releaseOutsideHandler);
	        stage.removeEventListener(Event.MOUSE_LEAVE, releaseOutsideHandler);
		}
		
		
		
		/**
		 * RELEASE EVENT HANDLER
		 */
		public function releaseHandler(event : MouseEvent) : void
		{
			var mc : Object = event.currentTarget; 
			
			// call the specific function
			if(mc == currPressedObject) releaseFunction(mc);
		}


		/**
		 * RELEASE FUNCTION 
		 */
		public function releaseFunction(mc : Object) : void
		{
			switch(mc.name)
			{
				case "mcHolder":
					URLNavigator.ChangePage(itemsArray[selectedImage].link, itemsArray[selectedImage].target);
				break;
			
				case "mcPrev":
					prevImage();
				break;
				
				case "mcNext":
					nextImage();
				break;
				
				case "mcPause":
					toggleSlideshow();
				break;
			}
		}
		

	} // FROM CLASS
} // FROM PACKAGE


