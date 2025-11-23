use flutter_rust_bridge::StreamSink;
use anyhow::Result;

pub fn init_core() -> Result<String> {
    Ok("Gossamer Core Online".into())
}

pub fn get_radar_data() -> Result<Vec<String>> {
    Ok(vec!["Signal 1".into(), "Signal 2".into()])
}
