# adoc-service-status-page

- Simple service status page created using BASH and asciidoctor

- It is really dumb, because testing operations are done sequentially, not in parallel processes.. But from my point of view "it's good enough" for like max 30 clients.

- New services are configurable pretty simple:
  - Duplicate some check in **update-data.sh** (They start after "### CHECKS ###")
  - Modify it to fit your needs and don't forget that results must be saved in **SHELL variables**.
  - Don't forget to unset these vars and the EOF
  - In **gen.sh**, copy line commented "Make an error if any check fail" and modify variable to your. For example **TFTP_CHECK** variable
  - Unset this **TFTP_CHECK** variable below

# What it does

- Get's configuration from **config/host_groups/**
- Test host(s) **PING**, **HTTP**, and **HTTPS** and create page with report.
- Create main **index.html** that shows those *pretty not pretty* clickable bars with links to reports generated.

# How to configure

- Directory **config/host_groups** contains directories that represent some kind of a service group. Like the **private_servers** or **services** that are already in place.
   - In **config/host_groups/"dir"/NAME** is specified name of the host group that will be seen on the main page (it can contain spaces and similar stuff).
     - Under **config/host_groups/"dir"/hosts/**, there are "ASCII text" containing configuration of host that should be tested.
       - Configuration file should be **SHELL** compatible, its syntax is simple:
       ```shell
       # Set host address or hostname (if IPv6 is used, don't forget these: [] !)
         HOST=contoso.net

         # CONFIGURATION
         PING=y
         HTTP=y
         HTTP_PORT=80
         HTTPS=y
         HTTPS_PORT=443
       ```
> Variables __*_PORT___ don't need to be specified, if default port is used (HTTP=>80,HTTPS-=>443, etc..)

# How to run

- First of all you need some packages:

```bash
apt install -yq grep tr sed asciidoctor curl iputils-ping bash
```

- Then just run **gen.sh** in project directory:

```bash
./gen.sh
```

- Push your files to your web server. For example:
```bash
scp -r public/* web@mywebserver.com:/srv/http/
```

> By default, everything will be created in directory: **public**
