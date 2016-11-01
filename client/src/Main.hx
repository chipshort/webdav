package;

import net.kvdb.webdav.WebDAVClient;
import net.kvdb.webdav.io.FileInput;
import net.kvdb.webdav.io.FileOutput;

class Main
{
    static inline var URL_OPT = "-url";
    static inline var USER_OPT = "-user";
    static inline var PASS_OPT = "-pass";
    static inline var REMOTE_OPT = "-remote";
    static inline var LOCAL_OPT = "-local";
    
    static inline var LIST_CMD = "list";
    static inline var UPLOAD_CMD = "upload";
    static inline var DOWNLOAD_CMD = "download";
    static inline var DELETE_CMD = "delete";
    static inline var CREATEDIR_CMD = "mkdir";
    
    static inline var AUTH_DOC = '[$USER_OPT <username>] [$PASS_OPT <password>]';
    
    static inline var LIST_DOC = '$LIST_CMD $URL_OPT <url> [$REMOTE_OPT <folder>] $AUTH_DOC';
    static inline var UPLOAD_DOC = '$UPLOAD_CMD $URL_OPT <url> $LOCAL_OPT <file> [$REMOTE_OPT <file>] $AUTH_DOC';
    static inline var DOWNLOAD_DOC = '$DOWNLOAD_CMD $URL_OPT <url> $REMOTE_OPT $AUTH_DOC';
    static inline var DELETE_DOC = '$DELETE_CMD $URL_OPT <url> $REMOTE_OPT <file/folder> $AUTH_DOC';
    static inline var CREATEDIR_DOC = '$CREATEDIR_CMD $URL_OPT <url> $REMOTE_OPT <folder> $AUTH_DOC';
    
    static inline var DOCS = 'Usage: webdav <command> [options...]\n
Possible commands:
    $LIST_DOC
        Lists the files and folders within the remote <folder> (or the root, if no <folder> is specified)
    
    $UPLOAD_DOC
        Uploads the local <file> to remote <file> (uploads to the root directory using the same file name if no "$REMOTE_OPT" was specified)
    
    $DOWNLOAD_DOC
        Downloads the remote <file> to local <file>
    
    $DELETE_DOC
        Deletes the remote <file/folder>. When deleting a remote <folder>, a trailing / is obligatory. E.g.: $DELETE_CMD $URL_OPT http://webdav.example.com $REMOTE_OPT test/
    
    $CREATEDIR_DOC
        Creates the remote <folder> directory
';
    
    public static function main () : Void
    {
        var client = new WebDAVClient ();
        
        #if sys
        var args = new ArgParser (Sys.args ());
        
        var command = args.safeGet (0);
        
        if (command != null) {
            var url = args.getCommandValue (URL_OPT);
            var user = args.getCommandValue (USER_OPT);
            var pass = args.getCommandValue (PASS_OPT);
            if (url == null)
                throw "Please specify a server using " + URL_OPT;
            
            client.server = url;
            client.user = user;
            client.password = pass;
            
            client.listComplete = function (files : Array<File>) {
                for (file in files) {
                    Sys.println (file.name + "\t" + file.href + "\t" + file.size);
                }
            };
            client.uploadComplete = function () {
                Sys.println ("Success");
            };
            client.downloadComplete = client.uploadComplete;
            client.deleteComplete = client.uploadComplete;
            client.createDirComplete = client.uploadComplete;
            
            client.onError = function (status : Int, msg : String) {
                Sys.stderr ().writeString ("<ERROR: " + status + "> " + msg + "\n");
            }
            
            switch (command) {
                case LIST_CMD:
                    var path = args.getCommandValue (REMOTE_OPT);
                    
                    if (path != null)
                        client.list (path);
                    else
                        client.list ();
                case UPLOAD_CMD:
                    var local = args.getCommandValue (LOCAL_OPT);
                    var remote = args.getCommandValue (REMOTE_OPT);
                    if (local == null)
                        throw "You need to specify a file to upload using " + LOCAL_OPT;
                    if (remote == null)
                        remote = haxe.io.Path.withoutDirectory (local);
                    
                    client.upload (FileInput.fromFile (local), remote);
                case DOWNLOAD_CMD:
                    var remote = args.getCommandValue (REMOTE_OPT);
                    var local = args.getCommandValue (LOCAL_OPT);
                    if (remote == null)
                        throw "You need to specify a file to download using " + REMOTE_OPT;
                    if (local == null)
                        throw "You need to specify a file to download to using " + LOCAL_OPT;
                    
                    client.download (remote, FileOutput.fromFile (local));
                case DELETE_CMD:
                    var remote = args.getCommandValue (REMOTE_OPT);
                    if (remote == null || remote == "")
                        throw "You need to specify a file to delete using " + REMOTE_OPT;
                    
                    client.delete (remote);
                case CREATEDIR_CMD:
                    var remote = args.getCommandValue (REMOTE_OPT);
                    if (remote == null || remote == "")
                        throw "You need to specify a folder name using " + REMOTE_OPT;
                    
                    client.createDir (remote);
            }
        }
        else {
            Sys.print (DOCS);
        }
        #end
    }
    
    #if sys
    static function getCommandValue (cmd : String) : String
    {
        var args = Sys.args ();
        var pos = args.indexOf (cmd);
        
        if (pos != -1)
            return safeGet (args, pos + 1);
        
        return null;
    }
    #end
    
    static function safeGet<T> (array : Array<T>, i : Int) : T
    {
        if (array.length > i)
            return array[i];
        else
            return null;
    }
}

class ArgParser
{
    var args : Array<String>;
    
    public function new (args : Array<String>)
    {
        this.args = args;
    }
    
    public function getCommandValue (cmd : String) : String
    {
        var pos = args.indexOf (cmd);
        
        if (pos != -1)
            return safeGet (pos + 1);
        
        return null;
    }
    
    public function safeGet (i : Int) : String
    {
        if (args.length > i)
            return args[i];
        else
            return null;
    }
    
}
