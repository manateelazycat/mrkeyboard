namespace ID3
{
    [CCode(cheader_filename = "id3.h", cname = "enum ID3_FieldType", cprefix = "ID3FTY_")]
    public enum FieldType
    {
        NONE           = -1,
        INTEGER        = 0,
        BINARY,
        TEXTSTRING,
        NUMTYPES    
    }
    
    [CCode(cheader_filename = "id3.h", cname = "enum ID3_TextEnc", cprefix = "ID3TE_")]
    public enum TextEncoding
    {
        NONE = -1,
        ISO8859_1,
        UTF16,
        UTF16BE,
        UTF8,
        NUMENCODINGS,
        ASCII = ISO8859_1, 
        UNICODE = UTF16   
    }
    
    [CCode(cheader_filename = "id3.h", cname = "enum ID3_TagType", cprefix = "ID3TT_")]
    public enum TagType
    {
        NONE       =      0,   /**< Represents an empty or non-existant tag */
        ID3V1      = 1 << 0,   /**< Represents an id3v1 or id3v1.1 tag */
        ID3V2      = 1 << 1,   /**< Represents an id3v2 tag */
        LYRICS3    = 1 << 2,   /**< Represents a Lyrics3 tag */
        LYRICS3V2  = 1 << 3,   /**< Represents a Lyrics3 v2.00 tag */
        MUSICMATCH = 1 << 4,   /**< Represents a MusicMatch tag */
        /**< Represents a Lyrics3 tag (for backwards compatibility) */
        LYRICS     = TagType.LYRICS3,
        /** Represents both id3 tags: id3v1 and id3v2 */
        ID3        = TagType.ID3V1 | TagType.ID3V2,
        /** Represents all possible types of tags */
        ALL        = ~TagType.NONE,
        /** Represents all tag types that can be prepended to a file */
        PREPENDED  = TagType.ID3V2,
        /** Represents all tag types that can be appended to a file */
        APPENDED   = TagType.ALL & ~TagType.ID3V2
    }
    
    [CCode(cheader_filename = "id3.h", cname = "enum ID3_Err", cprefix = "ID3E_")]
    public enum Err
    {
        NoError = 0,             /**< No error reported */
        NoMemory,                /**< No available memory */
        NoData,                  /**< No data to parse */
        BadData,                 /**< Improperly formatted data */
        NoBuffer,                /**< No buffer to write to */
        SmallBuffer,             /**< Buffer is too small */
        InvalidFrameID,          /**< Invalid frame id */
        FieldNotFound,           /**< Requested field not found */
        UnknownFieldType,        /**< Unknown field type */
        TagAlreadyAttached,      /**< Tag is already attached to a file */
        InvalidTagVersion,       /**< Invalid tag version */
        NoFile,                  /**< No file to parse */
        ReadOnly,                /**< Attempting to write to a read-only file */
        zlibError                /**< Error in compression/uncompression */
    }
    
    [CCode(cheader_filename = "id3.h", cname = "enum ID3_FieldID", cprefix = "ID3FN_")]
    public enum FieldID
    {
        NOFIELD = 0,    /**< No field */
        TEXTENC,        /**< Text encoding (unicode or ASCII) */
        TEXT,           /**< Text field */
        URL,            /**< A URL */
        DATA,           /**< Data field */
        DESCRIPTION,    /**< Description field */
        OWNER,          /**< Owner field */
        EMAIL,          /**< Email field */
        RATING,         /**< Rating field */
        FILENAME,       /**< Filename field */
        LANGUAGE,       /**< Language field */
        PICTURETYPE,    /**< Picture type field */
        IMAGEFORMAT,    /**< Image format field */
        MIMETYPE,       /**< Mimetype field */
        COUNTER,        /**< Counter field */
        ID,             /**< Identifier/Symbol field */
        VOLUMEADJ,      /**< Volume adjustment field */
        NUMBITS,        /**< Number of bits field */
        VOLCHGRIGHT,    /**< Volume chage on the right channel */
        VOLCHGLEFT,     /**< Volume chage on the left channel */
        PEAKVOLRIGHT,   /**< Peak volume on the right channel */
        PEAKVOLLEFT,    /**< Peak volume on the left channel */
        TIMESTAMPFORMAT,/**< SYLT Timestamp Format */
        CONTENTTYPE,    /**< SYLT content type */
        LASTFIELDID     /**< Last field placeholder */  
    }
    
    [CCode(cheader_filename = "id3.h", cname = "enum ID3_FrameID", cprefix = "ID3FID_")]
    public enum FrameID
    {
      /* ???? */ NOFRAME = 0,       /**< No known frame */
  /* AENC */ AUDIOCRYPTO,       /**< Audio encryption */
  /* APIC */ PICTURE,           /**< Attached picture */
  /* ASPI */ AUDIOSEEKPOINT,    /**< Audio seek point index */
  /* COMM */ COMMENT,           /**< Comments */
  /* COMR */ COMMERCIAL,        /**< Commercial frame */
  /* ENCR */ CRYPTOREG,         /**< Encryption method registration */
  /* EQU2 */ EQUALIZATION2,     /**< Equalisation (2) */
  /* EQUA */ EQUALIZATION,      /**< Equalization */
  /* ETCO */ EVENTTIMING,       /**< Event timing codes */
  /* GEOB */ GENERALOBJECT,     /**< General encapsulated object */
  /* GRID */ GROUPINGREG,       /**< Group identification registration */
  /* IPLS */ INVOLVEDPEOPLE,    /**< Involved people list */
  /* LINK */ LINKEDINFO,        /**< Linked information */
  /* MCDI */ CDID,              /**< Music CD identifier */
  /* MLLT */ MPEGLOOKUP,        /**< MPEG location lookup table */
  /* OWNE */ OWNERSHIP,         /**< Ownership frame */
  /* PRIV */ PRIVATE,           /**< Private frame */
  /* PCNT */ PLAYCOUNTER,       /**< Play counter */
  /* POPM */ POPULARIMETER,     /**< Popularimeter */
  /* POSS */ POSITIONSYNC,      /**< Position synchronisation frame */
  /* RBUF */ BUFFERSIZE,        /**< Recommended buffer size */
  /* RVA2 */ VOLUMEADJ2,        /**< Relative volume adjustment (2) */
  /* RVAD */ VOLUMEADJ,         /**< Relative volume adjustment */
  /* RVRB */ REVERB,            /**< Reverb */
  /* SEEK */ SEEKFRAME,         /**< Seek frame */
  /* SIGN */ SIGNATURE,         /**< Signature frame */
  /* SYLT */ SYNCEDLYRICS,      /**< Synchronized lyric/text */
  /* SYTC */ SYNCEDTEMPO,       /**< Synchronized tempo codes */
  /* TALB */ ALBUM,             /**< Album/Movie/Show title */
  /* TBPM */ BPM,               /**< BPM (beats per minute) */
  /* TCOM */ COMPOSER,          /**< Composer */
  /* TCON */ CONTENTTYPE,       /**< Content type */
  /* TCOP */ COPYRIGHT,         /**< Copyright message */
  /* TDAT */ DATE,              /**< Date */
  /* TDEN */ ENCODINGTIME,      /**< Encoding time */
  /* TDLY */ PLAYLISTDELAY,     /**< Playlist delay */
  /* TDOR */ ORIGRELEASETIME,   /**< Original release time */
  /* TDRC */ RECORDINGTIME,     /**< Recording time */
  /* TDRL */ RELEASETIME,       /**< Release time */
  /* TDTG */ TAGGINGTIME,       /**< Tagging time */
  /* TIPL */ INVOLVEDPEOPLE2,   /**< Involved people list */
  /* TENC */ ENCODEDBY,         /**< Encoded by */
  /* TEXT */ LYRICIST,          /**< Lyricist/Text writer */
  /* TFLT */ FILETYPE,          /**< File type */
  /* TIME */ TIME,              /**< Time */
  /* TIT1 */ CONTENTGROUP,      /**< Content group description */
  /* TIT2 */ TITLE,             /**< Title/songname/content description */
  /* TIT3 */ SUBTITLE,          /**< Subtitle/Description refinement */
  /* TKEY */ INITIALKEY,        /**< Initial key */
  /* TLAN */ LANGUAGE,          /**< Language(s) */
  /* TLEN */ SONGLEN,           /**< Length */
  /* TMCL */ MUSICIANCREDITLIST,/**< Musician credits list */
  /* TMED */ MEDIATYPE,         /**< Media type */
  /* TMOO */ MOOD,              /**< Mood */
  /* TOAL */ ORIGALBUM,         /**< Original album/movie/show title */
  /* TOFN */ ORIGFILENAME,      /**< Original filename */
  /* TOLY */ ORIGLYRICIST,      /**< Original lyricist(s)/text writer(s) */
  /* TOPE */ ORIGARTIST,        /**< Original artist(s)/performer(s) */
  /* TORY */ ORIGYEAR,          /**< Original release year */
  /* TOWN */ FILEOWNER,         /**< File owner/licensee */
  /* TPE1 */ LEADARTIST,        /**< Lead performer(s)/Soloist(s) */
  /* TPE2 */ BAND,              /**< Band/orchestra/accompaniment */
  /* TPE3 */ CONDUCTOR,         /**< Conductor/performer refinement */
  /* TPE4 */ MIXARTIST,         /**< Interpreted, remixed, or otherwise modified by */
  /* TPOS */ PARTINSET,         /**< Part of a set */
  /* TPRO */ PRODUCEDNOTICE,    /**< Produced notice */
  /* TPUB */ PUBLISHER,         /**< Publisher */
  /* TRCK */ TRACKNUM,          /**< Track number/Position in set */
  /* TRDA */ RECORDINGDATES,    /**< Recording dates */
  /* TRSN */ NETRADIOSTATION,   /**< Internet radio station name */
  /* TRSO */ NETRADIOOWNER,     /**< Internet radio station owner */
  /* TSIZ */ SIZE,              /**< Size */
  /* TSOA */ ALBUMSORTORDER,    /**< Album sort order */
  /* TSOP */ PERFORMERSORTORDER,/**< Performer sort order */
  /* TSOT */ TITLESORTORDER,    /**< Title sort order */
  /* TSRC */ ISRC,              /**< ISRC (international standard recording code) */
  /* TSSE */ ENCODERSETTINGS,   /**< Software/Hardware and settings used for encoding */
  /* TSST */ SETSUBTITLE,       /**< Set subtitle */
  /* TXXX */ USERTEXT,          /**< User defined text information */
  /* TYER */ YEAR,              /**< Year */
  /* UFID */ UNIQUEFILEID,      /**< Unique file identifier */
  /* USER */ TERMSOFUSE,        /**< Terms of use */
  /* USLT */ UNSYNCEDLYRICS,    /**< Unsynchronized lyric/text transcription */
  /* WCOM */ WWWCOMMERCIALINFO, /**< Commercial information */
  /* WCOP */ WWWCOPYRIGHT,      /**< Copyright/Legal information */
  /* WOAF */ WWWAUDIOFILE,      /**< Official audio file webpage */
  /* WOAR */ WWWARTIST,         /**< Official artist/performer webpage */
  /* WOAS */ WWWAUDIOSOURCE,    /**< Official audio source webpage */
  /* WORS */ WWWRADIOPAGE,      /**< Official internet radio station homepage */
  /* WPAY */ WWWPAYMENT,        /**< Payment */
  /* WPUB */ WWWPUBLISHER,      /**< Official publisher webpage */
  /* WXXX */ WWWUSER,           /**< User defined URL link */
  /*      */ METACRYPTO,        /**< Encrypted meta frame (id3v2.2.x) */
  /*      */ METACOMPRESSION,   /**>>> */ LASTFRAMEID;       /**< Last field placeholder */ 
    }

    [CCode(cheader_filename = "id3.h", cname = "struct ID3Tag", cprefix = "ID3Tag_", unref_function = "ID3Tag_Delete")]
    public class Tag
    {
        [CCode(cname = "ID3Tag_New")]
        public Tag();
        public void Clear();
        public bool HasChanged();
        public void SetUnsync(bool unsync);
        public void SetExtendedHeader(bool ext);
        public void SetPadding(bool pad);
        public void AddFrame (Frame frame);
        public bool AttachFrame(Frame frame);
        public void AddFrames(Frame[] frames);
        public Frame RemoveFrame(Frame frame);
        public Err Parse(uint8[] header, out uint8[] buffer);
        public size_t Link(string filename);
        public size_t LinkWithFlags(string filename, uint16 flags);
        public Err Update();
        public Err UpdateByTagType(uint16 type);
        public Err Strip(uint16 flags);
        public Frame FindFrameWithID(FrameID id);
        public Frame FindFrameWithINT(FrameID id, FieldID fid, uint data);
        public Frame FindFrameWithASCII(FrameID id, FieldID fid, string ascii);
        public Frame FindFrameWithUNICODE(FrameID id, FieldID fid, uint16[] unicode);
        public size_t NumFrames();
        public bool HasTagType(TagType type);
        public Iterator CreateIterator();
        public ConstIterator CreateConstIterator();
    }
    
    [CCode(cheader_filename = "id3.h", cname = "struct ID3TagIterator", cprefix = "ID3TagIterator_", 
        unref_function = "ID3TagIterator_Delete")]
    public class Iterator
    {
        public Frame GetNext();
    }
    
    [CCode(cheader_filename = "id3.h", cname = "struct ID3TagConstIterator", cprefix = "ID3TagConstIterator_", 
        unref_function = "ID3TagConstIterator_Delete")]
    public class ConstIterator
    {
        public Frame GetNext();
    }
    
    [CCode(cheader_filename = "id3.h", cname = "struct ID3Frame", cprefix = "ID3Frame_", unref_function = "")]
    public class Frame
    {
        [CCode(cname = "ID3Frame_New")]
        public Frame();
        [CCode(cname = "ID3Frame_NewID")]
        public Frame.ID(FrameID id);
        public void Clear();
        public void SetID(FrameID id);
        public FrameID GetID();
        public Field GetField(FieldID id);
        public void SetCompression(bool compression);
        public bool GetCompression();
    }
    [CCode(cheader_filename = "id3.h", cname = "struct ID3Field", cprefix = "ID3Field_", unref_function = "")]
    public class Field
    {
        public size_t Size();
        public size_t GetNumTextItems();
        public void SetINT(uint val);
        public uint GetINT();
        public void SetUNICODE(uint16[] unicode);
        public size_t GetUNICODE(uint16[] unicode);
        public size_t GetUNICODEItem(uint16[] unicode, size_t num);
        public void AddUNICODE(uint16[] unicode);
        public void SetASCII(uint8[] ascii);
        public size_t GetASCII(uint8[] ascii);
        public size_t GetASCIIItem(uint8[] ascii, size_t num);
        public void AddASCII(uint8[] ascii);
        public void GetBINARY(uint8[] data);
        public void SetBINARY(uint8[] data);
        public void FromFile(string file);
        public void ToFile(string file);
        public bool SetEncoding(TextEncoding enc);
        public TextEncoding GetEncoding();
        public bool IsEncodable();
    }
    
    [CCode(cheader_filename = "id3.h", cprefix = "ID3FrameInfo_", unref_function = "")]
    public class FrameInfo
    {   
        public static string ShortName(FrameID id);
        public static string LongName(FrameID id);
        public static string Description(FrameID id);
        public static int MaxFrameID();
        public static int NumFields(FrameID id);
        [CCode(cname = "ID3FrameInfo_FieldType")]
        public static FieldType Type(FrameID id, int num);
        public static size_t FieldSize(FrameID id, int num);
        public static uint16 FieldFlags(FrameID id, int num);
    }
}