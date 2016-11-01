package example;

import net.kvdb.webdav.WebDAVClient;
import net.kvdb.webdav.io.FileInput;

class Main
{
    static var client : WebDAVClient;
    
    #if js
    static var username : js.html.InputElement;
    static var password : js.html.InputElement;
    static var file : js.html.InputElement;
    static var list : js.html.UListElement;
    #end
    
    public static function main () : Void
    {
        #if js
        username = cast js.Browser.document.getElementById ("username");
        password = cast js.Browser.document.getElementById ("password");
        file = cast js.Browser.document.getElementById ("file");
        list = cast js.Browser.document.getElementById ("list");
        
        file.onchange = function () {
            loadFile (function (input) {
                client.upload (input, input.name);
            });
        };
        #end
        
        
        #if sys
        Sys.println ("Please enter your account details for magentacloud.de");
        Sys.print ("Username: ");
        var user = Sys.stdin ().readLine ();
        Sys.print ("Password: ");
        var password = Sys.stdin ().readLine ();
        #end
        
        client = new WebDAVClient ();
        client.server = "https://magentacloud.de";
        
        client.listComplete = function (files : Array<File>) {
            #if js
            
            #end
            trace (files);
        };
        
        client.list();
        
    }
    
    #if js
    inline static function addToFileList (file : File) : Void
    {
        var li = js.Browser.document.createLIElement ();
        var a = js.Browser.document.createAnchorElement ();
        a.href = file.href;
        a.innerText = file.name;
        
        li.appendChild (a);
        list.appendChild (li);
    }
    
    inline static function clearFileList () : Void
    {
        while (list.lastChild != null) {
            list.removeChild (list.lastChild);
        }
    }
    
    inline static function loadFile (onLoad : FileInput->Void) : Void
    {
        var files = file.files;
        js.Browser.alert (files.length);
        for (file in files) {
            var reader = new js.html.FileReader ();
            reader.onload = function () {
                var ab : js.html.ArrayBuffer = reader.result;
                var bytes = haxe.io.Bytes.ofData (ab);
                var input = new haxe.io.BytesInput (bytes);
                
                var fileinput = new FileInput (input, file.name, file.size);
                onLoad (fileinput);
            };
            reader.readAsArrayBuffer (file);
        }
    }
    #end
}
