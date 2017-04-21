# The application connects contrail to gateway and prepares internal/floating networks

The container shloud be run on a cfg01 node at least with the following volumes:

`docker run --rm -v /root/.ssh:/root/.ssh:ro -v /etc/hosts:/etc/hosts:ro alrem/contrail_prepare`

