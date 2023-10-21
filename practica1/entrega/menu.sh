#!/bin/bash

while true; do
    # Prompt for the first file
    read -rp "Enter the name of the first file: " file1

    # Check if the first file exists
    if [ ! -f "$file1" ]; then
        read -rp "The first file does not exist. Do you want to re-enter the file name? (y/n): " reenter
        case "$reenter" in
            [Yy]*)
                continue
                ;;
            [Nn]*)
                exit 1
                ;;
            *)
                echo "Please enter 'y' for yes or 'n' for no."
                ;;
        esac
    else
        break
    fi
done

while true; do
    # Prompt for the second file
    read -rp "Enter the name of the second file: " file2

    # Check if the second file exists
    if [ ! -f "$file2" ]; then
        read -rp "The second file does not exist. Do you want to re-enter the file name? (y/n): " reenter
        case "$reenter" in
            [Yy]*)
                continue
                ;;
            [Nn]*)
                exit 1
                ;;
            *)
                echo "Please enter 'y' for yes or 'n' for no."
                ;;
        esac
    else
        break
    fi
done

# Prompt for the third file
while true; do
    read -rp "Enter the name of the third file (must end with .freq and should not exist): " file3

    if [[ "$file3" != *".freq" ]]; then
        echo "The third file must end with .freq."
    elif [ -e "$file3" ]; then
        read -rp "The file already exists. Do you want to overwrite it? (y/n): " overwrite
        case "$overwrite" in
            [Yy]*)
                break
                ;;
            [Nn]*)
                continue
                ;;
            *)
                echo "Please enter 'y' for yes or 'n' for no."
                ;;
        esac
    else
        break
    fi
done

echo "File names entered:"
echo "First file: $file1"
echo "Second file: $file2"
echo "Third file: $file3"
