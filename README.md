# ics-dm-cli
ics-dm-cli is a cli tool to manage your ics-dm-device [variants](https://wiki.conplement.de/display/ICSDeviceManagement/ICS_DeviceManagement+Home).

# Features
ics-dm-cli provides commands to inject various configurations into a flash image (wic) build with [meta-ics-dm](https://github.com/ICS-DeviceManagement/meta-ics-dm). Currently the following configurations options are supported:
- Wifi configuration
  - Inject wifi configuration via wpa_supplicant into all ics-dm-device variants
- Enrollment demo configuration
  - Inject [enrollment demo](https://github.com/ICS-DeviceManagement/enrollment) configuration
- Identity configuration
  - Inject general identity configuration for AIS (Azure Identity Service)
  - Inject an iotedge gateway identity configuration for AIS
  - Inject an iot leaf identity configuration for AIS
  - Inject a device certificate with corresponding key from a given intermediate full-chain-certificate and corresponding key
- Device Update for IoT Hub configuration
  - Inject [`du-config.json`](https://docs.microsoft.com/en-us/azure/iot-hub-device-update/device-update-configuration-file)
- Boot configuration
  - Inject `boot.scr`

# Download prebuild Docker image
- login to azure docker registry either via admin user
    ```sh
    docker login icsdm.azurecr.io
    ```
    or via your AAD account
    ```sh
    az login
    az acr login -n icsdm
    ```
- Pull latest docker image
    ```sh
    docker pull icsdm.azurecr.io/ics-dm-cli-backend:latest
    ```
If you want to use a specific version, look for available versions in the [registry](https://portal.azure.com/#@CONPLEMENTAG1.onmicrosoft.com/resource/subscriptions/ff939028-597d-472b-a7cc-bca2ac8f96bd/resourcegroups/DockerRegistry/providers/Microsoft.ContainerRegistry/registries/icsdm/repository).

# Installation
Ensure ~/bin/ exists and is in your $PATH before executing:

```sh
docker run --rm --entrypoint cat icsdm.azurecr.io/ics-dm-cli-backend:latest /install/ics-dm-cli > ~/bin/ics-dm-cli && chmod +x ~/bin/ics-dm-cli
```

# Wifi configuration
## Inject wifi configuration
Adapt either [wpa_supplicant.conf.simple.template](conf/wpa_supplicant.conf.simple.template) or [wpa_supplicant.conf.template](conf/wpa_supplicant.conf.template).
Use `wpa_passphrase` to generate your `psk`. Depending on your host system you may have to install `wpa_supplicant` to be able to use `wpa_passphrase`.

```sh
ics-dm-cli wifi set -c <path>/wpa_supplicant.conf -i <path>/image.wic

Options:
  -b create bmap file
```

# Enrollment configuration
## Inject enrollment configuration
This is an optional step to configure the [enrollment demo](https://github.com/ICS-DeviceManagement/enrollment) in case it is part of your image.
Adapt [enrollment_static.json.template](conf/enrollment_static.json.template) to your needs.

```sh
ics-dm-cli enrollment set -c <path>/enrollment_static.json -i <path>/image.wic

Options:
  -b create bmap file
```

# Identity configuration
## Configuration of devices NOT part of a gateway with leaf scenario
For `ics-iot-devices` and `ics-iotedge-devices` adapt [config.toml.ics-iot.template](conf/config.toml.ics-iot.template) or [config.toml.ics-iotedge.template](conf/config.toml.ics-iotedge.template) to your needs.

```sh
ics-dm-cli identity set-config -c <path>/config.toml -i <path>/image.wic

Options:
  -b create bmap file
```

## Prepare `ics-iotedge-gateway-device` and `ics-iot-leaf-device` for a transparent gateway with leaf scenario
Follow this article [Configure an IoT Edge device to act as a transparent gateway](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-create-transparent-gateway?view=iotedge-2020-11) to understand the iotedge based transparent gateway setup. We assume that you use a X.509 CA certificate setup.

## Gateway configuration
### Certificates
Follow the article [Create demo certificates to test IoT Edge device features](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-create-test-certificates?view=iotedge-2020-11=) in case you don't have a workflow for certificate creation yet.
For the gateway, you need the following files:
  - `azure-iot-test-only.root.ca.cert.pem`
  - `iot-edge-ca-<name>-full-chain.cert.pem`
  - `iot-edge-ca-<name>.key.pem`

### Config file
Adapt [config.toml.ics-iotedge-gateway.template](conf/config.toml.ics-iotedge-gateway.template) to your needs.

### Inject configuration
```sh
ics-dm-cli identity  set-iotedge-gateway-config -c <path>/iotedge_config.toml -i <path>/iotedge_image.wic  -r <path>/azure-iot-test-only.root.ca.cert.pem -d <path>/iot-edge-device-ca-<name>-full-chain.cert.pem -k <path>/iot-edge-device-ca-<name>.key.pem

Options:
  -b create bmap file
```

## Leaf configuration
### Restriction
We provision iot applications as modules. Currently our leaf device configuration is restricted to SaS authentication. See https://azure.github.io/iot-identity-service/develop-an-agent.html#connecting-your-agent-to-iot-hub for details.

### Certificates
For the leaf device with SaS provisioning you only need the root ca certificate:
  - `azure-iot-test-only.root.ca.cert.pem`

### Config file
Adapt [config.toml.ics-iot-leaf.template](conf/config.toml.ics-iot-leaf.template) to your needs.

### Inject configuration
```sh
ics-dm-cli identity set-iot-leaf-sas-config -c <path>/iot_config.toml -i <path>/leaf_image.wic  -r <path>/azure-iot-test-only.root.ca.cert.pem

Options:
  -b create bmap file
```

## Device certificate and key

For a given full-chain intermediate certificate and corresponding key, both as pem files, generate a device certificate and device key valid for 365 days.
```sh
ics-dm-cli identity set-device-certificate -d "device_id" -i <path>/image.wic -c <path>/intermediate_full_chain_cert.pem -k <path>/intermediate_cert_key.pem -D 365
```
Note: "device_id" has to match the `registration_id` respectively the `device_id` configured in `config.toml`.

See [`config.toml.est.template`](conf/config.toml.est.template) as a corresponding `config.toml` is case of using `EST service`.

### Get full-chain intermediate certificate and key for existing ICS-DM PKI
Please get into contact with us in case you want to use our existing cloud services for device provisioning. We can provide certificate and key file to configure your device.

### Generate your own full-chain intermediate certificate and key
In case you intend to use your own certificates (e.g. because you want to use your own `PKI` and/or `EST service`), you can find some information about generating certificate and key here: https://docs.microsoft.com/en-us/azure/iot-edge/how-to-create-test-certificates?view=iotedge-2020-11.

# Device Update for IoT Hub configuration
## Inject `du-config.json`

```sh
ics-dm-cli iot-hub-device-update set -c <path>/du-config.json -i <path>/image.wic

Options:
  -b create bmap file
```

# Boot configuration
## Inject `boot.scr`

```sh
ics-dm-cli boot set -c <path>/boot.scr -i <path>/image.wic

Options:
  -b create bmap file
```

# Troubleshooting

If anything goes wrong, setting RUST_LOG=debug enables output of debug information.

## No credential store support
`ics-dm-cli` needs to pull a docker image `icsdm.azurecr.io/ics-dm-cli-backend` as backend for some cli
commands. If you use a docker environment with credential store you have to
pull the image prior to calling `ics-dm-cli` manually. (Note this is not necessary if you installed ´ics-dm-cli´ via: [Installation](#installation))
```sh
docker pull icsdm.azurecr.io/ics-dm-cli-backend:$(ics-dm-cli --version | awk '{print $2}')
```

## Verify configuration is functional
Check for valid AIS identity configuration on iotedge devices:
```sh
iotedge system logs
```

Check for valid AIS identity configuration on iot devices:
```sh
aziotctl system logs
```

Check for valid wifi configuration:
```sh
systemctl status wpa_supplicant@wlan0
```

# ToDo's
- [ ] Make linked ICS_DeviceManagement Wiki public
- [ ] Describe local build and overwriting backend docker registry via `ICS_DM_CLI_DOCKER_REG_NAME`
      at buildtime and at runtime

# License
Licensed under either of

* Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
* MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.

# Contribution
Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.

Copyright (c) 2021-2022 conplement AG
