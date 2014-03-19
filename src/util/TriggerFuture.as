package util
{
	public class TriggerFuture extends Future
	{
		
		/**
		 * trigger the completion of the Future and the call to every referenced callback
		 * @param res	an optional data object
		 */
		public function complete( res:* = null ):void
		{
			
			this._completeEither( Either.Right( res ) ) ;
			
		}
		
		/**
		 * trigger the failed completion of the Future and the call to every referenced error related callback
		 * @param error	an optional error
		 */
		public function fail( error:* = null ):void
		{
			
			this._completeEither( Either.Left( error ) ) ;
			
		}
		
		/**
		 * trigger the completion of the Future with a result either right or erroneous
		 * @param res	an Either of type Left(error) or Right(data)
		 */
		public function completeEither( res:Either ):void
		{
			
			this._completeEither( res ) ;
			
		}
		
		public static function fromFuture(f:Future):TriggerFuture
		{
			
			var tf:TriggerFuture = new TriggerFuture() ;
			tf.bind( f ) ;
			return tf ;
			
		}
		
		/**
		 * bind the completion or failure of this Future to the completion or failure of f2
		 * when f2 completes this Future will complete, and if f2 fails this Future will fail
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function bind( f2:Future ) : Future
		{
			
			return _bind( f2 ) ;
			
		}
		
		public static function completed( data:* = null ) : TriggerFuture
		{
			
			var f : TriggerFuture = new TriggerFuture() ;
			f._complete( data ) ;
			return f ;
			
		}
		
	}
}