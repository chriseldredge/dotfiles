#!uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "boto3",
# ]
# ///

import argparse
import boto3
import queue
import threading
import time
import sys
from botocore.exceptions import ClientError


class S3EmptyBucket:
    def __init__(self, bucket_name, region=None, profile=None, max_workers=10, batch_size=1000, quiet=False):
        self.bucket_name = bucket_name
        self.region = region
        self.profile = profile
        self.max_workers = max_workers
        self.batch_size = batch_size
        self.quiet = quiet
        self.queue = queue.Queue(maxsize=100000)  # Limit queue size to prevent memory issues
        self.listing_complete = False
        self.session = None
        self.s3_client = None
        self.setup_aws_session()
        
    def log(self, message):
        """Print message if quiet mode is not enabled."""
        if not self.quiet:
            print(message)

    def setup_aws_session(self):
        """Set up AWS session with optional profile and region."""
        session_kwargs = {}
        if self.profile:
            session_kwargs['profile_name'] = self.profile

        self.session = boto3.Session(**session_kwargs)
        client_kwargs = {}
        if self.region:
            client_kwargs['region_name'] = self.region

        self.s3_client = self.session.client('s3', **client_kwargs)

    def list_object_versions(self):
        """List all object versions and markers in the bucket and add to queue."""
        try:
            paginator = self.s3_client.get_paginator('list_object_versions')

            # Track progress
            total_objects = 0
            self.log(f"Listing objects in bucket {self.bucket_name}...")

            for page in paginator.paginate(Bucket=self.bucket_name):
                # Process versions
                if 'Versions' in page:
                    for version in page['Versions']:
                        self.queue.put(('version', version['Key'], version['VersionId']))
                        total_objects += 1

                # Process delete markers
                if 'DeleteMarkers' in page:
                    for marker in page['DeleteMarkers']:
                        self.queue.put(('delete_marker', marker['Key'], marker['VersionId']))
                        total_objects += 1

                # Print progress periodically
                if total_objects % 10000 == 0:
                    self.log(f"Listed {total_objects} objects so far...")

            self.log(f"Finished listing {total_objects} objects.")
            self.listing_complete = True

        except ClientError as e:
            print(f"Error listing objects: {e}", file=sys.stderr)
            sys.exit(1)

    def delete_objects(self, worker_id):
        """Delete objects in batches from the queue."""
        deleted_count = 0
        batch = []

        while True:
            try:
                # If listing is complete and queue is empty, we're done
                if self.listing_complete and self.queue.empty():
                    if batch:  # Delete any remaining items in the batch
                        self._delete_batch(batch)
                        deleted_count += len(batch)
                    self.log(f"Worker {worker_id} finished, deleted {deleted_count} objects")
                    return

                try:
                    # Wait for 1 second if queue is empty but listing isn't complete
                    item = self.queue.get(timeout=1)
                    obj_type, key, version_id = item

                    batch.append({
                        'Key': key,
                        'VersionId': version_id
                    })

                    # Delete in batches to improve performance
                    if len(batch) >= self.batch_size:
                        self._delete_batch(batch)
                        deleted_count += len(batch)
                        batch = []

                    self.queue.task_done()

                except queue.Empty:
                    # If queue is empty but we're still listing, just continue
                    continue

            except Exception as e:
                print(f"Error in worker {worker_id}: {e}", file=sys.stderr)
                # In case of error, put the batch back in the queue
                for item in batch:
                    self.queue.put(('version', item['Key'], item['VersionId']))
                return

    def _delete_batch(self, batch):
        """Delete a batch of objects."""
        if not batch:
            return

        self.log(f"Deleting {len(batch)} objects")
        try:
            self.s3_client.delete_objects(
                Bucket=self.bucket_name,
                Delete={
                    'Objects': batch,
                    'Quiet': True
                }
            )
        except ClientError as e:
            print(f"Error deleting batch: {e}", file=sys.stderr)
            # Individual retries could be implemented here

    def delete_bucket(self):
        """Delete the empty bucket."""
        try:
            self.log(f"Deleting bucket {self.bucket_name}...")
            self.s3_client.delete_bucket(Bucket=self.bucket_name)
            self.log(f"Bucket {self.bucket_name} deleted successfully.")
        except ClientError as e:
            print(f"Error deleting bucket: {e}", file=sys.stderr)
            sys.exit(1)

    def empty_and_delete(self):
        """Empty and delete the bucket using multiple threads."""
        start_time = time.time()

        # Start the listing thread
        listing_thread = threading.Thread(target=self.list_object_versions)
        listing_thread.daemon = True

        self.log('Start listing thread')
        listing_thread.start()

        self.log('Start worker threads')
        # Start worker threads for deletion
        workers = []
        for i in range(self.max_workers):
            worker = threading.Thread(target=self.delete_objects, args=(i,))
            worker.daemon = True
            worker.start()
            workers.append(worker)

        # Wait for listing to complete
        listing_thread.join()

        # Wait for queue to be processed
        self.queue.join()

        # Wait for all workers to finish
        for worker in workers:
            worker.join()

        # Delete the bucket
        self.delete_bucket()

        elapsed_time = time.time() - start_time
        self.log(f"Operation completed in {elapsed_time:.2f} seconds")


def main():
    parser = argparse.ArgumentParser(description='Empty and delete an S3 bucket including all versions')
    parser.add_argument('bucket_name', help='Name of the S3 bucket to empty and delete')
    parser.add_argument('--region', help='AWS region of the bucket')
    parser.add_argument('--profile', help='AWS profile to use')
    parser.add_argument('--workers', type=int, default=1, help='Number of worker threads (default: 1)')
    parser.add_argument('--batch-size', type=int, default=1000, help='Number of objects to delete in each batch (default: 1000)')
    parser.add_argument('-q', '--quiet', action='store_true', help='Suppress output messages')

    args = parser.parse_args()

    s3_empty = S3EmptyBucket(
        bucket_name=args.bucket_name,
        region=args.region,
        profile=args.profile,
        max_workers=args.workers,
        batch_size=args.batch_size,
        quiet=args.quiet
    )

    s3_empty.empty_and_delete()


if __name__ == '__main__':
    main()
