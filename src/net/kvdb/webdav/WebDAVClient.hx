package net.kvdb.webdav;

import net.kvdb.webdav.io.FileOutput;
import net.kvdb.webdav.io.FileInput;
import net.kvdb.webdav.io.CallbackOutput;
import haxe.io.Output;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;

using helper.StringHelper;
using helper.XmlHelper;
using StringTools;

typedef File = {
    var name : String;
    var href : String;
    @:optional var size : Float;
}

class WebDAVClient
{
    public var listComplete : Array<File>->Void;
    public var uploadComplete : Void->Void;
    public var downloadComplete : Void->Void;
    public var createDirComplete : Void->Void;
    public var deleteComplete : Void->Void;
    public var onDownloadProgress : Int->Void;
    public var onError : Int->String->Void;
    
    public var server (default, set) : String;
    public var basePath (default, set) = "/";
    public var port : Int = -1;
    public var user : String;
    public var password : String;
    
    inline function set_server (s : String) : String
    {
        return server = s.trimEnd ("/");
    }
    
    inline function set_basePath (s : String) : String
    {
        if (s == "/")
            return basePath = s;
        
        return basePath = "/" + s.trim2 ("/") + "/";
    }
    
    public function new ()
    {
    }
    
    function getCompletePath (path : String, appendTrailingSlash : Bool) : String
    {
        var completePath = basePath;
        if (path != null) {
            completePath += path.trim2 ("/");
        }
        
        if (appendTrailingSlash && !completePath.endsWith ("/")) {
            completePath += "/";
        }
        
        return completePath;
    }
    
    function getServerUrl (path : String, appendTrailingSlash : Bool) : String
    {
        var completePath = getCompletePath (path, appendTrailingSlash);
        
        if (port != -1) {
            return server + ":" + port + completePath;
        }
        else {
            return server + completePath;
        }
    }
    
    public function list (path : String = "/", depth = 1) : Void
    {
        if (path == null || path == "")
            throw "path cannot be " + path;
        if (depth < 1)
            throw "depth cannot be smaller than 1";
        
        var listUrl = getServerUrl (path, true);
        
        // http://webdav.org/specs/rfc4918.html#METHOD_PROPFIND
        var propfind = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\r\n";
        propfind += "<propfind xmlns=\"DAV:\">\r\n";
        propfind += "  <allprop/>\r\n";
        propfind += "</propfind>";
        
        var headers = new Map<String, String> ();
        headers.set ("Depth", Std.string (depth));
        
        var output = new CallbackOutput (function (bytes : Bytes) {
            var xml = Xml.parse (bytes.toString ());
            
            var elements = xml.getElementsByTagNameWithoutNS ("response");
            var completePath = getCompletePath (path, true);
            
            var files = new Array<File> ();
            for (element in elements) {
                var size = element.getElementsByTagNameWithoutNS ("getcontentlength");
                var href = element.getElementsByTagNameWithoutNS ("href")[0].getInnerXml ();
                var name = href.substr (completePath.length).urlDecode ().trimStart ("/");
                
                if (name != "") {
                    var file : File = {
                        name: name,
                        href: href,
                    };
                    
                    if (size.length > 0) {
                        file.size = Std.parseFloat (size[0].getInnerXml ());
                    }
                    
                    files.push (file);
                }
            }
            
            if (listComplete != null)
                listComplete (files);
        });
        
        httpRequest (listUrl, "PROPFIND", headers, propfind, null, output);
    }
    
    public function upload (localFile : FileInput, remoteFile : String) : Void
    {
        if (remoteFile == null || remoteFile == "")
            throw "remoteFile cannot be " + remoteFile;
        if (localFile == null)
            throw "localFile cannot be null";
            
        var uploadUrl = getServerUrl (remoteFile, false);
        
        var output = new CallbackOutput (function (bytes : Bytes) {
            if (uploadComplete != null)
                uploadComplete ();
        });
        
        httpRequest (uploadUrl, "PUT", null, null, localFile, output);
    }
    
    public function download (remoteFile : String, localFile : Output) : Void
    {
        if (remoteFile == null || remoteFile == "")
            throw "remoteFile cannot be " + remoteFile;
        if (localFile == null)
            throw "localFile cannot be null";
        
        var downloadUrl = getServerUrl (remoteFile, false);
        
        var file = new FileOutput (localFile);
        file.onProgress = function (progress : Int) {
            if (onDownloadProgress != null)
                onDownloadProgress (progress);
        };
        file.onClose = function () {
            if (downloadComplete != null)
                downloadComplete ();
        };
        
        httpRequest (downloadUrl, "GET", null, null, null, file);
    }
    
    public function createDir (remotePath : String) : Void
    {
        var url = getServerUrl (remotePath, false);
        
        var output = new CallbackOutput (function (bytes : Bytes) {
            if (createDirComplete != null)
                createDirComplete ();
        });
        
        httpRequest (url, "MKCOL", null, null, null, output);
    }
    
    public function delete (remotePath : String) : Void
    {
        var url = getServerUrl (remotePath, remotePath.endsWith ("/"));
        
        var output = new CallbackOutput (function (bytes : Bytes) {
            if (deleteComplete != null)
                deleteComplete ();
        });
        
        httpRequest (url, "DELETE", null, null, null, output);
    }
    
    function httpRequest (url : String, method : String, headers : Map<String, String>, content : String, file : FileInput, output : Output) : Void
    {
        var request = new request.Http (url);
        //var output = new BytesOutput ();
        
        //set headers
        if (headers != null) {
            for (key in headers.keys ()) {
                request.setHeader (key, headers[key]);
            }
        }
        //authentication
        if (user != null && password != null) {
            request.setHeader ("Authorization", "Basic " + StringHelper.encodeCredentials (user, password));
        }
        
        //content or file upload
        if (content != null) {
            //request.setHeader ("Content-Length", Std.string (content.length)); //done by setPostData
            request.setHeader ("Content-Type", "application/xml");
            request.setPostData (content);
        }
        else if (file != null) {
            #if sys
            request.fileTransfert ("file", file.name, file.input, file.size);
            #else
            request.setPostData (file.input.readAll ().toString ());
            #end
        }
        
        var status : Int;
        var retry = false;
        
        request.onStatus = function (s : Int) {
            status = s;
            
            #if sys
            if (status == 301) {
                url = request.responseHeaders.get ("Location");
                //try again with new url
                httpRequest (url, method, headers, content, file, new CallbackOutput (null)); //FIXME: cannot reuse output, because it is closed
                retry = true;
            }
            #end
        };
        
        request.onError = function (msg : String) {
            if (onError != null)
                onError (status, msg);
        };
        
        #if sys
        if (file != null)
            request.uploadRequest (true, output, #if debug new test.TraceSocket () #else null #end, method);
        else
            request.customRequest (true, output, #if debug new test.TraceSocket () #else null #end, method);
        #else
        //FIXME: this needs to be finished
        request.onData = function (data : String) {
            output.writeString (data);
        }
        
        request.request2 (true, method);
        #end
        
        if (file != null && !retry)
            file.input.close ();
    }
}
