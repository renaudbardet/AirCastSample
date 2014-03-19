package util
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class LoaderFuture extends Future
	{
		
		private var request:URLRequest;
		private var loader:URLLoader;
		
		public function LoaderFuture( request:URLRequest )
		{
			super(String);
			this.request = request;
			this.loader = new URLLoader();
			this.loader.addEventListener( Event.COMPLETE, onLoaderComplete );
			this.loader.addEventListener( ErrorEvent.ERROR, onError );
			this.loader.addEventListener( IOErrorEvent.IO_ERROR, onError );
			this.loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onError );
			this.loader.load(this.request);
		}
		
		private function onLoaderComplete(e:Event):void
		{
			_complete(this.loader.data);
		}
		
		private function onError(e:Event):void
		{
			_fail(this.loader.data);
		}
		
		public static function load( url:String ):LoaderFuture
		{
			
			var request:URLRequest = new URLRequest( url );
			
			var l:LoaderFuture = new LoaderFuture(request);
			
			return l;
			
		}
		
	}
}