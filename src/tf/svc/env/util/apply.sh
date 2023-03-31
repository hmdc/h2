#!/usr/bin/env bash
terraform apply -var="envid=$(terraform workspace show)"
