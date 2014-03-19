package controllers
{
	import com.ezper.ane.aircast.AirCast;
	import com.ezper.ane.aircast.AirCastMediaStatus;
	import com.ezper.ane.aircast.event.AirCastMediaEvent;
	
	import model.Media;
	
	import util.Context;
	import util.Future;
	import util.LoaderFuture;
	import util.Signal;
	import util.f.callback;

	public class MediaController
	{
		
		private var _mediaList:Future;
		
		private var deviceController:DeviceController;
		
		private var _requestedMedia:Media;
		private var _mediaContext:Context;
		
		private var _currentStatus:AirCastMediaStatus;
		
		private var _mediaLoaded:Signal;
		private var _mediaUnloaded:Signal;
		private var _mediaStatus:Signal;
		
		public function MediaController( deviceController:DeviceController )
		{
			
			this.deviceController = deviceController;
			
			_mediaLoaded = new Signal( AirCastMediaStatus, this );
			_mediaUnloaded = new Signal( null, this );
			_mediaStatus = new Signal( AirCastMediaStatus, this );
			
			AirCast.getInstance().addEventListener( AirCastMediaEvent.STATUS_CHANGED, onMediaStatus );
			
			_mediaList = LoaderFuture.load( Config.MEDIA_LIST_URL )
				.onSuccess( callback( trace, "[MediaController]", "received media list" ) )
				.mapTry( JSON.parse )
				.map( createMediaList )
				.onSuccess( callback( trace, "[MediaController]", "media list ready" ) )
				.onError( callback( trace, "[MediaController]" ) );
			
		}

		public function get mediaList():Future { return _mediaList; }
		
		public function get requestedMedia():Media { return this._requestedMedia; }
		
		public function get mediaLoaded():Signal { return _mediaLoaded; }
		public function get mediaUnloaded():Signal { return _mediaUnloaded; }
		public function get mediaStatus():Signal { return _mediaStatus; }
		
		public function get currentStatus():AirCastMediaStatus { return _currentStatus; }
		
		private function get mediaSessionID():int { if(_currentStatus == null) return -1; return _currentStatus.mediaSessionID } 
		
		public function load( media:Media, start:Number = 0, autoPlay:Boolean = true ):void
		{
			if( _mediaContext )
				_mediaContext.close();
			
			_requestedMedia = media;
			_mediaContext = new Context();
			
			var deviceConnected:Future = deviceController.isConnected ? Future.completed() : Future.nextSignal( deviceController.deviceConnected );
			
			_mediaContext.safeFuture( deviceConnected )
				.onSuccess( callback(	AirCast.getInstance().loadMedia,
										media.sources[0],
										media.thumb,
										media.title,
										media.subtitle,
										"video/mp4",
										start,
										autoPlay
									) );
		}
		
		private function onMediaStatus(e:AirCastMediaEvent):void
		{
			_currentStatus = e.status;
			if( e.status != null )
			{
				if( mediaSessionID != e.status.mediaSessionID ) {
					_mediaLoaded.dispatch( e.status, this );
				} else {
					_mediaStatus.dispatch( e.status, this );
				}
			}
			else
			{
				_mediaUnloaded.dispatch( null, this );
			}
		}
		
		private static function createMediaList( data:Object ):Vector.<Media>
		{
			
			var medias:Vector.<Media> = new Vector.<Media>();
			
			for each ( var category:Object in data.categories as Array )
			{
				if ( category.name == "Movies" )
				{
					for each ( var video:Object in category.videos )
					{
						medias.push( new Media(
							video.title,
							video.studio,
							video.subtitle,
							Vector.<String>(video.sources as Array),
							video.thumb,
							video["image-480x270"],
							video["image-780-1200"]
						));
					}
				}
			}
			
			return medias;
			
		}
	}
}