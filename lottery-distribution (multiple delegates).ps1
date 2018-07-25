#Script Var
$MinLskBalance = 1
$APIendpoint = "https://wallet.lisknode.io/api/"
$DelegateName = "liskpro.com","liberspirita","robinhood","4fryn","bloqspace.io"
$LSKunit = 100000000
$exportcsvpath = "c:/temp/distribution.csv"
$exportxmlpath = "c:/temp/distribution.xml"

#get delegate publickey
$DelegatePubKey = $DelegateName | %{(Invoke-WebRequest ($APIendpoint + "delegates/get?username=" + $_) | ConvertFrom-Json).delegate.publickey}

#get delegate voters list with at least $MinLskBalance balance (see script var)
$voters = $DelegatePubKey | %{(Invoke-WebRequest ($APIendpoint + "delegates/voters?publicKey=" + $_) | ConvertFrom-Json).accounts |  where-object {[int64]$_.balance -ge $($MinLskBalance*100000000)}}
$voters = ($voters |  group address | where-object Count -eq $($DelegateName.count)).Group | get-unique -asstring

#Weight cap calculation
$cap = [math]::Round($($voters | Measure-Object balance -Sum).sum / 100000000 / $voters.count)

#tickets distibution
$List = @()
$CurentTicket = 1 
foreach ($vote in $voters)
{
if ( [int64]$vote.balance / 100000000 -gt $cap)
	{ 
	$currentadr= @{
					Address = $vote.address
					Tickets = $CurentTicket..$($CurentTicket-1+$cap)
					nbtickets = $cap
				  }
	$ServiceObject = New-Object -TypeName PSObject -Property $currentadr
	$CurentTicket += $cap
	}
else
	{
	$vbalance = ([int64]$vote.balance / 100000000)
	$currentadr= @{
					Address = $vote.address
					Tickets = $CurentTicket..$($CurentTicket-1+([math]::Round($vbalance)))
					nbtickets = [math]::Round($vbalance)
				  }
	$ServiceObject = New-Object -TypeName PSObject -Property $currentadr
	$CurentTicket += [math]::Round($vbalance)
	}

$List += $ServiceObject
}

### Export CSV file for web publishing
$List | select-object Address,nbtickets,{$_.Tickets -join(' ')}|  Export-Csv $exportcsvpath

### Export XML file for import into drawing script
$List | Export-Clixml $exportxmlpath




