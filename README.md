# S3 Diff

Simple shell utility to compare the contents of two S3 buckets

Running ``sh s3_diff s3://bucket_1 s3://bucket_2`` will output all files that are in ``bucket_1`` but not in ``bucket_2``, and vice versa

Options are: 
``-m`` limits the amount of listed files (default 100)
``-o`` allows you to specify the path to the output file (default ``s3_diff_output.txt``)

If you need to compare private buckets, make sure your shell has access to your AWS account one way or another
