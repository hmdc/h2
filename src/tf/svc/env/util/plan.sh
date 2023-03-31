#!/usr/bin/env bash
terraform plan -var="envid=$(terraform workspace show)"
