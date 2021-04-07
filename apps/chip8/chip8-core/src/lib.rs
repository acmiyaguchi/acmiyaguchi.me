use js_sys;
use std::f64;
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;

mod cpu;
mod display;
mod utils;

use cpu::Cpu;

#[wasm_bindgen]
pub struct Core {
    cpu: Cpu,
}

#[wasm_bindgen]
impl Core {
    pub fn new() -> Self {
        Self {
            cpu: Cpu::default(),
        }
    }

    pub fn get_display(self) -> js_sys::Uint8Array {
        js_sys::Uint8Array::from(self.cpu.display.memory.as_ref())
    }
}
