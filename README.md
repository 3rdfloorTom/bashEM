#bashEM

A seemingly random mixture of shell scripts for EM-related software packages. 

I have tried to group them to fit their application in handling files from different EM-related software packages. <br/> 
Almost all of these scripts invoke an IMOD function call, so it is best to have those on the PATH. <br/>
File parsing is generally performed with just AWK/sed/shell commands. <br/>
Plotting scripts typically use gnuplot and Eye of Gnome for display. <br/>
Additional dependencies will be explicitly stated in the usage for each script. <br/>

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

export PATH
```
For, C-shell users add this to your .cshrc (?) <br/>
```csh
foreach dir ('/path/to/bashEM'/*)
	set PATH=($dir:$PATH)
end
```
- Running of any (most?) scripts without any arguements should print out the usage (some better than others).


## Known issues
- AWK/sed are favorite square peg solutions to round hole problems.
- All of these scripts can be deemed as "works-in-progress". Use if you find them helpful, but don't have too high of hopes for them. 
- I am not great at using git.

