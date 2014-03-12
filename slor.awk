BEGIN {
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
        skipSpace();
        ch = substr(content, 0, 1);
        debugPrint("processing " ch);
        
        # process a tag or processing instruction or XML declaration or DTD
        # declaration
        if (ch == "<") {
        }
    }
}

function helpAndExit() {
    print "Usage: awk slor.awk BASE=<directory> SOURCE=<url>";
    print "Downloads the images and stylesheets from SOURCE and stores them to BASE";
    exit 2;
}

function debugPrint(str) {
    print str;
}

# replaces content by the longest substring that doesn't start with a space
function skipSpace(             pos, ch) {
    pos = 0;
    while (1) {
        ch = substr(content, pos, 1);
        if (ch == " " || ch == "\t" || ch == "\r" || ch == "\n" || ch == "\v")
            pos++;
        else
            break;
    }

    content = substr(content, pos);
}
