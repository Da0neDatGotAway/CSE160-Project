$container = docker ps -q | Select-Object -First 1

if (-not $container) {
    Write-Error "No running Docker container found."
    exit 1
}

$file = $env:VSCODE_CURRENT_FILE

docker exec -it $container bash -lc "cd /home/workspace && make micaz sim && python /home/workspace/$file"

exit $LASTEXITCODE
