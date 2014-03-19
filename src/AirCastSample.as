package
{
	import com.ezper.ane.aircast.AirCast;
	import com.ezper.ane.aircast.AirCastDevice;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import controllers.DeviceController;
	import controllers.MediaController;
	import controllers.ScreenController;
	
	import view.DeviceListPopup;
	import view.MainView;
	
	public class AirCastSample extends Sprite
	{
		
		private var screenController:ScreenController;
		private var deviceController:DeviceController;
		private var mediaController:MediaController;
		
		public function AirCastSample()
		{
			
			super();
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.autoOrients = false;
			stage.color = 0x333333;
			
			var scaleFitX:Number = stage.fullScreenWidth/768;
			var scaleFitY:Number = stage.fullScreenHeight/1024;
			var scale:Number = Math.min(scaleFitX, scaleFitY);
			var fitUIWidth:Number = stage.fullScreenWidth*scaleFitX/scale;
			var fitUIHeight:Number = stage.fullScreenHeight*scaleFitY/scale;
			this.scaleX = this.scaleY = scale;
			Ui.stageWidth = int(stage.fullScreenWidth/scale);
			Ui.stageHeight = int(stage.fullScreenHeight/scale);
			
			var pageLayer:Sprite = new Sprite();
			pageLayer.x = (fitUIWidth - stage.fullScreenWidth)/2;
			pageLayer.y = (fitUIHeight - stage.fullScreenHeight)/2;
			var popupLayer:Sprite = new Sprite();
			addChild(pageLayer);
			addChild(popupLayer);
			
			AirCast.logger = new AirCastTraceLogger();
			AirCast.getInstance().init( Config.APP_ID );
			
			screenController = new ScreenController(pageLayer, popupLayer);
			deviceController = new DeviceController();
			mediaController = new MediaController( deviceController );
			
			start();
			
		}
		
		private function start():void {
			
			var mainView:MainView = screenController.setPage( MainView ) as MainView;
			mainView.init( deviceController, mediaController );
			
			deviceController.deviceListPopupRequested.add( function():void {
				AirCast.getInstance().scan();
				screenController.setPopup( DeviceListPopup, deviceController )
					.onSuccess( function(device:AirCastDevice):void{
						deviceController.connectToDevice( device );
					})
					.onResult( function():void{
						AirCast.getInstance().stopScan();
					});
			});
			
		}
		
	}
}
import com.ezper.ane.aircast.IAirCastLogger;

class AirCastTraceLogger implements IAirCastLogger {
	public function log( ...params ):void
	{
		trace.apply( null, params );
	}
}