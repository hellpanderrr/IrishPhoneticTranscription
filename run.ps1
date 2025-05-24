# Clear old token
Remove-Item env:ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue

# Route traffic to running ccr server
$env:ANTHROPIC_BASE_URL="http://127.0.0.1:3456/v1"
$env:ANTHROPIC_API_KEY="sk-ant-bypasslogincheck123456789"

# Set alias that CCR will understand as the default model from config.json
$env:ANTHROPIC_MODEL="claude-3-5-sonnet-latest"

# Launch client
claude --dangerously-skip-permissions
