
# Get the latest CSV file from the Corsair Logger, read the last line, and publish the data to MQTT.

# Load secrets
Get-Content -Path "secrets.json" | ConvertFrom-Json | ForEach-Object {
    $broker = $_.mqtt_broker
    $port = $_.mqtt_port
    $mqtt_user = $_.mqtt_user
    $mqtt_pass = $_.mqtt_password
}

# Load settings
Get-Content -Path "settings.ps1" | ForEach-Object {
    if ($_ -match '^\s*\$csv_folder\s*=\s*"([^"]+)"') {
        $csv_folder = $matches[1]
    }
    if ($_ -match '^\s*\$mqttExe\s*=\s*"([^"]+)"') {
        $mqttExe = $matches[1]
    }
    if ($_ -match '^\s*\$loop_timeout\s*=\s*(\d+)') {
        $loop_timeout = [int]$matches[1]
    }
}

try {$all_csv_files = gci $csv_folder -filter "*.csv"}
catch {write-error "Found no csv files in $($csv_folder) to process"; break}

$latest_csv_file = $all_csv_files | sort -Property LastWriteTime -Descending | select -first 1
$old_csv_files = (compare-object $all_csv_files $latest_csv_file | where-object {$_.Sideindicator -eq "<="}).Inputobject
if ($old_csv_files.fullname.count -gt 0) {
  try {remove-item $old_csv_files.fullname}
  catch {}
}


#Read first line
$csv_header = Get-Content $latest_csv_file | select -first 1

$TopicMap = @{
  Fan1 = "corsair/sensors/fan1"
  Fan2 = "corsair/sensors/fan2"
  Fan3 = "corsair/sensors/fan3"
  Fan4 = "corsair/sensors/fan4"
  Fan5 = "corsair/sensors/fan5"
  Fan6 = "corsair/sensors/fan6"
  Temp1 = "corsair/sensors/temp1"
  Temp2 = "corsair/sensors/temp2"
  Temp3 = "corsair/sensors/temp3"
  Temp4 = "corsair/sensors/temp4"
}

#Loop forever
while (1) {
    #measure-command {
        try {$all_csv_files = gci $csv_folder -filter "*.csv"}
	catch {write-error "Found no csv files in $($csv_folder) to process"; break}
	$latest_csv_file = $all_csv_files | sort -Property LastWriteTime -Descending | select -first 1

        $last_line = (get-content $latest_csv_file -Tail 1) -replace ("°C","") -replace ("RPM","")
	$csv_header = $csv_header -replace ("Commander PRO Temp #","Temp") -replace ("Commander PRO Fan #","Fan")
        $make_csv = $csv_header + "`n"+$last_line
        $reading = $make_csv | convertfrom-csv
        $reading | Add-Member -MemberType NoteProperty -Name "Filesize" -Value (get-item $latest_csv_file).Length
        $reading | Add-Member -MemberType NoteProperty -Name "Filename" -Value (get-item $latest_csv_file).Name
        $reading

	"Updating MQTT"
""
	foreach ($key in $reading.PSObject.Properties.Name) {
	  $value = $reading.$key
	  if ($topicMap.Containskey($key)) {
	    $topic = $topicMap[$key]
	    & "$mqttexe" -h $broker -p $port -t $topic -m "$value" -u $mqtt_user -P $mqtt_pass
	  }
	}
	"Waiting $($loop_timeout) seconds before next upgrade"
        start-sleep -Seconds $loop_timeout
    #}
}



