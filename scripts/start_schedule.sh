#!/usr/bin/env bash

echo "Running Schedule..."
php /var/www/artisan schedule:work > /dev/null


