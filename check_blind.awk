function org_date_to_epoch(date,    timespec, numbers) {
    if (match(date, /^<([0-9]+)-([0-9][0-9])-([0-9][0-9])/, numbers)){
        timespec = sprintf("%d %d %d 0 0 0", numbers[1], numbers[2], numbers[3]);
        return mktime(timespec);
    }
    return 0;
}

BEGIN {
    FS = ",";
    OFS = ",";
    seconds_in_day = 60 * 60 * 24;
}

NF != 13 { printf("Line %d, NF=%d, %s\n", NR, NF, $0) }

NR == 1 {
    if ($1 != "Date") printf("Bad $1 in header: '%s'\n", $1);
    if ($3 != "Phenibut Blinded") printf("Bad $3 in header: '%s'\n", $3);
    if ($4 != "Phenibut g") printf("Bad $5 in header: '%s'\n", $5);
    if ($5 != "Think Phenibut Today") printf("Bad $5 in header: '%s'\n", $5);
    if ($6 != "Think Phenibut Yesterday") printf("Bad $6 in header: '%s'\n", $6);
    printf( \
        "%-18s %-18s %-14s %-22s %-25s %-10s %-10s\n", \
        $1, $3, $4, $5, $6, "Match Today", "Match Yesterday" \
    );
}

NR != 1 && $3 != "False" && $3 != "True" {
    printf("Bad $3 = '%s' in line no. %d: %s", $3, NR, $0);
}

$3 == "True" {
    prev_epoch = epoch;
    epoch = org_date_to_epoch($1);
    if ($6 != "Not Applicable" && epoch - prev_epoch != seconds_in_day) {
        printf("Something bad happened: ")
    }
    prev_phenibut_g = $4
    if ($4 && $5 == "True" || !$4 && $5 == "False") {
        match_today = 1;
    }
    else if ($4 && $5 == "False" || !$4 && $5 == "True") {
        match_today = 0;
    }
    else { match_today = -1; }

    if ($6 != "Not Applicable") {
        if (prev_phenibut_g && $6 == "True" || !prev_phenibut_g && $6 == "False") {
            match_yesterday = 1;
        }
        else if ( \
            prev_phenibut_g && $6 == "False" || \
            !prev_phenibutg && $6 == "True" \
        ){
            match_yesterday = 0;
        }
        else {
            match_yesterday = -1;
        }
    }
    else {
        match_yesterday = -1;
    }
    
    printf( \
        "%-18s %-18s %-14s %-22s %-25s %-10d %-10d\n", \
        $1, $3, $4, $5, $6, \
        match_today, match_yesterday \
    );

    if (match_today == 1) matches_today += 1;
    if (match_today == 0) mismatches_today += 1;
    if (match_yesterday == 1) matches_yesterday += 1;
    if (match_yesterday == 0) mismatches_yesterday += 1;
}

NR != 1 && $3 != "True" && $3 != "False" {
    printf("%d, %s: weird value in $3: %s\n", NR, $1, $3)
}

NR != 1 && $3 == "True" && $4 != 0.5 && $4 != 0 && $4 != "?" {
    printf("%d, %s: weird value in $4: %s\n", NR, $1, $4)
}

function max(x, y) {
    if (x <= y) return y;
    return x;
}

function factorial(n,    result, i) {
    result = 1;
    for (i = 1; i <= n; ++i) {
        result *= i;
    }
    return result;
}
    

func choose(n, k) {
    return factorial(n) / factorial(n - k) / factorial(k);
}   

function calc_blinded_p_value( \
    correct, incorrect,      total, m, good_sequences, j, total_sequences \
) {
    total = correct + incorrect;
    m = max(correct, incorrect);
    good_sequences = 0;
    for (j = m; j <= total; ++j) {
        good_sequences += choose(total, j);
    }
    total_sequences = 2^total;
    return good_sequences / total_sequences;
}   

END {
    printf("\n");
    printf("%d matches today\n", matches_today);
    printf("%d mismatches today\n", mismatches_today);
    printf( \
        "today guessing p-value = %f\n", \
        calc_blinded_p_value(matches_today, mismatches_today) \
    );
    
    printf("\n");
    printf("%d matches yesterday\n", matches_yesterday);
    printf("%d mismatches yesterday\n", mismatches_yesterday);
    printf( \
        "today guessing p-value = %f\n", \
        calc_blinded_p_value(matches_yesterday, mismatches_yesterday) \
    );
}

