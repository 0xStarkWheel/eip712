from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import (
    uint256_unsigned_div_rem,
    uint256_mul,
    uint256_sub,
    uint256_add,
    uint256_lt,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn
from contracts.utils.keccak import finalize_keccak, keccak
from starkware.cairo.common.hash import hash2

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

func get_max{range_check_ptr}(op1, op2) -> (result):
    let (le) = is_le(op1, op2)
    if le == 1:
        return (op2)
    else:
        return (op1)
    end
end

func floor_div{range_check_ptr}(a, b) -> (res):
    let (q, _) = unsigned_div_rem(a, b)
    return (q)
end

func ceil_div{range_check_ptr}(a, b) -> (res):
    let (q, r) = unsigned_div_rem(a, b)
    if r == 0:
        return (q)
    else:
        return (q + 1)
    end
end

func update_msize{range_check_ptr}(msize, offset, size) -> (result):
    # Update MSIZE on memory access from 'offset' to 'offset +
    # size', according to the rules specified in the yellow paper.
    if size == 0:
        return (msize)
    end

    let (result) = get_max(msize, offset + size)
    return (result)
end

func round_down_to_multiple{range_check_ptr}(x, div) -> (y):
    let (r) = floor_div(x, div)
    return (r * div)
end

func round_up_to_multiple{range_check_ptr}(x, div) -> (y):
    let (r) = ceil_div(x, div)
    return (r * div)
end

func felt_to_uint256{range_check_ptr}(x) -> (x_ : Uint256):
    let split = split_felt(x)
    return (Uint256(low=split.low, high=split.high))
end

func uint256_to_address_felt(x : Uint256) -> (address : felt):
    return (x.low + x.high * 2 ** 128)
end

# Todo - This should be updated to precise float div function
func uint256_div{range_check_ptr}(x : Uint256, y : Uint256) -> (res : Uint256):
    let (res, _rem) = uint256_unsigned_div_rem(x, y)
    return (res=res)
end

# return (x * percent) / 100
func uint256_percent{pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : Uint256, percent : Uint256
) -> (res : Uint256):
    let (mul, _high) = uint256_mul(x, percent)
    assert _high.low = 0
    assert _high.high = 0

    let (hundred) = felt_to_uint256(100)
    let (res) = uint256_div(mul, hundred)

    return (res=res)
end

# return (x * y) / z
func uint256_mul_div{pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : Uint256, y : Uint256, z : Uint256
) -> (res : Uint256):
    let (mul, _high) = uint256_mul(x, y)
    # assert _high.low = 0
    # assert _high.high = 0

    let (res) = uint256_div(mul, z)

    return (res=res)
end

# return abs(x-y)
func uint256_pos_diff{pedersen_ptr : HashBuiltin*, range_check_ptr}(x : Uint256, y : Uint256) -> (
    res : Uint256
):
    let (lt) = uint256_lt(x, y)
    if lt == 1:
        let (res) = uint256_sub(y, x)
        return (res=res)
    end
    let (res) = uint256_sub(x, y)
    return (res=res)
end

func min_max{pedersen_ptr : HashBuiltin*, range_check_ptr}(a : felt, b : felt) -> (
    min : felt, max : felt
):
    let (isnn) = is_nn(a - b)
    if isnn == 1:
        return (min=a, max=b)
    end
    return (min=b, max=a)
end

func compute_contract_address{pedersen_ptr : HashBuiltin*, range_check_ptr}(salt : felt) -> (
    res : felt
):
    let basic_seed : felt = 4291823
    let (h1) = hash2{hash_ptr=pedersen_ptr}(basic_seed, salt)
    return (res=h1)
end

# return flag?1:-1
func signed_flag{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(a : felt) -> (
    res : felt
):
    if a == 1:
        return (res=1)
    end
    return (res=-1)
end

# return flag?(a,b):(b,a)
func flag_ordered_pair{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    flag : felt, a : Uint256, b : Uint256
) -> (res0 : Uint256, res1 : Uint256):
    if flag == 1:
        return (res0=a, res1=b)
    end
    return (res0=b, res1=a)
end

# return flag?a:b
func uint256_flag_select{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    flag : felt, a : Uint256, b : Uint256
) -> (res : Uint256):
    if flag == 1:
        return (res=a)
    end
    return (res=b)
end

func is_eq{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a : felt, b : felt
) -> (res : felt):
    if a == b:
        return (res=1)
    end
    return (res=0)
end

func uint256_signed_add{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    flag : felt, a : Uint256, b : Uint256
) -> (res : Uint256):
    alloc_locals
    if flag == 1:
        let (add, _) = uint256_add(a, b)
        return (res=add)
    end
    let (sub) = uint256_sub(a, b)
    return (res=sub)
end

func uint256_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len : felt, arr : Uint256*
) -> (res : Uint256):
    alloc_locals
    if len == 1:
        return (res=arr[0])
    end
    let (extra_sum) = uint256_sum(len - 1, arr + 2)
    let (sum, _) = uint256_add(extra_sum, arr[0])
    return (res=sum)
end
