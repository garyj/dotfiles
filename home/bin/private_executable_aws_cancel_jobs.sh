#!/usr/bin/env bash

# Check if the job queue name is provided as an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <job-queue-name>"
  exit 1
fi

job_queue_name="$1"

for i in $(aws batch list-jobs --job-queue "$job_queue_name" --job-status runnable --output text --query "jobSummaryList[*].[jobId]"); do
  echo "Cancel Job: $i"
  aws batch cancel-job --job-id $i --reason "Cancelling job."
  echo "Job $i canceled"
done
