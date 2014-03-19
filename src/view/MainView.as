package view
{
	import com.ezper.ane.aircast.AirCastMediaStatus;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	
	import controllers.DeviceController;
	import controllers.MediaController;
	import controllers.Page;
	
	import model.Media;
	
	import ui.MediaHolderMC;
	import ui.MediaPlayerMC;
	
	public class MainView extends Page
	{
		
		private var graphic:MediaPlayerMC;

		private var deviceController:DeviceController;

		private var mediaController:MediaController;
		
		public function MainView()
		{
			super();
			
			graphic = new MediaPlayerMC();
			addChild(graphic);
			
			graphic.mediaList.container.removeChildren();
			
			graphic.mediaList.faderBottom.visible = false;
			graphic.mediaList.faderTop.visible = false;
			
			context.registerResumer( refreshState );
			
		}
		
		public function init(deviceController:DeviceController, mediaController:MediaController):void
		{
			
			this.deviceController = deviceController;
			this.mediaController = mediaController;
			
			context.registerEventListener( graphic.castBtn, MouseEvent.CLICK, function(e:Event):void {
				
				if ( deviceController.isConnected )
					deviceController.disconnectFromDevice();
				else
					deviceController.requestDeviceListPopup();
				
			});
			
			context.registerSignal( deviceController.deviceConnected, refreshState );
			context.registerSignal( deviceController.deviceDisconnected, refreshState );
			context.registerSignal( mediaController.mediaLoaded, refreshState );
			context.registerSignal( mediaController.mediaUnloaded, refreshState );
			context.registerSignal( mediaController.mediaStatus, refreshState );
			
			// display media list
			mediaController.mediaList.onSuccess( function(medias:Vector.<Media>):void {
				
				for each ( var media:Media in medias )
				{
					var mediaHolder:MediaHolderMC = new MediaHolderMC();
					
					mediaHolder.gotoAndStop(1);
					
					mediaHolder.title.text = media.title;
					var thumbLoader:Loader = new Loader();
					thumbLoader.load( new URLRequest(Config.MEDIA_BUCKET_URL + media.thumb) );
					var thumbWidth:Number = mediaHolder.thumb.width;
					var thumbHeight:Number = mediaHolder.thumb.height;
					
					context.registerEventListener(thumbLoader.contentLoaderInfo, Event.COMPLETE, function(e:Event):void{
						var content:DisplayObject = (e.target as LoaderInfo).content;
						var scale:Number = Math.min( thumbWidth/content.width, thumbHeight/content.height );
						content.scaleX = content.scaleY = scale;
						content.x = (thumbWidth - content.width) / 2;
						content.y = (thumbHeight - content.height) / 2;
					});
					
					function scope(media):void{
						context.registerEventListener(mediaHolder, MouseEvent.CLICK, function(e:Event):void{
							mediaController.load( media );
						});
					}
					scope(media);
					
					mediaHolder.y = graphic.mediaList.container.height;
					if ( mediaHolder.y > 0 ) mediaHolder.y += 1;
					
					mediaHolder.thumb.container.addChild( thumbLoader );
					graphic.mediaList.container.addChild( mediaHolder );
				}
				
				graphic.mediaList.faderBottom.visible = graphic.mediaList.container.height > graphic.mediaList.faderBottom.y + graphic.mediaList.faderBottom.height;
				
			});
			
			refreshState();
			
		}
		
		private function refreshState():void {
			
			if ( deviceController.isConnected )
			{
				graphic.castBtn.gotoAndStop("casting");
				graphic.connectionStatus.visible = true;
				graphic.connectionStatus.devceName.text = deviceController.connectedDevice.friendlyName;
			}
			else if ( deviceController.isConnecting )
			{
				graphic.castBtn.gotoAndStop("connecting");
				graphic.connectionStatus.visible = false;
			}
			else
			{
				graphic.castBtn.gotoAndStop("off");
				graphic.connectionStatus.visible = false;
			}
			
			if ( deviceController.isConnected && mediaController.currentStatus != null )
			{
				var status:AirCastMediaStatus = mediaController.currentStatus; 
				graphic.volume.visible = true;
				graphic.playback.visible = true;
				graphic.playBtn.visible = status.playerState == AirCastMediaStatus.MEDIA_PLAYER_STATE_PAUSED;
				graphic.pauseBtn.visible = status.playerState == AirCastMediaStatus.MEDIA_PLAYER_STATE_PLAYING;
				
				if ( status.playerState == AirCastMediaStatus.MEDIA_PLAYER_STATE_BUFFERING) {
					graphic.playback.visible = true;
					graphic.playback.gotoAndStop(2);
				}
				else if ( status.playerState == AirCastMediaStatus.MEDIA_PLAYER_STATE_PLAYING || status.playerState == AirCastMediaStatus.MEDIA_PLAYER_STATE_PAUSED ) {
					graphic.playback.visible = true;
					graphic.playback.gotoAndStop(1);
					graphic.playback.fill.scaleX = status.streamPosition / status.mediaInformation.streamDuration;
				}
			}
			else
			{
				graphic.connectionStatus.visible = false;
				graphic.volume.visible = false;
				graphic.playback.visible = false;
				graphic.playback.gotoAndStop(1);
				graphic.playback.fill.scaleX = 0;
				graphic.playBtn.visible = false;
				graphic.pauseBtn.visible = false;
			}
			
		}
		
	}
}