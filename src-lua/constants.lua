-- LWP-Serialization v2.3 (The "Anchor" Edition)
local Constants = {
    -- 0x00: NIL and Table Terminator
    NIL         = 0x00,
    
    -- 0x01 - 0x0F: Specials & Fixed types
    FALSE       = 0x01,
    TRUE        = 0x02,
    FLOAT64     = 0x03,
    
    I8          = 0x04,
    I16         = 0x05,
    I32         = 0x06,
    I64         = 0x07,
    
    STR_I1      = 0x08,
    STR_I2      = 0x09,
    STR_I4      = 0x0A,
    STR_I8      = 0x0B,
    
    LNK_I1      = 0x0C,
    LNK_I2      = 0x0D,
    LNK_I4      = 0x0E,
    LNK_I8      = 0x0F,

    -- Range Starts (Aligned to 16-byte boundaries where possible)
    SMALL_STR_START = 0x10, -- 0x10...0x4F (64 values) -> len 0..63
    SMALL_LNK_START = 0x50, -- 0x50...0x8F (64 values) -> ID 0..63
    SMALL_INT_START = 0x90, -- 0x90...0xFE (111 values) -> 0..110

    -- 0xFF: The Anchor
    TABLE_START = 0xFF,

    -- Limits
    MAX_SMALL_STR = 63,
    MAX_SMALL_LNK = 63,
    MAX_SMALL_INT = 110
}

return Constants
