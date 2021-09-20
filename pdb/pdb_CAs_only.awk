#!/usr/bin/awk -f

{
if ($3 == "CA") 
	{
		printf("%4s%7i%5s%4s%2s%4i    %8.3f%8.3f%8.3f%6.2f%6.2f%12s    \n",$1, $2, $3, $4, $5, $6, $7, $8, $9,$10, $11, $12)
	} 

else if ( $1=="TER" ) 
	{
	printf "TER\n"
	} 
}

