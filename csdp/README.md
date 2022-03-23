# CSDP Utils

A set of scripts to help with Codefresh Software Delivery Platform Management

## cf-runtime-uninstall.sh

A script to remove all the parts that may have been left behind after a failed uninstallation for the runtime.

### Pre Requisites

To run this command you need to create a personal access token for your git provider and provide it using:

```
        export GIT_TOKEN=<token>
```

### Parameters:

1. Runtime Name

### Usage

./csdp-runtime-uninstall.sh RUNTIME_NAME
