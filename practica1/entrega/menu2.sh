#!/bin/bash

# Prompt for analysis
while true; do
    read -rp "Did you just perform an analysis? (yes or no): " user_input
    case "$user_input" in
        [Yy]*)
            if [ "$analysis_done" = "TRUE" ]; then
                echo "The analysis has been done."
                break
            else
                read -rp "The analysis hasn't been done. Would you like to exit? (yes or no): " exit_input
                case "$exit_input" in
                    [Yy]*)
                        exit 1
                        ;;
                    [Nn]*)
                        break
                        ;;
                    *)
                        echo "Please enter 'yes' or 'no'."
                        ;;
                esac
            fi
            ;;
        [Nn]*)
            echo "Loading analysis from a file..."
            # Add your code to load the analysis from a file here
            break
            ;;
        *)
            echo "Please enter 'yes' or 'no'."
            ;;
    esac
done

# Add the rest of your script logic here
