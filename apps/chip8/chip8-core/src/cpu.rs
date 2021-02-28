use super::display::Display;

/// I'm borrowing the basic structure for the CPU.
/// https://blog.scottlogic.com/2017/12/13/chip8-emulator-webassembly-rust.html
pub struct Cpu {
    // index register
    pub i: u16,
    // program counter
    pub pc: u16,
    // memory
    pub memory: [u8; 4096],
    // registers
    pub v: [u8; 16],
    // peripherals
    // pub keypad: Keypad,
    pub display: Display,
    // stack
    pub stack: [u16; 16],
    // stack pointer
    pub sp: u8,
    // delay timer
    pub dt: u8,
}

impl Default for Cpu {
    fn default() -> Self {
        Self {
            memory: [0; 4096],
            v: [0; 16],
            stack: [0; 16],
            ..Default::default()
        }
    }
}

impl Cpu {
    pub fn execute_cycle(&mut self) {
        // let opcode: u16 = read_word(self.memory, self.pc);
    }

    pub fn get_memory(&self) -> &[u8; 4096] {
        &self.memory
    }
}
