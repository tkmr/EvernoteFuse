module REvernote
  class ENML
    BASEXML = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml.dtd"><en-note></en-note>'

    TAGS = %w{A ABBR ACRONYM ADDRESS AREA B BDO BIG BLOCKQUOTE BR CAPTION CENTER
              CITE CODE COL COLGROUP DD DEL DFN DIV DL DT EM FONT H1 H2 H3 H4 H5 H6
              HR I IMG INS KBD LI MAP OL P PRE Q S SAMP SMALL SPAN STRIKE STRONG
              SUB SUP TABLE TBODY TD TFOOT TH THEAD TITLE TR TT U UL VAR XMP EN-NOTE}

    REPLACE_TAGS = {
      'TEXTAREA' => 'DIV'
    }

    DTD_ATTRS = {
      "html"=>["id", "xmlns"],
      "head"=>["id", "profile"],
      "script"=>["id", "charset", "type", "language", "src", "defer", "xml:space"],
      "noframes"=>[],
      "en-note"=>["bgcolor", "text"],
      "h3"=>[],
      "dd"=>[],
      "address"=>[],
      "del"=>["cite", "datetime"],
      "basefont"=>["id", "size", "color", "face"],
      "colgroup"=>["span", "width"],
      "col"=>["span", "width"],
      "noscript"=>[],
      "h4"=>[],
      "ul"=>["type", "compact"],
      "center"=>[],
      "a"=>["charset", "type", "name", "href", "hreflang", "rel", "rev", "shape", "coords", "target"],
      "en-crypt"=>["hint", "cipher", "length"],
      "en-todo"=>["checked"],
      "h5"=>[],
      "bdo"=>["lang", "xml:lang", "dir"],
      "en-media"=>["type", "hash", "height", "width", "usemap", "align", "border", "hspace", "vspace", "longdesc", "alt"],
      "thead"=>[],
      "h6"=>[],
      "pre"=>["width", "xml:space"],
      "ins"=>["cite", "datetime"],
      "img"=>["src", "alt", "name", "longdesc", "height", "width", "usemap", "ismap", "align", "border", "hspace", "vspace"],
      "iframe"=>["longdesc", "name", "src", "frameborder", "marginwidth", "marginheight", "scrolling", "align", "height", "width"],
      "blockquote"=>["cite"],
      "param"=>["id", "name", "value", "valuetype", "type"],
      "tfoot"=>[],
      "tbody"=>[],
      "meta"=>["id", "http-equiv", "name", "content", "scheme"],
      "p"=>[],
      "dt"=>[],
      "br"=>["clear"],
      "table"=>["summary", "width", "border", "cellspacing", "cellpadding", "align", "bgcolor"],
      "td"=>["abbr", "rowspan", "colspan", "nowrap", "bgcolor", "width", "height"],
      "div"=>[],
      "q"=>["cite"],
      "font"=>["size", "color", "face"],
      "applet"=>["codebase", "archive", "code", "object", "alt", "name", "width", "height", "align", "hspace", "vspace"],
      "map"=>["title", "name"],
      "area"=>["shape", "coords", "href", "nohref", "alt", "target"],
      "caption"=>["align"],
      "ol"=>["type", "compact", "start"],
      "li"=>["type", "value"],
      "title "=>["id"],
      "link"=>["charset", "href", "hreflang", "type", "rel", "rev", "media", "target"],
      "dl"=>["compact"],
      "tr"=>["bgcolor"],
      "h1"=>[],
      "object"=>["declare", "classid", "codebase", "data", "type", "codetype", "archive", "standby", "height", "width", "usemap", "name", "tabindex", "align", "border", "hspace", "vspace"],
      "th"=>["abbr", "rowspan", "colspan", "nowrap", "bgcolor", "width", "height"],
      "base"=>["id", "href", "target"],
      "style"=>["id", "type", "media", "title", "xml:space"],
      "h2"=>[],
      "hr"=>["align", "noshade", "size", "width"],
      "span"=>[]}
  end
end
