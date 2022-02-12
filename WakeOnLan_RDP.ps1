# Wake on LAN target MAC Address and connect to IP Server via RDP after 30 seconds
# ================================================================================
$Server = '10.1.1.1'
$MacAdress = '00:0A:00:00:AA:A0'
$Seconds = 30
# ================================================================================

function Invoke-WakeOnLan
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [ValidatePattern('^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$')]
    [string[]]
    $MacAddress 
  )
 
  begin
  {
    # instantiate a UDP client:
    $UDPclient = [System.Net.Sockets.UdpClient]::new()
  }
  process
  {
    foreach($_ in $MacAddress)
    {
      try {
        $currentMacAddress = $_
        
        # get byte array from mac address:
        $mac = $currentMacAddress -split '[:-]' |
          # convert the hex number into byte:
          ForEach-Object {
            [System.Convert]::ToByte($_, 16)
          }
 
        $packet = [byte[]](,0xFF * 102)
        
        6..101 | Foreach-Object { 
          $packet[$_] = $mac[($_ % 6)]
        }
        
        #endregion
        
        $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
        
        $null = $UDPclient.Send($packet, $packet.Length)
        Write-Verbose "Sending WOL Packet to $currentMacAddress..."
      }
      catch 
      {
        Write-Warning "Unable to send WOL packet to ${mac}: $_"
      }
    }
  }
  end
  {
    # release the UDF client and free its memory:
    $UDPclient.Close()
    $UDPclient.Dispose()
  }
}

# ======================== CORE ========================
Invoke-WakeOnLan -MacAddress $MacAdress
Write-Host "Waking up MACAdress $MacAdress"
Write-Host "Sleeping for $Seconds seconds"
Start-Sleep -s $Seconds
Write-Host "Connecting via RDP to $Server with IP $Server"
mstsc /v:$Server
