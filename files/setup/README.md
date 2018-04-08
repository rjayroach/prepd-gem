# prepd

## Getting Started with a new Host

First, modify vars.yml to

- include your git name and email
- the list of extra packages to install

Next, run the setup.yml playbook. It will fail on the first attempt to install VirtualBox

After installation fails go to security settings and enable kernel extensions from Oracle Amercia

Then rerun setup.yml


```bash
prepd setup
```

Full documentation is available [here](https://github.com/rjayroach/prepd/tree/master/docs)
