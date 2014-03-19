package util.f{
	import flash.events.Event;

	/**
	 * transforms a function():void into a function(e:Event):void to be passed as an eventListener
	 * @param _f	a function():void
	 * @return 		a function(e:Event):void
	 * 
	 */
	public function eventListener( _f:Function ) : Function
	{
		
		return function( e:Event ):void { _f() ; }
		
	}
}