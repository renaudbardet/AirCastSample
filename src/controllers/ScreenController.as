package controllers
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.utils.Dictionary;
	
	import ui.CloseButtonMC;
	
	import util.Future;
	import util.TriggerFuture;
	import util.getClass;
	import util.f.callback;

	public class ScreenController
	{
		
		private var storedPages:Dictionary;
		private var pageStack:Vector.<Page>;
		private var popupStack:Vector.<Popup>;
		private function get currentPage():Page { return pageStack.length > 0 ? pageStack[pageStack.length-1] : null; }
		private function get currentPopup():Popup { return popupStack.length > 0 ? popupStack[popupStack.length-1] : null; }
		
		private var pageLayer:Sprite;
		private var popupLayer:Sprite;
		
		public function ScreenController(pageLayer:Sprite, popupLayer:Sprite)
		{
			storedPages = new Dictionary();
			pageStack = new Vector.<Page>();
			popupStack = new Vector.<Popup>();
			this.pageLayer = pageLayer;
			this.popupLayer = popupLayer;
		}
		
		public function setPage(page:Class, stack:Boolean = false, store:Boolean = false):Page
		{
			
			if(currentPage != null)
			{
				if(getClass(currentPage) == page) return currentPage;
				
				var previousPage:Page = currentPage;
				if(stack)
					previousPage.context.pause();
				else {
					previousPage.context.close();
					pageStack.pop();
				}
				
				pageLayer.removeChild(previousPage);
			}
			
			clearPopups();
			
			if(storedPages[page] != null)
				pageStack.push( storedPages[page] );
			else
				pageStack.push( new page() as Page );
			
			if(store) storedPages[page] = currentPage;
			
			pageLayer.addChild(currentPage);
			
			currentPage.context.resume();
			
			return currentPage;
			
		}
		
		public function discardStoredPage( page:Class, removeFromStack:Boolean = false ):Boolean
		{
			if(storedPages.hasOwnProperty(page)) {
				var inStack:Boolean = pageStack.indexOf(storedPages[page]) > 0;
				if(removeFromStack || !inStack)
					storedPages[page].context.close();
				if(removeFromStack && inStack)
					pageStack.splice(pageStack.indexOf(storedPages[page]), 1);
				delete storedPages[page];
				return true;
			}
			return false;
		}
		
		public function setPopup(popup:Class, ...params):Future
		{
			
			var newPopup:Popup = new popup();
			
			popupStack.push( newPopup );
			
			popupLayer.addChild( newPopup );
			var shader:Sprite = new Sprite();
			shader.graphics.beginFill( 0x000000, .8 );
			shader.graphics.drawRect( 0, 0, Ui.stageWidth, Ui.stageHeight );
			
			var popupResult:Future = newPopup.init.apply( null, params );
			
			newPopup.x = (Ui.stageWidth - newPopup.width) / 2;
			newPopup.y = (Ui.stageHeight - newPopup.height) / 2;
			
			newPopup.shader = shader;
			shader.x = -newPopup.x;
			shader.y = -newPopup.y;
			
			if (newPopup.hasCloseButton)
				popupResult = popupResult.unless( createCloseButton( newPopup ) );
			
			togglePageUnderPopup();
			
			popupResult.onResult( callback( removePopup, newPopup ) );
			
			return popupResult;
			
		}
		
		public function clearPopups():void
		{
			
			while( currentPopup != null )
				removeCurrentPopup();
			
		}
		
		public function removePopup(popup:Popup):Boolean
		{
			var idx:int = popupStack.indexOf( popup );
			if ( idx>-1 )
			{
				popupStack.splice( idx, 1 );
				popupLayer.removeChild( popup );
				popup.context.close();
				togglePageUnderPopup();
			}
			return idx>-1;
		}
		
		public function removeCurrentPopup(ifPopupType:Class = null):Boolean
		{
			
			if ( currentPopup != null && ( ifPopupType == null || getClass( currentPopup ) == ifPopupType ) )
				return removePopup( currentPopup );
			
			return false;
			
		}
		
		private function togglePageUnderPopup():void{
			
			if(currentPopup != null){
				if(pageLayer.filters.length == 0)
					pageLayer.filters = [new BlurFilter(10,10,1)];
				if( currentPage != null )
					currentPage.context.pause();
			}
			else {
				pageLayer.filters = [];
				if( currentPage != null )
					currentPage.context.resume();
			}
			
			
			
		}
		
		private function createCloseButton(popup:Popup):Future
		{
			var closed:TriggerFuture = new TriggerFuture();
			var closeBtn:CloseButtonMC = new CloseButtonMC();
			
			popup.context.registerEventListener( closeBtn, MouseEvent.CLICK, function(e:Event):void{
				closed.complete("popup closed");
			});
			
			closeBtn.x = Ui.stageWidth - (20 + closeBtn.width) - popup.x;
			closeBtn.y = 20 - popup.y;
			
			popup.addChild( closeBtn );
			
			return closed;
		}
		
	}
}