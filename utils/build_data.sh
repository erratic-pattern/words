#/bin/bash
D=$1
eng_filter='^[a-z'\''-]+[a-rt-z-]{2}$'
shift
gb_opt() { echo perl ./construct_grams.pl -m \"$1\"${2:+ -f \"$2\"}${3:+ -e \"$3\"} \"$D/googlebooks-$1-\"*\".csv\"; }
d_opt()  { echo perl ./construct_grams.pl -m \"$1\"${2:+ -e \"$2\"}${3:+ -f \"$3\"}  \"dict/$1\"; }
{
    gb_opt eng-1M "$eng_filter"
    gb_opt eng-all "$eng_filter"
    gb_opt eng-fiction "$eng_filter"
    gb_opt eng-gb "$eng_filter"
    gb_opt eng-us "$eng_filter"
    gb_opt fre
    gb_opt ger
    gb_opt heb
    gb_opt rus
    gb_opt spa
    d_opt irish latin1
    d_opt german-medical latin1
    d_opt bulgarian cp-1251
    d_opt catalan
    d_opt swedish latin1
    d_opt brazilian latin1
    d_opt canadian-english-insane utf-8 "$eng_filter"
    d_opt manx latin8
    d_opt italian
    d_opt ogerman latin1
    d_opt portuguese latin1
    d_opt polish 
    d_opt gaelic latin8
    d_opt finnish latin1
} | parallel