package by.blooddy.api {
	
	import flash.display.Stage;
	import flash.errors.IOError;
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
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
		private static const SO:Object = ( function():Object {
		
			try {
				return SharedObject.getLocal( 'blooddy_api', null, true ).data;
			} catch ( e:Error ) {
				try {
					return SharedObject.getLocal( 'blooddy_api' ).data;
				} catch ( e:Error ) {
					return {};
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
		
		private var _auth_queue:Vector.<Auth>;
		
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
			return SO[ this._key + '_' + name ];
		}
		
		protected function setKey(name:String, value:*):void {
			SO[ this._key + '_' + name ] = value;
		}
		
		protected final function query_api(method:String, url:String, data:URLVariables, success:Function, fail:Function=null):void {
			
			var request:URLRequest = new URLRequest();
			request.url = url;
			request.method = method.toUpperCase();
			request.data = data;
			
			var loader:URLLoader = new URLLoader( request );
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			loader.addEventListener( Event.COMPLETE, handler );
			loader.addEventListener( IOErrorEvent.IO_ERROR, handler );
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, handler );
			
			function handler(event:Event):void {
				
				loader.removeEventListener( Event.COMPLETE, handler );
				loader.removeEventListener( IOErrorEvent.IO_ERROR, handler );
				loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, handler );
				
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
						
						e = new ErrorClass( ( event as ErrorEvent ).text, ( event as ErrorEvent ).errorID );
						
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
			
			if ( !this._auth_queue ) {
				
				var api:API = this;
				api._auth_queue = new Vector.<Auth>();
				api.query_auth(
					function():void {
						while ( api._auth_queue.length ) {
							var auth:Auth = api._auth_queue.shift(); 
							if ( auth.success ) auth.success();
						}
						api._auth_queue = null;
					},
					function(e:Error):void {
						while ( api._auth_queue.length ) {
							var auth:Auth = api._auth_queue.shift();
							if ( auth.fail ) auth.fail( e );
						}
						api._auth_queue = null;
					}
				);
				
			}
			
			this._auth_queue.push( new Auth( success, fail ) );
			
		}
		
		protected virtual function query_auth(success:Function, fail:Function):void {
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
internal final class Auth {
	
	public function Auth(success:Function, fail:Function) {
		this.success = success;
		this.fail = fail;
	}
	
	internal var success:Function;
	internal var fail:Function;
	
}