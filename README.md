Bash Scripts
============

run-command.sh
----------------

* Runs any commands on the remote EC2 instances which you can filter based on AWS tags.
* Help:
```
$ ./run-command.sh
Usage: run-command.sh [-l dsh_fork_limit] -f '<filter 1>' -f '<filter 2>' ... -c '<command>'

   -l dsh_fork_limit      If not set, command is executed on one node at a time.
   -f filter              One or more aws describe-instance filters. https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html#options
   -c command             Command that is executed on the nodes.

   Example:
   ./run-command.sh -l 2 -f 'Name=tag:Environment,Values=loadtest' -f 'Name=tag:Cluster,Values=api,data' -c 'echo Test'
```

* Example:
```
$ ./run-command.sh -l 2 -f 'Name=tag:Environment,Values=loadtest' -f 'Name=tag:Cluster,Values=api,data' -c 'echo Test'
[run-command.sh] 2018-04-11T10:41:35+0200 | Execute 'echo Test' on the following nodes:

[\loadtest-api-xFJT8q\] 10.0.2.111
[\loadtest-api-Whr3fC\] 10.0.1.202
[\loadtest-data-dJra4Q\] 10.0.1.201
[\loadtest-data-494kTm\] 10.0.1.80
[\loadtest-data-qZ7SWU\] 10.0.1.190
[\loadtest-api-savWv4\] 10.0.2.204
[\loadtest-api-k6PRez\] 10.0.1.157
[\loadtest-data-fZtT7D\] 10.0.2.76
[\loadtest-data-VXbq7s\] 10.0.1.228
[\prod-api-Juub43\] 10.0.1.6
[\prod-api-6sCu58\] 10.0.2.192
[\prod-api-vJZ8So\] 10.0.1.225
[\prod-api-iEQYj3\] 10.0.2.135
[\prod-data-JKgy8m\] 10.0.2.57
[\prod-data-4mEzh4\] 10.0.2.231
[\prod-data-kCHe8C\] 10.0.2.109

Continue (y/n)? y

[run-command.sh] 2018-04-11T10:41:37+0200 | Executing ...

10.0.2.111: Test
10.0.1.202: Test
10.0.1.201: Test
10.0.2.204: Test
10.0.1.190: Test
10.0.1.80: Test
10.0.1.157: Test
10.0.2.76: Test
10.0.1.228: Test
10.0.1.6: Test
10.0.1.225: Test
10.0.2.192: Test
10.0.2.135: Test
10.0.2.57: Test
10.0.2.231: Test
10.0.2.109: Test
[run-command.sh] 2018-04-11T10:41:55+0200 |
[run-command.sh] 2018-04-11T10:41:55+0200 | Done
```