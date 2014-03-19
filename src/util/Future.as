package util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;
	
	import util.f.callback;
	
	//import org.osflash.signals.IOnceSignal;
	
	/** 
	 * @author renaudbardet
	 * 
	 * A Future is a utility class that functional style programing features
	 * 
	 * ------ use case :
	 * // initiating an asynchronous process
	 * var f = new Future() ;
	 * 
	 * // referencing a callback
	 * f.onSuccess( myFunction ) ;
	 * 
	 * // end of the process
	 * f.dispatch( myResult ) ;
	 * 
	 * // the result will be cached so that if you reference another callback after the result is
	 * // obtained the callback will be seamlessly called with the result
	 * 
	 * examples :
	 * ----- animation
	 * 
	 * 		var animationDone:Future = new Future() ;
	 * 		var myClip:MovieClip = new MyClip() ;
	 * 		myClip.addEventListener( Event.ENTER_FRAME, function(e:Event):void { if(myClip.currentFrame == 10) f.complete() } ) ;
	 * 		myClip.play() ;
	 * 		animationDone.onSuccess( // do something, like relaunch another animation ) ;
	 * 
	 * ----- server calls
	 * 
	 * 		function callServer():Future
	 * 		{
	 * 			var serverResponded:Future = new Future() ;
	 * 			var myRequest:ServerRequest = new ServerRequest() ;
	 * 			myRequest.addEventListener( ServerEvent.RESPONSE, function(e:ServerEvent) { serverResponded.complete( e.data ) ; } ) ;
	 * 			return serverResponded ;
	 * 		}
	 * 
	 * usage
	 * 		var myServerData:Future = callServer() ;
	 * 		myServerData.onSuccess( treatServerData ) ;
	 * 
	 * handling Errors
	 * future handles natively the error process, because so many things could go wrong once you go asynchronous
	 * 		myServerData.onError( treatError ) ;
	 * 
	 * handling custom error
	 * 		myServerData.onResult( treatResponseOrError ) ;
	 * 
	 * ----- filtering, combining, mapping
	 * 
	 * 		function createFoo( json:String ):String {
	 * 			return new Foo( JSON.decode( json ) ) ;
	 * 		} 
	 * 		var myFoo:Future = callServer().map( createJibbidyBoo ) ;
	 * 
	 * this can be used to refine errors as well
	 * 		
	 * 		function handleJsonError( result:Either ):Either {
	 * 			
	 * 			if ( result.isLeft() )
	 * 				return result ;
	 * 			
	 * 			var data = JSON.decode( result.getRight() ) ;
	 * 			if ( data.error )
	 * 				return Either.Left( data.error ) ; // convert valid result into an error result
	 * 			else
	 * 				return Either.Right( data ) ; // return the decoded JSON
	 * 			
	 * 		}
	 * 		var myRes = callServer.mapResult( handleJsonError ) ;
	 * 
	 */
	public class Future
	{
		
		protected var _isComplete : Boolean ;
		
		protected var result : Either ;
		
		private var callbacks:Vector.<Function> ;
		private var errorCallbacks:Vector.<Function> ;
		private var resultCallbacks:Vector.<Function> ;
		
		private var typeConstraint:Class ;
		
		public function Future( typeConstraint:Class = null )
		{
			
			_isComplete = false ;
			
			callbacks = new Vector.<Function>() ;
			errorCallbacks = new Vector.<Function>() ;
			resultCallbacks = new Vector.<Function>() ;
			
			this.typeConstraint = typeConstraint ;
			
		}
		
		/**
		 * @return	true if data or error has been received, false otherwise
		 */
		public function get isComplete() : Boolean
		{
			return _isComplete;
		}
		
		/**
		 * @param f		a function to be called when the future is reached
		 * 				can be of type function(data):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		public function onSuccess( f:Function ):Future
		{
			
			if ( _isComplete )
			{
				
				if ( result.isRight() )
				{
					if ( f.length == 0 )
						f() ;
					else
						f(result.getRight()) ;
				}
				
			}
			else
			{
				callbacks.push( f ) ;
			}
			
			return this ;
			
		}
		
		/**
		 * @param f		a function to be called when the future fails
		 * 				can be of type function(error):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		public function onError( f:Function ):Future
		{
			
			if ( _isComplete )
			{
				
				if ( result.isLeft() )
				{
					if ( f.length == 0 )
						f() ;
					else
						f(result.getLeft()) ;
				}
				
			}
			else
			{
				errorCallbacks.push( f ) ;
			}
			
			return this ;
			
		}
		
		/**
		 * @param f		a function to be called when data or error is received
		 * 				can be of type function(Either):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		public function onResult( f:Function ):Future
		{
			
			if ( _isComplete )
			{
				
				if ( f.length == 0 )
					f() ;
				else
					f(result) ;
				
			}
			else
			{
				resultCallbacks.push( f ) ;
			}
			
			return this ;
			
		}
		
		/**
		 * trigger the completion of the Future and the call to every referenced callback
		 * @param res	an optional data object
		 */
		protected function _complete( res:* ):void
		{
			
			_completeEither( Either.Right( res ) ) ;
			
		}
		
		/**
		 * trigger the failed completion of the Future and the call to every referenced error related callback
		 * @param error	an optional error
		 */
		protected function _fail( error:* ):void
		{
			
			_completeEither( Either.Left( error ) ) ;
			
		}
		
		/**
		 * trigger the completion of the Future with a result either right or erroneous
		 * @param res	an Either of type Left(error) or Right(data)
		 */
		protected function _completeEither( res:Either ):void
		{
			
			if ( _isComplete ) return ;
			
			result = res ;
			
			if ( typeConstraint != null && result.isRight() )
			{
				if ( !(result.getRight() is typeConstraint) )
					result = Either.Left("Type constraint failed, result given as "
						+ flash.utils.getQualifiedClassName(typeConstraint)
						+ " but is of type "
						+ flash.utils.getQualifiedClassName(result.getRight()) ) ;
			}
			
			_isComplete = true ;
			
			if ( res.isRight() )
			{
				for each ( var fct:Function in callbacks )
				{
					
					if ( fct.length == 0 )
						fct() ;
					else
						fct(res.getRight()) ;
					
				}
			}
			else
			{
				for each ( fct in errorCallbacks )
				{
					
					if ( fct.length == 0 )
						fct() ;
					else
						fct(res.getLeft()) ;
					
				}
			}
			
			for each ( fct in resultCallbacks )
			{
				
				if ( fct.length == 0 )
					fct() ;
				else
					fct(result) ;
				
			}
			
			callbacks = null ;
			errorCallbacks = null ;
			resultCallbacks = null ;
			
		}
		
		/**
		 * converts the resulting data of a Future throught a mapping function following the pattern
		 * 
		 * this					X - - - - -> A
		 * this.map(mapper)		X - - - - -> B
		 * 
		 * @param mapper	a function of type function( data:A ):B or function():B
		 * 					where A is the type returned by this Future and B the type you want to get
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(data) rather than data itself
		 * 
		 */
		public function map( mapper:Function ):Future
		{
			
			return mapResult(
				function mapCompleter( res:Either ) : Either
				{
					if ( res.isRight() )
					{
						if ( mapper.length > 0 )
							return Either.Right( mapper( res.getRight() ) ) ;
						else
							return Either.Right( mapper() ) ;
					}
					else
						return res ;
				} ) ;
			
		}
		
		/**
		 * idem map but surrounded with try catch and if an error occurs we fail with the Error as content
		 */
		public function mapTry( mapper:Function ):Future
		{
			
			return mapResult(
				function mapCompleter( res:Either ) : Either
				{
					if ( res.isRight() )
					{
						try{
							if ( mapper.length > 0 )
								return Either.Right( mapper( res.getRight() ) ) ;
							else
								return Either.Right( mapper() ) ;
						} catch(e:*) {
							return Either.Left(e);
						}
					}
					else
						return res ;
				} ) ;
			
		}
		
		/**
		 * 
		 * same as map but expects the mapper function to take the Either result rather than the data ( sim. to onResult comp. to onSuccess )
		 *  
		 * @param mapper	a function of type function( res:Either<A,error> ):Either<B,error> or function():Either<B,error>
		 * 					where A is the data expected in this Future and B the data you want, error is of any kind
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(result)
		 * 
		 */
		public function mapResult( mapper:Function ) : Future
		{
			
			var proxy:Future = new Future() ;
			this.onResult(
				function mapResultCompleter( res:Either ):void
				{
					if ( mapper.length > 0 )
						proxy._completeEither( mapper( res ) ) ;
					else
						proxy._completeEither( mapper() ) ;
				} ) ;
			return proxy ;
			
		}
		
		/**
		 * onSucess we process the data throught a mapper function that converts the result to an Either
		 * this is the same as using mapResult althought you don't need to care about the case were the result is already faulty
		 *  
		 * @param mapper	a function of type function( data:A ):Either<B,error> or function():Either<B,error>
		 * 					where A is the data expected in this Future and B the data you want, error is of any kind
		 * 
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(result)
		 * 
		 */
		public function refine( mapper:Function ) : Future
		{
			
			var proxy:Future = new Future() ;
			this.onResult(
				function refineCompleter( res:Either ):void
				{
					if ( mapper.length > 0 )
					{
						if ( res.isRight() )
							proxy._completeEither( mapper( res.getRight() ) ) ;
						else
							proxy._completeEither( res ) ;
					}
					else
						proxy._completeEither( mapper() ) ;
				} ) ;
			return proxy ;
			
		}
		
		/** 
		 * allows for joint asynchronous call patterns like
		 * 
		 * 	this			X - - - - -> A
		 * 	f2				X - - - - - - -> B
		 * 	f1.join(f2)		X - - - - - - -> (A,B)
		 * 
		 * @param f2	another Future completed or not
		 * @return 		a Future that will be completed on
		 * 
		 */
		public function join( f2 : Future ) : Future
		{
			
			var proxy:Future = new Future() ;
			
			function joinCheck():void {
				if ( _isComplete && f2._isComplete )
					proxy._complete( null ) ; // empty complete, if someone needs the data, he is welcome to implement an elegant tuple mechanism
			}
			
			onSuccess( joinCheck ) ;
			onError( proxy._fail ) ;
			f2.onSuccess( joinCheck ) ;
			f2.onError( proxy._fail ) ;
			
			return proxy ;
			
		}
		
		/**
		 * return a Future that will be completed by either this Future or f2, depending on wich is completed first
		 * and that will fail only if both fail
		 * 
		 * @param f2	a Future
		 * @return 		a new Future
		 * 
		 */
		public function or( f2:Future ):Future
		{
			
			var proxy:Future = new Future() ;
			this.onSuccess( proxy._complete ) ;
			f2.onSuccess( proxy._complete ) ;
			this.onError( function orErrorCompleter(thisError:*):void {
				if ( f2.isComplete && f2.result.isLeft() ) proxy._fail( [thisError, f2.result.getLeft()] ) ;
			} ) ;
			f2.onError( function orError2Completer(f2Error:*):void {
				if ( this.isComplete && this.result.isLeft() ) proxy._fail( [this.result.getLeft(), f2Error] ) ;
			} ) ;
			return proxy ;
			
		}
		
		/**
		 * fail this Future if f2 is complete first
		 * the error result will be the data result of f2
		 * 
		 * this produces the two following scenarios :
		 * 
		 * this					X - - - -> A
		 * f2					X - - -> B
		 * this.unless( f2 )	X - - -> Error(B)
		 * 
		 * or
		 * 
		 * this					X - - -> A
		 * f2					X - - - - -> B
		 * this.unless( f2 )	X - - -> A
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function unless( f2:Future ) : Future
		{
			
			f2.onSuccess( this._fail ) ;
			return this ;
			
		}
		
		/**
		 * fail this Future if f2 is complete first and vice-versa
		 * in both cases the failed Future will receive the data of the completed Future as an error
		 * 
		 * @see #unless()
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function mutex( f2:Future ) : Future
		{
			
			this.unless( f2 ) ;
			f2.unless( this ) ;
			
			return this ;
			
		}
		
		/**
		 * bind the completion or failure of this Future to the completion or failure of f2 and vice-versa
		 * either one of this or f2 completing or failing first will trigger the completion or failing of the other
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function sync( f2:Future ):Future
		{
			
			f2.onResult( this._completeEither ) ;
			this.onResult( f2._completeEither ) ;
			return this ;
			
		}
		
		/**
		 * bind the completion or failure of this Future to the completion or failure of f2
		 * when f2 completes this Future will complete, and if f2 fails this Future will fail
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		protected function _bind( f2:Future ) : Future
		{
			
			f2.onResult( this._completeEither ) ;
			return this ;
			
		}
		
		/**
		 * creates a copy of this Future that will be triggered at the same time with the same result (data or error)
		 * @return 	a new Future
		 * 
		 */
		public function copy() : Future
		{
			
			var f:Future = new Future() ;
			f._bind( this ) ;
			return f ;
			
		}
		
		/**
		 * 
		 * this chaining function allows for patterns like
		 * 
		 * 		X - - - - -> A -> X - - - - -> B
		 * 		X - - - - - - - - - - - - - -> B
		 * 
		 * for example play( "anim1" ).chain( F.callback( play, "anim2" ) )
		 * will wait for anim1 to complete then play anim2
		 * the Future returned by this expression will be completed once anim2 is done
		 * 
		 * @param func	a function of type function( data:* ):Future or function():Future
		 * 				where result is the data resulting of this Future's completion
		 * 				func will be called once this future is completed
		 * @return 		a Future that will be completed once both this Future and the Future returned by func are completed
		 * 
		 */
		public function chain( func:Function ):Future
		{
			
			return chainResult(
					function chainCompleter( res:Either ):Future {
						if ( res.isRight() )
						{
							if ( func.length > 0 )
								return func( res.getRight() ) ;
							else
								return func() ;
						}
						else
							return failed( res.getLeft() ) ;
					} ) ;
			
		}
		
		/**
		 * This is the same as chain but the passed function should use the Either result rather than the data ( sim. to onResult comp. to onSuccess )
		 * @param func	a function of type function( result:Either ):Future or function():Future
		 * 				where result is result in this Future upon result completion
		 * @return 		a Future that will be completed this Future then func's returned Future are completed
		 */
		public function chainResult( func:Function ):Future
		{
			
			var proxy:Future = new Future() ;
			
			function chainFunc( res:Either ):void
			{
				if ( func.length > 0 )
					func( res ).onResult( proxy._completeEither ) ;
				else
					func().onResult( proxy._completeEither ) ;
			}
			
			onResult( chainFunc ) ;
			
			return proxy ;
			
		}
		
		
		// ----------------------
		// secondary constructors
		
		/**
		 * Create a Future from an Event Dispatcher
		 * the event listener function will be removed once the event is triggered
		 *  
		 * @param dispatcher	the event dispatcher
		 * @param type			the event type as in addEventListener
		 * @param useCapture	same as addEvenListener
		 * @param priority		same as addEvenListener
		 * @return				a Future that will be completed on the next occurence of the event 
		 */		
		public static function nextEvent( dispatcher:EventDispatcher, type:String, useCapture:Boolean = false, priority:int = 0 ) : Future
		{
			
			var f:Future = new Future() ;
			
			function onEvent(e:Event):void
			{
				f._complete( e ) ;
			}
			
			f.onResult( callback( dispatcher.removeEventListener, type, onEvent ) );
			
			dispatcher.addEventListener( type, onEvent, useCapture, priority, false ) ;
			
			return f ;
			
		}
		
		/**
		 * Create a Future from an org.osflash.signal Signal
		 *  
		 * @param s		any instance of IOnceSignal
		 * @return		a Future that will be completed next time the signal dispatches
		 */		
		public static function nextSignal( s:Signal ) : Future
		{
			var f:Future = new Future() ;
			s.add( f._complete, true ) ;
			return f ;
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function completed( data : * = null ):Future
		{
			
			return completedEither( Either.Right( data ) ) ;
			
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function failed( error : * = null ):Future
		{
			
			return completedEither( Either.Left( error ) ) ;
			
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function completedEither( res:Either ):Future
		{
			
			var f:Future = new Future() ;
			f._completeEither( res ) ;
			return f ;
			
		}
		
	}
	
}
