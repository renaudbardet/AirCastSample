package util
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import util.Context;
	import util.Signal;
	import util.f.callback;
	import util.f.eventListener;

	public class Button
	{
		
		private var graphic:Sprite;
		
		private var _clicked:Signal;
		public function get clicked():Signal { return _clicked; }
		
		private var _context:Context;
		public function get context():Context { return _context; }
		
		public function Button( context:Context, graphic:Sprite )
		{
			
			this.graphic = graphic;
			this._clicked = new Signal(null, this);
			
			_context = new Context(context)
			_context.registerEventListener( graphic, MouseEvent.CLICK, eventListener( callback( _clicked.dispatch, null, this ) ) );
			
			_context.registerCleaner( destroy );
			
		}
		
		private function destroy():void {
			
			this.graphic = null;
			this._context = null;
			this._clicked = null;
			
		}
		
	}
}