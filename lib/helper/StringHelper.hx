package helper;

using StringTools;

class StringHelper
{
    public static inline function trim2 (s : String, t : String) : String
    {
        return trimStart (trimEnd (s, t), t);
    }
    
    public static function trimStart (s : String, start : String) : String
    {
        while (s.startsWith (start)) {
            s = s.substr (1, s.length - 1);
        }
        
        return s;
    }
    
    public static function trimEnd (s : String, end : String) : String
    {
        while (s.endsWith (end)) {
            s = s.substr (0, s.length - 1);
        }
        
        return s;
    }
    
    @:noUsing public static function encodeCredentials (user : String, pass : String) : String
    {
        return haxe.crypto.Base64.encode (haxe.io.Bytes.ofString (user + ":" + pass));
    }
}
