package controllers
{
	import com.ezper.ane.aircast.AirCast;
	import com.ezper.ane.aircast.AirCastDevice;
	import com.ezper.ane.aircast.event.AirCastDeviceEvent;
	import com.ezper.ane.aircast.event.AirCastDeviceListEvent;
	
	import util.Signal;

	public class DeviceController
	{
		
		private var _deviceListPopupRequested:Signal;
		private var _deviceList:Vector.<AirCastDevice>;
		private var _deviceListChanged:Signal;
		private var _deviceConnected:Signal;
		private var _deviceDisconnected:Signal;
		private var _connecting:Boolean;
		
		public function DeviceController()
		{
			
			_deviceListPopupRequested = new Signal(null, this);
			_deviceList = new Vector.<AirCastDevice>();
			_deviceListChanged = new Signal( Vector.<AirCastDevice>, this );
			_deviceConnected = new Signal(AirCastDevice, this);
			_deviceDisconnected = new Signal(AirCastDevice, this);
			
			AirCast.getInstance().addEventListener(
				AirCastDeviceListEvent.DEVICE_LIST_CHANGED,
				function(e:AirCastDeviceListEvent):void {
					consolidateDeviceList(e.deviceList);
					_deviceListChanged.dispatch( _deviceList, this );
				}
			);
			
			AirCast.getInstance().addEventListener(
				AirCastDeviceEvent.DID_CONNECT_TO_DEVICE,
				function(e:AirCastDeviceEvent):void {
					_connecting = false;
					_deviceConnected.dispatch( e.device, this );
				}
			);
			
			AirCast.getInstance().addEventListener(
				AirCastDeviceEvent.DID_DISCONNECT,
				function(e:AirCastDeviceEvent):void {
					_connecting = false;
					_deviceDisconnected.dispatch( e.device, this );
				}
			);
			
		}
		
		public function get deviceListPopupRequested():Signal { return this._deviceListPopupRequested; }
		public function get deviceList():Vector.<AirCastDevice> { return this._deviceList; }
		public function get deviceListChanged():Signal { return this._deviceListChanged; }
		public function get deviceConnected():Signal { return _deviceConnected; }
		public function get deviceDisconnected():Signal { return _deviceDisconnected; }
		public function get connectedDevice():AirCastDevice { return AirCast.getInstance().connectedDevice; }
		public function get isConnected():Boolean { return connectedDevice != null; }
		public function get isConnecting():Boolean { return _connecting; }
		
		public function requestDeviceListPopup():void {
			
			_deviceListPopupRequested.dispatch(null, this);
			
		}
		
		public function disconnectFromDevice():void {
			
			_connecting = false;
			AirCast.getInstance().disconnectFromDevice();
			
		}
		
		public function connectToDevice(device:AirCastDevice):void {
			
			if( device == connectedDevice ) return;
			_connecting = AirCast.getInstance().connectToDevice( device.deviceID );
			
		}
		
		private function consolidateDeviceList(newList:Vector.<AirCastDevice>):void
		{
			for each ( var newDevice:AirCastDevice in newList )
			{
				var known:Boolean = false;
				for each ( var knownDevice:AirCastDevice in _deviceList )
				{
					if ( newDevice.deviceID == knownDevice.deviceID )
					{
						known = true;
						break;
					}
				}
				if(!known)
					_deviceList.push( newDevice );
			}
			
			for each ( knownDevice in _deviceList.slice() )
			{
				var present:Boolean = false;
				for each ( newDevice in newList )
				{
					if ( newDevice.deviceID == knownDevice.deviceID )
					{
						present = true;
						break;
					}
				}
				if(!present)
					_deviceList.splice( _deviceList.indexOf(knownDevice), 1 );
			}
		}
		
	}
}