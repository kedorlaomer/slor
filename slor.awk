BEGIN {
    init();

    if (BASE == "" || SOURCE == "")
        helpAndExit();

    # ensure SOURCE starts with a protocol
    if (SOURCE !~ /^\w+:\/\//)
        SOURCE = "http://" SOURCE;

    # ensure SOURCE doesn't have a fragment
    if (SOURCE ~ /#/)
        SOURCE = substr(SOURCE, 1, index(SOURCE, "#")-1);

    # ensure SOURCE doesn't have a query
    if (SOURCE ~ /\?/)
        SOURCE = substr(SOURCE, 1, index(SOURCE, "?")-1);

    # ensure SOURCE ends with /
    if (SOURCE ~! /\/$/)
        SOURCE = SOURCE "/";

    debugPrint("will use BASE=" BASE ", SOURCE=" SOURCE);

    # slurp everything into content
    RS = "";
    content = "";
    while ((getline tmp) > 0) {
        content = content "\n\n" tmp;
    }

    getline content;

    # process content
    while (length(content) > 0) {
        printf "%s", skipTo(nonSpace());
        ch = substr(content, 1, 1);
        debugPrint("processing " substr(content, 1, 40) "...");
        
        # we see now
        #
        # * a comment
        # * a (closing or opening) tag
        # * processing instruction
        # * a processing instruction
        # * an XML declaration
        # * a doctype declaration
        # * none of that: an unescaped <

        if (ch == "<") {
            ch = substr(content, 2, 1);

            if (ch == "?") { # XML declaration or processing instruction; terminated by ?>
                skipTo(literal("?>"));
            } else if (ch == "!") { # comment or DTD
                ch = substr(content, 3, 2);
                if (ch == "--") { # comment
                    skipTo(literal("-->"));
                } else if (tolower(ch) == "do") { # DTD; don't handle inline DTD
                    skipTo(literal(">"));
                }
            } else if (ch == "/") { # closing tag
                skipTo(1+length("</"));
                tagname = skipTo(literal(">"));
                tagname = substr(tagname, 1, length(tagname)-1);
                debugPrint("closing tag " tagname "; is it bad? " isBadTag(tagname));
                if (!isBadTag(tagname)) {
                    printf "%s", "</" tagname ">";
                }
            } else if (!isAlnum(ch)) { # followed by something not like a tag name -> unescaped
                skipTo(literal("<"));
                printf "&lt;";
            } else { # now it has to be an opening tag (or we will be upset)
                skipTo(literal("<")); # next character starts the tag name
                tagname = tolower(skipTo(tagName()));
                debugPrint("opening tag " tagname "; is it bad? " isBadTag(tagname));

                if (isBadTag(tagname)) {
                    skipTo(endOfTag());
                    # also skip content of bad tags
                    skipTo(iliteral("</" tagname ">"));
                } else { # good tag
                    printf "%s", "<" tagname;
                    skipTo(nonSpace());
                    #printf "%s", skipTo(nonSpace());
                    while (substr(content, 1, 1) != ">" && substr(content, 1, 2) != "/>") {
                        attribute = tolower(skipTo(tagName())); # attributes look like tag names
                        debugPrint("found attribute '" attribute "'");
                        skipTo(nonSpace());
                        if (substr(content, 1, 1) == "=") {
                            skipTo(literal("="));
                            skipTo(nonSpace());
                            value = unquoteAttributeValue(skipTo(attributeValue()));
                            debugPrint("found value " value);
                            skipTo(nonSpace());
                        } else {
                            value = "";
                        }

                        # attribute is JavaScript iff it starts
                        # with "on"
                        if (substr(attribute, 1, 2) != "on")
                        {
                            # attribute is an URL
                            if (NEEDS_CHANGE[tagname] == attribute) {
                                if (tagname == "a") {
                                    value = makeAbsolute(value);
                                } else {
                                    value = makeRelative(value);
                                }
                            }

                            printf " %s=%s", attribute, quoteAttributeValue(value);
                        }
                    }

                    # end of tag
                    if (substr(content, 1, 2) == "/>")
                        printf " %s", skipTo(literal("/>"));
                    else
                        printf "%s", skipTo(literal(">"));
                }
            }
        } else { # literal text
            debugPrint("literal text...");
            printf "%s%", skipBefore(literal("<"));
            if (index(content, "<") == 0)
                break;
        }
    }

    doDownloads();
}

function helpAndExit() {
    print "Usage: awk slor.awk -v BASE=<directory> -v SOURCE=<url>";
    print "Downloads the images and stylesheets from SOURCE and stores them to BASE";
    exit 2;
}

function debugPrint(str) {
    if (NDEBUG == 0) {
        print "\x1B[34m " str " \x1B[39m";
        system("sleep 0.1");
    }
}

# returns the index to the first non-blank character in content
function nonSpace(              pos, ch) {
    pos = 1;
    while (1) {
        ch = substr(content, pos, 1);
        if (isSpace(ch))
            pos++;
        else
            break;
    }

    return pos;
}

# returns the index to the first character in content
function space(                 pos, ch) {
    pos = 1;
    while (1) {
        ch = substr(content, pos, 1);
        if (!isSpace(ch))
            pos++;
        else
            break;
    }

    return pos;
}

function isSpace(ch) {
    return index(SPACE, ch) > 0;
}

function isBadTag(tag) {
    return tolower(tag) in BAD_TAGS;
}

function isAlnum(ch) {
    return index(ALPHABET, tolower(ch)) > 0 || index(DIGITS, ch) > 0;
}

# parses an attribute, which may be
#
# * a single word without spaces
# * enclosed in "..."
# * or enclosed in '...'
#
# and returns the index after the attribute
function attributeValue(        ch) {
    ch = substr(content, 1, 1);
    if (ch == "\"" || ch == "'")
        return index1(2, content, ch)+1;
    else
        return space();
}

function unquoteAttributeValue(value,       ch1, ch2) {
    ch1 = substr(value, 1, 1);
    ch2 = substr(value, length(value), 1);
    if (ch1 == ch2 && (ch1 == "\"" || ch1 == "'"))
        return substr(value, 2, length(value)-2); # quoted
    else
        return value;                             # not quoted
}

# attribute values might be enclosed in "..." or '...', so they
# aren't allowed to contain both; returns the value quoted in a
# legal way
function quoteAttributeValue(value) {
    if (index(value, "\"") == 0) {
        return "\"" value "\"";
    }

    return "'" value "'";
}

function endOfTag(              pos, nextPos) {
    pos = 1;
    while (1) {
        nextPos = min(index1(pos, content, "\""),     # attribute with "
                      index1(pos, content, "\'"),     # attribute with '
                      index1(pos, content, ">"),      # end of tag
                      index1(pos, content, "<!--"));  # comment; is this actually possible?

        ch = substr(content, nextPos, 1);

        debugPrint("endOfTag: processing " substr(content, nextPos, 40));
        debugPrint("endOfTag: next character: '" ch "' at " nextPos);

        if (ch == "\"" || ch == "'") {  # attribute
            pos = 1+index1(nextPos+1, content, ch);
        } else if (ch == "<") {         # comment
            pos = 3+index1(nextPos+1, content, "-->");
        } else if (ch == ">") {         # end
            return 1+nextPos;
        } else {
            print "endOfTag: *** this shouldn't happen...";
            exit 1;
        }
    }
}

# like index, but starts searching from pos and returns INFINITY instead of zero
function index1(pos, long, short,           rv) {
    rv = index(substr(long, pos), short)-1;
    if (rv == -1) {
        return INFINITY;
    }

    return pos + rv;
}

# a tag name starts with an isAlpha and may continue with an isAlnum
function tagName(               ch, pos) {
    pos = 2; # we don't care if the first letter is actually an isAlpha

    while (1) {
        ch = substr(content, pos, 1);
        if (isAlnum(ch) || ch == "-" || ch == "_")
            pos++;
        else
            break;
    }

    return pos;
}

# interpret url relative to SOURCE
function makeAbsolute(url) {
    if (match(url, "^\\w+://")) {
        debugPrint("protocol URL " url);
        return url;
    }

    if (match(url, "^//")) {
        debugPrint("implicit http URL " url);
        return "http:" url;
    }

    if (match(url, "^/")) {
        debugPrint("semi-absolute URL " url " with prefix " PREFIX);
        return PREFIX url;
    }

    debugPrint("relative URL " url);
    return SOURCE "/" url;
}


# TODO: complete
function makeRelative(url,          localName) {
    url = makeAbsolute(url);
    debugPrint("scheduled for download: " url);
    localName = BASE "/temp_" DOWNLOAD_INDEX;
    # this may fail if url contains a quote '
    DOWNLOAD = DOWNLOAD " -o " localName " '" url "'";
    DOWNLOAD_INDEX++;
    return localName;
}

# TODO: complete
function doDownloads() {
    system(DOWNLOAD);
}

# returns the index past the first occurrence of str in content
function literal(str) {
    return length(str) + index(content, str);
}

# returns the index past the first occurrence of str in content disregarding case
function iliteral(str) {
    return length(str) + index(tolower(content), tolower(str));
}

# skips to pos; returns the skipped part
function skipTo(pos,            rv) {
    rv = substr(content, 1, pos-1);
    content = substr(content, pos);
    return rv;
}

function skipBefore(pos) {
    return skipTo(pos-1);
}

# set certain (constant?!) variables
function init(                          tmp, i) {
    SPACE = " \t\r\n\v\f";
    ALPHABET = "abcdefghijklmnopqrstuvwxyz";
    DIGITS = "0123456789";
    INFINITY = 1073741823; # 2**30-1 is infinite enough

    match(SOURCE, "^\\w+://[^/]+");
    PREFIX = substr(SOURCE, RSTART, RSTART+RLENGTH-1); # http://www.foo.com without the rest

    split("script applet object iframe embed", tmp, " ");

    # we skip these tags
    for (i in tmp) {
        BAD_TAGS[tmp[i]] = 1;
    }

    # if a tag has a certain value, we may need to change this
    # value
    NEEDS_CHANGE["a"] = "href";
    NEEDS_CHANGE["img"] = "src";
    NEEDS_CHANGE["link"] = "href";

    # command line for downloading things we haven't got yet
    DOWNLOAD = "curl -gk";
    DOWNLOAD_INDEX = 0;

    NDEBUG = 1;
}

function min2(a, b) {
    if (a < b) {
        return a;
    }

    return b;
}

function min(a, b, c, d) {
    return min2(min2(a, b), min2(c, d));
}

# vim: set fo-=a:
