package util
{
	
	/**
	 * @author renaudbardet
	 * 
	 * An Either is a utility that tells if the encapsulated object is of two expected cases
	 * 
	 * most common example is error handling
	 * 
	 * Either.Right would mean the content is the expected result
	 * Either.Left would mean the content is the error result
	 * 
	 */	
	public class Either
	{
		
		private var _isRight:Boolean ;
		
		private var _data:* ;
		
		// Do not use this constructor, althought it results in the same, use Either.Right or Either.Left wich are clearer for the reader
		public function Either( data : *, isRight:Boolean=true )
		{
			
			_data = data ;
			_isRight = isRight ;
			
		}
		
		public function isLeft() : Boolean
		{
			return !_isRight ;
		}
		
		public function isRight() : Boolean
		{
			return _isRight ;
		}
		
		public function getRight() : *
		{
			if (!_isRight)
				// throw "getRight on Left object" ;
				return null ;
			
			return _data ;
		}
		
		public function getLeft() : *
		{
			if (_isRight)
				// throw "getLeft on Right object" ;
				return null ;
			
			return _data ;
		}
		
		public static function Right( data : * ) : Either
		{
			return new Either( data, true ) ;
		}
		
		public static function Left( data : * ) : Either
		{
			return new Either( data, false ) ;
		}
		
	}
	
}