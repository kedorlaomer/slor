BEGIN {
    init();

    if (BASE == "" || SOURCE == "")
        helpAndExit();

    # ensure SOURCE ends with /
    if (substr(SOURCE, length(SOURCE)-1, 1) != "/")
        SOURCE = SOURCE "/";

    debugPrint("will use BASE=" BASE ", SOURCE=" SOURCE);

    # slurp everything into content
    RS = "";
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
            } else if (isSpace(ch)) { # followed by space -> unescaped
                skipTo(literal("<"));
                printf "&lt;";
            } else { # now it has to be an opening tag (or we will be upset)
                skipTo(literal("<")); # next character starts the tag name
                tagname = skipTo(tagName());
                debugPrint("opening tag " tagname "; is it bad? " isBadTag(tagname));

                if (isBadTag(tagname)) {
                    skipTo(endOfTag());
                    # TODO: also skip content of bad tags
                } else { # good tag
                    # TODO: process <img href=...> and <style ref="...>
                    # TODO: don't get confused by internal CSS
                    printf "%s", "<" tagname;
                    printf "%s", skipTo(endOfTag());
                }
            }
        } else { # literal text
            printf "%s%", skipTo(literal("<"));
            if (index(content, "<") == 0)
                exit 0;
        }
    }
}

function helpAndExit() {
    print "Usage: awk slor.awk BASE=<directory> SOURCE=<url>";
    print "Downloads the images and stylesheets from SOURCE and stores them to BASE";
    exit 2;
}

function debugPrint(str) {
    if (NDEBUG == 0) {
        print "\x1B[34m " str " \x1B[39m\n";
        system("sleep 1");
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

function endOfTag(              pos, nextPos) {
    pos = 1;
    while (1) {
        nextPos = min(index1(pos, content, "\""),     # attribute with "
                      index1(pos, content, "\'"),     # attribute with '
                      index1(pos, content, ">"),      # end of tag
                      index1(pos, content, "<!--"));  # comment

        ch = substr(content, nextPos, 1);

        debugPrint("endOfTag: processing " substr(content, nextPos, 40));
        debugPrint("endOfTag: next character: '" ch "' at " nextPos);

        if (ch == "\"" || ch == "'") {  # attribute
            pos = 1+index1(nextPos+1, content, ch);
        } else if (ch == "<") {         # comment
            pos = 3+index1(nextPos+1, content, "-->");
        } else if (ch == ">") {         # end
            return 1+pos;
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
        if (isAlnum(ch))
            pos++;
        else
            break;
    }

    return pos;
}

# returns the index past the first occurrence of str in content
function literal(str) {
    return length(str) + index(content, str);
}

# skips to pos; returns the skipped part
function skipTo(pos,            rv) {
    rv = substr(content, 1, pos-1);
    content = substr(content, pos);
    return rv;
}

# set certain (constant?!) variables
function init(                          tmp, i) {
    split("script applet object iframe embed", tmp, " ");
    SPACE = " \t\r\n\v\f";
    ALPHABET = "abcdefghijklmnopqrstuvwxyz";
    DIGITS = "0123456789";
    INFINITY = 1073741823; # 2**30-1 is infinite enough

    for (i in tmp) {
        BAD_TAGS[tmp[i]] = 1;
    }

    NDEBUG = 0;
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
