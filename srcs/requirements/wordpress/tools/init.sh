#!/bin/bash

set -e

if     [ -f /run/secrets/db_password ] 
    && [ -f /run/secrets/wp_admin_password ] 
    && [ -f /run/secrets/wp_editor_password ]; then
    DB_PASSWORD="$(cat /run/secrets/db_password)"
    WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
    WP_EDITOR_PASSWORD="$(cat /run/secrets/wp_editor_password)"
fi