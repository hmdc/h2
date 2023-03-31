#!/usr/bin/env bash
terraform destroy -var="envid=$(terraform workspace show)"
