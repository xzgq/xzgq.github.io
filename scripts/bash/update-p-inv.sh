#!/usr/bin/env bash

for host in sh0 sh1; do
    ssh ecs-user@$host "sudo apt update -y; sudo apt upgrade -y"
done
