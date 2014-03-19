package util.f{
	/**
	 * 
	 * create a reflexive function over any data
	 * 
	 * @param _ret	the data to encapsulate
	 * @return 		a function that once called will return the data encapsulated
	 * 
	 */
	public function identity( _ret : * ) : Function
	{
		
		return function() : * { return _ret ; } ;
		
	}
}

