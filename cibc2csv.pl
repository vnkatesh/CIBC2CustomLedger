#!/opt/local/bin/perl -W
use strict;
use warnings;

my $file = '../cibc.csv';
open my $info, $file or die "Could not open $file: $!";

my $notdonefile = '>../notdone.csv';
open my $ndinfo, $notdonefile or die "Could not open $file: $!";

while( my $line = <$info>)  {
    chomp($line);
    my ($date,$desc,$value) = split(',',$line);
    chomp($value);
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
    print $date." $keyWord\n";
    print "\t$expenseWord\t\t\$$value\t;$keyWord\n";
    print "\tAssets:Checking\t\t\t\t\t\t$-$value\n\n";
}

sub processDesc{
    my $desc = shift;
    my ($keyWord, $expenseWord) = ("","");
    if($desc =~ /Point of Sale - INTERAC RETAIL PURCHASE \d{12} (.*)/g) {
        #print $1."\n";
        #return ($keyWord, $expenseWord);
        return ("Key Word", "Expense:TestExpense:Dummy");
    }
    return ($keyWord, $expenseWord);
}

close $ndinfo;
close $info;

exit 0;
