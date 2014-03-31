# SLOR: read off-line sites

This is a set of scripts for downloading a web site and its
images and stylesheets. The web site is manipulated in such a
way that

*   links point to the right position on the internet
*   whereas links to images and stylesheets point to the
    downloaded version
*   scripts and iframes are removed without trace

Great, ha?

This is done using an awkward awk script `slor.awk` which has an
ugly interface. That's why there is a script `wrapper.sh` that
allows the following usage

    sh wrappper.sh www.abc.de

Somewhat more practical is `listener.sh` which runs `wrapper.sh`
in a loop, constantly prompting for URLs.

The downloaded files are saved in directories with such
memorable names as cfd140df628db7480213704ae76d85a5; the html
file is saved in
cfd140df628db7480213704ae76d85a5/cfd140df628db7480213704ae76d85a5.html.

## Requirements

*   POSIX shell
*   POSIX awk
*   [curl](http://curl.haxx.se/)

Note that the `sh` and `awk` of
[busybox](http://www.busybox.net/) fulfill the requirements.
With some little changes in `wrapper.sh` and `slor.awk`, `wget`
can be used instead (even the `wget` of busybox).
