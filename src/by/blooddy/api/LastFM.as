package by.blooddy.api {
	
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.setTimeout;
	
	import by.blooddy.crypto.MD5;
	
	/**
	 * @author					BlooDHounD
	 * @version					1.0
	 * @playerversion			Flash 10
	 * @langversion				3.0
	 */
	public class LastFM extends API {
		
		//--------------------------------------------------------------------------
		//
		//  Class variables
		//
		//--------------------------------------------------------------------------
		
		private static const API_URL:String = 'http://ws.audioscrobbler.com/2.0/';
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Constructor
		 */
		public function LastFM(parameters:Object) {
			
			super( parameters );
			
			this._api_key =	parameters[ 'api_key' ];
			this._secret =	parameters[ 'secret' ];
			
			this._token =	parameters[ 'token' ] ||	getKey( 'token' );
			this._sk =		parameters[ 'sk' ] ||		getKey( 'sk' );
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		protected var _api_key:String;
		protected var _secret:String;
		
		protected var _token:String;
		protected var _sk:String;
		
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
			
			var data:URLVariables = new URLVariables();
			
			for ( var i:* in params ) {
				data[ i ] = params[ i ];
			}
			
			data.method = method;
			data.api_key = this._api_key;
			
			if ( this._token ) {
				data.token = this._token;
			}
			if ( this._sk ) {
				data.sk = this._sk;
			}
			if ( this._secret ) {
				data.api_sig = this.signature( data );
			}
			
			data.format = 'json';
			
			super.query_api( URLRequestMethod.POST, API_URL, data, function(result:Object):void {
				
				if ( !result || result.error ) {
					
					if ( typeof result.error == 'object' ) {
						result = result.error;
					}
					
					var e:Error = ( result && typeof result == 'object'
						? new Error( result.message, result.error )
						: new Error( result || 'unknown error' )
					);
					
					switch ( e.errorID ) {
						
						case 8:
						case 11:
						case 16:
						case 29:
							setTimeout( query_api, 10e3, URLRequestMethod.POST, API_URL, data, arguments.callee, fail );
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
		
		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function signature(data:URLVariables):String {
			
			var i:*;
			
			var keys:Array = new Array();
			for ( i in data ) {
				keys.push( i );
			}
			keys.sort();
			
			var	arr:Array = new Array();
			for each ( i in keys ) {
				arr.push( i, data[ i ] );
			}
			
			return MD5.hash( arr.join( '' ) + this._secret );
			
		}
		
	}
	
}