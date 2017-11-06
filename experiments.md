# Fun Cluster Experiments

## HDFS Failure

In the [HDFS explorer](http://localhost:50070/explorer.html), find a file and click to see which nodes it's available on. We're going to fail one of those nodes to see how HDFS responds. Keep this tab open in your browser.

You can fail a node by simply rebooting the node: the Hadoop processes don't start up automatically, so the HDFS node will be gone. You can restart a VM with a command like: `vagrant reload hadoop3`

Watch [the DataNode list](http://localhost:50070/dfshealth.html#tab-datanode) to see the &ldquo;last contact&rdquo; tick up to (the unusually low `dfs.namenode.heartbeat.recheck-interval` of) 30 seconds when the NameNode gives up on the DataNode and declares it dead.

Once that happens, in the [NameNode overview page](http://localhost:50070/dfshealth.html#tab-overview), you'll see the &ldquo;Number of Under-Replicated Blocks&rdquo; jump up. If you reload the page every few seconds, you'll see it tick down toward zero as HDFS heals itself and re-replicates the blocks from the failed node.

As the HDFS heals itself, reload the page with the file information: you should see the HDFS file you were looking at back to its full replication on a surviving node.

## YARN Job Failure

TODO
