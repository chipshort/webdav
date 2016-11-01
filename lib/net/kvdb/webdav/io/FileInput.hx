package net.kvdb.webdav.io;

import haxe.io.Input;

class FileInput
{
    public var input (default, null) : Input;
    public var name (default, null) : String;
    public var size (default, null) : Int;
    
    public function new (input : Input, name : String, size : Int)
    {
        this.input = input;
        this.name = name;
        this.size = size;
    }
    
    #if sys
    public static function fromFile (file : String) : FileInput
    {
        var size = sys.FileSystem.stat (file).size;
        var input = sys.io.File.read (file);
        var name = haxe.io.Path.withoutDirectory (file);
        return new FileInput (input, name, size);
    }
    #end
}
