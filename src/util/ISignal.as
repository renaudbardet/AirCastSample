package util
{
	public interface ISignal
	{
		function add( listener:Function, once:Boolean=false ):void;
		function map( listener:Function ):ISignal;
		function remove( listener:Function ):Boolean;
		function removeAll():void;
		function hasListener( listener:Function ):Boolean;
	}
}