package model
{
	public class Media
	{
		
		private var _title:String;
		private var _studio:String;
		private var _subtitle:String;
		private var _sources:Vector.<String>;
		private var _thumb:String;
		private var _imageSmall:String;
		private var _imageBig:String;
		
		public function Media(	title:String,
								studio:String,
								subtitle:String,
								sources:Vector.<String>,
								thumb:String,
								imageSmall:String,
								imageBig:String )
		{
			_title = title;
			_studio = studio;
			_subtitle = subtitle;
			_sources = sources;
			_thumb = thumb;
			_imageSmall = imageSmall;
			_imageBig = imageBig;
		}
		
		public function get title():String { return this._title; }
		public function get studio():String { return this._studio; }
		public function get subtitle():String { return this._subtitle; }
		public function get sources():Vector.<String> { return this._sources.slice(); }
		public function get thumb():String { return this._thumb; }
		public function get imageSmall():String { return this._imageSmall; }
		public function get imageBig():String { return this._imageBig; }
		
	}
}