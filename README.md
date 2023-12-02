# Network Log Analysis Script

This is a network log analysis script implemented using bash script. The script is named `log_sum.sh`.
If you're unable to run the script, please try modifying the permission of your local copy of the script
with `chmod +x log_sum.sh`.
<br> <br>
The standard run procedure for executing `log_sum.sh` is: 
<br> <br>
`./log_sum.sh [-L N] [-e] (-c|-2|-r|-F|-t) <filename>`
<br> <br>
Optional options:
<br>
`-L`: Limit the number of results to `N` (Argument `N` required)
<br>
`-e`: Check the IP address to see if the domain name has been blacklisted
<br> <br>
Required options:
<br>
`-c`: Which IP address makes the most number of connection attempts?
<br>
`-2`: Which address makes the most number of successful attempts?"
<br>
`-r`: What are the most common results codes and where do they come from?
<br>
`-F`: What are the most common result codes that indicate failure (no auth, not found etc) and where do they come from?
<br>
`-t`: Which IP number get the most bytes sent to them?
<br> <br>
`<filename>` refers to the logfile. If `-` is given as a filename, or no filename is given, then _**standard input**_ should be read. 
This allows the script to be used in a pipeline.
