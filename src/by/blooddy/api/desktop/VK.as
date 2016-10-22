package by.blooddy.api.desktop {
	
	import flash.events.Event;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import by.blooddy.api.VK;
	
	/**
	 * @author					BlooDHounD
	 * @version					1.0
	 * @playerversion			Flash 10
	 * @langversion				3.0
	 */
	public class VK extends by.blooddy.api.VK {
		
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
			
			this._scope =		parameters[ 'scope' ];
			this._username =	parameters[ 'username' ];
			this._password =	parameters[ 'password' ];
			
			if ( !this._token ) {
				super.auth();
			}
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		private var _scope:String;
		private var _username:String;
		private var _password:String;
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public override function query(method:String, params:Object=null, success:Function=null, fail:Function=null):void {
			
			var auth:Function = super.auth;
			var query:Function = super.query;
			
			super.query( method, params, success, function(e:Error):void {
				switch ( e.errorID ) {
					
					case 4:
					case 5:
					case 10:
						auth( function():void {
							query( method, params, success, fail );
						}, fail );
						break;
						
					default:
						if ( fail ) fail( e );
						break;
					
				}
			} );
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Protected methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		protected override function query_auth(success:Function, fail:Function):void {
			
			var vk:by.blooddy.api.desktop.VK = this;
			
			setKey( 'token', vk._token = null );
			
			var data:URLVariables = new URLVariables();
			data.v = VERSION;
			data.client_id = this._api_id;
			data.redirect_uri = 'https://oauth.vk.com/blank.html';
			data.display = 'mobile';
			data.response_type = 'token';
			data.scope = ( this._scope ? this._scope + ',' : '' ) + 'email';
			
			var request:URLRequest = new URLRequest();
			request.url = 'https://oauth.vk.com/authorize';
			request.data = data;
			
			var html:HTMLLoader = new HTMLLoader();
			html.load( request );
			html.addEventListener( HTMLUncaughtScriptExceptionEvent.UNCAUGHT_SCRIPT_EXCEPTION, function(event:Event):void {} );
			html.addEventListener( Event.HTML_DOM_INITIALIZE, function domInitialize(event:Event):void {
				
				if ( html.parent ) html.parent.removeChild( html );
				
				function cancel():void {
					html.removeEventListener( Event.HTML_DOM_INITIALIZE, domInitialize );
					html.cancelLoad();
				}
				
				var document:Object = html.window.document;
				
				if ( /^https?:\/\/oauth\.vk\.com\/(oauth\/)?authorize/.test( html.window.location ) ) {
					
					document.addEventListener( 'DOMContentLoaded', function domLoaded(event:Object):void {
						document.removeEventListener( 'DOMContentLoaded', domLoaded );
						
						try {
							
							var form:Object = document.querySelector( 'form[action*="://login.vk.com"]' );
							if ( form.email ) form.email.value = vk._username;
							if ( form.pass ) form.pass.value = vk._password;
							document.createElement( 'form' ).submit.call( form );
							
						} catch ( e:Error ) {
							
							if ( fail ) fail( e );
							cancel();
							
						}
						
					} );
					
				} else if ( ( new RegExp( '^' + request.data.redirect_uri.replace( /([\/\.])/g, '\\$1' ) ) ).test( html.window.location ) ) {
					
					cancel();
					
					try {
						
						var vars:URLVariables = new URLVariables(
							html.window.location.hash.replace( /^#?/, '' )
						);
						
						if ( vars.email.toLowerCase() == vk._username.toLowerCase() ) {
						
							if ( !vars.access_token ) throw new VerifyError( 'unknown token' );
							
							setKey( 'token', vk._token = vars.access_token );
							
							if ( success ) success();
							
						} else {
							
							data.revoke = 1;
							
							html.window.location.replace( request.url + '?' + data.toString() );
							
							html.addEventListener( Event.HTML_DOM_INITIALIZE, function domInitializeLogout(event:Event):void {
								html.removeEventListener( Event.HTML_DOM_INITIALIZE, domInitializeLogout );
								
								var document:Object = html.window.document;
								
								document.addEventListener( 'DOMContentLoaded', function domLoaded(event:Object):void {
									document.removeEventListener( 'DOMContentLoaded', domLoaded );
									
									html.addEventListener( Event.HTML_DOM_INITIALIZE, domInitialize );
									
									try {
										
										html.window.location.replace( document.querySelector( 'a[href^="/logout"]' ).href );
										
									} catch ( e:Error ) {
										
										if ( fail ) fail( e );
										cancel();
										
									}
									
								} );
								
							} );
							
						}
						
					} catch ( e:Error ) {
						
						if ( fail ) fail( e );
						
					}
					
				} else {
					
					vk.accept( html, function(e:Error):void {
						if ( fail ) fail( e );
						cancel();
					} );
					
				}
				
			} );
		}
		
	}
	
}