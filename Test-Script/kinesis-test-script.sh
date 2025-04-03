#!/bin/bash

# Validate and use input argument for number of records
NUM_RECORDS=${1:-5}
if ! [[ "$NUM_RECORDS" =~ ^[0-9]+$ ]]; then
  echo "Error: You must pass a number as an argument. Example: ./send.sh 10"
  exit 1
fi

STREAM_NAME="Kinesis-stack-DataStream-3XPOY2eELP3Q" # Replace with the name of your stream
echo "Sending $NUM_RECORDS records to stream: $STREAM_NAME"

for ((i = 1; i <= NUM_RECORDS; i++)); do
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 20% chance of generating an invalid payload
  if (( RANDOM % 100 < 20 )); then
    PAYLOAD="user: bob | event: fail | timestamp: $TIMESTAMP"
    echo "Sending INVALID record $i"
  else
    USER="user_$RANDOM"
    PAYLOAD="{\"event\":\"login\",\"user\":\"$USER\",\"timestamp\":\"$TIMESTAMP\"}"
    echo "Sending VALID record $i: $PAYLOAD"
  fi

  aws kinesis put-record \
    --stream-name "$STREAM_NAME" \
    --partition-key "test-$i" \
    --data "$(echo -n "$PAYLOAD" | base64)"

  SLEEP_DURATION=$((RANDOM % 5 + 1))
  echo "Sleeping for $SLEEP_DURATION seconds...\n"
  sleep $SLEEP_DURATION
done

echo -e "\n Finished sending $NUM_RECORDS total records. Check S3 for raw/ and unformatted/ folders."
