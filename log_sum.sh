#! /bin/bash

function usage() {
    echo
    echo "The usage of the log_sum.sh script is as follows:"
    echo
    echo "log_sum.sh [-L N] [-e] (-c|-2|-r|-F|-t) <filename>"
    echo
    echo "Optional options"
    echo "-L: Limit the number of results to N (Argument N required)"
    echo "-e: Check the IP address to see if the domain name has been blacklisted"
    echo
    echo "Required options"
    echo "-c: Which IP address makes the most number of connection attempts?"
    echo "-2: Which address makes the most number of successful attempts?"
    echo "-r: What are the most common results codes and where do they come from?"
    echo "-F: What are the most common result codes that indicate failure (no auth, not found etc) and where do they come from?"
    echo "-t: Which IP number get the most bytes sent to them?"
    echo
    echo "<filename> refers to the logfile. If '-' is given as a filename, or no filename is given, then standard input should be read. This enables the script to be used in a pipeline."
    echo
}

old=$IFS

if [[ ${@: -1} == "-L" || ${@: -1} =~ ^[0-9]+$ ]]; then
    usage
elif [[ ${@: -1} == "-" || ${@: -1} == $0 || ${@: -1} == "-"? ]]; then
    if [[ -t 0 ]]; then
        usage
        exit 1
    fi
    if [ -f "tmp.txt" ]; then
        rm "tmp.txt"
    fi
    while IFS= read -r line; do
        echo -e "$line" >> "tmp.txt"
    done
    logs=`cat "tmp.txt"`
    rm "tmp.txt"
else
    log_path=${@: -1}
    logs=`cat $log_path`
fi

blacklist_path="dns.blacklist.txt"

n=-1
blacklist_check=0
c2rFt=0
output=""

while getopts :L:c2rFte option; do
    case $option in
        L)
            n=$OPTARG
            ;;
        c)
            if [ $c2rFt -eq 0 ]; then
                c2rFt=1
                output=`echo "$logs" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -n | uniq -c | sort -nr | awk '{ printf "%s\t%s\n", $2, $1 }'`
            else
                usage
                exit 1
            fi
            ;;
        2)
            if [ $c2rFt -eq 0 ]; then
                c2rFt=2
                output=`echo -e "$logs" | grep -Po '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*? 2[0-9]{2} ' | grep -Eow '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|2[0-9]{2}' | awk '{ if (NR % 2 == 1) { line=$0 } else { printf("%s\t%s\n", $0, line) } }' | awk '{ printf "%s\t%s\n", $2, $1 }' | sort -n | uniq -c | sort -nr | awk '{ printf "%s\t%s\n", $2, $1 }'`
            else
                usage
                exit 1
            fi
            ;;
        r)
            if [ $c2rFt -eq 0 ]; then
                c2rFt=3
                output=`echo -e "$logs" | grep -Po '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*? [1-5][0-9]{2} ' | grep -Eow '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[1-5][0-9]{2}' | awk '{ if (NR % 2 == 1) { line=$0 } else { printf("%s\t%s\n", $0, line) } }' | awk '{ printf "%s\t%s\n", $2, $1 }' | sort -n | uniq -c | sort -nr | sort -r -k 3 | awk '{ printf "%s\t%s\n", $3, $2 }'`
            else
                usage
                exit 1
            fi
            ;;
        F)
            if [ $c2rFt -eq 0 ]; then
                c2rFt=4
                output=`echo -e "$logs" | grep -Po '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*? [4-5][0-9]{2} ' | grep -Eow '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[4-5][0-9]{2}' | awk '{ if (NR % 2 == 1) { line=$0 } else { printf("%s\t%s\n", $0, line) } }' | awk '{ printf "%s\t%s\n", $2, $1 }' | sort -n | uniq -c | sort -nr | sort -r -k 3 | awk '{ printf "%s\t%s\n", $3, $2 }'`
            else
                usage
                exit 1
            fi
            ;;
        t)
            if [ $c2rFt -eq 0 ]; then
                c2rFt=5
                if [ -f "tmp.txt" ]; then
                    rm "tmp.txt"
                fi
                echo -e "$logs" | while IFS=\n read line; do
                    IFS='"'
                    read ip_chunk request status_bytes website remaining <<< "$line"
                    if [[ "$status_bytes" == *"-"* ]]; then
                        continue
                    fi
                    ip=`echo "$ip_chunk" | grep -Po '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
                    size=`echo "$status_bytes" | grep -Po '(?<=[1-5][0-9]{2}.)[^ \n]*'`
                    echo -e "$ip $size" >> "tmp.txt"
                    IFS=$old
                done
                temp=`cat "tmp.txt" | sort -nr`
                rm "tmp.txt"
                declare -A result_table
                while read i s; do
                    if [[ -v "result_table[$i]" ]]; then
                        existing_value=${result_table[$i]}
                        result_table[$i]=$(( $existing_value + $s ))
                    else
                        result_table[$i]=$s
                    fi
                done <<< $temp
                for key in ${!result_table[@]}; do
                    value=${result_table[$key]}
                    echo -e "$key $value" >> "tmp.txt"
                done
                output=`cat tmp.txt | awk '{ printf "%s\t%s\n", $2, $1 }' | sort -nr | awk '{ printf "%s\t%s\n", $2, $1 }'`
                rm "tmp.txt"
            else
                usage
                exit 1
            fi
            ;;
        e)
            blacklist_check=1
            ;;
        *)
            usage
            exit 1 
            ;;
    esac
done

if [[ $output == "" ]]; then
    usage
    exit 1
fi

if [ $n -ne -1 ]; then
    output=`echo "$output" | head -n $n`
fi

if [ $blacklist_check -eq 1 ]; then
    if [ -f "output.txt" ]; then
        rm "output.txt"
    fi
    if [ ! -f "searched_dns.txt" ]; then
        touch "searched_dns.txt"
    fi
    dns_blacklist=`cat $blacklist_path`
    searched_dns=`cat "searched_dns.txt"`
    echo "$output" | while IFS=\n read ol; do
        ip=`echo "$ol" | grep -Po '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
        if [[ "$ip" == "" ]]; then
            echo "Error: Empty ip, something wrong :("
            continue
        fi
        if [[ $searched_dns == *"$ip"* ]]; then
            dns=`echo "$searched_dns" | grep "$ip" | grep -Po '(?<= )[a-zA-Z0-9.-]*'`
        else
            dns=`nslookup $ip | awk '{ print }' | grep 'in-addr' | grep -Po '(?<== )[a-zA-Z0-9.-]*' | sed 's/\.$//' | sed 's/\n/ /g'`
            if [[ "$dns" == "" ]]; then
                dns="NONE"
            fi
            echo -e "$ip $dns" >> "searched_dns.txt"
        fi
        if [[ "$dns" != "NONE" ]]; then
            if [[ $dns_blacklist == *"$dns"* ]]; then
                echo -e "$ol\t*blacklisted*" >> "output.txt"
            else
                echo -e "$ol" >> "output.txt"
            fi
        else
            echo -e "$ol" >> "output.txt"
        fi
    done
    output=`cat "output.txt"`
    rm "output.txt"
fi

echo "$output"
