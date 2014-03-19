package util
{
	import flash.utils.clearInterval;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	
	public class FutureTimer extends Future
	{
		
		private var time:Number ;
		
		private var last_start_time:Number ;
		
		private var pid:uint ;
		
		/**
		 * Create a FutureTimer object
		 * @param time		the time in milliseconds
		 */
		public function FutureTimer( time:Number )
		{
			
			super() ;
			
			this.time = time ;
			
		}
		
		/**
		 * start the timer
		 */
		public function start():void
		{
			
			last_start_time = getTimer() ;
			pid = setInterval( stop, time ) ;
			
		}
		
		/**
		 * pause the timer
		 */
		public function pause():void
		{
			
			if ( isNaN(last_start_time) || pid == 0 )
				return ;
			
			var diff:Number = getTimer() - last_start_time ;
			if ( diff < 0 )
				return ; // impossible, the last start is ahead in time from now, just quit
			
			if ( diff >= time )
				stop() ;
			
			time = time - diff ;
			
			clearInterval( pid ) ;
			
			pid = 0 ;
			last_start_time = 0 ;
			
		}
		
		/**
		 * stop the timer, will trigger the Future
		 */
		public function stop():void
		{
			
			if ( isNaN(last_start_time) || pid == 0 )
				return ;
			
			clearInterval( pid ) ;
			
			pid = 0 ;
			last_start_time = 0 ;
			
			_complete( null ) ;
			
		}
		
		/**
		 * create a FutureTimer that is started right away
		 */
		public static function delay( time:Number ) : FutureTimer
		{
			var f:FutureTimer = new FutureTimer( time ) ;
			f.start() ;
			return f ;
		}
		
	}
	
}
