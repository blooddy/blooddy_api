package by.blooddy.api.desktop {
	
	import flash.events.Event;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.events.LocationChangeEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import by.blooddy.api.SoundCloud;
	
	/**
	 * @author					BlooDHounD
	 * @version					1.0
	 * @playerversion			Flash 10
	 * @langversion				3.0
	 */
	public class SoundCloud extends by.blooddy.api.SoundCloud {
		
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
			
			this._username =		parameters[ 'username' ];
			this._password =		parameters[ 'password' ];
			this._redirect_uri =	parameters[ 'redirect_uri' ];
			
			if ( !this._token ) {
				this.auth();
			}
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		private var _username:String;
		private var _password:String;
		private var _redirect_uri:String;
		
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
					
					case 401:
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
		protected override function auth_api(success:Function, fail:Function):void {
			
			var soundcloud:by.blooddy.api.desktop.SoundCloud = this;
			
			setKey( 'token', soundcloud._token = null );
			
			var data:URLVariables = new URLVariables();
			data.client_id = this._client_id;
			data.redirect_uri = this._redirect_uri;
			data.display = 'popup';
			data.response_type = 'code';
			
			var request:URLRequest = new URLRequest();
			request.url = 'https://soundcloud.com/connect';
			request.data = data;
			
			var html:HTMLLoader = new HTMLLoader();
			html.load( request );
			html.addEventListener( HTMLUncaughtScriptExceptionEvent.UNCAUGHT_SCRIPT_EXCEPTION, function(event:Event):void {} );
			html.addEventListener( Event.HTML_DOM_INITIALIZE, function domInitialize(event:Event):void {
				
				if ( html.parent ) html.parent.removeChild( html );
				
				function cancel():void {
					if ( html.parent ) html.parent.removeChild( html );
					html.removeEventListener( Event.HTML_DOM_INITIALIZE, domInitialize );
					html.cancelLoad();
				}
				
				var document:Object = html.window.document;
				
				if ( /^https?:\/\/soundcloud\.com\/connect/.test( html.window.location ) ) {
					
					document.addEventListener( 'DOMContentLoaded', function domLoaded(event:Object):void {
						document.removeEventListener( event.type, domLoaded );
						
						try {
							
							var form:Object = document.querySelector( 'form[action="/connect/return_to_client"]' );
							if ( form ) {
								
								if ( form.querySelector( 'a[href$="/' + soundcloud._username + '"]' ) ) {
									
									document.createElement( 'form' ).submit.call( form );
									
									html.addEventListener( LocationChangeEvent.LOCATION_CHANGING, function locationChanging(event:LocationChangeEvent):void {
										if ( ( new RegExp( '^' + request.data.redirect_uri.replace( /([\/\.])/g, '\\$1' ) ) ).test( event.location ) ) {
											
											html.removeEventListener( LocationChangeEvent.LOCATION_CHANGING, locationChanging );
											
											cancel();
											
											var data:URLVariables = new URLVariables( event.location.replace( /^[^\?]*\?/, '' ) );
											
											soundcloud.query(
												'post.oauth2.token',
												{
													client_secret: soundcloud._secret,
													redirect_uri: request.data.redirect_uri,
													grant_type: 'authorization_code',
													code: data.code
												},
												function(result:Object):void {
													
													setKey( 'token', soundcloud._token = result.access_token );
													
													if ( success ) success();
													
												},
												fail
											);
											
										}
									} );
									
								} else {
									
									html.window.location.replace( document.querySelector( 'a[href^="/connect/logout"]' ).href );
									
								}
								
							} else {
								
								form = document.querySelector( 'form[action="/connect/login"]' );
								form.username.value = soundcloud._username;
								form.password.value = soundcloud._password;
								
								if ( form.querySelector( '#recaptcha_widget_div' ) ) {
									
									soundcloud.accept( html, function(e:Error):void {
										
										if ( fail ) fail( e );
										cancel();
										
									} );
									
								} else {
									
									document.createElement( 'form' ).submit.call( form );
									
								}
								
							}
							
						} catch ( e:Error ) {
							
							if ( fail ) fail( e );
							cancel();
							
						}
						
					} );
					
				} else {
					
					soundcloud.accept( html, function(e:Error):void {
						
						if ( fail ) fail( e );
						cancel();
						
					} );
					
				}
				
			} );
			
		}
		
	}
	
}