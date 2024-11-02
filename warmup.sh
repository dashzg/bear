#!/bin/bash

# Define API key and confirmation file path
API_KEY=$(env | grep -i "OPEN_BUTTON_TOKEN" | cut -d'=' -f2)
WARMUP_FILE="/dev/shm/warmup_complete"
LOG_FILE="/workspace/warmup.log"

echo "Using API Key: $API_KEY" | tee -a "$LOG_FILE"

# Initial delay to allow Automatic1111 services to start
echo "Initial wait: Giving 10 seconds for Automatic1111 to start up..." | tee -a "$LOG_FILE"
sleep 10

# Loop until "Lino" is found in the response from sdapi/v1/sd-models
until curl -k -s -H "Authorization: Bearer $API_KEY" https://127.0.0.1:7860/sdapi/v1/sd-models | grep -q "Lino"; do
    echo "Waiting for Automatic1111 to be ready with Lino model available..."
    sleep 5
done

# Short pause to ensure model is fully loaded
echo "Automatic1111 is ready. Waiting 10 seconds before warm-up." | tee -a "$LOG_FILE"
sleep 10

# Load SD XL model and perform a warm-up generation
echo "Loading SD XL model and performing warm-up generation..." | tee -a "$LOG_FILE"
curl -k -X POST "https://127.0.0.1:7860/sdapi/v1/options" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"sd_model_checkpoint": "sd_xl_base_1.0.safetensors"}' >> "$LOG_FILE" 2>&1

curl -k -X POST "https://127.0.0.1:7860/sdapi/v1/txt2img" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"prompt": "A simple warm-up scene", "steps": 10, "cfg_scale": 7.5, "width": 256, "height": 256}' >> "$LOG_FILE" 2>&1

# Load Lino model
echo "Switching to Lino model..." | tee -a "$LOG_FILE"
curl -k -X POST "https://127.0.0.1:7860/sdapi/v1/options" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"sd_model_checkpoint": "LinoBear_v1.safetensors"}' >> "$LOG_FILE" 2>&1

# Mark warm-up as complete
touch "$WARMUP_FILE"
echo "Warm-up complete. Ready to receive requests." | tee -a "$LOG_FILE"
