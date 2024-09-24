# from https://github.com/awsdocs/aws-doc-sdk-examples/blob/main/python/example_code/kinesis/streams/kinesis_stream.py

import json
import logging
import os
import time

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
_kinesis_client = boto3.client("kinesis")

class KinesisStream:
    """Encapsulates a Kinesis stream."""

    def __init__(self, kinesis_client, name):
        """
        :param kinesis_client: A Boto3 Kinesis client.
        """
        self.kinesis_client = kinesis_client
        self.name = name
        self.details = None
        self.stream_exists_waiter = kinesis_client.get_waiter("stream_exists")


    def put_record(self, data, partition_key):
        """
        Puts data into the stream. The data is formatted as JSON before it is passed
        to the stream.

        :param data: The data to put in the stream.
        :param partition_key: The partition key to use for the data.
        :return: Metadata about the record, including its shard ID and sequence number.
        """
        try:
            response = self.kinesis_client.put_record(
                StreamName=self.name, Data=json.dumps(data), PartitionKey=partition_key
            )
            logger.info("Put record in stream %s.", self.name)
        except ClientError:
            logger.exception("Couldn't put record in stream %s.", self.name)
            raise
        else:
            return response

if __name__ == "__main__":
    k = KinesisStream(_kinesis_client, os.environ["STREAM_NAME"])
    while True:
        try:
            time.sleep(1)
            now = int(time.time())
            r = k.put_record(data=f"log record at {now}", partition_key=os.environ["P_KEY"])
            print(f'data sent to shard {r["ShardId"]}')

        except Exception as e:
            print(f"error putting record - {e}")
            break


