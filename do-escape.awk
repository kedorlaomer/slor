BEGIN {
    SUBST["f"] = "7";
    SUBST["e"] = "6";
    SUBST["d"] = "5";
    SUBST["c"] = "4";
    SUBST["b"] = "3";
    SUBST["a"] = "2";
    SUBST["9"] = "1";
    SUBST["8"] = "0";
}

{ for (i = 1; i <= NF; i++) {
    if (substr($i, 1, 1) in SUBST)
        printf "16 %s%s ", SUBST[substr($i, 1, 1)], substr($i, 2, 1);
    else
        printf "%s ", $i;
    }

    print "";
}
