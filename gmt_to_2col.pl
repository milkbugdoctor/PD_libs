#!/usr/bin/perl

open ("input", $ARGV[0])|| die "sorry \n";
open ("output", ">$ARGV[1]") || die "sorry I said \n";

while (<input>){
      			grep(s/\s+$//,$_);
                  @input= split (/\t/,$_);
                  $x=@input;
                  for ($i=1; $i<$x; $i++){
                  			print output "$input[$i]\t$input[0]\n";
                                        }
                  }



