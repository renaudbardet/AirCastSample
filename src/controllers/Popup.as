package controllers
{
	import flash.display.Sprite;
	
	import util.Future;

	public class Popup extends Page
	{
		
		private var _shader:Sprite;
		private var _hasCloseButton:Boolean;
		public function get hasCloseButton():Boolean { return this._hasCloseButton; }
		public function get shader():Sprite { return this._shader; }
		public function set shader(s:Sprite):void { if(_shader!=null) removeChild(_shader); _shader = s; addChildAt(s,0); }
		
		public function Popup( hasCloseButton:Boolean = true )
		{
			
			super();
			
			_hasCloseButton = hasCloseButton;
			
		}
		
		public function init(...params):Future
		{
			return Future.completed();
		}
		
	}
}