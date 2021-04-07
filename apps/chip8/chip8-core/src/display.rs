pub struct Display {
    pub memory: [u8; 2048],
}

impl Default for Display {
    fn default() -> Self {
        Self { memory: [0; 2048] }
    }
}
