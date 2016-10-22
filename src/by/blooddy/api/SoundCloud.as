package by.blooddy.api {
	
	import flash.errors.IOError;
	import flash.net.URLVariables;
	import flash.utils.setTimeout;
	
	/**
	 * @author					BlooDHounD
	 * @version					1.0
	 * @playerversion			Flash 10
	 * @langversion				3.0
	 */
	public class SoundCloud extends API {
		
		//--------------------------------------------------------------------------
		//
		//  Class variables
		//
		//--------------------------------------------------------------------------
		
		private static const API_URL:String = 'https://api.soundcloud.com/';
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Constructor
		 */
		public function SoundCloud(parameters:Object) {
			
			super( parameters );
			
			this._client_id =	parameters[ 'client_id' ];
			this._secret =		parameters[ 'secret' ];
			
			this._token =		parameters[ 'token' ] || getKey( 'token' );
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		protected var _client_id:String;
		protected var _secret:String;
		
		protected var _token:String;
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public override function query(method:String, params:Object=null, success:Function=null, fail:Function=null):void {
			
			var query_api:Function = super.query_api;
			
			var args:Array = method.split( '.' );
			
			var data:URLVariables = new URLVariables();
			
			for ( var i:* in params ) {
				data[ i ] = params[ i ];
			}
			
			data.client_id = this._client_id;
			if ( this._token ) {
				data.oauth_token = this._token;
			}
			
			var query_method:String = args.shift();
			var query_url:String = API_URL + args.join( '/' );
			
			super.query_api( query_method, query_url, data, function(result:Object):void {
				
				if ( !result || result.errors ) {
					
					result = typeof result.errors == 'object' ? result.errors[ 0 ] : result.errors;
					
					var e:Error = ( result && typeof result == 'object'
						? new Error( result.error_message, parseInt( result.error_message ) )
						: new Error( result || 'unknown error' )
					);
					
					switch ( e.errorID ) {
						
						case 429:
							setTimeout( query_api, 10e3, query_method, query_url, data, arguments.callee, fail );
							break;
						
						default:
							if ( fail ) fail( e );
							break;
						
					}
					
				} else {
					if ( success ) success( result );
				}
				
			}, fail );
			
		}
		
	}
	
}