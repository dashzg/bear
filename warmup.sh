#!/bin/bash

# Define API key and confirmation file path
API_KEY=$(env | grep -i "OPEN_BUTTON_TOKEN" | cut -d'=' -f2)
WARMUP_FILE="/dev/shm/warmup_complete"

echo "Using API Key: $API_KEY"
echo "Waiting for Automatic1111 to be fully ready..."

# Loop until Automatic1111 returns a 200 status, indicating readiness
until curl -k -s -o /dev/null -w "%{http_code}" https://127.0.0.1:7860/sdapi/v1/options \
    -H "Authorization: Bearer $API_KEY" | grep -q "200"; do
    echo "Automatic1111 not ready yet. Waiting..."
    sleep 5
done

echo "Automatic1111 is ready. Starting the warm-up process..."

# Load SD XL model and perform a warm-up generation
curl -k -X POST "https://127.0.0.1:7860/sdapi/v1/options" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"sd_model_checkpoint": "sd_xl_base_1.0.safetensors"}'

curl -k -X POST "https://127.0.0.1:7860/sdapi/v1/txt2img" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"prompt": "A simple warm-up scene", "steps": 10, "cfg_scale": 7.5, "width": 256, "height": 256}'

# Switch to Lino model
curl -k -X POST "https://127.0.0.1:7860/sdapi/v1/options" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"sd_model_checkpoint": "LinoBear_v1.safetensors"}'

# Mark warm-up as complete
touch "$WARMUP_FILE"
echo "Warm-up complete. Ready to receive requests."
