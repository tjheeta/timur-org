#!/bin/sh
set -o errexit

http --form POST http://10.0.0.175:4000/api/v1/documents X-api-client:de4927d9-a099-4ec8-bb99-4f69888acb34 X-api-key:somekey file@README.org
