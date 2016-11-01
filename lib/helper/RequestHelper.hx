/*
 * Copyright (C)2005-2013 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
 
 package helper;
 
 import haxe.Http;
 
 #if sys

 import sys.net.Host;

 private typedef AbstractSocket = {
 	var input(default,null) : haxe.io.Input;
 	var output(default,null) : haxe.io.Output;
 	function connect( host : Host, port : Int ) : Void;
 	function setTimeout( t : Float ) : Void;
 	function write( str : String ) : Void;
 	function close() : Void;
 	function shutdown( read : Bool, write : Bool ) : Void;
 	#if hxssl
 	function setCertLocation( file : String, folder : String ) : Void;
 	#end
 }

 #end
 
 class RequestHelper
 {
    /**
     * Copy of Http.request, but with a String argument for method
     */
    @:access(haxe.Http)
    public static function request2 (request : Http, post : Bool, method : String) : Void
    {
        var me = request;
 	#if js
        me.responseData = null;
        var r = js.Browser.createXMLHttpRequest();
        var onreadystatechange = function(_) {
            if( r.readyState != 4 )
                return;
            var s = try r.status catch( e : Dynamic ) null;
 			if( s == untyped __js__("undefined") )
 				s = null;
 			if( s != null )
 				me.onStatus(s);
 			if( s != null && s >= 200 && s < 400 )
 				me.onData(me.responseData = r.responseText);
 			else if ( s == null )
 				me.onError("Failed to connect or resolve host")
 			else switch( s ) {
 			case 12029:
 				me.onError("Failed to connect to host");
 			case 12007:
 				me.onError("Unknown host");
 			default:
 				me.responseData = r.responseText;
 				me.onError("Http Error #"+r.status);
 			}
 		};
 		if( me.async )
 			r.onreadystatechange = onreadystatechange;
 		var uri = me.postData;
 		if( uri != null )
 			post = true;
 		else for( p in me.params.keys() ) {
 			if( uri == null )
 				uri = "";
 			else
 				uri += "&";
 			uri += StringTools.urlEncode(p)+"="+StringTools.urlEncode(me.params.get(p));
 		}
 		try {
 			if( post )
 				r.open(method,me.url,me.async);
 			else if( uri != null ) {
 				var question = me.url.split("?").length <= 1;
 				r.open(method,me.url+(if( question ) "?" else "&")+uri,me.async);
 				uri = null;
 			} else
 				r.open(method,me.url,me.async);
 		} catch( e : Dynamic ) {
 			me.onError(e.toString());
 			return;
 		}
 		if( me.headers.get("Content-Type") == null && post && me.postData == null )
 			r.setRequestHeader("Content-Type","application/x-www-form-urlencoded");

 		for( h in me.headers.keys() )
 			r.setRequestHeader(h,me.headers.get(h));
 		r.send(uri);
 		if( !me.async )
 			onreadystatechange(null);
 	#elseif flash9
 		me.responseData = null;
 		var loader = new flash.net.URLLoader();
 		loader.addEventListener( "complete", function(e) {
 			me.responseData = loader.data;
 			me.onData( loader.data );
 		});
 		loader.addEventListener( "httpStatus", function(e:flash.events.HTTPStatusEvent){
 			// on Firefox 1.5, Flash calls onHTTPStatus with 0 (!??)
 			if( e.status != 0 )
 				me.onStatus( e.status );
 		});
 		loader.addEventListener( "ioError", function(e:flash.events.IOErrorEvent) {
 			me.responseData = loader.data;
 			me.onError(e.text);
 		});
 		loader.addEventListener( "securityError", function(e:flash.events.SecurityErrorEvent){
 			me.onError(e.text);
 		});

 		// headers
 		var param = false;
 		var vars = new flash.net.URLVariables();
 		for( k in params.keys() ){
 			param = true;
 			Reflect.setField(vars,k,params.get(k));
 		}
 		var small_url = url;
 		if( param && !post ){
 			var k = url.split("?");
 			if( k.length > 1 ) {
 				small_url = k.shift();
 				vars.decode(k.join("?"));
 			}
 		}
 		// Bug in flash player 9 ???
 		var bug = small_url.split("xxx");

 		var request = new flash.net.URLRequest( small_url );
 		for( k in headers.keys() )
 			request.requestHeaders.push( new flash.net.URLRequestHeader(k,headers.get(k)) );

 		if( me.postData != null )
 			request.data = postData;
 		else
 			request.data = vars;
        
        request.method = method;

 		try {
 			loader.load( request );
 		}catch( e : Dynamic ){
 			onError("Exception: "+Std.string(e));
 		}
 	#elseif flash
 		me.responseData = null;
 		var r = new flash.LoadVars();
 		// on Firefox 1.5, onData is not called if host/port invalid (!)
 		r.onData = function(data) {
 			if( data == null ) {
 				me.onError("Failed to retrieve url");
 				return;
 			}
 			me.responseData = data;
 			me.onData(data);
 		};
 		#if flash8
 		r.onHTTPStatus = function(status) {
 			// on Firefox 1.5, Flash calls onHTTPStatus with 0 (!??)
 			if( status != 0 )
 				me.onStatus(status);
 		};
 		untyped ASSetPropFlags(r,"onHTTPStatus",7);
 		#end
 		untyped ASSetPropFlags(r,"onData",7);
 		for( h in headers.keys() )
 			r.addRequestHeader(h,headers.get(h));
 		var param = false;
 		for( p in params.keys() ) {
 			param = true;
 			Reflect.setField(r,p,params.get(p));
 		}
 		var small_url = url;
 		if( param && !post ) {
 			var k = url.split("?");
 			if( k.length > 1 ) {
 				small_url = k.shift();
 				r.decode(k.join("?"));
 			}
 		}
 		if( !r.sendAndLoad(small_url,r,if( param ) method else null) )
 			onError("Failed to initialize Connection");
 	#elseif sys
 		var me = request;
 		var output = new haxe.io.BytesOutput();
 		var old = me.onError;
 		var err = false;
 		me.onError = function(e) {
 			#if neko
 			me.responseData = neko.Lib.stringReference(output.getBytes());
 			#else
 			me.responseData = output.getBytes().toString();
 			#end
 			err = true;
 			old(e);
 		}
 		me.customRequest(post,output);
 		if( !err )
 		#if neko
 			me.onData(me.responseData = neko.Lib.stringReference(output.getBytes()));
 		#else
 			me.onData(me.responseData = output.getBytes().toString());
 		#end
 	#end
 	}
    
    #if sys
    @:access(haxe.Http)
    public static function uploadRequest (me : Http, post : Bool, api : haxe.io.Output, ?sock : AbstractSocket, ?method : String)
    {
		me.responseData = null;
		var url_regexp = ~/^(https?:\/\/)?([a-zA-Z\.0-9-]+)(:[0-9]+)?(.*)$/;
		if( !url_regexp.match(me.url) ) {
			me.onError("Invalid URL");
			return;
		}
		var secure = (url_regexp.matched(1) == "https://");
		if( sock == null ) {
			if( secure ) {
				#if php
				sock = new php.net.SslSocket();
				#elseif hxssl
				sock = new sys.ssl.Socket();
				sock.setCertLocation( me.certFile, me.certFolder );
				#else
				throw "Https is only supported with -lib ssl";
				#end
			} else {
				#if hxssl
				sock = new sys.ssl.Socket();
				#else
				sock = new sys.net.Socket();
				#end
			}
		}
		var host = url_regexp.matched(2);
		var portString = url_regexp.matched(3);
		var request = url_regexp.matched(4);
		if( request == "" )
			request = "/";
		var port = if ( portString == null || portString == "" ) secure ? 443 : 80 else Std.parseInt(portString.substr(1, portString.length - 1));
		var data;

		var multipart = (me.file != null);
		var uri = null;
		for( p in me.params.keys() ) {
			if( uri == null )
				uri = "";
			else
				uri += "&";
			uri += StringTools.urlEncode(p)+"="+StringTools.urlEncode(me.params.get(p));
		}

		var b = new StringBuf();
		if( method != null ) {
			b.add(method);
			b.add(" ");
		} else if( post )
			b.add("POST ");
		else
			b.add("GET ");

		if( Http.PROXY != null ) {
			b.add("http://");
			b.add(host);
			if( port != 80 ) {
				b.add(":");
				b.add(port);
			}
		}
		b.add(request);

		if( !post && uri != null ) {
			if( request.indexOf("?",0) >= 0 )
				b.add("&");
			else
				b.add("?");
			b.add(uri);
		}
		b.add(" HTTP/1.1\r\nHost: "+host+"\r\n");
		if( multipart )
			b.add("Content-Length: "+me.file.size+"\r\n");
		else if( post && uri != null ) {
			if( multipart || me.headers.get("Content-Type") == null ) {
				b.add("Content-Type: ");
				b.add("application/x-www-form-urlencoded");
				b.add("\r\n");
			}
			b.add("Content-Length: "+uri.length+"\r\n");
		}
		for( h in me.headers.keys() ) {
			b.add(h);
			b.add(": ");
			b.add(me.headers.get(h));
			b.add("\r\n");
		}
		b.add("\r\n");
		if( !multipart && post && uri != null )
			b.add(uri);
		try {
			if( Http.PROXY != null )
				sock.connect(new Host(Http.PROXY.host),Http.PROXY.port);
			else
				sock.connect(new Host(host),port);
			sock.write(b.toString());
            if( multipart ) {
				var bufsize = 4096;
				var buf = haxe.io.Bytes.alloc(bufsize);
				while( me.file.size > 0 ) {
					var size = if( me.file.size > bufsize ) bufsize else me.file.size;
					var len = 0;
					try {
						len = me.file.io.readBytes(buf,0,size);
					} catch( e : haxe.io.Eof ) break;
					sock.output.writeFullBytes(buf,0,len);
					me.file.size -= len;
				}
            }
			me.readHttpResponse(api,sock);
			sock.close();
		} catch( e : Dynamic ) {
			try sock.close() catch( e : Dynamic ) { };
			me.onError(Std.string(e));
		}
	}
    #end
}
