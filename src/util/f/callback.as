package util.f{
	/**
	 * Creates a function from another function by prefilling some parameters
	 * usage is:
	 * function foo( a:int, b:int ):int {}
	 * F.callback( foo, 12 ) ; // == function( b:int ):int { return foo( 12, b ) ; }
	 * 
	 * /!\ Warning
	 * in some cases optional parameters would make it difficult to understand what
	 * parameters are passed to the function, try as much as possible to fill in
	 * all the parameters of the function, even the optional ones  
	 * 
	 * @param _f		the original function
	 * @param params	parameters to pre-fill the function with, in the order of declaration of the original method 
	 * @return 			a new function that takes ( _f.length - param.length ) parameters
	 * 
	 */
	public function callback( _f:Function, ...params ):Function
	{
		
		if ( _f.length - params.length > 0 )
			// _first:* = undefined is used so that the function does not appear to take 0 parameter
			return function callbackWithParams( _first : * = undefined, ...rest ):* {
				if ( _first != undefined || rest.length > 0 || params.length < _f.length )
					rest = [_first].concat(rest) ; // cannot use unshift because rest seems to be unmutable, WTF ?
				return _f.apply( this, params.concat(rest) ) ;
			} ;
		else
			return function callbackNoParams():* { return _f.apply( this, params ) ; } ;
		
	}
}