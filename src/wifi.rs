use crate::docker;
use crate::file;
use std::io::{Error, ErrorKind};

const WPA_SUPPLICANT_CONF_TARGET_PATH: &'static str = "/mnt/etc/upper/wpa_supplicant.conf";

pub fn config(config_file: std::path::PathBuf, image_file: std::path::PathBuf ) -> Result<(),Error> {
    file::file_exits(&config_file)?;
    file::file_exits(&image_file)?;

    /*
        todo some content verification of config_file and image_file?
        e.g. image_file currently should be an uncompressed wic file
    */

    docker::inject_config(config_file.to_str().unwrap(),
                        WPA_SUPPLICANT_CONF_TARGET_PATH,
                        image_file.to_str().unwrap())?;

    Ok (())
}

pub fn info(image_file: std::path::PathBuf) -> Result<(),Error> {
    file::file_exits(&image_file)?;

    Err(Error::new(ErrorKind::Other, "Not implemented"))
}
