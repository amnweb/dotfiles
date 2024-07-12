Register-ArgumentCompleter -Native -CommandName ollama -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    # Get the help output and extract command names
    $helpOutput = & ollama help
    $commands = $helpOutput | ForEach-Object {
        if ($_ -match '^\s+(\w+)\s+') {
            $matches[1]
        }
    }
    $wordToComplete = $wordToComplete -replace '"', '""'
    $commandAst = $commandAst.ToString() -replace '"', '""'

    # Create an array to hold the completion results
    $results = @()

    foreach ($command in $commands) {
        if ($command -like "$wordToComplete*") {
            $results += [System.Management.Automation.CompletionResult]::new($command, $command, 'ParameterValue', $command)
        }
    }
    # Return results if there are matches, otherwise return $null
    if ($results.Count -gt 0) {
        $results
    } else {
        # Return $null explicitly to prevent fallback to file or folder names
        $null
    }
}