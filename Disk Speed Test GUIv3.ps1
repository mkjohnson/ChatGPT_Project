# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Disk Speed Test"
$form.Width = 300
$form.Height = 325

# Create a label to display a prompt to the user
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select the disk drive to test:"
$label.Width = 400
$label.Height = 30
$label.Left = 20
$label.Top = 20
$form.Controls.Add($label)

# Create a combobox to display the list of disk drives
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Width = 200
$comboBox.Height = 30
$comboBox.Left = 20
$comboBox.Top = 50
$comboBox.DropDownStyle = "DropDownList"

# Get the list of disk drives
$drives = Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID

# Add the disk drives to the combobox
foreach ($drive in $drives) {
    $comboBox.Items.Add($drive.DeviceID)
}
if ($comboBox.SelectedItem -eq $null) {
$comboBox.SelectedItem = "C:"
}
# Add the combobox to the form
$form.Controls.Add($comboBox)

# Create a label for the iterations
$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Enter the number of times to run the test (Default is 5):"
$label2.Width = 200
$label2.Height = 30
$label2.Left = 20
$label2.Top = 90
$form.Controls.Add($label2)

# Create a textbox for the user to enter the iterations
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Width = 30
$textBox.Height = 30
$textBox.Left = 20
$textBox.Top = 120
$form.Controls.Add($textBox)

# Create a button to perform the test
$button = New-Object System.Windows.Forms.Button
$button.Text = "Test Drive"
$button.Width = 100
$button.Height = 30
$button.Left = 20
$button.Top = 150
$form.Controls.Add($button)

# Create a label to display the results
$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Width = 400
$resultLabel.Height = 100
$resultLabel.Left = 20
$resultLabel.Top = 190
$form.Controls.Add($resultLabel)
# Create a button to cancel the test
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Width = 100
$cancelButton.Height = 30
$cancelButton.Left = 130
$cancelButton.Top = 150
$form.Controls.Add($cancelButton)

# Add an event handler for the cancel button
$cancelButton.Add_Click({
    $form.Close()
})


$button.Add_Click({TestDrive})
function TestDrive { 
   # Create a new window with a ProgressBar
$progressWindow = New-Object System.Windows.Forms.Form
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressWindow.Height = 100
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Step = 5
$progressBar.Size = New-Object System.Drawing.Size(250, 20)
$progressBar.Location = New-Object System.Drawing.Size(10, 10)
$progressWindow.Controls.Add($progressBar)
$progressWindow.Show()
    # Get the selected drive
    $selectedDrive = $comboBox.SelectedItem
    $iterations = $textBox.Text

    # Use the selected drive in the test file
    $file = "$($selectedDrive)\temp\testfile.dat"

    $size = 200MB
    $buffer = New-Object byte[] 1048576

    if ($iterations -eq "") {
        # Set a default value if no value is entered
        $iterations = 5
    }

    $read_speeds = @()
    $write_speeds = @()
    $iops_read = 0
    $iops_write = 0
    $total_time = 0
    # Create the test file
    New-Item -ItemType File -Path $file -Force | Out-Null

    for ($i = 0; $i -lt $iterations; $i++) {
        # Measure the write speed
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [IO.File]::Open($file, [IO.FileMode]::Create, [IO.FileAccess]::Write)

        # Write to the file
        for ($j = 0; $j -lt $size / $buffer.Length; $j++) {
            $fs.Write($buffer, 0, $buffer.Length)
            $iops_write++
        }
        $fs.Close()
        $stopwatch.Stop()
        $elapsed = $stopwatch.Elapsed
        $write_speeds += ($size / 1MB) / ($elapsed.TotalSeconds)
        $total_time += $elapsed.TotalSeconds
        # Measure the read speed
        $stopwatch.Restart()
        $fs = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::Read)
        while ($fs.Read($buffer, 0, $buffer.Length)) { 
            $iops_read++
        }
        $fs.Close()
        $stopwatch.Stop()
        $elapsed = $stopwatch.Elapsed
        $read_speeds += ($size / 1MB) / ($elapsed.TotalSeconds)
        $progressBar.PerformStep()

    $total_time += $elapsed.TotalSeconds
 
    }
   $progressWindow.Close()
    $iops_read = "{0:N2} " -f ($iops_read / $total_time)
    $iops_write = "{0:N2} " -f ($iops_write / $total_time)
    $totalIOPS = [decimal]$iops_write + [decimal]$iops_read
    $totalIOPS = "{0:N2} " -f $totalIOPS
    $testtime = "{0:N2}" -f $total_time
    $read_avg = "{0:N2} " -f ($read_speeds | Measure-Object -Average).Average
    $write_avg = "{0:N2} " -f ($write_speeds | Measure-Object -Average).Average

    $resultLabel.Text = "Disk read speed: $read_avg MB/s`nDisk write speed: $write_avg MB/s`nTotal IOPS: $totalIOPS`n`nResults are averaged over $iterations test(s).`n`nTest completed in $testtime seconds."
    $button.Text = "Test Again"
    $cancelButton.Text = "Close"
    # Clean up
    Remove-Item $file -Force
}
$form.ShowDialog()

