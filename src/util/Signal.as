package util
{
	import flash.utils.Dictionary;

	public class Signal implements ISignal
	{
		
		private var typeConstraint:Class;
		private var callbacks:Dictionary;
		private var dispatcher:Object;
		
		/**
		 * @param typeConstraint		specify a Class that enforces that only this specified type of object goes throught that signal
		 * @param restrictDispatcher	specify an object that will serve as a credential to dispatch, if not null you will need to pass the same instance when calling dispatch
		 */
		public function Signal( typeConstraint:Class = null, restrictedDispatcher:Object = null )
		{
			
			this.typeConstraint = typeConstraint;
			this.dispatcher = restrictedDispatcher;
			
			callbacks = new Dictionary();
			
		}
		
		public function add(cb:Function, once:Boolean=false):void
		{
			
			if(cb.length > 1)
				return;// throw "cannot add a function that expects more than 1 parameter";
			
			callbacks[cb] = once;
			
		}
		
		public function map( mapper:Function ):ISignal
		{
			return new SignalMapper(this, mapper);
		}
		
		public function hasListener(cb:Function):Boolean
		{
			return callbacks[cb] != undefined;
		}
		
		public function remove(cb:Function):Boolean
		{
			var exists:Boolean = callbacks[cb] != undefined;
			if(exists)
				delete callbacks[cb];
			return exists;
		}
		
		public function removeAll():void
		{
			callbacks = new Dictionary();
		}
		
		public function nextDispatch():Future { return Future.nextSignal( this ); }
		
		public function dispatch(data:*=null, restrictedDispatcher:Object=null):void
		{
			
			if( dispatcher!=null && restrictedDispatcher != dispatcher )
				return;
				// throw "signal dispatch error: illegal dispatcher, a restricted dispatcher has been specified upon creation of this signal, you need to pass it to dispatch"
			
			if( data != null && typeConstraint != null && !(data is typeConstraint))
				return;
				// throw "signal dispatch error: the type of data to be dispatched by this signal has been constrained to "
				// + getQualifiedClassName(typeConstraint) + " but data provided is of type " + getQualifiedClassName(data);
			
			for (var cb:Function in callbacks)
			{
				if(cb.length > 0)
					cb(data);
				else
					cb();
				if(callbacks[cb])
					delete callbacks[cb];
			}
			
		}
		
	}
}