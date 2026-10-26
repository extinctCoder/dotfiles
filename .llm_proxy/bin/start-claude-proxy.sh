#!/bin/bash

# Start LiteLLM Proxy for Claude

set -e

# Unset SSL_CERT_FILE for proxy to use system certs
unset SSL_CERT_FILE
unset REQUESTS_CA_BUNDLE

# Configuration
CONFIG_FILE="$HOME/.llm_proxy/config/litellm-config.yaml"
PORT="${LITELLM_PORT:-8082}"
LOG_FILE="${LITELLM_LOG_FILE:-$HOME/.cache/litellm.log}"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable not set"
    exit 1
fi

# Start the proxy
echo "Starting LiteLLM proxy on port $PORT..."
echo "Config: $CONFIG_FILE"
echo "Log: $LOG_FILE"
echo ""

litellm --config "$CONFIG_FILE" --port "$PORT" >> "$LOG_FILE" 2>&1 &
PROXY_PID=$!

echo "✓ Proxy started with PID $PROXY_PID"
echo "✓ Listening on http://localhost:$PORT"
echo ""
echo "To stop: kill $PROXY_PID"
echo "To view logs: tail -f $LOG_FILE"

# Keep process in foreground
wait $PROXY_PID