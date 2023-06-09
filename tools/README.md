
# SLURM

Setting up SLURM is useful for evaluating user contributed translations.
On Ubuntu, this should work:

```
sudo apt-get install slurmd slurm-client slurmctld
sudo cp cgroup.conf /etc/slurm-llnl/
h=`hostname` && sudo cat slurm.conf | \
sed -e "s/REPLACE_SLURM_SERVER/$h/" \
    -e s/REPLACE_SLURM_NODES/$h/" \
    -e s/REPLACE_SLURM_SHORT_NODES/$h/" \
    -e s/REPLACE_SLURM_STANDARD_NODES/$h/" \
    -e s/REPLACE_SLURM_LONG_NODES/$h/" > /etc/slurm-llnl/slurm.conf
sudo service slurmctld start
sudo service slurmd start
```

Make sure that the web-server has permissions to the data directory used by the web interface:

```
mkdir /path/to/localdir/Contributed-MT-leaderboard-data
chmod 775 /path/to/localdir/Contributed-MT-leaderboard-data
chmod +s /path/to/localdir/Contributed-MT-leaderboard-data
sudo chown www-data /path/to/localdir/Contributed-MT-leaderboard-data
```

`/path/to/localdir/` needs to match the path from `OPUS-MT-dashboard/upload/index.php`.

If all works then it should be possible to upload translation files and the evaluation jobs are run through SLURM. Check with `squeue` what happens in the SLURM queues.
