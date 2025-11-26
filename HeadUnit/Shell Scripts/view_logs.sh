#!/bin/bash

# View HeadUnit application logs

LOG_DIR="./logs"

if [ ! -d "$LOG_DIR" ]; then
    echo "Log directory not found: $LOG_DIR"
    exit 1
fi

case "${1:-}" in
    list)
        echo "Available log files:"
        ls -lh "$LOG_DIR"/*.log 2>/dev/null || echo "No log files found"
        ;;
    tail)
        if [ -z "$2" ]; then
            echo "Usage: $0 tail <AppName>"
            exit 1
        fi
        LOG_FILE="$LOG_DIR/$2.log"
        if [ -f "$LOG_FILE" ]; then
            tail -f "$LOG_FILE"
        else
            echo "Log file not found: $LOG_FILE"
            exit 1
        fi
        ;;
    cat)
        if [ -z "$2" ]; then
            echo "Usage: $0 cat <AppName>"
            exit 1
        fi
        LOG_FILE="$LOG_DIR/$2.log"
        if [ -f "$LOG_FILE" ]; then
            cat "$LOG_FILE"
        else
            echo "Log file not found: $LOG_FILE"
            exit 1
        fi
        ;;
    errors)
        if [ -z "$2" ]; then
            echo "Usage: $0 errors <AppName>"
            exit 1
        fi
        ERR_FILE="$LOG_DIR/$2.err.log"
        if [ -f "$ERR_FILE" ]; then
            cat "$ERR_FILE"
        else
            echo "Error log file not found: $ERR_FILE"
            exit 1
        fi
        ;;
    all)
        echo "=== All Application Logs ==="
        for log in "$LOG_DIR"/*.log; do
            if [ -f "$log" ]; then
                echo ""
                echo "=== $(basename $log) ==="
                tail -n 20 "$log"
            fi
        done
        ;;
    clean)
        echo "Cleaning log files..."
        rm -f "$LOG_DIR"/*.log
        echo "Log files cleaned"
        ;;
    *)
        echo "HeadUnit Log Viewer"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list                List all log files"
        echo "  tail <AppName>      Tail specific application log"
        echo "  cat <AppName>       Display specific application log"
        echo "  errors <AppName>    Display application error log"
        echo "  all                 Display last 20 lines of all logs"
        echo "  clean               Remove all log files"
        echo ""
        echo "Example:"
        echo "  $0 tail HomePage"
        echo "  $0 errors MediaPlayer"
        ;;
esac
