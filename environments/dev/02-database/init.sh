#!/bin/bash

terraform init \
    -backend-config="bucket=${TF_VAR_bucket}" \
    -backend-config="key=${TF_VAR_dev_database_key}" \
    -backend-config="region=${TF_VAR_region}"