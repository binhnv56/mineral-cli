#!/bin/bash

EXPECTED_ARGS=1

# Check if the number of arguments is not equal to the expected number
if [ $# -ne $EXPECTED_ARGS ]; then
    echo "Error: Expected $EXPECTED_ARGS arguments, but got $#"
    echo "Usage: $(basename $0) private_key"
    exit 1
fi

private_key=$1

run_mineral () {
	docker_id=$(docker ps | grep "binhnv56/mineral" | awk '{ print $1 }')
	docker stop $docker_id >> /dev/null 2>&1
	docker container rm $docker_id >> /dev/null 2>&1
	docker run -d -e WALLET=${private_key} binhnv56/mineral >> /dev/null 2>&1
	mineral_id=$(docker ps | grep "binhnv56/mineral" | awk '{ print $1 }')
	echo $mineral_id  # Output mineral_id
}

fail_check () {
	mineral_id=$1
	if docker logs --tail 20 $mineral_id 2>&1 | grep -q "Error" >> /dev/null 2>&1; then
		return 1
	else
		return 0
	fi
}

echo "Starting Mineral..."
mineral_id=$(run_mineral)
echo "Started Mineral. Looping to check status of Mineral..."

while true; do
    if ! fail_check $mineral_id; then
		echo "Mineral failed. Restarting..."
		mineral_id=$(run_mineral)
		echo "Started Mineral. Looping to check status of Mineral..."
    fi
    sleep 10
done
