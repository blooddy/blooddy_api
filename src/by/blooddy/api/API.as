package by.blooddy.api {
	
	import flash.display.Stage;
	import flash.errors.IOError;
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.html.HTMLLoader;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import avmplus.getQualifiedClassName;
	
	import by.blooddy.crypto.MD5;
	import by.blooddy.crypto.serialization.JSONer;
	
	/**
	 * @author					BlooDHounD
	 * @version					1.0
	 * @playerversion			Flash 10
	 * @langversion				3.0
	 */
	public class API {
		
		//--------------------------------------------------------------------------
		//
		//  Class variables
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private static const SO:SharedObject = ( function():SharedObject {
		
			try {
				return SharedObject.getLocal( 'blooddy_api', null, true );
			} catch ( e:Error ) {
				try {
					return SharedObject.getLocal( 'blooddy_api' );
				} catch ( e:Error ) {
					return null;
				}
			}
			
		}() );
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Constructor
		 */
		public function API(parameters:Object) {
			
			super();
			
			this._stage = parameters[ 'stage' ];
			
			this._key = parameters[ 'key' ] || MD5.hash( ( parameters[ 'username' ] || '' ) + '_' + getQualifiedClassName( this ) + '_' + ( parameters[ 'password' ] || '' ) );
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		private var _stage:Stage;
		
		private var _key:String;
		
		private var _queue:Vector.<Queue>;
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		public virtual function query(method:String, params:Object=null, success:Function=null, fail:Function=null):void {
			throw new IllegalOperationError();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Protected methods
		//
		//--------------------------------------------------------------------------
		
		protected function getKey(name:String):* {
			if ( SO ) {
				return SO.data[ this._key + '_' + name ];
			} else {
				return null;
			}
		}
		
		protected function setKey(name:String, value:*):void {
			if ( SO ) {
				SO.data[ this._key + '_' + name ] = value;
				SO.flush();
			}
		}
		
		protected final function query_api(method:String, url:String, data:URLVariables, success:Function, fail:Function=null):void {
			
			var request:URLRequest = new URLRequest();
			request.url = url;
			request.method = method.toUpperCase();
			request.data = data;
			
			var loader:URLLoader = new URLLoader( request );
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			loader.addEventListener( Event.COMPLETE, stateHandle );
			loader.addEventListener( IOErrorEvent.IO_ERROR, stateHandle );
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, stateHandle );
			loader.addEventListener( HTTPStatusEvent.HTTP_STATUS, statusHandle );
			
			var status:int;
			
			function statusHandle(event:HTTPStatusEvent):void {
				status = event.status;
			}
			
			function stateHandle(event:Event):void {
				
				loader.removeEventListener( Event.COMPLETE, stateHandle );
				loader.removeEventListener( IOErrorEvent.IO_ERROR, stateHandle );
				loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, stateHandle );
				loader.removeEventListener( HTTPStatusEvent.HTTP_STATUS, statusHandle );
				
				var result:Object;
				var error:Error;
				
				try {
					
					result = JSONer.parse( loader.data );
					
				} catch ( e:Error ) {
					
					if ( event is ErrorEvent ) {
						
						var ErrorClass:Class;
						switch ( true ) {
							case event is SecurityErrorEvent:	ErrorClass = SecurityError;	break;
							case event is IOErrorEvent:			ErrorClass = IOError;		break;
							default:							ErrorClass = Error;			break;
						}
						
						e = new ErrorClass( ( event as ErrorEvent ).text, status );
						
					}
					
					error = e;
					
				}
				
				if ( error ) {
					if ( fail ) fail( error );
				} else {
					if ( success ) success( result );
				}
				
			}
			
		}
		
		protected final function auth(success:Function=null, fail:Function=null):void {
			
			if ( !this._queue ) {
				
				var api:API = this;
				api._queue = new Vector.<Queue>();
				api.auth_api(
					function():void {
						while ( api._queue.length ) {
							var auth:Queue = api._queue.shift(); 
							if ( auth.success ) auth.success();
						}
						api._queue = null;
					},
					function(e:Error):void {
						while ( api._queue.length ) {
							var auth:Queue = api._queue.shift();
							if ( auth.fail ) auth.fail( e );
						}
						api._queue = null;
					}
				);
				
			}
			
			this._queue.push( new Queue( success, fail ) );
			
		}
		
		protected virtual function auth_api(success:Function, fail:Function):void {
			throw new IllegalOperationError();
		}
		
		protected final function accept(html:HTMLLoader, fail:Function):void {
			
			if ( this._stage ) {
				
				html.width = this._stage.stageWidth;
				html.height = this._stage.stageHeight;
				this._stage.addChild( html );
				
			} else {
				
				if ( fail ) fail( new VerifyError() );
				
			}
			
		}
		
	}
	
}

/**
 * @private
 */
internal final class Queue {
	
	public function Queue(success:Function, fail:Function) {
		this.success = success;
		this.fail = fail;
	}
	
	internal var success:Function;
	internal var fail:Function;
	
}