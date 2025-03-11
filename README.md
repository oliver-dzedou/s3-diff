# S3 Diff

Simple shell utility to compare the contents of two S3 buckets

Running ``sh s3_diff s3://bucket_1 s3://bucket_2`` will: <br/>
- output all files that are in ``bucket_1`` but not in ``bucket_2``, and vice versa <br/>
- compare the json content of the files that the two buckets have in common and output the differences 

Options are: <br/>
- ``-m`` limits the amount of compared files (default 100) -- each file compare has to run aws s3 cp twice, so it's wise to keep this number low
- ``-o`` allows you to specify the path to the output file (default ``s3_diff_output.txt``)

If you need to compare private buckets, make sure your shell has access to your AWS account one way or another
