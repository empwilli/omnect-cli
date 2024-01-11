# omnect-cli
**Product page: https://www.omnect.io/home**

# Features
omnect-cli is a command-line tool to manage omnect-os empowered devices. It provides commands to inject various configurations into a flash image (wic) formerly build with [meta-omnect](https://github.com/omnect/meta-omnect). Currently the following configuration options are supported:

- Identity configuration:
  - Inject general identity configuration for AIS (Azure Identity Service)
  - Inject a device certificate with corresponding key from a given intermediate full-chain-certificate and corresponding key
- Device Update for IoT Hub configuration: inject [`du-config.json`](https://docs.microsoft.com/en-us/azure/iot-hub-device-update/device-update-configuration-file)
- Generic configuration of services
  - copy files to image in order to configure e.g. boot service, firewall, wifi and others
  - copy files from image, e.g. to patch and re-inject configurations
- ssh:
  - inject a ssh root ca and device principal for ssh tunnel creation

Further omnect-cli supports device management features. Currently supported:
  - open a ssh tunnel on a device in the field to connect to it

# Installation

Available debian packages can be listed as a xml document via this [link](https://omnectassetst.blob.core.windows.net/omnect-cli?restype=container&comp=list). Choose, download and install a version:
```sh
wget https://omnectassetst.blob.core.windows.net/omnect-cli/omnect-cli_<version>_amd64.deb
sudo dpkg -i omnect-cli_<version>_amd64.deb
```
**Note**: `dpkg` lists necessary runtime dependencies in case they are not present.

# Build from sources

The application can be built via `cargo` as usual. A prerequisite is libmagic, e.g. the package libmagic-dev must be installed on a debian-based host system.

# Commands
## Identity configuration
### Inject identity

For `omnect-iotedge-devices` adapt [config.toml.est.template](conf/config.toml.est.template) or [config.toml.tpm.template](conf/config.toml.tpm.template) to your needs.

```sh
omnect-cli identity set-config -c <path>/config.toml -i <path>/image.wic

Options:
  -e <path>/extra-payload.json
  -p pack and compress image [xz, bzip2, gzip]
  -b create bmap file
```
For further information on using dps payloads read the following [link](https://learn.microsoft.com/de-de/azure/iot-dps/concepts-custom-allocation).

### inject device certificate and key for x509 based DPS provisioning

For a given full-chain intermediate certificate and corresponding key, both as pem files, generate a device certificate and device key valid for 365 days.
```sh
omnect-cli identity set-device-certificate -d "device_id" -i <path>/image.wic -c <path>/intermediate_full_chain_cert.pem -k <path>/intermediate_cert_key.pem -D 365

Options:
  -p pack and compress image [xz, bzip2, gzip]
  -b create bmap file
```
**Note**: "device_id" has to match the `registration_id` respectively the `device_id` configured in `config.toml`.

See [`config.toml.est.template`](conf/config.toml.est.template) as a corresponding `config.toml` is case of using `EST service`.

#### Get full-chain intermediate certificate and key for existing OMNECT PKI
Please get into contact with us in case you want to use our existing cloud services for device provisioning. We can provide certificate and key file to configure your device.

#### Generate your own full-chain intermediate certificate and key
In case you intend to use your own certificates (e.g. because you want to use your own `PKI` and/or `EST service`), you can find some information about generating certificate and key here: https://docs.microsoft.com/en-us/azure/iot-edge/how-to-create-test-certificates?view=iotedge-2020-11.

## Device Update for IoT Hub configuration
### Inject `du-config.json`

```sh
omnect-cli iot-hub-device-update set -c <path>/du-config.json -i <path>/image.wic

Options:
  -p pack and compress image [xz, bzip2, gzip]
  -b create bmap file
```

## Copy files

Copying files into or from the image is restricted to partitions `boot`, `rootA`, `cert` and `factory`. Destination paths that are not existing will be created on host as well as on image.

### Copy files from image

`omnect-cli` allows copying multiple files from multiple partitions in one command:

```sh
omnect-cli file copy-from-image -f <partition>:<absolute-path-to-src>,<path-to-dest> -f <partition>:<absolute-path-to-src>,<path-to-dest> -i <path>/image.wic
```

### Copy files to image

`omnect-cli` allows copying multiple files to multiple partitions in one command:

```sh
omnect-cli file copy-to-image -f <path-to-src>,<partition>:<absolute-path-to-dest> -f <path-to-src>,<partition>:<absolute-path-to-dest> -i <path>/image.wic

Options:
  -p pack and compress image [xz, bzip2, gzip]
  -b create bmap file
```

**Note1**: If you need special permissions on copied files, you have to additionally copy a systemd-tmpfiles.d configuration file which handles these permissions.<br>
**Note2**: Injecting files allows configuration of device behavior and services, e.g.:
- Boot: inject `boot.scr` or grub.cfg
- Firewall: inject `iptables.rules`
- File permissions: inject `systemd-tmpfiles.d`
- Wifi: inject `wpa_supplicant-wlan0.conf`

## ssh tunnel

### Inject ssh tunnel credentials

For the ssh feature, the device requires the public key of the ssh root ca and the principal. The latter should be the device id.
```sh
omnect-cli ssh set-certificate -r <path>/ssh_ca.pub -d "device_id" -i <path>/image.wic

Options:
  -p pack and compress image [xz, bzip2, gzip]
  -b create bmap file
```

### Creating a ssh tunnel

One can use `omnect-cli` to create a tunneled ssh connection to a device in the field. This is especially useful if the device is behind a NAT and can not directly be contacted. The device must have the `ssh` activated for this. Per default, this command will create a single use ssh key pair, certificate, and ssh configuration to establish a connection to the device.

To create an ssh tunnel, `omnect-cli` must first authenticate against the authentication service. The service credentials vary, depending on whether the device is in the `dev` or `prod` environment.

**Note**: if unused, the tunnel will close after 5 minutes.

Creating the ssh tunnel:
```sh
omnect-cli ssh set-connection <device>

Options:
  -u <name> optional: name of the user on the device
  -d <dir> optional: directory where the ssh key pair, certificate, and configuration are stored to
  -k <key> optional: path to an existing private ssh key to use for the connection. Requires the existence of the public key <key>.pub
  -c <config_path> optional: path where the ssh configuration should be stored to
  --env <env_config_path> optional: path to a .toml configuration specifying the devices execution environment, defaults to the production environment.
```

#### Example usage

Open an ssh tunnel to the device `prod_device` in the `prod` environment as follows:
```sh
~ omnect-cli ssh set-connection prod_device

Successfully established ssh tunnel!
Certificate dir: /run/user/1000/omnect-cli
Configuration path: /run/user/1000/omnect-cli/ssh_config
Use the configuration in "/run/user/1000/omnect-cli/ssh_config" to use the tunnel, e.g.:
ssh -F /run/user/1000/omnect-cli/ssh_config prod_device
```
Now follow the command output to establish a connection to the device as such:

```sh
~ ssh -F /run/user/1000/omnect-cli/ssh_config prod_device

[omnect@prod_device ~]$
```

To connect to the device `dev_device` in the `dev` environment, we additionally
have to supply a configuration with backend and the authentication details for
the `dev` environment:

```dev_env.toml
backend = 'https://cp.dev.omnect.conplement.cloud'

[auth.Keycloak]
provider = 'https://keycloak.omnect.conplement.cloud'
realm = 'cp-dev'
client_id = 'cp-development'
bind_addr = 'localhost:4000'
redirect = 'http://localhost:4000'
```

You then have to pass this configuration with the `--env` flag:
```sh
~ omnect-cli ssh set-connection dev_device --env dev_env.toml

Successfully established ssh tunnel!
...
```

# Troubleshooting

If anything goes wrong, setting RUST_LOG=debug enables output of debug information.

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

---

copyright (c) 2021 conplement AG<br>
Content published under the Apache License Version 2.0 or MIT license, are marked as such. They may be used in accordance with the stated license conditions.

