BEGIN {
    SUBST["7"] = "f";
    SUBST["6"] = "e";
    SUBST["5"] = "d";
    SUBST["4"] = "c";
    SUBST["3"] = "b";
    SUBST["2"] = "a";
    SUBST["1"] = "9";
    SUBST["0"] = "8";

    printf "000 "; # line number for hexdump -R
}

{ 
    for (i = 1; i <= NF; i++) {
        if ($i == 16) {
            i++;
            printf "%s%s ", SUBST[substr($i, 1, 1)], substr($i, 2, 1);
        } else {
            printf "%s ", $i;
        }
    }
}
