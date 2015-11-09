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
            year = ((string) buffer[93:97]).to_int ();
            genre = (Genre) buffer[127];
        }
        
        private string get_utf8_string(uint8[] buffer, int start, int end) {
            
            unowned string locale;
            bool need_convert = GLib.get_charset(out locale);
            ssize_t len = end - start;
            string text;
            if (need_convert) {
                try {
                    text = GLib.convert((string) buffer[start:end], len, locale, "UTF-8");
                } catch (ConvertError e) {
                    print("%i %i\n", start, end);
                    stderr.printf("%s\n", e.message);
                    text = (string)buffer[start:end];
                }
            } else {
                text = (string)buffer[start:end];
            }

            return text.strip();
        }
      }
}  