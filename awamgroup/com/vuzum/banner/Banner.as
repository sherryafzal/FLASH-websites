/**
* XML Image Slideshow, May 2009
* @author Vuzum Media, LLC.
* @version 1; 
* http://www.vuzum.com
* email: office@vuzum.com
*/

package com.vuzum.banner 
{
	import flash.events.MouseEvent;	
	
	import flash.events.Event;	
	import flash.display.MovieClip;
	
	import caurina.transitions.*;
	import caurina.transitions.properties.*;
	
	import flash.utils.*;
	import flash.filters.BlurFilter;
	
	// OTHER'S IMPORTS	
	import caurina.transitions.properties.ColorShortcuts;
	import caurina.transitions.properties.FilterShortcuts;
	//
	import com.zorked.URLNavigator;
	
	// MY IMPORTS
	import com.vuzum.utils.*;
	
	public class Banner extends MovieClip 
	{
		// COMPONENTS INSIDE
		public var mcController : MovieClip;
		public var mcTimer : MovieClip;
		public var mcMask : MovieClip;
		public var mcAllItems : MovieClip;
		public var mcText : MovieClip;
		public var mcBack : MovieClip;
		public var mcLoader : MovieClip;
		
		// HANDLERS VARS
		private var currPressedItem : MovieClip;
		
		// INTERNAL MEMBERS
		// component vars
		public var pathTo : String;
		public var componentWidth : Number;
		public var componentHeight : Number;
		
		// data vars
		public var bannerArray : Array;
		private var selectedImage : Number = 0;
		private var previousImage : Number;
		private var transitionSpeed : Number = .8;
		//
		
		var filter : BlurFilter = new BlurFilter(0, 0, 15);
        var filters_array : Array = new Array();
		
		// XML VARS
		//
		private var slideShowTime : Number;
		private var startWith : Number;
		private var backgroundColor : Number;
		private var backgroundTransparency : Number;
		private var barHeight : Number;
		
		// SETTINGS VARS
		private var thumbsX : Number = 20;
		private var distanceBetweenControllerElements : Number = 10;
		private var distanceBetweenThumbs : Number = 6;
		private var minAlpha : Number = .2;
		private var blurValue : Number = 8;
		private var titleX : Number = 0;
		private var titleY : Number = 0;
		
		// AUX VARS
		private var count : Number = 0;
		private var nrFrames : Number = 30;
		private var firstImageLoaded : Boolean = false;
		private var initialX : Number;
		private var isLoading : Boolean = false;
		private var isPlaying2 : Boolean = true;
		private var fadeTransition : Boolean = false;
		private var verticalTransition : Boolean = false;
		private var controllerTop : Boolean = false;

		// CONSTRUCTOR
		public function Banner()
		{
			// PROTOTYPES init			
			new Prototypes();
			
			// TWEENER inits
			ColorShortcuts.init();
			FilterShortcuts.init();
			
			// timer
			mcTimer.mcProgress.scaleX = 0;
			
			// controller
			mcController.mcBack.visible = false;
			mcController.mcAllThumbs.mcThumb.visible = false;
			mcController.visible = false;
			
			// items holder
			if(verticalTransition)
				initialX = mcAllItems.y;
			else
				initialX = mcAllItems.x;
				
			mcAllItems.mask = mcMask;
			mcAllItems.mcItem.visible = false;
			
			mcText.mouseChildren = false;
			mcText.mouseEnabled = false;
			
			mcText.alpha = 0;
			mcText.txt.initText("");
			
			filters_array.push(filter);
       	 	mcAllItems.filters = filters_array;
		}
		
		
		// show/hide all components
		public function show(flag : Boolean = true) : void
		{
			mcController.visible = flag;
			mcTimer.visible = flag;	
			mcText.visible = flag;	
			mcBack.visible = flag;	
			
			mcLoader.visible = !flag;	
		}
		
		
		public function init(pComponentWidth : Number = NaN, pComponentHeight : Number = NaN, pPathTo : String = "", xmlPath : String = "") : void
		{
			// hide everything
			show(false);
			
			// read the params
			componentWidth = pComponentWidth;
			componentHeight = pComponentHeight;
			pathTo = pPathTo;
			
			mcLoader.centerOn(!isNaN(componentWidth) ? componentWidth : stage.stageWidth, !isNaN(componentHeight) ? componentHeight : stage.stageHeight);
			
        	// read the xml file
			Prototypes.loadXML(pathTo + xmlPath, xmlLoaded);
		}
		
		public function xmlLoaded(xmlObject : XML) : void			
		{
			// read COMPONENT DIMENSIONS if they were not defined in flash vars
	   		
			// the width of the component
			if(isNaN(componentWidth))
				componentWidth = Prototypes.readNumberVar(xmlObject.@width.toString(), stage.stageWidth);
			
			// the height of the component
			if(isNaN(componentHeight))
				componentHeight = Prototypes.readNumberVar(xmlObject.@height.toString(), stage.stageHeight);					
			

			backgroundColor = Prototypes.readNumberVar(xmlObject.@backgroundColor, backgroundColor);
			backgroundTransparency = Prototypes.readNumberVar(xmlObject.@backgroundTransparency, backgroundTransparency)/100;
			
			slideShowTime = Prototypes.readNumberVar(xmlObject.@slideShowTime, slideShowTime);
			startWith = Prototypes.readNumberVar(xmlObject.@startWith, startWith);
			barHeight = Prototypes.readNumberVar(xmlObject.@barHeight, barHeight);
			transitionSpeed = Prototypes.readNumberVar(xmlObject.@transitionSpeed, transitionSpeed);
			
			titleX = Prototypes.readNumberVar(xmlObject.@titleX, titleX);
			titleY = Prototypes.readNumberVar(xmlObject.@titleY, titleY);
			
			fadeTransition = Prototypes.readBooleanVar(xmlObject.@fadeTransition, fadeTransition);
			verticalTransition = Prototypes.readBooleanVar(xmlObject.@verticalTransition, verticalTransition);
			controllerTop = Prototypes.readBooleanVar(xmlObject.@controllerTop, controllerTop);
			
			
			var itemsNode : XMLList = (xmlObject.items.item);
			bannerArray = new Array();
			
		
			// read the LIST OF IMAGES
			for(var i : Number = 0; i < itemsNode.length(); i++)
			{
				bannerArray[i] = new Object();
				bannerArray[i].id = i;
				bannerArray[i].title = Prototypes.readStringVar(itemsNode[i].title); 
				bannerArray[i].imagePath = Prototypes.readAssetPath(itemsNode[i].path, pathTo); 
				bannerArray[i].url = Prototypes.readStringVar(itemsNode[i].url);
				bannerArray[i].target = Prototypes.readStringVar(itemsNode[i].target);
				bannerArray[i].bar_color = Prototypes.readNumberVar(itemsNode[i].bar_color);
				bannerArray[i].bar_transparency = Prototypes.readNumberVar(itemsNode[i].bar_transparency)/100;
				bannerArray[i].slideShowTime = Prototypes.readNumberVar(itemsNode[i].slideShowTime);
			}
			
			
			// START THE COMPONENT
			start();
		}
		
		
		/*
		 * resizes the banner depending on the params dimensions
		 */
		public function resize(w : Number, h : Number) : void
		{
			mcBack.width = w;
			mcBack.height = h;
			
			mcTimer.width = w;
			
			mcText.x = titleX;
			mcText.y = titleY;

			mcMask.width = w;
			mcMask.height = h;
			
			if(controllerTop)
			{
				mcController.y = -mcController.height;
			}
			else
			{
				mcController.y = h;
			}
			
			mcTimer.y = mcController.y;
			
			mcController.mcBack.width = w;
		}		
		


		/*
		 * Loads all images in an array of movie clips 
		 */
		public function start() : void
		{
			// resize the component
			resize(componentWidth, componentHeight);
			
			// init the controller
			selectedImage = startWith - 1;
			
			
			// BACKGROUND
			mcController.mcBack.height = barHeight;
			mcBack.alpha = backgroundTransparency;
			Tweener.addTween(mcBack, {_color : backgroundColor, time : 0, transition:"linear"});
			mcBack.visible = true;
			
			if(bannerArray.length > 1) mcController.visible = true;
			
			// LIST OF IMAGES AND THUMBS
			for(var i : uint = 0; i < bannerArray.length; i++)
			{
				// IMAGE ITEMS
				
				var mc : MovieClip = mcAllItems.duplicateMovieClip(new mcImageItem(), "mcItem" + i); 
				bannerArray[i].item = mc;
				
				bannerArray[i].item.index = i;
				if(!fadeTransition)	
				{
					if(verticalTransition)
						bannerArray[i].item.y = i * componentHeight;
					else
						bannerArray[i].item.x = i * componentWidth;
				}
				
				// loader for images
				bannerArray[i].item.isLoaded = false;
				bannerArray[i].item.mcHolder.alpha = 0;
				
				// thumbnails
				var mcThumb : MovieClip = mcController.mcAllThumbs.duplicateMovieClip(new mcImageThumb(), "mcThumb" + i); 
				bannerArray[i].thumb = mcThumb;
				
				bannerArray[i].thumb.index = i;
				bannerArray[i].thumb.alpha = minAlpha;
				bannerArray[i].thumb.mcSelected.visible = false;
				
				bannerArray[i].thumb.x = i * (mcController.mcAllThumbs.mcThumb.width + distanceBetweenThumbs);
				
				// if you want to activate the thumbnails before the image is loaded
				bannerArray[i].thumb.addEvents(this);
			}
			
			
			
			// CONTROLLER
			mcController.mcPrev.x = thumbsX;
			mcController.mcAllThumbs.x = mcController.mcPrev.x + mcController.mcPrev.width + distanceBetweenControllerElements;
			mcController.mcNext.x = mcController.mcAllThumbs.x + mcController.mcAllThumbs.width + distanceBetweenControllerElements;
			//
			mcController.mcAllThumbs.y = Math.round((mcController.mcBack.height - mcController.mcAllThumbs.height)/2);
			mcController.mcPrev.y = Math.round((mcController.mcBack.height - mcController.mcPrev.height)/2);
			mcController.mcNext.y = Math.round((mcController.mcBack.height - mcController.mcNext.height)/2);
			//
			mcController.mcBack.alpha = .6;
			mcController.mcBack.visible = true;
			
			// init the buttons
			mcController.mcPrev.addEvents(this);
			mcController.mcNext.addEvents(this);
			
			show();
			
			// SELECT THE FIRST IMAGE
			selectImage();
		}
		
		/*
		 * resets the banner to the initial state
		 */
		public function resetBanner() : void
		{
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			Tweener.addTween(mcTimer.mcProgress, {scaleX : 0, time : 1, transition:"easeOutExpo"}); 
			
			previousImage = selectedImage;
			selectedImage = 0;
			
			mcAllItems.x = initialX;
			
			selectImage();
		}
	
		/*
		 * ON LOAD COMPLETE AN IMAGE
		 */
		public function completeListener(pTarget : MovieClip) : void
		{
			var mcParent : MovieClip = MovieClip(pTarget.parent);
			isLoading = false;
			
			// SHOW THE TIMER
			if(bannerArray.length > 1) mcTimer.visible = true;
			
			// INIT THE PARENT
			MovieClip(pTarget.parent).isLoaded = true;
			if(bannerArray[selectedImage].url) pTarget.addEvents(this);
			
			// SELECT THIS IMAGE'S THUMB
			//bannerArray[mcParent.index].thumb.addEvents(this);
			bannerArray[mcParent.index].thumb.mcSelected.visible = true;
			Tweener.addTween(bannerArray[mcParent.index].thumb, {alpha : 1, time :1, transition : "easeOutExpo"});
			
			Tweener.addTween(mcLoader, {alpha : 0, time : 1, transition:"easeOutExpo", onComplete : function() : void {this.visible = false;}});
			
			// HIDE THE LOADER and then START COUNTING for the next image
			Tweener.addTween(pTarget, {alpha : 1, time : 1, transition:"easeOutExpo", onComplete : function() : void 
			{
				// after the first image is loaded SHOW THE CONTROLLER
				if(firstImageLoaded != true)
				{
					// change the status
					firstImageLoaded = true;
					
					// show the timer and controller
					
					Tweener.addTween(mcTimer, {y : controllerTop ? mcController.height : componentHeight - mcController.height, time :1, transition : "easeOutExpo",onComplete : function() : void 
					{
						if(bannerArray.length > 1 && !isLoading && isPlaying2) countTime();
					}});
					
					Tweener.addTween(mcController, {y : controllerTop ? 0 : componentHeight - mcController.height, time :1, transition : "easeOutExpo"});
				}
				else
				{
					if(bannerArray.length > 1 && isPlaying2) countTime();
				}
				
				mcText.txt.htmlText = bannerArray[selectedImage].title;
				Tweener.addTween(mcText, {alpha : 1, time : 1, transition:"easeOutExpo"});
				
			}});
		}
		
		
		
		/***** NAVIGATE THROUGH IMAGES *****/
		/*
		 * moves to previous image
		 */		 
		public function nextImage() : void
		{
			mcTimer.mcProgress.scaleX = 1;
			
			selectedImage++;
			if(selectedImage >= bannerArray.length) selectedImage = 0;
			
			selectImage();
		}
		
		
		/*
		 * moves to previous image
		 */
		public function prevImage() : void
		{
			selectedImage--;
			
			if(selectedImage < 0) selectedImage = bannerArray.length - 1;
			
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
				if(bannerArray[selectedImage].slideShowTime != 0) this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
			else
			{
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);	
			}
		}
		
		/*
		 * selects the current image
		 */
		public function selectImage() : void
		{
			isLoading = true;
			count = 0;
			
			// RESET TIMER
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			Tweener.addTween(mcTimer.mcProgress, {scaleX : 0, time : 1, transition:"easeOutExpo"}); 
			
			Tweener.removeTweens(mcAllItems);

			
			// change the controller background
			Tweener.addTween(mcController.mcBack, {_color : bannerArray[selectedImage].bar_color, time : 1, transition:"linear"});
			Tweener.addTween(mcController.mcBack, {alpha : bannerArray[selectedImage].bar_transparency, time : 1, transition:"linear"});
			
			// change the timer color
			Tweener.addTween(mcTimer.mcProgress, {_color : bannerArray[selectedImage].bar_color, time : 1, transition:"linear"});
			
			// deselect the previouos image thumb
			if(!isNaN(previousImage)) 
			{
				Tweener.removeTweens(bannerArray[previousImage].item.mcHolder);
//				bannerArray[previousImage].item.mcHolder.alpha = 1;
				
				Tweener.addTween(bannerArray[previousImage].thumb, {alpha : minAlpha, time : 1, transition:"easeOutExpo"});
				bannerArray[previousImage].thumb.mcSelected.visible = false;
			}
			
			bannerArray[selectedImage].thumb.mcSelected.visible = true;
			previousImage = selectedImage;
			
			// select the image's thumb
			Tweener.addTween(bannerArray[selectedImage].thumb.mcSelected, {_color : bannerArray[selectedImage].bar_color, time : 1, transition:"linear"});
			mcText.txt.htmlText = "";
			
			if(!fadeTransition)
			{
				// blur the items
				Tweener.addTween(mcAllItems, {_Blur_blurX : blurValue, time : .5, transition:"easeOutExpo", onComplete : function() : void 
				{
					Tweener.addTween(mcAllItems, {_Blur_blurX : 0, time : .5, transition:"easeOutExpo"});
				}});
				
				// move the items
				if(verticalTransition)
				{
					Tweener.addTween(mcAllItems, {y : -selectedImage * mcBack.height + initialX, time : transitionSpeed, transition:"easeOutExpo", onComplete : function() : void 
					{	
						showThumb();
					}});
				}
				else
				{
					Tweener.addTween(mcAllItems, {x : -selectedImage * mcBack.width + initialX, time : transitionSpeed, transition:"easeOutExpo", onComplete : function() : void 
					{	
						showThumb();
					}});
				}
			}
			else
			{
				mcAllItems.setChildIndex(bannerArray[selectedImage].item, mcAllItems.numChildren - 1);
				bannerArray[selectedImage].item.mcHolder.alpha = 0;
				Tweener.addTween(bannerArray[selectedImage].item.mcHolder, {alpha : 1, time : 1, transition:"easeOutExpo"});
				
				showThumb();
			}
			
		}
		
		public function showThumb() : void
		{
			// show the image's thumb			
			Tweener.addTween(bannerArray[selectedImage].thumb, {alpha : 1, time : 1, transition:"easeOutExpo"});
			
			mcText.alpha = 0;
			Tweener.addTween(mcText, {alpha : 1, time : 1, transition:"easeOutExpo"});
			mcText.txt.htmlText = bannerArray[selectedImage].title;
							
			// load the image
			if(bannerArray[selectedImage].item.isLoaded == false)
			{
				mcLoader.alpha = 1;
				bannerArray[selectedImage].item.mcHolder.loadContent(bannerArray[selectedImage].imagePath, completeListener, mcLoader);
			}
			// start counting
			else
			{
				isLoading = false;
				if(isPlaying2) countTime();
			}
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
			var val : Number = int((count / nrFrames * 100) / bannerArray[selectedImage].slideShowTime);
			
			if (count / nrFrames >= bannerArray[selectedImage].slideShowTime)
			{
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				Tweener.addTween(mcTimer.mcProgress, {scaleX : Math.round(val) / 100, time : .5, transition:"easeOutExpo"}); 
				
				setTimeout(nextImage, 1000);
			}
			else
			{
				Tweener.addTween(mcTimer.mcProgress, {scaleX : Math.round(val) / 100, time : 1, transition:"easeOutExpo"}); 
			}
		}

		public function countTime() : void
		{
			isPlaying2 = true;
			
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			
			Tweener.addTween(mcTimer.mcProgress, {scaleX : 0, time : 1, transition:"easeOutExpo"}); 
			
			count = 0;
			
			previousImage = selectedImage;
			if(bannerArray[selectedImage].slideShowTime != 0) this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}

		
		/**
		 * OVER EVENT HANDLER
		 */
		public function overHandler(event : MouseEvent) : void
		{
			var item : Object = event.currentTarget; 
			var mcParent : MovieClip = MovieClip(item.parent);
			
			switch(item.name)
			{
				case "mcPrev":
					Tweener.addTween(item, {alpha : .7, time :1, transition : "easeOutExpo"});
				break;
				
				case "mcNext":
					Tweener.addTween(item, {alpha : .7, time :1, transition : "easeOutExpo"});
				break;
			}
			
			switch(mcParent.name)
			{
				case "mcAllThumbs":
					if(item.index != selectedImage)
					{
						Tweener.addTween(item, {alpha : 1, time :1, transition : "easeOutExpo"});
						item.mcSelected.visible = true;
					}
				break;
			}
		}


		/**
		 * OUT EVENT HANDLER
		 */
		public function outHandler(event : MouseEvent) : void
		{
			var item : Object = event.currentTarget; 
			var mcParent : MovieClip = MovieClip(item.parent);
			
			switch(item.name)
			{
				case "mcPrev":
					Tweener.addTween(item, {alpha : 1, time :1, transition : "easeOutExpo"});
				break;
				
				case "mcNext":
					Tweener.addTween(item, {alpha : 1, time :1, transition : "easeOutExpo"});
				break;
			}
			
			switch(mcParent.name)
			{
				case "mcAllThumbs":
					if(item.index != selectedImage)
					{
						Tweener.addTween(item, {alpha : minAlpha, time :1, transition : "easeOutExpo"});
						item.mcSelected.visible = false;
					}
				break;
			}
		}


		/**
		 * PRESS EVENT HANDLER
		 */
		public function pressHandler(event : MouseEvent) : void
		{
			var item : MovieClip = MovieClip(event.currentTarget); //trace(item.name);
			
			// set pressed the new item
			this.currPressedItem = item;
			
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
	        
	        // here release outside for the items where release outside is the same with release
			switch(currPressedItem)
			{
				case mcBack:
					// write the code here for this clip
					break;
			}	        
		}
		
		
		/**
		 * RELEASE EVENT HANDLER
		 */
		public function releaseHandler(event : MouseEvent) : void
		{
			var item : MovieClip = MovieClip(event.currentTarget); //trace(item.name);
			var mcParent : MovieClip = MovieClip(item.parent);
			
			// test if the releasse event comes from the same item that was pressed
			if(item == this.currPressedItem)
			{
				switch(item.name)
				{
					case "mcHolder":
						URLNavigator.ChangePage(bannerArray[selectedImage].url, bannerArray[selectedImage].target);
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
				
				switch(mcParent.name)
				{
					case "mcAllThumbs":
						if(item.index != selectedImage)
						{
							selectedImage = item.index;
							selectImage();
						}
					break;
				}
			}
		}



	} // FROM CLASS
} // FROM PACKAGE