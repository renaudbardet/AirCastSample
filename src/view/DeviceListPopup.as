package view
{
	import com.ezper.ane.aircast.AirCast;
	import com.ezper.ane.aircast.AirCastDevice;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import controllers.DeviceController;
	import controllers.Popup;
	
	import ui.DeviceHolderMC;
	import ui.DevicePopupMC;
	
	import util.Context;
	import util.Future;
	import util.TriggerFuture;
	
	public class DeviceListPopup extends Popup
	{

		private var deviceListContext:Context;

		private var graphic:DevicePopupMC;

		private var deviceController:DeviceController;

		private var deviceChosen:TriggerFuture;
		
		public function DeviceListPopup()
		{
			
			super();
			
			graphic = new DevicePopupMC();
			addChild(graphic);
			
			graphic.container.removeChildren();
			
		}
		
		override public function init( ...params ):Future
		{
			
			deviceController = params[0];
			
			deviceChosen = new TriggerFuture();
			
			deviceController.deviceListChanged.add( refreshList );
			
			refreshList( deviceController.deviceList );
			
			return deviceChosen;
			
		}
		
		private function refreshList( deviceList:Vector.<AirCastDevice> ):void
		{
			
			if(deviceListContext) deviceListContext.close();
			deviceListContext = new Context(context);
			
			deviceList.sort( function( d1:AirCastDevice, d2:AirCastDevice ):Number { return d1.friendlyName < d2.friendlyName ? -1 : 1 ; } );
			
			for each ( var device:AirCastDevice in deviceList )
			{
				
				var holder:DeviceHolderMC = new DeviceHolderMC();
				if(deviceController.connectedDevice == device)
					holder.gotoAndStop(2);
				else
					holder.gotoAndStop(1);
				
				holder.deviceName.text = device.friendlyName;
				holder.ip.text = device.ipAddress;
				
				function scope(device:AirCastDevice):void{
					deviceListContext.registerEventListener(holder, MouseEvent.CLICK, function(e:Event):void{
						deviceChosen.complete( device );
					});
				}
				scope(device);
				
				holder.y = graphic.container.height;
				graphic.container.addChild( holder );
				
			}
			
		}
		
	}
}