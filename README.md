# bashEM

A seemingly random mixture of shell scripts for EM-related software packages. 

I have tried to group them to fit their application in handling files from different EM-related software packages. <br/> 
Almost all of these scripts invoke an IMOD function call, so it is best to have those on the PATH. <br/>
Metadata parsing is generally performed with just awk/shell commands. <br/>
Plotting scripts typically use gnuplot and Eye of Gnome for display. <br/>

## Abbreviations list
- dyn	-	Dynamo
-  e2	-	EMAN2
- emC	-	emClarity
- rln	-	RELION
- wrp	-	Warp/M

## How to run
- Add the directories to your PATH for ease of use by adding something like this to your .bashrc <br/>
```bash
for dir in '/path/to/bashEM'*/
do  
	PATH="$dir:$PATH" 
done  
export PATH;
```
<br/>
- Running of any (most?) scripts without any command-line arguements should printout the usage (some better than others).


## Known issues
- All of these scripts can be deemed as "works-in-progress", so use if you find them helpful but don't have too high of hopes for them. 
- I am not great the using git.

