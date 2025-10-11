.data
str1: .string ": produces value "
str2: .string " but encodes back to "
str3: .string ": value "
str4: .string " <= previous_value "
str5: .string "\n"
.text
main:
    li   s0, 0            # s0 = i / fl (0..255)
    li   s1, -1           # s1 = previous_value
    li   s2, 256          # s2 = remaining count
    li   s3, 1            # s3 = passed (1=ok, 0=fail)
    li   s5, 15           # s5 = cmp value
    jal  test             # run test
# halt:
#     j    halt             # infinite loop
    li a7, 10               # syscall exit
    ecall

# round-trip test
# val = uf8_decode(fl)
# fl2 = uf8_encode(val)
test:
    addi sp, sp, -4       # make space in stack
    sw   ra, 0(sp)        # store ra in stack
loop:
    beqz s2, test_end     # remaining == 0 ? test_end 
    andi a0, s0, 255      # load fl = (uint8_t)i
    jal  uf8_decode

    addi s4, a0, 0        # s4 = a0 = value = uf8_decode(fl)
    jal  uf8_encode   
    andi a0, a0, 255      # a0 = (uint8_t)fl2 = uf8_encode(value)
    bne  s0, a0, set_fail # fl != fl2 ? fail 

check_mono_inc:
    blt  s1, s4, ok       # previous_value <  value ? ok 
    li   s3, 0            # passed = 0
    li   t3, 1            # for debug
    jal  print_fail_msg 


ok:
    addi s1, s4, 0        # previous_value = value
    addi s0, s0, 1        # i++
    addi s2, s2, -1       # remaining--
    j    loop

set_fail:
    li   s3, 0            # passed = 0
    li   t3, 0            # for debu
    jal  print_fail_msg    
    j    check_mono_inc

test_end:
    addi a0, s3, 0        # a0 = (1=all pass，0=has fail)
    lw   ra, 0(sp)        # restore ra from stack
    addi sp, sp, 4        # restore sp
    ret
# ------------------------------------------------------------
# return a0
uf8_decode:
    srli t0, a0, 4        # t0 = e
    andi a0, a0, 0x0F     # a0 = m
    addi a0, a0, 16       # a0 = m + 16
    sll  a0, a0, t0       # a0 = (m + 16) << e
    addi a0, a0, -16      # a0 = a0 - 16
    ret
# ------------------------------------------------------------
# return a0
uf8_encode:
    li  t3, 16
    bge a0, t3, e_!0         # if (a0 >= 16) e_!0
    ret
e_!0:                        # e != 0 
    addi sp, sp, -8
    sw   a0, 0(sp)          # store a0 in stack
    sw   ra, 4(sp)          # store ra in stack  

    jal   ra, clz            # a0 = clz(a0)
    li  t3, 31
    sub t0, t3, a0          # msb = t0 = 31 - clz(a0)

    lw   a0, 0(sp)            # restore a0 from stack
    lw   ra, 4(sp)            # restore ra from stack
    addi sp, sp, 8

    li t1, 0                # exp = t1 = 0
    li t2, 0                # of = t2 = 0

    li   t3, 5
    blt  t0, t3, find_exa_exp         # if (msb < 5) find_exa_exp
    addi t1, t0, -4               # exp = msb - 4

    li  t0, 0                    # t0 = cnt = 0
    ble t1, s5, calc_exp        # if (exp < 15) calc_exp
    li  t1, 15                   # exp = 15

calc_exp:
    bge  t0, t1, adj_exp         # if (cnt < exp) loop
    slli t2, t2, 1              # of = of << 1
    addi t2, t2, 16             # of = of + 16
    addi t0, t0, 1              # cnt++
    j    calc_exp
    
adj_exp:
    ble  t1, x0, find_exa_exp        # if (exp <= 0) find_exa_exp
    bge  a0, t2, find_exa_exp        # if (a0 >= of) find_exa_exp 
    addi t2, t2, -16                # of = of - 16
    srli t2, t2, 1                  # of = of >> 1
    addi t1, t1, -1                 # exp--
    j    adj_exp
    

    
find_exa_exp:
    bge  t1, s5, calc_m         # if (exp >= 15) calc_m    
    slli t0, t2, 1              # t0 = of << 1
    addi t0, t0, 16             # t0 = (of << 1) + 16 = of_e+1
    blt  a0, t0, calc_m         # if (a0 < of_e) calc_m
    mv   t2, t0                   # of = of_e
    addi t1, t1, 1              # exp++
    j    find_exa_exp

calc_m:
    sub t0, a0, t2              # t0 = value - of
    srl t0, t0, t1             # t0 = (value - of) >> exp = m
    ble t0, s5, cmb_num        # if (m < 15) cmb_num
    li  t0, 15                   # m = 15
cmb_num:    
    slli t1, t1, 4              # t1 = exp << 4
    or   a0, t1, t0              # a0 = (exp << 4) | m
    ret
# ------------------------------------------------------------
#return a0
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
    bgtz t1, clz_loop        # while (c) loop
    sub  a0, t0, a0          # return n - x
    ret


print_fail_msg:
    bnez t3, t3_1 
    # fl != fl2
    mv  t3, a0
    mv  a0, s0
    li a7, 1
    ecall
    
    la a0, str1
    li a7, 4
    ecall

    mv  a0, s4
    li a7, 1
    ecall

    la a0, str2
    li a7, 4
    ecall

    mv  a0, t3
    li a7, 1
    ecall
    
    la a0, str5
    li a7, 4
    ecall
    ret
t3_1:
    # previous_value >= value
    mv  a0, s0
    li a7, 1
    ecall
    
    la a0, str3
    li a7, 4
    ecall

    mv  a0, s4
    li a7, 1
    ecall

    la a0, str4
    li a7, 4
    ecall

    mv  a0, s1
    li a7, 1
    ecall
    
    la a0, str5
    li a7, 4
    ecall
    ret
