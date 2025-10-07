.data
test_in:
    .byte 0x00, 0x10, 0x1F, 0x20, 0x2F, 0x7F, 0xF0, 0xFF
test_out:
    .word 0,0,0,0,0,0,0,0

.text
main:
    la   s0, test_in
    la   s1, test_out
    li   s2, 8

loop:
    beqz s2, halt
    lbu  a0, 0(s0)          # load test_int -> a0
    addi s0, s0, 1
    jal  ra, uf8_decode     # a0 = uf8_decode(a0)
    sw   a0, 0(s1)          # store a0 -> test_out
    addi s1, s1, 4
    addi s2, s2, -1
    j    loop

halt:
    j    halt

# uf8_decode:
#     andi t0, a0, 0x0F       # mantissa = fl & 0x0F
#     srli t1, a0, 4          # exponent = fl >> 4
#     li   t2, 15
#     sub  t2, t2, t1         # t2 = 15 - exponent
#     li   t3, 0x7FFF
#     srl  t3, t3, t2         # t3 = 0x7FFF >> (15 - e)
#     slli t3, t3, 4          # offset = t3 << 4
#     sll  t0, t0, t1         # (mantissa << exponent)
#     add  a0, t0, t3         # return (mantissa<<e) + offset
#     ret

# a0 = ((m+16)<<e) - 16
uf8_decode:
    srli t0, a0, 4      # t0 = e
    andi a0, a0, 0x0F   # a0 = m
    addi a0, a0, 16     # a0 = m + 16
    sll  a0, a0, t0     # a0 = (m + 16) << e
    addi a0, a0, -16    # a0 = a0- 16
    ret