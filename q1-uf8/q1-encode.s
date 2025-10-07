.data
test_in:
    # .byte 0x00, 0x10, 0x1F, 0x20, 0x2F, 0x7F, 0xF0, 0xFF
    .word 0, 1, 15, 16, 17, 31, 32, 111
test_out:
    .byte 0,0,0,0,0,0,0,0

.text
main:
    la   s0, test_in
    la   s1, test_out
    li   s2, 8

loop:
    beqz s2, halt
    lw  a0, 0(s0)          # load test_int -> a0
    addi s0, s0, 4
    jal  ra, uf8_encode     # a0 = uf8_encode(a0)
    sb   a0, 0(s1)          # store a0 -> test_out
    addi s1, s1, 1
    addi s2, s2, -1
    j    loop

halt:
    j    halt

# uf8_encode : encode a value into 1-byte uf8 encoding
# input a0 - uint32_t value
# return a0 - uf8 uf8_encode(value)
uf8_encode:
    li t3, 16
    blt a0, t3, e_0         # if (a0 < 16)

    addi sp, sp, -4
    sw   a0, 0(sp)          # store a0 in stack

    jal  ra, clz            # a0 = clz(a0)
    li t3, 31
    sub t0, t3, a0          # msb = t0 = 31 - clz(a0)

    lw a0, 0(sp)            # restore a0 from stack
    addi sp, sp, 4

    li t1, 0                # exp = t1 = 0
    li t2, 0                # of = t2 = 0

    li t3, 5
    blt t0, t3, fine_exa_exp         # if (msb >= 5) fine_exa_exp
    addi t1, t0, -4               # exp = msb - 4

    li t3, 15
    ble t1, t3, calc_exp     # if (exp > 15)
    li t1, 15                   # exp = 15

    li t3, 0                   # t3 = cnt = 0
calc_exp:
    bge t3, t1, adj_exp         # if (cnt >= exp) adj_exp
    slli t2, t2, 1              # of = of << 1
    addi t2, t2, 16             # of = of + 16
    addi t3, t3, 1              # cnt++

adj_exp:
    ble t1, x0, fine_exa_exp        # if (exp <= 0) fine_exa_exp
    bge a0, t2, fine_exa_exp        # if (a0 >= of) fine_exa_exp 
    addi t2, t2, -16             # of = of - 16
    srli t2, t2, 1               # of = of >> 1
    addi t1, t1, -1              # exp--

fine_exa_exp:
    li t3, 15
    bge t1, t3, cmb_num         # if (exp >= 15)
    slli t0, t2, 1              # t0 = of << 1
    addi t0, t0, 16             # t0 = (of << 1) + 16 = of_e+1
    bge a0, t0, cmb_num         # if (a0 >= of_e) cmb_num
    mv t2, t0                   # of = of_e
    addi t1, t1, 1              # exp++

cmb_num:
    sub t0, a0, t2              # t0 = value - of
    srl t0, t0, t1             # t0 = (value - of) >> exp = manti
    slli t1, t1, 4              # t1 = exp << 4
    or  a0, t1, t0              # a0 = (exp << 4) | manti
    ret
e_0:                        # e = 0
    ret 
# clz : count leading zeros
# input : a0 - uint32_t x
# return : a0 - uint32_t clz (x)
clz:
    li   t0, 32              # n = 32
    li   t1, 16              # c = 16

clz_loop:
    srl  t2, a0, t1          # y = x >> c
    beq  t2, x0, skip_update # if (y == 0) skip update
    sub  t0, t0, t1          # n = n - c
    mv   a0, t2              # x = y

skip_update:
    srli t1, t1, 1           # c = c / 2
    bnez t1, clz_loop        # while (c) loop
    sub  a0, t0, a0          # return n - x
    ret






