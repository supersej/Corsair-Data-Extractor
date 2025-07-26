# Create MQTT discovery sensors for Corsair hardware

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

# Sensor-definitions
$sensors = @(
    @{
        id = "temp1"; name = "Corsair Temp 1"; topic = "corsair/sensors/temp1"
        unit = "°C"; device_class = "temperature"; icon = "mdi:thermometer"
    },
    @{
        id = "temp2"; name = "Corsair Temp 2"; topic = "corsair/sensors/temp2"
        unit = "°C"; device_class = "temperature"; icon = "mdi:thermometer"
    },
    @{
        id = "fan1"; name = "Corsair Fan 1"; topic = "corsair/sensors/fan1"
        unit = "RPM"; device_class = "power"; icon = "mdi:fan"
    },
    @{
        id = "fan2"; name = "Corsair Fan 2"; topic = "corsair/sensors/fan2"
        unit = "RPM"; device_class = "power"; icon = "mdi:fan"
    },
    @{
        id = "fan3"; name = "Corsair Fan 3"; topic = "corsair/sensors/fan3"
        unit = "RPM"; device_class = "power"; icon = "mdi:fan"
    }
)

# Send discovery-payload to MQTT broker
foreach ($sensor in $sensors) {
    $object_id = $sensor.id
    $configTopic = "$discoveryPrefix/sensor/corsair_$object_id/config"

    $payload = @{
        name = $sensor.name
        state_topic = $sensor.topic
        unit_of_measurement = $sensor.unit
        device_class = $sensor.device_class
        icon = $sensor.icon
        unique_id = "corsair_$object_id"
        availability_topic = "corsair/sensors/status"

    } | ConvertTo-Json -Depth 5

    & "$mqttExe" -h $broker -p $port -t $configTopic -m $payload -u $mqtt_user -P $mqtt_pass
}
