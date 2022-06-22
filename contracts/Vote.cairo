# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.signature import (
    verify_eth_signature_uint256,
    recover_public_key,
)
from starkware.cairo.common.cairo_keccak.keccak import (
    finalize_keccak,
    keccak_uint256s_bigend,
    keccak_add_uint256s,
    keccak,
)

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.alloc import alloc
from contracts.utils.utils import felt_to_uint256

func keccak_lp{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, keccak_ptr : felt*}(
    n_elements : felt, elements : Uint256*, padding : felt
) -> (res : Uint256):
    alloc_locals
    let (inputs) = alloc()
    let inputs_start = inputs

    keccak_add_uint256s{inputs=inputs}(n_elements=n_elements, elements=elements, bigend=0)

    return keccak(inputs=inputs_start, n_bytes=n_elements * 32 - padding)
end

@storage_var
func prefix() -> (res : Uint256):
end

@storage_var
func domain_separator() -> (res : Uint256):
end

@storage_var
func vote_typehash() -> (res : Uint256):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vote_typehash : Uint256
):
    vote_typehash.write(_vote_typehash)
    return ()
end

# vote(proposal, choice, from)
@external
func vote{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(proposal : Uint256, choice : Uint256, voter : felt, r : Uint256, s : Uint256, v : felt):
    # calc msg hash
    verify_vote(proposal, choice, voter, r, s, v)
    return ()
end

@view
func verify_vote{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(proposal : Uint256, choice : Uint256, voter : felt, r : Uint256, s : Uint256, v : felt) -> (
    res : Uint256
):
    alloc_locals

    let (vote_hash : Uint256) = hash_vote(proposal, choice, voter)

    let (local elements : Uint256*) = alloc()

    # hash (VOTE_TYPEHASH, vote_hash, proposal_hash, choice_hash)
    let (_prefix) = prefix.read()
    let (DOMAIN_SEPARATOR) = domain_separator.read()
    assert elements[0] = _prefix
    assert elements[1] = DOMAIN_SEPARATOR
    assert elements[2] = vote_hash

    let (local keccak_ptr : felt*) = alloc()

    let (msg_hash) = keccak_uint256s_bigend{keccak_ptr=keccak_ptr}(n_elements=3, elements=elements)

    # verify hash with sig
    # verify_eth_signature_uint256{keccak_ptr=keccak_ptr}(
    #     msg_hash=msg_hash, r=r, s=s, v=v, eth_address=voter
    # )

    return (res=msg_hash)
end

@view
func hash_vote{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(proposal : Uint256, choice : Uint256, voter : felt) -> (res : Uint256):
    alloc_locals
    let (local elements : Uint256*) = alloc()
    let (VOTE_TYPEHASH) = vote_typehash.read()
    # hash (VOTE_TYPEHASH, vote_hash, proposal_hash, choice_hash)
    assert elements[0] = VOTE_TYPEHASH
    let (voter_uint256) = felt_to_uint256(voter)
    assert elements[1] = voter_uint256
    assert elements[2] = proposal
    assert elements[3] = choice

    let (local keccak_ptr : felt*) = alloc()

    let (vote_hash) = keccak_uint256s_bigend{keccak_ptr=keccak_ptr}(n_elements=4, elements=elements)
    let (res) = domain_separator.read()
    return (res=vote_hash)
end

@external
func set_hashes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _prefix : felt, _domain_separator : Uint256
):
    prefix.write(Uint256(_prefix, 0))
    domain_separator.write(_domain_separator)

    return ()
end
