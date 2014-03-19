package util
{
	import flash.utils.Dictionary;

	public class SignalMapper implements ISignal
	{
		
		private var _s:ISignal;
		private var _f:Function;
		
		private var listeners:Dictionary;
		
		public function SignalMapper( s:ISignal, f:Function )
		{
			this._s = s;
			this._f = f;
			listeners = new Dictionary();
		}
		
		public function add( listener:Function, once:Boolean=false ):void
		{
			
			var innerListener:Function;
			if( listeners[listener] != null )
				innerListener = listeners[listener]; 
			else{
				innerListener = function( e:* ):void{ listener( _f(e) ); };
				listeners[listener] = innerListener;
			}
			_s.add( innerListener, once );
			
		}
		
		public function map( mapper:Function ):ISignal
		{
			return new SignalMapper( this, mapper );
		}
		
		public function remove( listener:Function ):Boolean
		{
			
			if( listeners[listener] == null )
				return false;
			var innerListener:Function = listeners[listener]; 
			_s.remove( innerListener );
			if( !_s.hasListener( innerListener ) )
				delete listeners[listener];
			return true;
			
		}
		
		public function hasListener( listener:Function ):Boolean
		{
			
			if( listeners[listener] == null )
				return false;
			var innerListener:Function = listeners[listener];
			return _s.hasListener( innerListener );
			
		}
		
		public function removeAll():void
		{
			for ( var l:Function in listeners )
			{
				do {
					var haslistener:Boolean = _s.remove( listeners[l] );
				} while( haslistener )
				delete listeners[l];
			}
		}
		
	}
}