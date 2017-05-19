ls -1 /tmp/ | xargs -I {} -P 10  ls -la /tmp/{}
