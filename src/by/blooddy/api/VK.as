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
	public class VK extends API {
		
		//--------------------------------------------------------------------------
		//
		//  Class variables
		//
		//--------------------------------------------------------------------------
		
		private static const API_URL:String = 'https://api.vk.com/';
		
		protected static const VERSION:Number = 5.58;
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Constructor
		 */
		public function VK(parameters:Object) {
			
			super( parameters );
			
			this._api_url =		parameters[ 'api_url' ] || API_URL + 'api.php';
			this._api_id =		parameters[ 'api_id' ];
			
			this._secret =		parameters[ 'secret' ];
			this._sid =			parameters[ 'sid' ];
			
			this._token =		parameters[ 'token' ] || getKey( 'vk_token' );
			
			this._viewer_id =	parameters[ 'viewer_id' ];
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		protected var _api_url:String;
		protected var _api_id:int;
		
		protected var _secret:String;
		protected var _sid:String;
		
		protected var _token:String;
		
		protected var _viewer_id:int;
		
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
			var url:String;
			
			for ( var i:* in params ) {
				data[ i ] = params[ i ];
			}
			
			data.format = 'json';
			data.v = VERSION;
			data.api_id = this._api_id;
			
			if ( this._api_id ) {
				data.client_id = this._api_id;
			}
			if ( this._token ) {
				
				url = API_URL + 'method/' + method;
				data.access_token = this._token;
				
			} else {
				
				url = this._api_url;
				
				if ( this._sid && this._secret ) {
				
					data.method = method;
					
					data.sig = this.signature( data );
					data.sid = this._sid;
					
				}
				
			}
			
			super.query_api( URLRequestMethod.POST, url, data, function(result:Object):void {
				
				if ( result && result.response ) {
					if ( success ) success( result.response );
				} else {
					
					result = result.error;
					
					var e:Error = ( result && typeof result == 'object'
						? new Error( result.error_msg || '', result.error_code || 0 )
						: new Error( result || 'unknown error' )
					);
					
					switch ( e.errorID ) {
						
						case 6:
						case 9:
							setTimeout( query_api, 10e3, URLRequestMethod.POST, url, data, arguments.callee, fail );
							break;
						
						default:
							if ( fail ) fail( e );
							break;
						
					}
					
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
			
			var arr:Array = new Array();
			for ( var i:* in data ) {
				arr.push( i + '=' + data[ i ] );
			}
			arr.sort();
			
			return MD5.hash(
				( this._viewer_id > 0 ? this._viewer_id : '' ) +
				arr.join( '' ) +
				this._secret
			);
			
		}
		
	}
	
}