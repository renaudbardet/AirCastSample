package util
{

	public class Option
	{
		
		private var _isNone:Boolean;
		
		private var _data:*;
		
		// Do not use this constructor, you wouldn't be able to do anything with the object anyway
		public function Option() {}
		
		public function get isNone():Boolean { return _isNone; }
		
		public function get value() : *
		{
			if (_isNone)
				// throw "getValue on None option" ;
				return null;
			
			return _data;
		}
		
		public function valueOr( defaultValue:* ) : *
		{
			if (_isNone)
				return defaultValue;
			return _data;
		}
		
		public function map( f:Function ):Option
		{
			if(_isNone) return this;
			return Some(f(_data));
		}
		
		public static function Some( data : * ) : Option
		{
			var o:Option = new Option();
			o._data = data;
			return o;
		}
		
		public static const None:Option = createNone();
		private static function createNone():Option {
			var o:Option = new Option();
			o._isNone = true;
			return o;
		}
		
	}
}