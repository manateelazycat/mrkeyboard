using GLib;

namespace Tagle {
    public enum TagVersion {
        ID3_V1,
        ID3_V1_1,
        ID3_V1_EXT,
        ID3_V2_2_0,
        ID3_V2_3_0,
        ID3_V2_4_0
    }
  
    public class Id3 : Object {
        public enum Genre {
            BLUES, CLASSIC_ROCK, COUNTRY, DANCE, DISCO, FUNK, GRUNGE, HIP_HOP,
            JAZZ, METAL, NEW_AGE, OLDIES, OTHER, POP, RNB, RAP,
            REGGAE, ROCK, TECHNO, INDUSTRIAL, ALTERNATIVE, SKA, DEATH_METAL, PRANKS,
            FILM_SCORE, EURO_TECHNO, AMBIENT, TRIP_HOP, VOCAL, JAZZ_FUNK, FUSION, TRANCE
        }
      
        public string title { get; set; }
        public string artist { get; set; }
        public string album { get; set; }
        public int duration { get; set; }
        public int year { get; set; }
        public Genre genre { get; set; }
  	  	
      	public Id3 (string path) throws Error {
      	    uint8[] buffer = new uint8[128];
      	    var file = File.new_for_path (path);
      	    var input_stream = file.read ();
      	    input_stream.seek (-128, SeekType.END);
      	    if (input_stream.read (buffer) != 128) throw new IOError.FAILED ("aie");
      	    if (buffer[0] != 'T' || buffer[1] != 'A' || buffer[2] != 'G') throw new IOError.FAILED ("aie2");
            
            title = get_utf8_string(buffer, 3, 33);
            artist = get_utf8_string(buffer, 33, 63);
            album = get_utf8_string(buffer, 63, 93);
            
            year = int.parse((string) buffer[93:97]);
            genre = (Genre) buffer[127];
            
            // FIXME: we need faster way than spawn process to get duration.
            string stdout;
            string stderr;
            int status;
            string[] spawn_args;
            Shell.parse_argv("mediainfo --Inform=\"Audio;%Duration%\" \"%s\"".printf(path), out spawn_args);
            Process.spawn_sync(null,
                               spawn_args,
                               null,
                               SpawnFlags.SEARCH_PATH,
                               null,
                               out stdout,
                               out stderr,
                               out status);
            duration = int.parse(stdout);
        }
            
        private string get_utf8_string(uint8[] buffer, int start, int end) {
            string? text = null;
            string charset;
            
            if (start == 33) {
                charset = "gbk";
            } else {
                charset = "UTF-8";
            }
            int read;
            int fallbacks;
            try {
                text = (string) convert_to_utf8(buffer[start:end], ref charset, out read, out fallbacks);
            } catch (Error e) {
                stderr.printf("%s\n", e.message);
            }
            
            if (text != null) {
                return text.strip();
            } else {
                return (string) buffer[start:end];
            }
        }

        static const string[] detected_charsets = { "gbk", "big5", "utf-8", "iso-8859-1", "cp1251" };
	
    	/* Try to guess the charset and return the converted data along with the number of bytes read.
    	 * If no charset can be detected, returns latin1 converted to utf-8 with fallbacks */
    	public uint8[]? convert_to_utf8 (uint8[] text, ref string? charset, out int read, out int fallbacks) throws Error {
    		read = 0;
    		fallbacks = 0;
    		if (text.length == 0) {
    			return text;
    		}
    		
    		var default_charset = charset ?? "UTF-8";
    		var buf = new uint8[text.length*4];
    		buf.length--; // space for trailing zero
    		uint8[] bestbuf = null;
    		charset = null;
    		
    		// first try the default charset
    		var conv = new CharsetConverter ("UTF-8", default_charset);
    		size_t sread, written;
    		try {
    			conv.convert (text, buf, ConverterFlags.NONE, out sread, out written);
    			var newread = (int) sread;
    			charset = default_charset;
    			bestbuf = buf;
    			bestbuf.length = (int) written;
    			read = newread;
    		} catch (IOError.PARTIAL_INPUT e) {
    			var newread = (int) sread;
    			charset = default_charset;
    			bestbuf = buf;
    			bestbuf.length = (int) written;
    			read = newread;
    		} catch (Error e) {
    			// invalid byte sequence
    		}
    		
    		foreach (unowned string cset in detected_charsets) {
    			if (cset == default_charset) {
    				continue;
    			}
    			
    			conv = new CharsetConverter ("UTF-8", cset);
    			try {
    				conv.convert (text, buf, ConverterFlags.NONE, out sread, out written);
    				var newread = (int) sread;
    				if (newread > read) { // FIXME: check readable chars
    					charset = cset;
    					bestbuf = buf;
    					bestbuf.length = (int) written;
    					read = newread;
    				}
    			} catch (IOError.PARTIAL_INPUT e) {
    				var newread = (int) sread;
    				if (newread > read) { // FIXME: check reaable chars
    					charset = cset;
    					bestbuf = buf;
    					bestbuf.length = (int) written;
    					read = newread;
    				}
    			} catch (Error e) {
    				// invalid byte sequence
    			}
    		}
    
    		if (bestbuf == null) {
    			// assume latin1 with fallbacks
    			conv = new CharsetConverter ("UTF-8", "ISO-8859-1");
    			conv.use_fallback = true;
    			conv.convert (text, bestbuf, ConverterFlags.NONE, out sread, out written);
    			read = (int) read;
    			bestbuf.length = (int) written;
    			charset = "ISO-8859-1";
    			fallbacks = (int) conv.get_num_fallbacks ();
    		}
    
    		bestbuf[bestbuf.length] = '\0';
    		return bestbuf;
    	}        
    }
}  