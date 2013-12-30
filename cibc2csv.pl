#!/opt/local/bin/perl -W
use strict;
use warnings;

my $notdonefile = '>../notdone.csv';
open my $ndinfo, $notdonefile or die "Could not open $notdonefile: $!";
my $donefile = '>../done.ldg';
open my $doneinfo, $donefile or die "Could not open $donefile: $!";

open( FILE, "<../cibc.csv" )
    or die( "Can't open file cibc.csv $!" );

my @lines = reverse <FILE>;
close FILE;
foreach my $line (@lines) {
    chomp($line);
    my ($date,$desc,$value) = split(',',$line);
    $value =~ s/\s*$//g;
    if ($value eq "" || $line !~ /Point of Sale/) {
        print $ndinfo $line."\n";
        next;
    }
    my ($keyWord, $expenseWord) = &processDesc($desc);
    if($keyWord eq "" || $expenseWord eq "") {
        print $ndinfo $line."\n";
        next;
    }
    $date =~ s/-/\//g;
    print $doneinfo $date." $keyWord\n";
    print $doneinfo "\t$expenseWord\t\t\t\t\$$value\t;$keyWord\n";
    print $doneinfo "\tAssets:Checking\t\t\t\t\t\t\t\t\$-$value\n\n";
}

sub processDesc{
    my $desc = shift;
    if($desc =~ /Point of Sale - INTERAC RETAIL PURCHASE \d{12} (.*)/) {
        my $matched = $1;
        $matched =~ s/\s*$//g;
        my $length = length($matched);
        my $lastchar = lc(substr $matched, -1);
        if ($lastchar =~ /[a-z]/) {
            return &processMatchedWord($matched);
        } else {
            #$matched =~ s/\s+\w+$//;
            my @splitWords = split(/ +/, $matched);
            pop(@splitWords);
            $matched = join(" ", @splitWords);
            return &processMatchedWord($matched);
        }
        #return ("Key Word", "Expense:TestExpense:Dummy");
    }
    return ("", "");
}

sub processMatchedWord {
    my ($keyWord, $expenseWord, $regexInput) = ("","","");
    my $matched = shift;
    my @splitWords = split(/ +/, $matched);
    if(scalar(@splitWords)>2) {
        #if first two sum is greater than 6; then good, else bad. include until end?
        if((length($splitWords[0])+length($splitWords[1]))>6) {
            #greater than 6. Use the first two.
            $keyWord = $splitWords[0]." ".$splitWords[1];
            ($keyWord, $regexInput) = &getKeyWordRegex($keyWord);
            $expenseWord = &SearchForKeyWord($regexInput);
            return ($keyWord, $expenseWord);
        } else {
            #not greater than 6. Add until greater than 6 or runs out of words to ad..
            $keyWord = $splitWords[0]." ".$splitWords[1];
            my $lengthArray = scalar(@splitWords);
            my $i=2;
            for(; $i<$lengthArray; $i++) {
                $keyWord .= " ".$splitWords[$i];
                if(length($keyWord)>8) {
                    last;
                }
            }
            ($keyWord, $regexInput) = &getKeyWordRegex($keyWord);
            $expenseWord = &SearchForKeyWord($regexInput);
            return ($keyWord, $expenseWord);
        }
    } else  {
        $keyWord = $matched;
        ($keyWord, $regexInput) = &getKeyWordRegex($keyWord);
        $expenseWord = &SearchForKeyWord($regexInput);
        return ($keyWord, $expenseWord);
    }

}

sub getKeyWordRegex {
    my $keyWord = shift;
    my $regexInput = "";
    $keyWord = (lc($keyWord));
    $keyWord =~ s/([\w']+)/\u\L$1/g;
    $regexInput = "Expenses ".$keyWord;
    $regexInput =~ s/ /\.\*/g;
    $regexInput = lc($regexInput);
    return ($keyWord, $regexInput);
}

sub SearchForKeyWord {
    my $regexInput = shift;
    my $expenseWord = "";

    open( FILE, "<../finance.ldg" )
        or die( "Can't open file finance.ldg $!" );

    my @lines = reverse <FILE>;
    close FILE;
    foreach my $line (@lines) {
        chomp($line);
        $line =~ s/\s*$//g;
        if($line =~ /($regexInput)/gi) {
            if($line =~ /gift/i) {
                #TODO fix.
                next;
            }
            my $matched = $1;
            $matched =~ s/\s*$//g;
            return (split(/[\t ]+/, $matched))[0];
        }
    }
    return $expenseWord;
}

close $ndinfo;
close $doneinfo;

exit 0;
